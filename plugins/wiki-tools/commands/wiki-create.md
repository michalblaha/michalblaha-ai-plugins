---
description: Inicializuje wiki vault v aktuálním projektu. Zkopíruje CLAUDE.md pluginu do rootu projektu (pokud chybí) a vytvoří očekávanou adresářovou strukturu.
---

Inicializuj wiki vault v aktuálním projektu (cwd) podle konvencí pluginu `wiki-tools`. Operace je idempotentní — existující soubory a složky nepřepisuj.

## Postup

1. **Zjisti root projektu**: použij aktuální pracovní adresář (cwd). Pokud se nezdá, že jde o root (např. cwd je `wiki/`, `raw/` atd.), upozorni uživatele a zeptej se, kam má inicializace proběhnout.

2. **Zkopíruj `CLAUDE.md` pluginu do rootu projektu**, jen pokud v rootu ještě neexistuje:
   - Zdroj: `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md`
   - Cíl: `<project-root>/CLAUDE.md`
   - Pokud cíl už existuje, **nepřepisuj** ho. Nahlas „CLAUDE.md už existuje — ponecháno beze změny" a pokračuj.
   - Pro kopii použij `Bash`: `cp "${CLAUDE_PLUGIN_ROOT}/CLAUDE.md" "<project-root>/CLAUDE.md"` (s předchozí kontrolou `test -f`).

3. **Vytvoř očekávanou adresářovou strukturu** podle CLAUDE.md. Každou položku zakládej jen tehdy, pokud chybí (`mkdir -p` je idempotentní, ale u souborů použij `test -f` než zapíšeš):

   ```
   raw/                  zdrojové dokumenty (immutable)
   raw/_attachments/     obrázky a PDF
   wiki/                 znalostní báze
   wiki/index.md         hlavní katalog (TOC)
   wiki/log.md           append-only záznam operací
   wiki/hot.md           cache nedávného kontextu
   wiki/overview.md      výkonné shrnutí vaultu
   ```

4. **Iniciální obsah souborů** zakládej jen u nově vytvořených (existující obsah nikdy nepřepisuj):

   `wiki/index.md`:
   ```markdown
   ---
   type: index
   title: "Wiki Index"
   updated: <YYYY-MM-DD>
   ---

   # Wiki Index

   Hlavní katalog wiki. Sem doplňuj jednořádkové popisy nově založených stránek.

   ## Stránky

   _Zatím prázdné. První záznamy doplní ingest nebo autoresearch._
   ```

   `wiki/log.md`:
   ```markdown
   ---
   type: log
   title: "Wiki Log"
   updated: <YYYY-MM-DD>
   ---

   # Wiki Log

   Append-only záznam operací nad wiki. Nové záznamy přidávej na začátek.

   ## [<YYYY-MM-DD>] init | wiki vault inicializován
   - Vytvořil command `/wiki-create` z pluginu `wiki-tools`.
   ```

   `wiki/hot.md`:
   ```markdown
   ---
   type: hot
   title: "Hot Cache"
   updated: <YYYY-MM-DD>
   ---

   # Hot Cache

   Stručný kontext nedávné práce (~500 slov). Aktualizuj na konci každé relace.

   _Zatím prázdné._
   ```

   `wiki/overview.md`:
   ```markdown
   ---
   type: overview
   title: "Overview"
   updated: <YYYY-MM-DD>
   ---

   # Overview

   Výkonné shrnutí vaultu — co pokrývá, hlavní zjištění, stav. Aktualizuj, když se změní celkový obraz.

   _Zatím prázdné. První obsah doplní ingest nebo autoresearch._
   ```

   Datum doplň jako reálné dnešní `YYYY-MM-DD`.

5. **Report uživateli** — shrň, co bylo vytvořeno, co existovalo a bylo ponecháno:

   ```
   wiki vault setup v <project-root>

   CLAUDE.md:   created | already existed
   raw/:        created | already existed
   raw/_attachments/: created | already existed
   wiki/:       created | already existed
   wiki/index.md: created | already existed
   wiki/log.md:   created | already existed
   wiki/hot.md:   created | already existed
   wiki/overview.md: created | already existed
   ```

## Pravidla

- **Idempotence**: opakované spuštění `/wiki-create` nesmí nic přepsat ani duplikovat.
- **Neptej se zbytečně**: pokud cwd vypadá jako rozumný root projektu (obsahuje `.git/`, `package.json`, `pyproject.toml`, `README.md` apod.), inicializuj v něm bez dotazu.
- **Nevytvářej** `wiki/sources/`, `wiki/entities/`, `wiki/concepts/` ani další doménové podsložky — ty vznikají dynamicky až při prvním ingestu/autoresearchi (viz „Detekce uspořádání vaultu" ve skillu `wiki-autoresearch`).
- **Nečti `raw/`** ani existující obsah `wiki/` — jen ověřuj existenci přes `test -d` / `test -f` v `Bash`.
