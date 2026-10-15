---
tipus: changelog
frissitve: 2026-10-16
---

# Változásnapló

Formátum: [Keep a Changelog](https://keepachangelog.com/), verziózás: [[03 Fejlesztési folyamat#Verziószámozás|szemantikus]].
Kategóriák: **Hozzáadva** · **Módosítva** · **Javítva** · **Eltávolítva** · **Biztonság**

## [Unreleased]

### Hozzáadva
- Listák: létrehozás (dátumos alapnévvel), átnevezés, törlés; a főképernyőn a legutóbb módosított van felül, mellette a kipipált / összes tétel
- Kijelölés hosszú nyomással: több lista törlése egyszerre, átnevezés a kijelölésből
- **Szerkesztő mód:** gépelés + Enter, a billentyűzet nyitva marad; tétel szerkesztése (név, megjegyzés), törlése visszavonással
- **Vásárló mód:** koppintásra a tétel halványabb és áthúzott lesz, de olvasható marad
- Duplikátumszűrés: a listán már szereplő név (kis- és nagybetűtől függetlenül) nem kerül fel újra; a kipipált tételről lekerül a pipa
- Rendezés listánként: beírás sorrendje, név A–Z, név Z–A
- Vásárlás után: *Uncheck all*, *Remove checked items*
- Beállítások: a kipipált tételek alulra kerülnek vagy a helyükön maradnak; névjegy
- Saját alkalmazásikon: sötétzöld C három sorral, citromsárga háttéren ([[ADR-006 Alkalmazásikon]])
- CI: elemzés, automatikus tesztek, aláírt APK, Preview és végleges kiadás ([[ADR-005 Fordítás, aláírás és kiadás a GitHub Actionsben]])

## [0.1.0] – 2026-10-15 – Koncepció

### Hozzáadva
- Specifikáció: listák szerkesztő és vásárló móddal, rendezés, megjegyzés, katalógus automatikus kiegészítéssel, megosztás `.cetli` fájllal és összefésülés, teljes mentés
- Döntések: Flutter és technikai alapok, nyilvános repó és nyelvek, repó- és vault-szerkezet, megosztás fájllal szerver nélkül (ADR-001…004)
- Ütemterv (0.2.0 → 0.3.0 → 0.4.0 → 1.0.0), fejlesztési folyamat, tesztstratégia és kézi tesztlista, hibakezelés, ötletek
- Angol README, GitHub issue- és PR-sablonok
