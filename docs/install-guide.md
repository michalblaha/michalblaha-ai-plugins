# wiki-tools — Instalační průvodce

**Společník pro znalostní bázi nad Claude**
[github.com/michalblaha/claude-wikitools](https://github.com/michalblaha/claude-wikitools)

---

## Co je wiki-tools?

`wiki-tools` je Claude Code plugin , který buduje a udržuje trvalou, kumulující se znalostní bázi. Každý zdroj, který přidáte, se zpracuje do křížově propojených wiki stránek. Každá otázka, kterou položíte, čerpá ze všeho, co bylo přečteno. Znalosti se kumulují jako úroky.

Postaveno na vzoru LLM Wiki od Andreje Karpathyho.

---

## Předpoklady

| Nástroj | Jak získat | Poznámky |
|------|--------------|-------|
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` | Free tier dostupný |
| **Obsidian** | [obsidian.md](https://obsidian.md) | Zdarma |
| **Git** | Předinstalován na většině systémů | Pro Možnost 1 |

---

## Instalace

### Instalace jako Claude Code plugin

Instalace pluginu je dvoukroková. Nejprve přidáte marketplace katalog, poté plugin nainstalujete.

```bash
# Krok 1: přidat marketplace
claude plugin marketplace add michalblaha/claude-wikitools

# Krok 2: nainstalovat plugin
claude plugin install wiki-tools@wiki-tools-marketplace
```

Ověření:
```bash
claude plugin list
```

V libovolné Claude Code relaci napište `/wiki-tools` a Claude vás provede nastavením vaultu.

---

## První kroky

### 1. Vložte první zdroj

Vložte libovolný dokument do `raw/`:
- PDF, markdown soubory, transkripty, články, URL

Řekněte Claudovi: `ingest [filename]`

Claude přečte zdroj a vytvoří 8–15 vzájemně propojených wiki stránek.

### 3. Pokládejte otázky

```
what do you know about [topic]?
```

Claude přečte hot cache, prohledá rejstřík, ponoří se do relevantních stránek a poskytne syntetizovanou odpověď — s citacemi konkrétních wiki stránek, ne tréninkových dat.

---

## Reference příkazů

| Příkaz | Co Claude udělá |
|---------|-----------------|
| `/wiki` | Kontrola nastavení, scaffold, nebo pokračování tam, kde jste skončili |
| `ingest [file]` | Načte zdroj, vytvoří 8–15 wiki stránek, aktualizuje rejstřík a log |
| `ingest all of these` | Dávkové zpracování více zdrojů, poté křížové propojení |
| `what do you know about X?` | Přečte rejstřík → relevantní stránky → syntetizuje odpověď |
| `/wiki-autoresearch [topic]` | Autonomní výzkumná smyčka: vyhledá, stáhne, syntetizuje, založí |
| `lint the wiki` | Health check: orphans, dead links, mezery |
| `update hot cache` | Obnoví `hot.md` aktuálním shrnutím kontextu |

---

## Doporučené Obsidian pluginy

Nainstalujte ze **Settings → Community Plugins**:

| Plugin | Účel |
|--------|---------|
| **Templater** | Auto-vyplňování frontmatter ze složky `_templates/` |
| **Obsidian Git** | Auto-commit vault každých 15 minut |
| **Dataview** | Pro Dataview dotazy (volitelné, pro legacy dashboard) |
| **Calendar** | Kalendář v pravém panelu |
| **Banners** | Hlavičkové obrázky přes `banner:` ve frontmatter |



---

## Podpora

- **GitHub**: [github.com/michalblaha/claude-wikitools](https://github.com/michalblaha/claude-wikitools)

---

*Postaveno na vzoru LLM Wiki od Andreje Karpathyho.*
*`wiki-tools` je inspirováno projektem https://github.com/AgriciDaniel/claude-obsidian*
