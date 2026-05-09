---
name: wiki-lint
description: >
  Health check Obsidian wiki vaultu. Najde osamocené stránky, mrtvé wikilinky, zastaralá
  tvrzení, chybějící křížové reference, mezery ve frontmatter a prázdné sekce. Vytváří
  nebo aktualizuje Dataview dashboardy. Generuje canvas mapy. Triggers on: "lint",
  "health check", "clean up wiki", "check the wiki", "wiki maintenance", "find orphans",
  "wiki audit".
allowed-tools: Read Write Edit Glob Grep
---

# wiki-lint: Health check wiki

Spouštěj lint po každých 10–15 ingestech, případně týdně. Před autoopravou se zeptej. Výstupem je lint report v `wiki/meta/lint-report-YYYY-MM-DD.md`.

---

## Lint kontroly

Projdi je v tomto pořadí:

1. **Osamocené stránky (orphans)**. Wiki stránky bez příchozích wikilinks. Existují, ale nikdo na ně neodkazuje.
2. **Mrtvé odkazy (dead links)**. Wikilinky odkazující na stránku, která neexistuje.
3. **Zastaralá tvrzení (stale claims)**. Tvrzení na starších stránkách, která novější zdroje vyvrátily nebo aktualizovaly.
4. **Chybějící stránky**. Koncepty nebo entity zmiňované na více stránkách, které nemají vlastní stránku.
5. **Chybějící křížové reference**. Entity zmíněné na stránce, ale nelinkované.
6. **Mezery ve frontmatter**. Stránky bez povinných polí (type, status, created, updated, tags).
7. **Prázdné sekce**. Nadpisy bez obsahu.
8. **Zastaralé záznamy v rejstříku**. Položky v `wiki/index.md` odkazující na přejmenované nebo smazané stránky.

---

## Formát lint reportu

Vytvoř v `wiki/meta/lint-report-YYYY-MM-DD.md`:

```markdown
---
type: meta
title: "Lint Report YYYY-MM-DD"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [meta, lint]
status: developing
---

# Lint Report: YYYY-MM-DD

## Summary
- Pages scanned: N
- Issues found: N
- Auto-fixed: N
- Needs review: N

## Orphan Pages
- [[Page Name]]: bez příchozích odkazů. Návrh: olinkovat z [[Related Page]] nebo smazat.

## Dead Links
- [[Missing Page]]: referencováno v [[Source Page]], ale neexistuje. Návrh: vytvořit stub nebo odstranit odkaz.

## Missing Pages
- "concept name": zmíněno v [[Page A]], [[Page B]], [[Page C]]. Návrh: vytvořit konceptovou stránku.

## Frontmatter Gaps
- [[Page Name]]: chybí pole: status, tags

## Stale Claims
- [[Page Name]]: tvrzení „X" může být v rozporu s novějším zdrojem [[Newer Source]].

## Cross-Reference Gaps
- [[Entity Name]] zmíněno v [[Page A]] bez wikilinku.
```

---

## Konvence pojmenování

Vynucuj během lintu:

| Prvek | Konvence | Příklad |
|---------|-----------|---------|
| Filenames | Title Case s mezerami | `Machine Learning.md` |
| Folders | malými písmeny s pomlčkami | `wiki/data-models/` |
| Tagy | malá písmena, hierarchické | `#domain/architecture` |
| Wikilinky | přesně dle názvu souboru | `[[Machine Learning]]` |

Názvy souborů musí být ve vault unikátní. Wikilinky bez cesty fungují, jen pokud jsou názvy unikátní.

---

## Kontrola stylu psaní

Během lintu označ stránky, které porušují styl:

- Není použito oznamovací způsob přítomný čas („X v podstatě dělá Y" místo „X dělá Y")
- Chybí citace zdroje u tvrzení
- Nejistota není označena `> [!gap]`
- Rozpory nejsou označeny `> [!contradiction]`

---

## Dataview Dashboard

Vytvoř nebo aktualizuj `wiki/meta/dashboard.md` s těmito dotazy:

````markdown
---
type: meta
title: "Dashboard"
updated: YYYY-MM-DD
---
# Wiki Dashboard

## Recent Activity
```dataview
TABLE type, status, updated FROM "wiki" SORT updated DESC LIMIT 15
```

## Seed Pages (Need Development)
```dataview
LIST FROM "wiki" WHERE status = "seed" SORT updated ASC
```

## Entities Missing Sources
```dataview
LIST FROM "wiki/entities" WHERE !sources OR length(sources) = 0
```

## Open Questions
```dataview
LIST FROM "wiki/questions" WHERE answer_quality = "draft" SORT created DESC
```
````

---

## Canvas mapa

Vytvoř nebo aktualizuj `wiki/meta/overview.canvas` pro vizuální mapu domén:

```json
{
  "nodes": [
    {
      "id": "1",
      "type": "file",
      "file": "wiki/overview.md",
      "x": 0, "y": 0,
      "width": 300, "height": 140,
      "color": "1"
    }
  ],
  "edges": []
}
```

Přidej jeden uzel na doménovou stránku. Propoj domény s významnými křížovými referencemi. Barvy mapuj na CSS schéma: 1=modrá, 2=fialová, 3=žlutá, 4=oranžová, 5=zelená, 6=červená.

---

## Před auto-opravami

Vždy nejprve ukaž lint report. Zeptej se: „Mám to opravit automaticky, nebo chceš zkontrolovat každý případ?"

Bezpečné auto-opravy:
- Doplnění chybějících polí frontmatter s placeholder hodnotami
- Vytvoření stub stránek pro chybějící entity
- Přidání wikilinků pro nelinkované zmínky

Vyžaduje kontrolu před opravou:
- Mazání orphan stránek (mohou být záměrně izolované)
- Řešení rozporů (vyžaduje lidský úsudek)
- Sloučení duplicitních stránek
