# Výzkumný program
Tento soubor konfiguruje smyčku autoresearch. Upravte jej tak, aby odpovídal vaší doméně a stylu výzkumu. Skill autoresearch jej načítá před každým spuštěním.

---
## Cíle vyhledávání
Výchozí cíle pro každou výzkumnou relaci:
- Najít autoritativní zdroje (preferovat: oficiální státní zdroje, média, oficiální dokumentaci, primární zdroje, zavedené publikace, veřejné zakázky, smlouvy)
- Extrahovat klíčové entity (osoby, organizace, produkty, nástroje)
- Extrahovat klíčové koncepty a rámce
- Zaznamenat rozpory mezi zdroji
- Identifikovat otevřené otázky a mezery ve výzkumu


---
## Hodnocení míry jistoty
U každého tvrzení při ukládání označte míru jistoty:
- **high**: více nezávislých autoritativních zdrojů se shoduje
- **medium**: jeden dobrý zdroj, nebo částečná shoda zdrojů
- **low**: spekulace, názorový text, jeden neformální zdroj nebo neověřené tvrzení

**Zápis míry jistoty:**
- Inline u každého tvrzení vždy doslova ve tvaru `míra jistoty: low|medium|high` (ne holé `(high)`, ne `confidence:`, ne česká synonyma vysoká/střední/nízká). Umísti do citační závorky, např. `(Source: Hlídač státu — míra jistoty: high)`.
- Každá stránka s frontmatterem nese navíc pole **`confidence_overall: low|medium|high`** (hned za `status:`) = převažující jistota hlavních zjištění stránky (ne striktní minimum). Slouží k filtrování v Dataview. Po ověření silnějším zdrojem hodnotu zvyš a zaznamenej do `wiki/log.md`.

U faktických tvrzení vždy uvádějte datum zdroje. Tvrzení ze zdrojů starších než 3 roky označte jako potenciálně zastaralá.

---
## Omezení smyčky
- Maximální počet kol vyhledávání na téma: **5**
- Maximální počet wiki stránek vytvořených za relaci: **20**
- Maximální počet zdrojů stažených v jednom kole: **10**
- Pokud je dosaženo maxima stránek před dokončením smyčky: založte, co máte, a co bylo vynecháno, poznamenejte do sekce Open Questions

---
## Styl výstupu
- Oznamovací způsob, přítomný čas
- Každé netriviální tvrzení opatřete citací: `(Source: [[Page]])`
- Krátké stránky: pod 200 řádků. Delší rozdělte.
- Žádné vyhýbavé formulace („zdá se", „možná", „pravděpodobně")
- Nejistotu označujte explicitně: `> [!gap] Toto tvrzení vyžaduje ověření.`

---
## Poznámky k doméně

Pro výzkum v oblasti státních zakázek:
- Preferuj: Hlídač státu, veřejné zakázky (Hlídač státu, nen.gov.cz, zakazky.gov.cz), oficiální produktovou dokumentaci, 

Poznámka: Pokud není nainstalovaný MCP server Hlídač státu, instaluj dle instrukcí na https://mcp.api.hlidacstatu.cz/doc

Pro byznysový a tržní výzkum:
- Preferovat: výroční zprávy a regulatorní podání společností (company filings), obchodní rejstřík (https://or.justice.cz/) , ověřené oborové reporty, ověřená média
- Označit: tiskové zprávy jako málo důvěryhodné bez nezávislého ověření

---
## Vyloučení
Jako zdroje s vysokou mírou jistoty necitujte:
- Příspěvky na Redditu nebo fórech (využívejte je pouze jako odrazový můstek k primárním zdrojům)
- Příspěvky na sociálních sítích
- Nedatované webové stránky
- Zdroje, které samy necitují, odkud čerpají

---
## Ukládání výsledků

Po dokončení výzkumu vytvořte:

1. ZÁSADNÍ PRAVIDLO: veškeré použité zdroje stáhni a ulož do `raw/` adresáře.

2. Wiki stránky — cílové složky odvoď podle sekce **Detekce uspořádání vaultu** ve skillu (`{type → složka}` mapa, případně doménově specifické rozlišení podle `entity_type` / `source_type` níže). Pro každý typ:

   - **Projekt** (`type: project`) — jedna stránka na každý významný státní projekt nebo iniciativu. Frontmatter: název, zadavatel, dodavatel, hodnota, stav, období. Tělo: popis projektu, kontext, klíčové milníky, finanční toky, vazby na osoby a instituce. Křížově odkazuj na příslušné instituce, dodavatele a osoby.

   - **Dodavatel** (`type: entity`, `entity_type: company`) — jedna stránka na každého významného dodavatele (firmu obchodující se státem). Frontmatter: IČO, sídlo, vlastnická struktura, K-index. Tělo: čím se firma zabývá, jaké zakázky získala, vazby na politicky exponované osoby. Před založením zkontroluj rejstřík; aktualizuj existující.

   - **Instituce** (`type: entity`, `entity_type: institution`) — jedna stránka na každou významnou státní instituci (ministerstvo, úřad, agentura, kraj, obec). Tělo: působnost, vedení, podřízené organizace, vystavené zakázky, dotační programy. Před založením zkontroluj rejstřík.

   - **Osoba** (`type: entity`, `entity_type: person`) — jedna stránka na každou významnou identifikovanou osobu (politik, úředník, vlastník, lobbista). Frontmatter: role, funkce, období, afiliace. Tělo: životopis ve vztahu k tématu, funkce, vazby na firmy a instituce, sponzorské dary. Před založením zkontroluj rejstřík.

   - **Médium** (`type: source`, `source_type: media`) — jedna stránka na každý významný mediální zdroj (médium, redakci, novináře). Frontmatter: název, autor, datum, URL. Tělo: shrnutí zjištění, kterých kauz se médium dotklo, hodnocení důvěryhodnosti. Tato kategorie se používá pro průběžně sledované mediální zdroje; jednorázové články jdou jako běžný `type: source`.

   - **Syntéza** (`type: synthesis`) — jedna hlavní stránka „Research: [Topic]". Sekce: Overview, Key Findings, Entities, Concepts, Contradictions, Open Questions, Sources. Plný frontmatter s `related` odkazy na všechny stránky vytvořené v této relaci.

---

## Fallback uspořádání

Použít pouze pokud ve vaultu zatím pro daný typ neexistuje žádná stránka (viz sekce „Detekce uspořádání vaultu" ve skillu). Pro doménově specifické sub-typy je rozlišovacím klíčem dvojice (`type`, `entity_type`/`source_type`):

| Typ / sub-typ                                | Fallback složka      |
|----------------------------------------------|----------------------|
| `project`                                    | `wiki/projekty/`     |
| `entity` + `entity_type: company`            | `wiki/dodavatelé/`   |
| `entity` + `entity_type: institution`        | `wiki/instituce/`    |
| `entity` + `entity_type: person`             | `wiki/osoby/`        |
| `entity` (ostatní)                           | `wiki/entity/`       |
| `source` + `source_type: media`              | `wiki/media/`        |
| `source` (ostatní)                           | `wiki/zdroje/`       |
| `concept`                                    | `wiki/myslenky/`     |
| `synthesis`                                  | `wiki/reserse/`       |

Pokud má vault preferovanou jinou konvenci, detekce ji použije automaticky.



