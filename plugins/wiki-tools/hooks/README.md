# wiki-tools Hooks

Plugin hooks pro `wiki-tools` wiki vault. Všechny hooks jsou definovány v `hooks.json`.

## Události

| Událost | Typ | Účel |
|---|---|---|
| `SessionStart` | command + prompt | Načítá `wiki/hot.md` do kontextu. Command typ spouští `[ -f wiki/hot.md ] && cat wiki/hot.md` jako kanonickou kontrolu (funguje i pro non-vault relace bez chyby). Prompt typ doplňuje sémantickou obnovou kontextu. Matcher: `startup\|resume`. |
| `PostCompact` | prompt | Re-loaduje `wiki/hot.md` po kompakci kontextu. Hook-injected kontext NEPŘEŽÍVÁ kompakci (pouze `CLAUDE.md` ano), takže tento hook obnoví hot cache uprostřed relace. |
| `PostToolUse` | command | Auto-commit změn ve `wiki/` nebo `raw/` po Write nebo Edit voláních. Chráněno `[ -d .git ]`, takže nikdy nechybuje v non-git adresářích, a `git diff --cached --quiet`, takže nikdy nevytvoří prázdný commit. |
| `Stop` | prompt | Aktualizuje `wiki/hot.md` na konci každé Claude odpovědi krátkým shrnutím změn. |

## Známý problém: Plugin Hooks STDOUT bug

`anthropics/claude-code#10875` dokumentuje, že **STDOUT plugin hooků nemusí být zachycen** Claude Code, zatímco identické inline hooks v `settings.json` fungují správně.

**Dopad**: Pokud je tento bug aktivní ve vaší verzi Claude Code, prompt-typ SessionStart a PostCompact hooks nemusí injektovat kontext podle očekávání.

**Workaround**: Command-typ SessionStart hook (`cat wiki/hot.md`) je kanonická kontrola. Spoléhá na zachycení STDOUT pro injekci kontextu, takže pokud obnova hot cache selhává, otestujte tento problém. Jako fallback zkopírujte konfiguraci hooků z `hooks.json` do svého user-level `~/.claude/settings.json` místo plugin hooků.

**Test bugu**: Po instalaci pluginu otevřete novou Claude Code relaci v adresáři s naplněným `wiki/hot.md`. Zeptejte se Claude „what's in the hot cache?". Pokud Claude nemá tušení, STDOUT bug je ve vaší verzi aktivní.

## Non-vault relace

SessionStart command hook používá `[ -f wiki/hot.md ] && cat wiki/hot.md || true`, takže vždy končí kódem 0, i když není přítomen vault. Díky tomu lze plugin bezpečně nainstalovat globálně, aniž by rozbil non-vault Claude Code relace.
