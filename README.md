<div align="center">

<img src="BusinessCardAIAssisstant/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" height="120" alt="BusinessCardAIAssistant Logo" />

# BusinessCardAIAssistant
### Capture once. Structure forever. Connect people ↔ companies.

**An AI-powered business card hub for people who meet a lot of people.**  
Turn business cards & brochures into **living profiles**: contacts, companies, links, tags, and enriched summaries that stay connected.

[中文说明](README.zh.md) · [Product Requirements (EN)](Product%20Requirement.en.md) · [产品需求（中文）](Product%20Requirement.md) · [License](LICENSE)

<br/>

<img alt="Stars" src="https://img.shields.io/github/stars/BruceLZX/Business-Card-AI-organzier?style=social">
<img alt="Forks" src="https://img.shields.io/github/forks/BruceLZX/Business-Card-AI-organzier?style=social">
<br/>
<img alt="Last Commit" src="https://img.shields.io/github/last-commit/BruceLZX/Business-Card-AI-organzier">
<img alt="Issues" src="https://img.shields.io/github/issues/BruceLZX/Business-Card-AI-organzier">
<img alt="License" src="https://img.shields.io/github/license/BruceLZX/Business-Card-AI-organzier">
<img alt="Swift" src="https://img.shields.io/badge/Swift-SwiftUI-orange">
<img alt="Platform" src="https://img.shields.io/badge/Platform-iOS-lightgrey">

<br/><br/>

> If your camera roll is full of business card photos and your CRM is empty, this is for you.

<!-- Optional: add a demo gif later (recommended) -->
<!-- <img src="assets/demo.gif" width="820" alt="Demo" /> -->

</div>

---

## Why this exists
Business cards are easy to **collect**, but hard to **use**:
- Photos pile up → zero structure → zero follow‑up
- Traditional CRMs are heavy → high friction → abandoned

**BusinessCardAIAssistant** sits in the middle:
- as lightweight as your camera
- as structured as a CRM
- as connected as your real network

---

## What makes it different

### ✅ Living profiles, not static scans
Contacts and companies are **first‑class documents** that stay linked:
- People ↔ Companies always connected
- Fast navigation across related entities
- Built for scale: directory + filters + A–Z indexing

### ✅ Vision‑first parsing (OCR fallback)
Capture multiple photos (front/back/angles/brochures):
- Vision parsing first
- OCR fallback for robustness

### ✅ AI enrichment with accountability
Every change is transparent:
- Field‑level highlights
- Original values shown next to new values
- **One‑tap undo per field**

### ✅ Language‑aware display (EN/中文)
Show the right name for the system language, with original name as context when languages differ.

---

## Feature highlights

**Core**
- Multi‑photo capture per document
- Contact & company documents
- Cross‑link contacts ↔ companies (existing only)
- Notes + tags + tappable links
- Fast directory: search + filters + A–Z

**Designed for speed**
- Modular detail pages (edit one module at a time)
- Fixed‑height related lists for quick linking
- Confirmed destructive actions

**Designed for trust**
- Highlights only what changed in the latest run
- Per‑field undo instead of “revert all”
- Uncertain info explicitly marked

---

## How it works (at a glance)
1) Capture photos (cards, brochures, QR)
2) AI extracts structure (vision → OCR fallback)
3) Enrichment adds missing context
4) You decide what stays (undo per field)

---

## Docs (source of truth)
Product behavior is defined by the PRDs:
- **EN:** [Product Requirement.en.md](Product%20Requirement.en.md)
- **中文：**[Product Requirement.md](Product%20Requirement.md)

---

## Roadmap
- [ ] In‑app memory usage display
- [ ] User‑managed API keys/models per stage with validation
- [ ] Document sharing with import confirmation + duplicate resolution
- [ ] PDF export per document
- [ ] Paid distribution (no in‑app purchase flow)

---

## Contributing
Pull requests and issues are welcome.

Recommended areas:
- UI polish (SwiftUI components, detail modules, navigation)
- Parsing robustness (multi‑photo edge cases)
- Enrichment reliability (merge/dedupe quality, uncertainty marking)
- Local storage performance (indexing/search)

---

## License
See [LICENSE](LICENSE).

---

## Support
If this matches how you actually network, please **star the repo** ⭐
Stars help visibility and attract contributors.
