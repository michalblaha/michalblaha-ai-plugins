# Referenční příručka: volání AI CLI providerů

Sdílená reference pro skilly `second-opinion` a `double-cross-check`. Ze skillu ji načteš relativní cestou `../references/cli-reference.md`. Drží se tu vše, co se týká volání tří CLI nástrojů — vzory, flagy, tabulky voleb a doporučené modely — aby se změny (např. nová verze modelu) dělaly na jednom místě.

Provideři:

- **Codex CLI** (OpenAI) — `codex`
- **Antigravity CLI** (Google) — `agy`; hostí Gemini, Claude i GPT-OSS modely, pro cross-check volej výhradně s `Gemini …` modelem
- **Claude Code CLI** (Anthropic) — `claude`

---

## 1. Dostupnost a autentizace

```bash
codex --version  || echo "Codex CLI není nainstalované"
command -v agy >/dev/null && agy models >/dev/null 2>&1 \
  && echo "Antigravity (agy) OK" \
  || echo "Antigravity CLI (agy) není nainstalované nebo není nakonfigurované"
claude --version || echo "Claude Code CLI není nainstalované"
```

- **Codex:** `codex login` nebo env var `OPENAI_API_KEY`
- **Antigravity (agy):** první nastavení `agy install` (PATH + shell aliases), přihlášení dle <https://antigravity.google/docs/cli-reference>
- **Claude Code:** `claude auth login` nebo env var `ANTHROPIC_API_KEY`

**Workdir:** všechny vzory používají `WORK=$(mktemp -d)` a pak `$WORK/...` pro mezivýstupy — žádné kolize při paralelním běhu.

**DŮLEŽITÉ:** `codex`, `agy` a `claude` spouštěj přímo v systému, **NE v sandboxu** — v sandboxu chybí login credentials a volání selžou.

---

## 2. Povinné flagy a ošetření selhání

**Codex — povinná kombinace `-a never exec --skip-git-repo-check`:** každé volání Codexu z těchto skillů má tvar `codex -a never exec --skip-git-repo-check ...`. Codex defaultně odmítne běžet mimo git repo; skilly přes něj nic nezapisují, takže check je zbytečný. Bez flagu volání selže s chybou *"not inside a Git repository"*.

**Fallback při selhání Codexu:** pokud `codex exec` selže i s flagy (timeout, autentizace, runtime error), deleguj na `codex:codex-rescue` skill / subagent. Jen jeden retry; pokud selže i ten, přepni na jiného providera a poznač selhání do sekce *Nejistoty* finální odpovědi.

**Kontrola selhání u všech providerů:** `agy` a `claude` při chybě typicky zapíšou prázdný výstupní soubor. Po každém volání ověř exit kód — prázdný soubor znamená **selhání volání, ne prázdnou odpověď externího modelu**:

```bash
agy -p "…" --model "Gemini 3.1 Pro (High)" > "$WORK/answer.txt" \
  || { echo "agy call failed"; }
[ -s "$WORK/answer.txt" ] || echo "WARNING: empty answer — treat as provider failure"
```

Po jednom retry přepni na jiného providera a selhání poznač do *Nejistot*. Nikdy nevyhodnocuj prázdný soubor jako platnou odpověď.

---

## 3. Volací vzory

### Codex (OpenAI)

```bash
WORK=$(mktemp -d)

# Jednoduchá otázka
codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-last-message "$WORK/answer.txt" \
  "Tvá otázka tady"
cat "$WORK/answer.txt"

# Strukturovaný výstup s validací JSON Schema
cat > "$WORK/schema.json" <<'EOF'
{
  "type": "object",
  "properties": {
    "assessment":     { "type": "string" },
    "strengths":      { "type": "array", "items": { "type": "string" } },
    "concerns":       { "type": "array", "items": { "type": "string" } },
    "recommendation": { "type": "string" }
  },
  "required": ["assessment", "strengths", "concerns", "recommendation"],
  "additionalProperties": false
}
EOF

codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-schema "$WORK/schema.json" \
  --output-last-message "$WORK/result.json" \
  "Analyzuj [téma]. Vrať strukturované zhodnocení."
cat "$WORK/result.json"
```

**Pozn. ke schématu:** všechny objekty (i vnořené) musí mít `"additionalProperties": false` a `"required": [...]` se všemi vlastnostmi. Jinak Codex volání odmítne.

### Antigravity / agy (Google)

```bash
WORK=$(mktemp -d)

# Jednoduchá otázka s Gemini 3.1 Pro
agy -p "Tvá otázka tady" --model "Gemini 3.1 Pro (High)" > "$WORK/answer.txt"
cat "$WORK/answer.txt"

# Rychlejší / levnější Flash
agy -p "Tvá otázka tady" --model "Gemini 3.5 Flash (High)" > "$WORK/answer.txt"

# JSON výstup (bez schema validace — tvar vynucuj v promptu)
agy -p "Analyzuj [téma]. Odpověz JSONem s klíči assessment (string), strengths (array), concerns (array), recommendation (string). Vrať POUZE JSON objekt, žádný okolní text." \
  --model "Gemini 3.1 Pro (High)" > "$WORK/result.json"
cat "$WORK/result.json"

# Volitelně: workspace pro grounding nad konkrétními soubory
agy -p "Reviewuj architekturu projektu." \
  --add-dir "$PWD/src" \
  --model "Gemini 3.1 Pro (High)" > "$WORK/answer.txt"
```

**Pozn.:** `agy` nemá `--output-format` flag — výstup je vždy raw text na stdout. JSON tvar vynucuj v promptu; pro validaci proti schématu použij Codex (`--output-schema`) nebo Claude (`--json-schema`). Názvy modelů obsahují mezery a závorky — vždy dvojité uvozovky. Aktuální seznam modelů: `agy models`.

### Claude Code (Anthropic)

```bash
WORK=$(mktemp -d)

# Jednoduchá otázka (alias 'opus' = nejlepší dostupný Opus)
claude -p "Tvá otázka tady" --model opus --output-format text > "$WORK/answer.txt"
cat "$WORK/answer.txt"

# Konkrétní pin verze (reprodukovatelnost)
claude -p "Tvá otázka tady" --model claude-opus-4-7 \
  --effort xhigh --output-format text > "$WORK/answer.txt"

# Levnější / rychlejší pro jednoduché úlohy
claude -p "Tvá otázka tady" --model haiku --output-format text > "$WORK/answer.txt"

# Strukturovaný výstup s validací JSON Schema
claude -p "Analyzuj [téma]. Vrať strukturované zhodnocení." \
  --model opus --json-schema "$WORK/schema.json" > "$WORK/result.json"
cat "$WORK/result.json"
```

**Pozn.:** `claude -p` (`--print`) spustí nezávislou instanci bez kontextu aktuální session — ověřovatel dostává opravdu čerstvý pohled. Totéž platí pro `codex exec` a `agy -p`.

---

## 4. Tabulky voleb CLI

### Codex CLI

| Volba | Účel |
|---|---|
| `-m gpt-5.5` | Aktuální frontier model (doporučeno pro hloubkovou kontrolu) |
| `-m gpt-5.5-codex` | Codex-optimalizovaná verze 5.5 pro agentické kódování |
| `-m gpt-5.4-mini` | Rychlý a levný pro jednoduché úlohy |
| `-c 'model_reasoning_effort="high"'` | Reasoning effort. Hodnoty: `low`, `medium`, `high`, `xhigh` |
| `--output-schema file.json` | Strukturovaný JSON s validací schématu |
| `--output-last-message file.txt` | Uložení odpovědi do souboru |
| `-i image.png` | Přidání obrázku k analýze |

### Antigravity (agy) CLI

| Volba | Účel |
|---|---|
| `--model "Gemini 3.1 Pro (High)"` | Nejlepší Gemini reasoning (uvozovky kvůli mezerám) |
| `--model "Gemini 3.1 Pro (Low)"` | Rychlejší Gemini Pro |
| `--model "Gemini 3.5 Flash (High)"` | Rychlejší a levnější Gemini Flash |
| `--model "Gemini 3.5 Flash (Medium\|Low)"` | Další varianty Flash modelu |
| `--model "Claude Opus 4.6 (Thinking)"` | Anthropic přes agy (pro cross-check **nepoužívej** — ztrácíš nezávislost providera) |
| `--model "GPT-OSS 120B (Medium)"` | Open-source GPT-OSS model |
| `-p "prompt"` / `--print` / `--prompt` | Neinteraktivní print mode (povinné pro skripty) |
| `--print-timeout 5m` | Timeout pro print mode (default 5m) |
| `--add-dir <path>` | Přidá adresář do workspace (repeatable) — grounding nad reálnými soubory |
| `--dangerously-skip-permissions` | Auto-approve tool permission promptů (jen pro neinteraktivní skripty) |
| `agy models` | Vypíše seznam dostupných modelů |
| `agy install` | První nastavení (PATH, shell aliases) |

### Claude Code CLI

| Volba | Účel |
|---|---|
| `--model opus` | Alias na nejlepší dostupný Opus |
| `--model claude-opus-4-7` | Pin konkrétní verze (reprodukovatelnost) |
| `--model sonnet` / `claude-sonnet-4-6` | Vyvážená rychlost a kvalita |
| `--model haiku` / `claude-haiku-4-5-20251001` | Rychlý a levný |
| `--effort xhigh` | Hluboké uvažování. Hodnoty: `low`, `medium`, `high`, `xhigh`, `max` |
| `-p "prompt"` | Neinteraktivní print mode (povinné pro skripty) |
| `--output-format text` / `json` | Formát výstupu (`json` = strukturovaný message objekt) |
| `--json-schema file.json` | Strukturovaný JSON s validací schématu |
| `--max-turns N` | Strop agentních kol (default: bez limitu) |
| `--max-budget-usd N` | Strop útraty na session |
| `--permission-mode bypassPermissions` | Pro CI / non-interactive bez schvalování — jen se souhlasem uživatele |

---

## 5. Doporučení modelu podle úlohy

| Úloha | Codex (OpenAI) | Antigravity / agy (Google) | Claude Code (Anthropic) |
|---|---|---|---|
| Komplexní rešerše / architektura | `gpt-5.5` + high/xhigh | `"Gemini 3.1 Pro (High)"` | `claude-opus-4-7` + xhigh |
| Rychlé code review | `gpt-5.4-mini` | `"Gemini 3.5 Flash (High)"` | `haiku` |
| Bezpečnostní audit (hluboký) | `gpt-5.5` + xhigh | `"Gemini 3.1 Pro (High)"` | `claude-opus-4-7` + xhigh |
| Strukturovaný výstup s validací | `gpt-5.5` + `--output-schema` | — (bez schema validace) | `claude-opus-4-7` + `--json-schema` |
| Faktografická verifikace | `gpt-5.5` (kombinuj se zdroji) | `"Gemini 3.1 Pro (High)"` | `claude-opus-4-7` |
| Multi-model konsenzus | spusť všechny tři a porovnej | spusť všechny tři a porovnej | spusť všechny tři a porovnej |

Aliasy (`opus`, `sonnet`, `haiku`, `gpt-5.5`) ukazují na aktuálně doporučenou verzi providera; pro reprodukovatelnost pinuj konkrétní verzi modelu.
