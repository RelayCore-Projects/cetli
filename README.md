# Cetli

[![CI](https://github.com/RelayCore-Projects/cetli/actions/workflows/ci.yml/badge.svg)](https://github.com/RelayCore-Projects/cetli/actions/workflows/ci.yml) [![Release](https://img.shields.io/github/v/release/RelayCore-Projects/cetli)](https://github.com/RelayCore-Projects/cetli/releases/latest) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A simple, offline shopping list app for Android – with file-based sharing and duplicate-free merging between devices.

*Cetli* (Hungarian) is the small slip of paper you scribble your shopping list on.

> **Status:** v0.2.0 – lists with edit and shopping modes. Next: the item catalog with autocomplete (v0.3.0). See the [roadmap](docs/02%20Ütemterv.md).

## Features (planned for v1.0)

- **Multiple lists** – long press to select, rename or delete several at once – with two modes:
  - **Edit mode** – type an item, press Enter, keep typing; the keyboard stays open
  - **Shopping mode** – tap an item as it goes into the basket: it fades and is struck through, but stays readable
- **Sorting** per list (order added, name A–Z, name Z–A); checked items move to the bottom or stay in place
- **Notes** per item – quantity, variety or brand (`2 l`, `whole grain`)
- **Catalog** of ~150 common items plus your own, with **autocomplete** and **multi-select**; new items are learned automatically
- **Share a list as a `.cetli` file** (e.g. via Messenger) and **merge** it on the other phone: items are matched by name (case-insensitive), so `Bread` and `bread` become one; checks, notes and deletions are reconciled by timestamp
- **Backup and restore** of all lists and the catalog
- **Private by design:** no internet permission, no account, no ads, no analytics – your data stays on your phone

## Install

1. On your phone, open the [latest release](https://github.com/RelayCore-Projects/cetli/releases/latest) and download `cetli-x.y.z.apk`
2. Open it and allow installing from this source
3. To update, install the new APK over the old one – **do not uninstall first**, or your lists are deleted

Requires Android 8.0 or newer on a 64-bit phone. Tip: [Obtainium](https://github.com/ImranR98/Obtainium) can watch this repository and notify you of new releases.

## Tech stack

- [Flutter](https://flutter.dev) (Dart), Material 3
- SQLite (`sqflite`) with a versioned schema and tested migrations
- Native Android sharing and file access through a small platform channel – no third-party native plugins
- GitHub Actions: static analysis, tests, signed release builds

## Project documentation

Development is run as a small, fully documented project: specification with functional and non-functional requirements, architecture decision records, roadmap, test plan and changelog.

The documentation lives in [`docs/`](docs) as an [Obsidian](https://obsidian.md) vault and is written in **Hungarian**:

| Document | Contents |
|---|---|
| [Specifikáció](docs/01%20Specifikáció.md) | Requirements, data model, screens, decisions |
| [Ütemterv](docs/02%20Ütemterv.md) | Roadmap and milestones |
| [Fejlesztési folyamat](docs/03%20Fejlesztési%20folyamat.md) | Versioning, branching, commits, releases |
| [Döntések](docs/Döntések) | Architecture decision records (ADR) |
| [Tesztelés](docs/05%20Tesztelés.md) | Test strategy and manual test plan |
| [CHANGELOG](docs/CHANGELOG.md) | Release notes |

## Development workflow

- `main` is protected; every change goes through a pull request with green CI
- [Semantic Versioning](https://semver.org) and [Conventional Commits](https://www.conventionalcommits.org)
- Each push builds a **Preview** APK for testing on real devices; a `vX.Y.Z` tag publishes a signed release with notes from the changelog

## License

[MIT](LICENSE) © 2026 RelayCore-Projects
