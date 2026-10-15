---
tipus: adr
azonosito: ADR-005
statusz: elfogadva
datum: 2026-10-16
felulirja:
felulirva_altala:
---

# ADR-005 – Fordítás, aláírás és kiadás a GitHub Actionsben

## Kontextus
A fejlesztői gépen nincs Flutter, és a pub.dev sem érhető el: az egyetlen fordító a CI. Egy kör (elemzés, tesztek, APK) 8–10 perc. A telepített app csak ugyanazzal a kulccsal aláírt APK-val frissíthető adatvesztés nélkül.

## Döntés
A Pulzarban bevált munkafolyamat (`.github/workflows/ci.yml`), a Cetli saját kulcsával:
- **Jobok:** `test` (pub get → `flutter analyze --no-fatal-infos` → `flutter test`) és `apk` **párhuzamosan**; `publish` csak ha mindkettő zöld. Pull Requestnél csak a `test` fut – ez a `main` kötelező ellenőrzése.
- **Ágra push** → **Preview** előzetes kiadás (`x.y.z-dev.N`), mellette a feloldott `pubspec.lock`; **`v*` címke** → végleges Release a CHANGELOG adott szakaszával. A címke és a `pubspec.yaml` verziója egyezzen, különben a CI leáll.
- **Csak arm64** APK; `versionCode` = a commitok száma, így mindig nő.
- **NDK rögzítve** a runneren előre telepített verzióra (`29.0.14206865`).
- **Aláírás:** PKCS12 kulcs (`cetli`, RSA 4096), a GitHub Secretsben: `CETLI_KEYSTORE_BASE64`, `CETLI_KEYSTORE_PASSWORD`, `CETLI_KEY_ALIAS`. Mentés: KeePass, a kulcsfájl helyben a `docs/_privat/signing/` mappában (nem verziózott).
- A bukott tesztek neve és hibaüzenete annotációként jelenik meg (`tool/ci_test_annotations.py`).
- A Flutter verziója a munkafolyamatban rögzített (`FLUTTER_VERSION`).

## Következmények
- Minden ágra pusholt állapot telefonon kipróbálható.
- A kulcs elvesztése esetén az app csak törlés után telepíthető újra – ezért kell a másolat.
- Új csomagnál a `pubspec.lock` a Preview kiadásról kerül vissza a repóba.
