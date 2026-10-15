---
tipus: adr
azonosito: ADR-007
statusz: elfogadva
datum: 2026-10-16
felulirja:
felulirva_altala:
---

# ADR-007 – Beépített katalógus az app részeként

## Kontextus
A katalógus kb. 160 beépített tételből és a felhasználó saját tételeiből áll (FR-10). Igény (2026-10-16): a beépített alaplista **ne legyen szerkeszthető vagy törölhető**, csak a felhasználó által felvett tételek.

## Lehetőségek
| | Előny | Hátrány |
|---|---|---|
| A – A beépített tételek is az adatbázisba kerülnek (első indításkor), `builtin` jelzővel | Egy helyen minden tétel | Frissítéskor szinkronizálni kell a listát az adatbázissal; elrejtést, átnevezést kezelni kellene |
| B – **A beépített tételek az app fájljában maradnak** (asset), az adatbázisban csak a saját tételek | Csak olvasható természetéből adódóan; új app-verzió új tételeket hoz migráció nélkül | Két forrás egyesítése a memóriában |

## Döntés
**B.**
- Forrás: `docs/Katalógus – beépített tételek.md` (Obsidianban átnézve) → `tool/build_catalog.py` → `assets/catalog/builtin_items.txt`.
- Az adatbázis `catalog_items` táblája (séma v2) csak a saját tételeket tárolja; a névkulcs egyedi a nem törölt tételek között.
- Az app a kettőt a memóriában egyesíti (A–Z). Ha egy saját tétel neve később beépítetté válik, egyszer jelenik meg.
- Saját tétel nem vehető fel olyan néven, ami már a katalógusban van.

## Következmények
- A teljes mentés (FR-18) csak a saját tételeket viszi; a beépítetteket az app úgyis tartalmazza.
- Beépített tétel eltávolítása csak új app-verzióval lehetséges (a dokumentumban áthúzva).
