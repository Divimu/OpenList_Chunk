<div align="center">
  <img src="https://raw.githubusercontent.com/OpenListTeam/Logo/main/logo.svg" width="128" height="128" alt="logo" />

  <h1>OpenList_Chunk</h1>

  <p><em>Verbeterde fork van OpenList — Omzeil CDN uploadlimieten met chunked upload</em></p>

  <a href="https://github.com/zmabin/OpenList_Chunk/actions?query=workflow%3ABuild"><img src="https://img.shields.io/github/actions/workflow/status/zmabin/OpenList_Chunk/build.yml?branch=main" alt="Build status" /></a>
  <a href="https://github.com/zmabin/OpenList_Chunk/releases"><img src="https://img.shields.io/github/v/release/zmabin/OpenList_Chunk" alt="latest version" /></a>
  <a href="https://github.com/zmabin/OpenList_Chunk/blob/main/LICENSE"><img src="https://img.shields.io/github/license/zmabin/OpenList_Chunk" alt="License" /></a>
</div>

---

[English](./README_en.md) | [中文](./README.md) | [日本語](./README_ja.md) | **Nederlands**

---

## Overzicht

**OpenList_Chunk** is een verbeterde fork van [OpenList](https://github.com/OpenListTeam/OpenList). Het herontwerpt de uploadlogica zonder de originele datastructuren aan te passen, om CDN-uploadlimieten (zoals Cloudflare's 100MB limiet) te omzeilen.

---

## Functionaliteiten

- **Form Chunked Upload**: Sessie-gebaseerde multipart chunking + `io.MultiReader` streaming merge
- **Stream Chunking**: Zero-copy pipe chunking via Content-Range headers (geen schijfgebruik)
- **CRC32 verificatie**: Controleert de integriteit van elke chunk
- **Automatische opschoning**: Verwijdert regelmatig verlopen chunk directories

Zie de [Chinese README](./README.md) of [Engelse README](./README_en.md) voor volledige documentatie.

---

## Routes

| Route | Methode | Functie |
|-------|---------|---------|
| `/api/fs/put/chunk/init` | POST | Initialiseer chunksessie |
| `/api/fs/put/chunk` | PUT | Upload een chunk |
| `/api/fs/put/chunk/merge` | POST | Voeg chunks samen en upload |

---

## Dankbetuigingen

- [LusiyAvA/openlist-chunk](https://github.com/LusiyAvA/openlist-chunk) — Kernideeën en implementatiereferentie voor chunked upload
- [OpenListTeam/OpenList](https://github.com/OpenListTeam/OpenList) — Stabiel en betrouwbaar basisraamwerk

---

## Licentie

`AGPL-3.0`
