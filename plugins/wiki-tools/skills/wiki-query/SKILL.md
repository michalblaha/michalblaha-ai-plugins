---
name: wiki-query
description: "Odpovídá na otázky pomocí Obsidian wiki vaultu. Nejprve čte hot cache, pak rejstřík, pak relevantní stránky. Syntetizuje odpovědi s citacemi. Dobré odpovědi ukládá zpět jako wiki stránky. Podporuje quick, standard a deep mód. Triggers on: what do you know about, query:, what is, explain, summarize, find in wiki, search the wiki, based on the wiki, wiki query quick, wiki query deep."
allowed-tools: Read Glob Grep
---

# wiki-query: Dotazy nad wiki

Wiki již provedla syntézní práci. Čti strategicky, odpovídej přesně a dobré odpovědi ukládej zpět, aby se znalosti kumulovaly.

---

## Query módy

Tři hloubky. Vyber podle složitosti dotazu.

| Mód | Trigger | Čte | Spotřeba tokenů | Vhodné pro |
|------|---------|-------|------------|---------|
| **Quick** | `query quick: ...` nebo jednoduchá faktická otázka | hot.md + index.md | ~1 500 | „What is X?", lookup dat, rychlá fakta |
| **Standard** | výchozí (bez flagu) | hot.md + index + 3–5 stránek | ~3 000 | Většina otázek |
| **Deep** | `query deep: ...` nebo „thorough", „comprehensive" | Celá wiki + volitelně web | ~8 000+ | „Compare A vs B across everything", syntéza, gap analýza |

---

## Quick mód

Použij, když odpověď bude pravděpodobně v hot cache nebo shrnutí v rejstříku.

1. Přečti `wiki/hot.md`. Pokud odpovídá, odpověz okamžitě.
2. Pokud ne, přečti `wiki/index.md`. Prohledej popisy.
3. Pokud nalezeno v shrnutí rejstříku, odpověz a žádné stránky neotvírej.
4. Pokud nenalezeno, řekni „Není v quick cache. Spustit jako standard query?"

V quick módu neotvírej jednotlivé wiki stránky.

---

## Standard query workflow

1. **Read** `wiki/hot.md` jako první. Může již obsahovat odpověď nebo přímo relevantní kontext.
2. **Read** `wiki/index.md` pro nalezení nejrelevantnějších stránek (prohledej názvy a popisy).
3. **Read** těchto stránek. Sleduj wikilinky do hloubky 2 pro klíčové entity. Hlouběji ne.
4. **Synthesize** odpověď v chatu. Citace jako wikilinky: `(Source: [[Page Name]])`.
5. **Offer to file** odpověď: „Tato analýza vypadá hodnotně. Mám ji uložit jako `wiki/questions/answer-name.md`?"
6. Pokud otázka odhalí **mezeru**: řekni „Nemám dost o X. Chceš najít zdroj?"

---

## Deep mód

Použij pro syntézní otázky, srovnání nebo „tell me everything about X."

1. Přečti `wiki/hot.md` a `wiki/index.md`.
2. Identifikuj všechny relevantní sekce (concepts, entities, sources, comparisons).
3. Přečti každou relevantní stránku. Bez vynechávání.
4. Pokud je pokrytí ve wiki řídké, nabídni doplnění web searchem.
5. Syntetizuj komplexní odpověď s úplnými citacemi.
6. Vždy výsledek zapisuj zpět jako wiki stránku. Hluboké odpovědi jsou příliš cenné, abychom je ztratili.

---

## Disciplína tokenů

Čti minimum potřebné:

| Začni | Cena (přibl.) | Kdy přestat |
|------------|---------------|--------------|
| hot.md | ~500 tokenů | Pokud má odpověď |
| index.md | ~1000 tokenů | Pokud identifikuješ 3–5 relevantních stránek |
| 3–5 wiki stránek | ~300 tokenů každá | Obvykle stačí |
| 10+ wiki stránek | drahé | Pouze pro syntézu napříč celou wiki |

Pokud má hot.md odpověď, odpověz bez dalšího čtení.

---

## Reference formátu rejstříku

Hlavní rejstřík (`wiki/index.md`) vypadá takto:

```markdown
## Domains
- [[Domain Name]]: popis (N sources)

## Entities
- [[Entity Name]]: role (first: [[Source]])

## Concepts
- [[Concept Name]]: definice (status: developing)

## Sources
- [[Source Title]]: autor, datum, typ

## Questions
- [[Question Title]]: shrnutí odpovědi
```

Nejprve prohledej hlavičky sekcí, abys určil, které sekce číst.

---

## Formát doménového sub-rejstříku

Každá doménová složka má `_index.md` pro fokusované hledání:

```markdown
---
type: meta
title: "Entities Index"
updated: YYYY-MM-DD
---
# Entities

## People
- [[Person Name]]: role, organizace

## Organizations
- [[Org Name]]: čím se zabývají

## Products
- [[Product Name]]: kategorie
```

Sub-rejstříky používej, když je otázka omezena na jednu doménu. U úzkých dotazů se vyhni čtení celého hlavního rejstříku.

---

## Ukládání odpovědí zpět

Dobré odpovědi se kumulují do wiki. Nenech je zmizet v historii chatu.

Při ukládání odpovědi:

```yaml
---
type: question
title: "Krátký popisný titulek"
question: "Přesný dotaz, jak byl položen."
answer_quality: solid
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [question, <domain>]
related:
  - "[[Page referenced in answer]]"
sources:
  - "[[wiki/sources/relevant-source.md]]"
status: developing
---
```

Pak napiš odpověď jako tělo stránky. Zahrň citace. Olinkuj každý zmíněný koncept nebo entitu.

Po uložení přidej záznam do `wiki/index.md` pod Questions a připoj do `wiki/log.md`.

---

## Řešení mezer

Pokud nelze otázku zodpovědět z wiki:

1. Řekni jasně: „Nemám ve wiki dostatek na dobrou odpověď."
2. Identifikuj konkrétní mezeru: „Nemám nic o [podtématu]."
3. Navrhni: „Chcete najít zdroj? Můžu pomoct s vyhledáním nebo zpracováním."
4. Nevymýšlej. Pokud je dotaz o konkrétní doméně této wiki, neodpovídej z tréninkových dat.

---

## Volitelné: druhý názor v deep módu

V deep módu (rozsáhlé syntézy, sporné domény, rozhodnutí s vyššími stakes) můžeš po sestavení odpovědi spustit skill `second-opinion` (z companion pluginu `ai-review`) pro nezávislou validaci od jiného modelu. Pokud plugin není nainstalován, vyhodnoť odpověď sám a explicitně označ tvrzení, která by si zasloužila externí cross-check.
