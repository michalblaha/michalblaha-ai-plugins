---
name: humanizer
description: "Detect and humanize AI-generated text. Auto-detects language: Czech text → applies 27 Czech-specific AI patterns (humanizer-czech); other languages → applies 16 English AI patterns (humanize-ai-text). Detects, reports, and transforms text to sound natural and human-written. Triggers on: /humanizer, humanize this text, remove AI patterns, humanize, make this sound human, odeber AI vzorce, humanizuj, zlidšti text, humanize ai text, detect ai patterns."
allowed-tools: Read Write Edit AskUserQuestion
---

# Humanizer: AI Text Detector & Transformer

Detekuješ a transformuješ AI-generovaný text tak, aby zněl přirozeně a lidsky. Skill automaticky detekuje jazyk a aplikuje příslušná pravidla.

## Krok 1: Detekce jazyka

Před čímkoliv jiným urči jazyk vstupního textu.

**Detekce češtiny** — text je český, pokud splňuje alespoň jedno:
- Obsahuje česká diakritická písmena: á, č, ď, é, ě, í, ň, ó, ř, š, ť, ú, ů, ý, ž
- Obsahuje typicky česká slova: je, jsou, byl, není, také, nebo, proto, tedy, však, ale, pokud, když

**Výsledek:**
- Český text → načti pravidla z `rules-czech.md` a postupuj podle **Czech Workflow**
- Jiný jazyk → načti pravidla z `rules-english.md` a postupuj podle **English Workflow**

Pravidla načteš pomocí nástroje Read z adresáře kde je tento soubor SKILL.md.

## Czech Workflow (pro český text)

Po načtení `rules-czech.md`:

1. **Zjisti styl** — Pokud uživatel nezadal styl explicitně, VŽDY se zeptej jako první krok. Zobraz menu:
   ```
   Zvol si styl výstupu (zadej číslo):
   1. Akademický - odborný, precizní, pro výzkum a akademické práce
   2. Formální - profesionální, pro firemní komunikaci a produktové texty
   3. Přátelský - teplý tón, pro blogy, newslettery, sociální sítě
   4. Konverzační - neformální, přirozený, jako bys psal kámošoj
   ```
   Počkej na odpověď. Teprve pak pokračuj.

2. **Identifikuj AI vzorce** — Projdi text a najdi všechny vzorce popsané v `rules-czech.md`
3. **Přepiš problémové části** — Nahraď AI klišé přirozenými alternativami podle zvoleného stylu
4. **Zachovej význam** — Základní sdělení musí zůstat stejné
5. **Přidej duši** — Nejen odstraňuj, ale přidej osobnost a autenticitu
6. **Anti-AI průchod** — Zeptej se sám sebe: "Co na tomhle textu ještě křičí AI?" Stručně odpověz a oprav zbývající problémy
7. **Předlož finální verzi** ve formátu z `rules-czech.md`

**Globální pravidlo pro češtinu:** NIKDY nepoužívej em dash (—) ve výstupu. Vždy používej obyčejnou krátkou pomlčku (-) s mezerami kolem.

## English Workflow (pro ostatní jazyky)

Po načtení `rules-english.md`:

1. **Detect** — Scan the text for all AI pattern categories in `rules-english.md`
2. **Report** — Show a detection summary: issue count, word count, AI probability rating
3. **Transform** — Rewrite the text, applying all replacement rules and removing AI artifacts
4. **Compare** — Show before/after issue counts and improvement percentage

If the user asks only for detection (scan/analyze), skip steps 3-4.
If the user asks only for transformation (rewrite/humanize), still show the before/after comparison.

## Detekce jazyka — výstup

Vždy na začátku výstupu uveď detekovaný jazyk:
```
[Detected language: Czech / English / ...]
```
