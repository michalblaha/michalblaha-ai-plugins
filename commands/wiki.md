---
description: Bootstrap nebo kontrola wiki-tools vaultu. Spustí setup workflow pro Obsidian vault.
---

Spusť setup workflow:

1. Zkontroluj, zda je nainstalován Obsidian. Pokud ne, nabídni instalaci.
2. Zkontroluj, zda tento adresář obsahuje vault (hledej složku `.obsidian/`). Pokud ano, nahlas aktuální stav vaultu.
3. Zkontroluj, zda je nakonfigurovaný MCP server (`claude mcp list`). Pokud ne, zeptej se, zda jej uživatel chce nastavit.
4. Polož JEDNU otázku: „K čemu tento vault slouží?"

Poté vybuduj celou strukturu wiki na základě odpovědi. Žádné další otázky. Vytvoř scaffold, ukaž, co bylo vytvořeno, a zeptej se: „Chcete něco upravit, než začneme?"

Příklady toho, co může uživatel říct:
- „Map the architecture of github.com/org/repo"
- „Build a sitemap and content analysis for example.com"
- „Track my SaaS business — product, customers, metrics, roadmap"
- „Research project on [topic] — papers, concepts, open questions"
- „Personal second brain — health, goals, learning, projects"
- „Organize my YouTube channel — transcripts, topics, tools mentioned"
- „Executive assistant brain — meetings, tasks, business context"

Pokud je vault již nastaven, přeskoč na kontrolu, co bylo nedávno ingestováno, a nabídni pokračování tam, kde jste skončili.

## Co scaffold vytváří

Typická struktura:

```
wiki/
├── index.md           hlavní katalog
├── log.md             append-only log operací
├── hot.md             cache nedávného kontextu (~500 slov)
├── overview.md        výkonné shrnutí
├── concepts/          koncepty a frameworky
├── entities/          osoby, organizace, produkty
├── sources/           shrnutí zdrojů
├── questions/         filed otázky a odpovědi
└── meta/              dashboardy, lint reporty
raw/                   zdrojové dokumenty (neměnné)
_templates/            Templater šablony
```

Použij šablony z `_templates/` (concept, entity, source, question, comparison). Používej Obsidian Flavored Markdown — viz skill `obsidian-markdown` pro syntax.
