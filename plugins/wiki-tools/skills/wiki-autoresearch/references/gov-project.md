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
Po dokončení výzkumu vytvořte tyto stránky:

**wiki/projekty/**. Jedna stránka na každý významný státní projekt nebo iniciativu
- Použijte frontmatter typu `project` (název, zadavatel, dodavatel, hodnota, stav, období)
- Tělo: popis projektu, kontext, klíčové milníky, finanční toky, vazby na osoby a instituce
- Křížově odkazujte na příslušné instituce, dodavatele a osoby

**wiki/dodavatelé/**. Jedna stránka na každého významného dodavatele (firmu, subjekt, který obchoduje se státem)
- Použijte frontmatter typu `entity` se `entity_type: company` (IČO, sídlo, vlastnická struktura, K-index)
- Tělo: čím se firma zabývá, jaké zakázky získala, vazby na politicky exponované osoby
- Nejprve zkontrolujte index: existující stránky dodavatelů aktualizujte, místo abyste vytvářeli duplikáty

**wiki/instituce/**. Jedna stránka na každou významnou státní instituci (ministerstvo, úřad, agenturu, kraj, obec)
- Použijte frontmatter typu `entity` se `entity_type: institution`
- Tělo: působnost, vedení, podřízené organizace, vystavené zakázky, dotační programy
- Nejprve zkontrolujte index: aktualizujte existující stránky institucí

**wiki/osoby/**. Jedna stránka na každou významnou identifikovanou osobu (politik, úředník, vlastník, lobbista)
- Použijte frontmatter typu `entity` se `entity_type: person` (role, funkce, období, afiliace)
- Tělo: životopis ve vztahu k tématu, funkce, vazby na firmy a instituce, sponzorské dary
- Nejprve zkontrolujte index: aktualizujte existující stránky osob

**wiki/media/**. Jedna stránka na každý významný mediální zdroj (médium, redakci, novináře)
- Použijte frontmatter typu `source` se `source_type: media` (název, autor, datum, URL)
- Tělo: shrnutí zjištění, kterých kauz se médium dotklo, hodnocení důvěryhodnosti
- Použijte tuto složku pro průběžné mediální zdroje; pro jednorázové články používejte standardní `wiki/sources/`

**wiki/otazky/**. Jedna syntetizující stránka s názvem „Research: [Topic]"
- Toto je hlavní syntéza. Všechno se zde sbíhá dohromady.
- Sekce: Overview, Key Findings, Entities, Concepts, Contradictions, Open Questions, Sources
- Plný frontmatter s `related` odkazy na všechny stránky vytvořené v této relaci



