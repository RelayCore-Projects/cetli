---
tipus: adr
azonosito: ADR-003
statusz: elfogadva
datum: 2026-10-15
felulirja:
felulirva_altala:
---

# ADR-003 – Repó- és vault-szerkezet

## Kontextus
A dokumentációt Obsidianban vezetjük, és a kóddal együtt verziózzuk – a Pulzarban bevált módon.

## Döntés
- Az Obsidian vault a repó **`docs/`** mappája
- A Flutter-projekt a repó gyökerébe kerül (0.2.0-tól)
- Commit és feltöltés: GitHub Desktop
- Személyes jegyzetek és az aláírókulcs a `docs/_privat/` mappába kerülnek, ami **nem** kerül fel a gitre
- A `docs/.obsidian` beállítások verziózottak, a személyes állapotfájlok (`workspace.json`) nem; a gyökérben lévő `.obsidian` mappa ki van zárva

## Következmények
- A dokumentáció és a kód változásai ugyanabban a commitban követhetők.
- Az Obsidian a kódfájlokat nem látja, csak a `docs/` tartalmát.
- A CHANGELOG a `docs/` mappában van, hogy Obsidianban is látható legyen; a README erre hivatkozik.
