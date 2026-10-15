# Cetli

A simple, offline shopping list app for Android – with file-based sharing and duplicate-free merging between devices.

*Cetli* (Hungarian) is the small slip of paper you scribble your shopping list on.

> **Status:** v0.1.0 – concept and specification. The first installable build is planned for v0.2.0. See the [roadmap](docs/02%20Ütemterv.md).

## Features (planned for v1.0)

- **Multiple lists** with two modes:
  - **Edit mode** – type an item, press Enter, keep typing; the keyboard stays open
  - **Shopping mode** – tap an item as it goes into the basket: it fades and is struck through, but stays readable
- **Sorting** per list (order added, name A–Z, name Z–A); checked items move to the bottom or stay in place
- **Notes** per item – quantity, variety or brand (`2 l`, `whole grain`)
- **Catalog** of ~150 common items plus your own, with **autocomplete** and **multi-select**; new items are learned automatically
- **Share a list as a `.cetli` file** (e.g. via Messenger) and **merge** it on the other phone: items are matched by name (case-insensitive), so `Bread` and `bread` become one; checks, notes and deletions are reconciled by timestamp
- **Backup and restore** of all lists and the catalog
- **Private by design:** no internet permission, no account, no ads, no analytics – your data stays on your phone

## Install

Not available yet. From v0.2.0, signed APKs will be published on the [Releases](https://github.com/RelayCore-Projects/cetli/releases) page (Android 8.0+, 64-bit).

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
