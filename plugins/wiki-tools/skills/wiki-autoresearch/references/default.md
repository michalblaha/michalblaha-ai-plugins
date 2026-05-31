# Výzkumný program (default)

Tento soubor konfiguruje smyčku autoresearch. Upravte jej tak, aby odpovídal vaší doméně a stylu výzkumu. Skill autoresearch jej načítá před každým spuštěním.

---

## Cíle vyhledávání

Výchozí cíle pro každou výzkumnou relaci:

- Najít autoritativní zdroje (preferovat: .edu, peer-reviewed články, oficiální dokumentaci, primární zdroje, zavedené publikace)
- Extrahovat klíčové entity (osoby, organizace, produkty, nástroje)
- Extrahovat klíčové koncepty a frameworky
- Zaznamenat rozpory mezi zdroji
- Identifikovat otevřené otázky a mezery ve výzkumu
- Preferovat zdroje z posledních 2 let, pokud není téma fundamentální

---

## Hodnocení míry jistoty

U každého tvrzení při ukládání označte míru jistoty:

- **high**: více nezávislých autoritativních zdrojů se shoduje
- **medium**: jeden dobrý zdroj nebo částečná shoda zdrojů
- **low**: spekulace, názorový text, jeden neformální zdroj nebo neověřené tvrzení

**Zápis míry jistoty:**
- Inline u každého tvrzení vždy doslova ve tvaru `míra jistoty: low|medium|high` (ne holé `(high)`, ne `confidence:`, ne česká synonyma vysoká/střední/nízká). Umísti do citační závorky, např. `(Source: Hlídač státu — míra jistoty: high)`.
- Každá stránka s frontmatterem nese navíc pole **`confidence_overall: low|medium|high`** (hned za `status:`) = převažující jistota hlavních zjištění stránky (ne striktní minimum). Slouží k filtrování v Dataview. Po ověření silnějším zdrojem hodnotu zvyš a zaznamenej do `wiki/log.md`.

U faktických tvrzení vždy uvádějte datum zdroje. Tvrzení ze zdrojů starších než 3 roky označte jako potenciálně zastaralá.

---

## Omezení smyčky

- Maximální počet kol vyhledávání na téma: **3**
- Maximální počet wiki stránek vytvořených za relaci: **15**
- Maximální počet zdrojů stažených v jednom kole: **5**
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

[Zde doplňte instrukce specifické pro vaši doménu. Příklady:]

Pro výzkum v oblasti AI/tech:
- Preferovat: arXiv, oficiální GitHub repozitáře, oficiální produktovou dokumentaci, diskuze na Hacker News s vysokou karmou
- Pozor: benchmarky LLM bývají často „ohýbány" — tvrzení z leaderboardů považujte za málo důvěryhodná, dokud nejsou nezávisle ověřena

Pro byznysový a tržní výzkum:
- Preferovat: výroční zprávy a regulatorní podání společností (company filings), Crunchbase, Bloomberg, ověřené oborové reporty
- Flagovat: tiskové zprávy jako málo důvěryhodné bez nezávislého ověření

Pro lékařský a zdravotnický výzkum:
- Preferovat: PubMed, Cochrane reviews, peer-reviewed klinické studie
- Vždy poznamenat: velikost vzorku, typ studie (RCT vs. observační) a recentnost

---
## Ukládání výsledků

Po dokončení rešerše vytvořte:

1. ZÁSADNÍ PRAVIDLO: veškeré použité zdroje stáhni a ulož do `raw/` adresáře.

2. Wiki stránky — cílové složky odvoď podle sekce **Detekce uspořádání vaultu** ve skillu (`{type → složka}` mapa). Pro každý typ:

   - **Zdroj** (`type: source`) — jedna stránka pro každý významný nalezený zdroj. Použijte frontmatter zdroje (type, source_type, author, date_published, url, confidence, key_claims). Tělo: shrnutí zdroje, čím přispívá k tématu.

   - **Koncept** (`type: concept`) — jedna stránka pro každý samostatný extrahovaný koncept. Před založením zkontrolujte rejstřík; nestavějte duplicity, aktualizujte stávající stránky.

   - **Entita** (`type: entity`) — jedna stránka pro každou významnou identifikovanou osobu, organizaci nebo produkt. Před založením zkontrolujte rejstřík.

   - **Syntéza** (`type: synthesis`) — jedna hlavní stránka „Research: [Topic]". Sekce: Overview (Přehled), Key Findings (Klíčová zjištění), Entities (Entity), Concepts (Koncepty), Contradictions (Rozpory), Open Questions (Otevřené otázky), Sources (Zdroje). Kompletní frontmatter s odkazy na všechny stránky vytvořené v této relaci.

---

## Fallback uspořádání

Použít pouze pokud ve vaultu zatím pro daný typ neexistuje žádná stránka (viz sekce „Detekce uspořádání vaultu" ve skillu):

| Typ        | Fallback složka     |
|------------|---------------------|
| source     | `wiki/zdroje/`      |
| concept    | `wiki/myslenky/`    |
| entity     | `wiki/entity/`      |
| synthesis  | `wiki/reserse/`     |

Pokud má vault preferovanou jinou konvenci (např. anglické názvy `wiki/sources/`, `wiki/concepts/`, `wiki/entities/`, `wiki/research/`), detekce ji použije automaticky.

---

## Vyloučení

Jako zdroje s vysokou mírou jistoty necitujte:
- Příspěvky na Redditu nebo fórech (využívejte je pouze jako odrazový můstek k primárním zdrojům)
- Příspěvky na sociálních sítích
- Nedatované webové stránky
- Zdroje, které samy necitují, odkud čerpají
