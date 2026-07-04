# wiki-tools Hooks

Plugin hooks pro `wiki-tools` wiki vault. Všechny hooks jsou definovány v `hooks.json`.

## Události

| Událost | Typ | Účel |
|---|---|---|
| `SessionStart` | command | Načítá `wiki/hot.md` do kontextu. Command typ spouští `[ -f wiki/hot.md ] && cat wiki/hot.md` jako kanonickou kontrolu (funguje i pro non-vault relace bez chyby). Matcher: `startup\|resume\|compact` — matcher `compact` obnoví hot cache i po kompakci kontextu, protože hook-injected kontext kompakci NEPŘEŽÍVÁ (pouze `CLAUDE.md` ano). (Pozn.: prompt typ zde byl odstraněn — Claude Code nepodporuje prompt hooky pro SessionStart, protože při startu relace ještě neexistuje kontext konverzace. Dřívější `PostCompact` event byl odstraněn — Claude Code takový event nemá, kompakce se zachytává právě přes SessionStart matcher `compact`.) |
| `PostToolUse` | command | Auto-commit změn ve `wiki/` nebo `raw/` po Write nebo Edit voláních. Chráněno `[ -d .git ] && [ -d wiki ]`, takže se neaktivuje mimo vault a nikdy nechybuje v non-git adresářích, a `git diff --cached --quiet`, takže nikdy nevytvoří prázdný commit. |
| `Stop` | command | Pokud se v relaci změnily soubory pod `wiki/`, vypíše na stdout připomínku `WIKI_CHANGED: ...`, která instruuje agenta aktualizovat `wiki/hot.md` krátkým shrnutím změn. Samotný hook nic nezapisuje — aktualizaci provede agent. |

## Známý problém: Plugin Hooks STDOUT bug

`anthropics/claude-code#10875` dokumentuje, že **STDOUT plugin hooků nemusí být zachycen** Claude Code, zatímco identické inline hooks v `settings.json` fungují správně.

**Dopad**: Pokud je tento bug aktivní ve vaší verzi Claude Code, SessionStart hook (včetně matcheru `compact`) a Stop hook nemusí injektovat kontext podle očekávání.

**Workaround**: Command-typ SessionStart hook (`cat wiki/hot.md`) je kanonická kontrola. Spoléhá na zachycení STDOUT pro injekci kontextu, takže pokud obnova hot cache selhává, otestujte tento problém. Jako fallback zkopírujte konfiguraci hooků z `hooks.json` do svého user-level `~/.claude/settings.json` místo plugin hooků.

**Test bugu**: Po instalaci pluginu otevřete novou Claude Code relaci v adresáři s naplněným `wiki/hot.md`. Zeptejte se Claude „what's in the hot cache?". Pokud Claude nemá tušení, STDOUT bug je ve vaší verzi aktivní.

## Non-vault relace

SessionStart command hook používá `[ -f wiki/hot.md ] && cat wiki/hot.md || true`, takže vždy končí kódem 0, i když není přítomen vault. Díky tomu lze plugin bezpečně nainstalovat globálně, aniž by rozbil non-vault Claude Code relace.
