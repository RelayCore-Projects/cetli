---
tipus: adr
azonosito: ADR-006
statusz: elfogadva
datum: 2026-10-16
felulirja:
felulirva_altala:
---

# ADR-006 – Alkalmazásikon

## Kontextus
Az első APK-hoz (0.2.0) ikon kell. A telefonok eltérő maszkkal (kör, lekerekített négyzet) és kis méretben (48 dp) jelenítik meg, ezért egyszerű, nagy kontrasztú forma kell.

## Lehetőségek
Négy kör, összesen kb. 35 változat (`tool/generate_icons.py` alapján, a vázlatok nem verziózottak):
| | Előny | Hátrány |
|---|---|---|
| Cetli zöld pipával | Letisztult | „Feladat kész” hangulat, nem bevásárlólista |
| Szakított, döntött cetli egy C-ben | Elmeséli az appot, a C a nevet | Kicsiben zsúfolt, sok részlet |
| **C betű három sorral, papír nélkül** | Kicsiben is tiszta, márkajel és lista egyben | Kevésbé szó szerinti |

## Döntés
**Sötétzöld C (`#17463A`) három lista-sorral, citromsárga háttéren (`#F7D248`)**, áthúzás nélkül. Adaptív ikon: a háttér a sárga szín, az előtér a C a 66 dp-s biztonságos zónán belül; Android 13+ témázott (egyszínű) ikon is készül.

## Következmények
- Az ikon a `tool/generate_icons.py` futtatásával újragenerálható; a forráskép: `assets/branding/cetli-icon-1024.png`.
- Az app színe (Material 3 seed) zöld marad.
