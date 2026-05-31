# wiki-tools — Claude

Tato složka je Claude Code / Codex plugin a zároveň Obsidian vault. Postaveno na vzoru LLM Wiki od Andreje Karpathyho.

**Název pluginu:** `wiki-tools`
**Skills:** `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-autoresearch`, `html-clean`, `obsidian-markdown`
**Příkazy:** `/wiki-autoresearch`
**Cesta k vaultu:** Tento adresář (otevřete přímo v Obsidianu)

## Účel

Trvalá, kumulující se znalostní báze udržovaná Claudem. Claude wiki vytváří, organizuje a propojuje. Uživatel kurátoruje zdroje, pokládá otázky a vede analýzu.

## Struktura vaultu

```
raw/                  zdrojové dokumenty — NEMĚNNÉ, Claude pouze čte, nikdy neupravuje
wiki/                 znalostní báze generovaná Claudem
wiki/index.md         hlavní katalog (table of contents) celé wiki
wiki/log.md           append-only záznam všech operací
wiki/hot.md           cache nedávného kontextu (~500 slov)
raw/_attachments/     obrázky a PDF, na které wiki stránky odkazují
```

## Workflow

### Ingest zdroje
Když uživatel přidá nový zdroj do `raw/` a požádá o ingest:

1. Přečti zdrojový dokument celý
2. Než cokoli napíšeš, prober s uživatelem klíčové poznatky
3. Vytvoř shrnující stránku v `wiki/sources/` pojmenovanou podle zdroje
4. Vytvoř nebo aktualizuj stránky konceptů a entit pro každou významnou myšlenku, osobu, organizaci nebo produkt
5. Použij wikilinks `[[Název stránky]]` pro propojení souvisejících stránek
6. Aktualizuj `wiki/index.md` o nové stránky a jednořádkové popisy
7. Připoj záznam do `wiki/log.md` s datem, názvem zdroje a co se změnilo

Jeden zdroj se typicky dotkne 8–15 wiki stránek. To je normální.

> Skill `wiki-ingest` provádí kompletní workflow včetně delta trackingu (`raw/.manifest.json`) a kontroly rozporů.

### Pokládání otázek
Když uživatel položí otázku:

1. Nejprve přečti `wiki/hot.md` (cache nedávného kontextu)
2. Pokud nestačí, přečti `wiki/index.md` a najdi relevantní stránky
3. Přečti tyto stránky a syntetizuj odpověď
4. V odpovědi cituj konkrétní wiki stránky (`[[Page]]`)
5. Pokud odpověď ve wiki není, řekni to jasně. Nevymýšlej z tréninkových dat.
6. Pokud je odpověď hodnotná, nabídni uložení jako wiki stránky v `wiki/questions/`

Dobré odpovědi ukládej zpět do wiki, aby se znalosti kumulovaly.

> Skill `wiki-query` má tři módy hloubky (quick / standard / deep).

### Lint a údržba
Když uživatel požádá o lint nebo audit wiki:

- Najdi rozpory mezi stránkami → callout `> [!contradiction]`
- Najdi osamocené stránky (orphans) — bez příchozích wikilinks
- Najdi mrtvé wikilinks (na neexistující stránky)
- Identifikuj koncepty zmiňované na více stránkách bez vlastní stránky
- Označ tvrzení, která mohou být zastaralá podle novějších zdrojů
- Zkontroluj, že všechny stránky dodržují formát stránky
- Reportuj nálezy jako číslovaný seznam s navrženými opravami

Nic neopravuj automaticky bez potvrzení od uživatele.

> Skill `wiki-lint` produkuje lint report v `wiki/meta/lint-report-YYYY-MM-DD.md`.

## Formát stránky

Každá wiki stránka má frontmatter a strukturu:

```markdown
---
type: concept | entity | source | question | comparison
title: "Název stránky"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - <tag>
status: seed | developing | solid
confidence_overall: low | medium | high
related:
  - "[[Related Page]]"
sources:
  - "[[wiki/sources/source-page]]"
---

# Název stránky

**Summary**: Jedna až dvě věty popisující stránku.

---

Hlavní obsah s krátkými odstavci a jasnými nadpisy.
Související koncepty propojuj pomocí `[[wikilinks]]`.

## Související stránky

- [[Related Concept 1]]
- [[Related Concept 2]]
```

> Konkrétní šablony jsou v `_templates/` (concept, entity, source, question, comparison).

## Pravidla citací

- Každé faktické tvrzení opatři odkazem na zdroj — formát `(Source: [[Zdrojová stránka]])`
- Když si dva zdroje protiřečí, označ rozpor explicitně calloutem `> [!contradiction]`
- Tvrzení bez ověřeného zdroje označ calloutem `> [!gap] Vyžaduje ověření.`
- Míru jistoty každého tvrzení uváděj inline ve tvaru `míra jistoty: low|medium|high` (viz sekce „Míra jistoty (confidence)" níže).

## Míra jistoty (confidence)

Každé netriviální tvrzení nese explicitní míru jistoty, vždy doslova ve tvaru:

```
míra jistoty: low | medium | high
```

- **high** — shoduje se více nezávislých autoritativních zdrojů, nebo ověřeno přímo proti primárnímu zdroji (oficiální rejstřík, plný text dokumentu, primární databáze).
- **medium** — jeden dobrý zdroj, částečná shoda zdrojů, nebo OCR/odvozený úryvek dosud nepotvrzený v primárním dokumentu.
- **low** — spekulace, názor, jeden neformální zdroj nebo neověřené tvrzení.

Pravidla:

- Vždy doslovná fráze `míra jistoty: <úroveň>` — nikdy holé `(high)`, `— medium`, anglické `confidence:` ani česká synonyma vysoká/střední/nízká.
- Umísti do citační závorky vedle zdroje, např. `(Source: [[Zdroj]] — míra jistoty: high)`, nebo samostatně za tvrzení `(míra jistoty: medium)`.
- Jedna stránka může míchat úrovně; znač každé tvrzení zvlášť, nehodnoť celou stránku jednou inline značkou.
- Po potvrzení silnějším zdrojem úroveň zvyš a změnu zaznamenej do `wiki/log.md`.
- Pro skutečně neověřené mezery použij callout `> [!gap] Vyžaduje ověření.` navíc k (nebo místo) značky low.

### Pole `confidence_overall` (pro Dataview)

Každá stránka s YAML frontmatterem nese navíc pole:

```yaml
confidence_overall: low | medium | high
```

- Vyjadřuje **převažující jistotu hlavních zjištění stránky** — ne striktní minimum. Stránka, jejíž ústřední teze stojí na nedoloženém/neověřeném tvrzení, je `medium` (či `low`), i když okrajová fakta jsou `high`; stránka s dobře doloženými hlavními zjištěními je `high`, i když nese drobné `medium` výhrady.
- Umísti hned za `status:` ve frontmatteru.
- Drž konzistentní s inline značkami `míra jistoty:` — je-li klíčové tvrzení inline `medium`, stránka není `high`.
- Přehodnoť při každé změně inline značek (např. po ověření proti primárnímu zdroji).
- Navigační/provozní stránky bez frontmatteru (`index.md`, `hot.md`, `log.md`) toto pole nemají.

Příklad Dataview — stránky vyžadující doověření:

```dataview
TABLE confidence_overall, status
WHERE confidence_overall != "high"
SORT confidence_overall ASC
```

## Konvence pojmenování

| Prvek | Konvence | Příklad |
|---|---|---|
| Filenames | Title Case s mezerami | `Machine Learning.md` |
| Folders | malá písmena s pomlčkami | `wiki/data-models/` |
| Tagy | malá písmena, hierarchické | `#domain/architecture` |
| Wikilinks | přesně podle názvu souboru (bez přípony) | `[[Machine Learning]]` |

Filenames musí být ve vault unikátní (jinak nefungují wikilinks bez cesty).

## Cross-Project napojení

Pro odkazování na tuto wiki z jiného Claude Code projektu přidejte do `CLAUDE.md` daného projektu:

```markdown
## Wiki Knowledge Base
Path: /path/to/this/vault

Když potřebujete kontext, který v tomto projektu není:
1. Nejprve přečtěte wiki/hot.md (nedávný kontext, ~500 slov)
2. Pokud nestačí, přečtěte wiki/index.md
3. Pokud potřebujete detaily domény, přečtěte wiki/<domain>/_index.md
4. Až poté čtěte jednotlivé wiki stránky

Wiki NEČTĚTE pro obecné programátorské dotazy nebo pro věci, které jsou již v tomto projektu.
```

## Skills pluginu

| Skill | Trigger |
|-------|---------|
| `wiki-ingest` | `ingest [source]` — ingest jednoho nebo více zdrojů |
| `wiki-query` | `query: [question]`, `what do you know about...` — odpovědi z obsahu wiki |
| `wiki-lint` | `lint the wiki` — health check |
| `wiki-autoresearch` | `/wiki-autoresearch [topic]` — autonomní výzkumná smyčka |
| `html-clean` | `clean this url`, `defuddle` — čištění webových stránek |
| `obsidian-markdown` | reference na syntax Obsidian Flavored Markdown |

## Klíčová pravidla

- **NIKDY neupravuj nic v `raw/`** — to jsou zdrojové dokumenty
- **Vždy aktualizuj `wiki/index.md` a `wiki/log.md`** po změnách
- **Vždy aktualizuj `wiki/hot.md`** na konci relace (cache pro příští session)
- Piš jasným, prostým jazykem
- Pokud si nejsi jistý kategorizací, zeptej se uživatele
- Stará tvrzení tiše nepřepisuj — flag rozpory a nech rozhodnout uživatele
