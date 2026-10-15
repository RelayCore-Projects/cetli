---
tipus: adr
azonosito: ADR-001
statusz: elfogadva
datum: 2026-10-15
felulirja:
felulirva_altala:
---

# ADR-001 – Flutter és a technikai alapok

## Kontextus
A Cetli ugyanabban a környezetben készül, mint a RelayCore-Projects korábbi appja, a Pulzar (v1.0.0, 2026-10-15): Android-telefonokra, GitHub Actionsben fordítva, a fejlesztői gépen helyi Flutter nélkül. A Pulzar technikai alapjai a napi használatban beváltak.

## Lehetőségek
| | Előny | Hátrány |
|---|---|---|
| A – Flutter, a Pulzar alapjaival | Bevált CI, aláírás, adatréteg és tesztelési minta; gyors indulás | Csak a CI fordít, ezért a kódot gondosan kell írni |
| B – Natív Kotlin (Jetpack Compose) | Natív Android-élmény | Új eszközlánc és CI, a meglévő minták nem használhatók |

## Döntés
**A – Flutter**, a Pulzar alapjaival:
- Flutter (a CI-ben rögzített verzió), Material 3, angol felület (`en_GB`)
- Adat: SQLite (`sqflite`), repository minta (SQLite + memóriabeli változat a tesztekhez), UUID, UTC időbélyegek, logikai törlés, verziózott séma, minden migrációhoz automatikus teszt
- Fájl- és megosztáskezelés saját MethodChannelen (`MainActivity.kt`), **natív plugin nélkül**; minden külső csomag kockázat, mert csak a CI fordít
- Tesztelhetőség: cserélhető szolgáltatások (fájlkezelés, óra), a tesztek rögzített „mával” futnak
- Csak arm64 APK, minSdk 26, applicationId `hu.relaycore.cetli` (soha nem változik)
- Fordítás, aláírás, kiadás: GitHub Actions; a részletek a 0.2.0-ban, külön ADR-ben

## Következmények
- A CI munkafolyamat és a segédszkriptek a Pulzarból átvehetők.
- Saját aláírókulcs és saját GitHub-secretek kellenek (`CETLI_…`).
- Új csomag csak akkor kerül be, ha az API-ját a forrásából ellenőriztük.
