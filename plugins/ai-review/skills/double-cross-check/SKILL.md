---
name: double-cross-check
description: "Ověř výsledek nezávislým modelem od jiného providera — Codex (OpenAI), Antigravity / agy (Google) nebo Claude Code (Anthropic). Použij na fráze: 'získej druhý názor', 'ověř z jiného modelu', 'zkontroluj přes Codex/Antigravity/Claude Code', 'porovnej názory modelů', 'cross-check', 'dvojitá kontrola', 'fact-check', 'ověř fakta'. Vhodné pro ověřování faktografických dat a investigativní rešerše, kontrolu architektonických rozhodnutí, bezpečnostní audit kódu, porovnávání implementačních přístupů a multi-model konsenzus u rozhodnutí s vyššími stakes. Pro běžný dotaz, kde stačí jedna odpověď, skill nepoužívej — je drahý a pomalý. Používej cíleně."

allowed-tools:
  - AskUserQuestion
  - Read
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Bash(command -v *)
  - Bash(codex --version:*)
  - Bash(codex -a never exec:*)
  - Bash(claude --version:*)
  - Bash(claude -p:*)
  - Bash(date:*)
  - Bash(agy -p:*)
  - Bash(agy --print:*)
  - Bash(agy --prompt:*)
  - Bash(agy models:*)
  - Bash(mktemp:*)
  - Bash(mkdir:*)
  - Bash(cat:*)
  - Bash(echo:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git add:*)
  - Bash(git commit:*)

argument-hint: "otázka / soubor / rozhodnutí k ověření"

---

# Double cross-check: kontrola jiným AI modelem

Získej nezávislý pohled od OpenAI (přes Codex CLI), Google (přes Antigravity CLI — `agy`) nebo Anthropic (přes Claude Code CLI) na výsledek, který sám/sama produkuješ. Smysl: chytit chyby, na které jsi slepý/á — ne potvrdit si vlastní odpověď.

**Sdílené reference** (cesty relativní k adresáři tohoto skillu):

- `../references/cli-reference.md` — kontrola dostupnosti, autentizace, povinné flagy, ošetření selhání, kompletní volací vzory, tabulky voleb CLI a doporučené modely pro všechny tři providery. **Načti před prvním voláním providera.**
- `../references/trusted-sources.md` — kdy AI cross-check nestačí: nezávislé zdroje a seznam důvěryhodných médií.

---

## 1. Identifikuj sebe sama

Než začneš, urči, který model skill právě spouští, podle prostředí (system prompt, název CLI, autentizační kontext). Ověřovatele vybírej **z těch zbývajících**:

- Pokud jsi **Claude** → ověřuje **Codex** a/nebo **agy** (s Gemini modelem).
- Pokud jsi **GPT/Codex** → ověřuje **Claude** a/nebo **agy** (s Gemini modelem).
- Pokud jsi **Gemini** → ověřuje **Codex** a/nebo **Claude**.

Nikdy se neověřuj stejným modelem, který odpověď vyrobil — sdílí stejné slabiny. Pozn.: `agy` hostí kromě Gemini i Claude a GPT-OSS modely. Pro účel cross-checku ho používej výhradně s `Gemini …` modelem (jinak ztrácíš nezávislost rodiny).

---

## 2. Předpoklady prostředí

Skill předpokládá shellové prostředí s nainstalovanými relevantními CLI nástroji. **V prostředí bez shellu** (čistý chat bez bash toolu) skill nelze použít — místo něj nabídni uživateli, ať verifikační prompt pošle do jiného modelu ručně, nebo použij web search pro grounding faktů.

Detaily drží `../references/cli-reference.md`. Nepodkročitelné minimum:

- Před použitím ověř dostupnost CLI (snippet a autentizace v referenci §1).
- `codex`, `agy` a `claude` spouštěj **přímo v systému, NE v sandboxu** — tam jim chybí login a nefungují.
- Každé volání Codexu má tvar `codex -a never exec --skip-git-repo-check ...`; při selhání fallback na `codex:codex-rescue` (jeden retry), pak přepni providera.
- U každého volání kontroluj exit kód — **prázdný výstupní soubor znamená selhání volání**, ne prázdnou odpověď modelu. Po jednom retry přepni providera a selhání poznač do *Nejistot*.
- Pro mezivýstupy používej `WORK=$(mktemp -d)`.

---

## 3. Workflow

1. **Získej ověření** od jednoho nebo více jiných modelů. Pro běžný cross-check stačí jeden; multi-model konsenzus si nech na rozhodnutí s vyššími stakes (publikovatelný výstup, bezpečnostní rozhodnutí, faktografická tvrzení v investigativním textu).
2. **Pročti zjištění bod po bodu.** Pro každou údajnou chybu: ověř ji nezávisle (zdroj, dokumentace, web search, vlastní úvaha) — kontrolor se může mýlit stejně jako autor. Zapracuj jen ty, které ti potvrzená data podpoří.
3. **Re-check.** Opravenou verzi pošli stejnému (nebo jinému) kontrolorovi znovu.
4. **Iterace max. 3×.** Skonči dřív, pokud kontrola nevrací žádné nové připomínky. Po 3 iteracích **shrň zbývající otevřené body uživateli k rozhodnutí** — neztrácej se v nekonečném ladění drobností, na kterých se modely nedohodnou.
5. **Ulož log celé výměny** (všechny iterace) do rootu projektu — viz sekce „Uložení logu konverzace" níže.

---

## 4. Kdy AI cross-check nestačí

AI modely sdílejí trénovací data a s nimi i halucinace. Když ověřuješ **fakt** (existence osoby/účtu, datum, hodnota, citát, právní/historický nárok), nejsilnější kontrola není další model, ale **nezávislý zdroj** — strategii a seznam důvěryhodných médií drží `../references/trusted-sources.md`.

Použij AI cross-check pro **uvažování, strukturu, logické skoky, code review, návrhová rozhodnutí**. Pro fakta ho použij jen jako první filtr a pak ověř proti zdroji.

---

## 5. Prompt engineering pro silnější verifikaci

Slabý prompt → slabá kontrola. Místo "Je tohle správně?" použij vstup uživatele a doporučený prompt.

### Doporučený prompt pro externí model

Použij tento tvar zadání a doplň jen nezbytný kontext:

(Pokud je `$ARGUMENTS` prázdné, ověř výstup z předchozího kola konverzace. Pokud je to cesta k souboru, načti ho. Pokud je to volný popis úlohy, použij ho jako kontext.)

```text
Posuď následující zadání kriticky. Nehledej potvrzení, hledej chyby.

Zaměř se na:
- chybné nebo slabé předpoklady,
- bezpečnostní a provozní rizika,
- opomenuté alternativy,
- nesoulad s běžnou praxí,
- tvrzení, která potřebují primární zdroj nebo test.

U každého nálezu uveď:
- závažnost,
- konkrétní důvod,
- jak nález ověřit,
- doporučenou opravu nebo další krok.

Zadání:
$ARGUMENTS

a přidej potřebný kontext, pokud je potřeba.
```

---

## 6. Rychlé vzory volání

Minimální příklady — kompletní vzory (strukturovaný výstup se schématem, obrázky, workspace grounding, levnější tiery) drží `../references/cli-reference.md` §3.

```bash
WORK=$(mktemp -d)

# Codex (OpenAI)
codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-last-message "$WORK/codex.txt" \
  "Tvá otázka tady"
cat "$WORK/codex.txt"

# Antigravity / agy (Google) — vždy Gemini model
agy -p "Tvá otázka tady" --model "Gemini 3.1 Pro (High)" > "$WORK/agy.txt"
cat "$WORK/agy.txt"

# Claude Code (Anthropic)
claude -p "Tvá otázka tady" --model opus --output-format text > "$WORK/claude.txt"
cat "$WORK/claude.txt"
```

Pro schema-validovaný strukturovaný výstup použij Codex `--output-schema` nebo Claude `--json-schema` (reference §3); `agy` schema validaci nemá — JSON tvar vynucuj v promptu.

**Pozn.:** Spuštěná instance běží nezávisle na aktuální session — kontrolující AI CLI nemá tvůj kontext, dostává opravdu čerstvý pohled.

---

## 7. Příklady použití

### Faktografická verifikace (typický investigativní use-case)

```bash
WORK=$(mktemp -d)

claude -p "Ověř následující tvrzení. Pro každé řekni: pravdivé / nepravdivé / nelze ověřit + důkaz nebo důvod nejistoty. Buď skeptický, nepředpokládej.

Tvrzení:
$(cat tvrzeni.txt)

Pokud potřebuješ pro ověření primární zdroj a nemáš ho, řekni 'potřebuji zdroj X' místo odhadu." \
  --model opus --effort high --output-format text > "$WORK/factcheck.txt"

cat "$WORK/factcheck.txt"
```

**Důležité:** model nemá přístup k živým zdrojům, takže "pravdivé" znamená "konzistentní s trénovacími daty modelu" — ne "ověřeno proti realitě". Pro fakta novější než cutoff modelu, nebo pro tvrzení o konkrétních osobách/účtech/datech, zkombinuj s web search nebo strukturovaným zdrojem (Wikidata, psp.cz, ARES, justiční databáze atd.).

### Cross-reference strukturovaného datasetu

```bash
WORK=$(mktemp -d)

codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="high"' \
  --output-last-message "$WORK/dataset_review.txt" \
  "Mám dataset přiřazení X účtů osobám (CSV níže). Najdi:
   - podezřelé záznamy (false-positive matching, různé osoby stejné jméno)
   - chybějící atribuce (osoba bez účtu — opravdu žádný, nebo nedohledán?)
   - nesrovnalosti mezi sloupci
   - vzorky vyžadující ruční ověření

   Pro každý nález: ID řádku + důvod podezření + konkrétní návrh, jak ověřit.

   Data:
   $(cat dataset.csv)"

cat "$WORK/dataset_review.txt"
```

### Kontrola architektury

```bash
WORK=$(mktemp -d)
agy -p "Posuď toto architektonické rozhodnutí: [popis].
  Buď skeptický. Hodnoť: škálovatelnost, udržovatelnost, bezpečnostní rizika, alternativy.
  Pro každou výhradu: konkrétní scénář, kde rozhodnutí selže." \
  --model "Gemini 3.1 Pro (High)" > "$WORK/arch.txt"
cat "$WORK/arch.txt"
```

### Bezpečnostní audit

```bash
WORK=$(mktemp -d)
codex -a never exec --skip-git-repo-check -m gpt-5.5 -c 'model_reasoning_effort="xhigh"' \
  --output-last-message "$WORK/security.txt" \
  "Bezpečnostní review následujícího kódu:

   $(cat src/auth.py)

   Hledej: vstupní validaci, autentizaci/autorizaci, expozici dat, race conditions, injection.
   Pro každou nalezenou zranitelnost: lokace (řádek), exploit scénář, oprava."
cat "$WORK/security.txt"
```

### Code review

```bash
WORK=$(mktemp -d)
claude -p "Review následujícího diffu na: bugy, výkonnostní problémy, udržovatelnost, test coverage gaps.
  Pro každou připomínku: lokace + závažnost (blocker / major / minor / nit) + návrh opravy.
  Buď skeptický k autorově optimismu.

  Diff:
  $(git diff main..HEAD -- src/)" \
  --model opus --effort high --output-format text > "$WORK/review.txt"
cat "$WORK/review.txt"
```

Pozn.: u příkladů s `$(cat soubor)` nejdřív ověř, že soubor existuje — chybějící soubor by do promptu vložil prázdný obsah.

---

## 8. Co dělat při neshodě modelů

Když si Codex a agy (Gemini) protiřečí, neber žádný z nich za autoritu:

1. **Konkrétnější tvrzení s odkazem na zdroj > obecné tvrzení.** Pokud Codex říká "X je špatně, viz CVE-2024-1234" a agy říká "X je v pořádku", začni s tím konkrétním a ověř CVE.
2. **Pro fakta zvol nezávislý zdroj** (web search, dokumentace, registry) místo třetího modelu — modely sdílejí halucinace, takže "tie-breaker" třetím modelem je iluze nezávislosti.
3. **Pro názory a preference** (např. "Redis vs PostgreSQL pro session storage") neshoda často odráží reálný trade-off, ne chybu. Surface obě perspektivy uživateli s tím, na čem rozhodnutí závisí.
4. **Pokud spor zůstává nerozhodnutý**, přiznej to v odpovědi explicitně — neforsírovej falešný konsenzus.

---

## 9. Náklady a latence

Multi-model cross-check není zadarmo. Reasoning modely na high/xhigh effort běží desítky sekund a stojí znatelně víc než single call. Doporučení:

- **Single cross-check** (jeden další model): default pro většinu kontrol.
- **Multi-model konsenzus** (všechny tři): nech si na rozhodnutí, kde stojí čas a peníze za to — publikovatelný výstup, faktografická tvrzení v investigativním materiálu, bezpečnostně-citlivý kód, architektonické rozhodnutí s dlouhodobým dopadem.
- **Levnější tier pro rychlé checky:** viz tabulka „Doporučení modelu podle úlohy" v `../references/cli-reference.md` §5.

V Claude Code se vyplatí omezit `--max-turns` (default je bez limitu) a případně `--max-budget-usd`, aby ti neutekly náklady při delší smyčce.

---

## 10. Uložení logu konverzace

Po dokončení cross-checku ulož **celou výměnu** (všechny iterace) do log souboru v **rootu projektu**. Log musí zachytit tři části: **prompt**, který jsi poslal/a, **odpověď** externího modelu a tvé vlastní **vyhodnocení** (přijaté/odmítnuté nálezy, doporučení, nejistoty).

```bash
# Ulož přesný prompt a své vyhodnocení do souborů (aby je log obsahoval doslovně)
cat > "$WORK/prompt.txt" << 'EOF'
[přesný prompt/otázka poslaná externímu modelu]
EOF

cat > "$WORK/evaluation.txt" << 'EOF'
[tvé vyhodnocení: přijaté nálezy, odmítnuté nálezy, doporučení, nejistoty]
EOF

# Log do rootu projektu
TIMESTAMP=$(date '+%Y-%m-%d_%H.%M.%S')
LOG="./.double-cross-check-talk_${TIMESTAMP}.log"

{
  echo "=== Double Cross-Check Log: $TIMESTAMP ==="
  echo "Provider: [provider/model]"
  echo ""
  echo "--- Prompt ---"
  cat "$WORK/prompt.txt"
  echo ""
  echo "--- Response ---"
  cat "$WORK/answer.txt"
  echo ""
  echo "--- Evaluation ---"
  cat "$WORK/evaluation.txt"
} > "$LOG"

echo "Log saved to: $LOG"

# Logy jsou určené k verzování — pokud je projekt git repo, commitni log
[ -d .git ] && git add "$LOG" && git commit -m "double-cross-check: log ${TIMESTAMP}"
```

Při více iteracích připoj do logu každé kolo (`--- Iteration N: Prompt / Response / Evaluation ---`).

---

## 11. Vyhodnocení a prezentace výsledků

Výstup externího modelu ber jako **hypotézy, ne jako pravdu**. Druhý model může mít stejné slepé místo jako ty — "ověřeno cross-checkem" není totéž co "ověřeno proti realitě".

### Postup vyhodnocení

1. Přečti nálezy externího modelu bod po bodu.
2. Každý konkrétní nález ověř proti dostupným souborům, testům, dokumentaci nebo primárnímu zdroji.
3. Přijmi jen nálezy, které jsou konkrétní, relevantní a ověřené.
4. Odmítni nálezy, které jsou spekulativní, neplatné nebo mimo rozsah.

Nikdy nezapracovávej doporučení jen proto, že ho uvedl jiný model. Zapracuj ho **až po vlastním ověření**.

### Struktura finální odpovědi uživateli

Jasně odděl:

- **Druhý názor** — který provider/model byl použit (např. *"OpenAI / Codex – gpt-5.5"* nebo *"Konsenzus: Codex + Gemini"*) a stručné shrnutí, co řekl.
- **Přijaté nálezy** — co jsi po vlastním ověření přijal/a jako pravdivé. Pro každý: lokace + důkaz nebo zdůvodnění.
- **Odmítnuté nálezy** — co jsi nepotvrdil/a a proč.
- **Změny nebo doporučení** — co bylo provedeno nebo co má následovat.
- **Nejistoty** — co vyžaduje další primární zdroj, test nebo rozhodnutí uživatele.

### Doplňková pravidla

- **Porovnej se svou původní analýzou.** Zdůrazni, kde ses lišil/a od externího modelu.
- **Při více kontrolorech** vyjmenuj oblasti shody i neshody mezi nimi předtím, než přejdeš k vlastnímu vyhodnocení.
- **Pokud spor mezi modely zůstává nerozhodnutý** i po vlastním ověření, nech ho v sekci *Nejistoty* otevřený a popiš, na čem rozhodnutí závisí — neforsírovej falešný konsenzus.
