<div align="center">

<img src="https://raw.githubusercontent.com/BruceLZX/Business-Card-AI-organzier/main/BusinessCardAIAssistant/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" height="120" alt="BusinessCardAIAssistant Logo" />


# BusinessCardAIAssistant
### Capture once. Structure forever. Connect people ↔ companies.

**An AI-powered business card hub for people who meet a lot of people.**  
Turn business cards & brochures into **living profiles**: contacts, companies, links, tags, and enriched summaries that stay connected.

[中文说明 / Chinese](README.zh.md) · [Product Requirements (EN)](Product%20Requirement.en.md) · [产品需求 (中文)](Product%20Requirement.md) · [License](LICENSE)

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

## Table of Contents
- [Why this exists](#why-this-exists)
- [What makes it different](#what-makes-it-different)
- [Feature overview](#feature-overview)
- [AI enrichment (staged & accountable)](#ai-enrichment-staged--accountable)
- [Language-aware display (EN/中文)](#language-aware-display-en中文)
- [Local-first & privacy](#local-first--privacy)
- [Quick start](#quick-start)
- [Project structure](#project-structure)
- [Roadmap](#roadmap)
- [Docs (source of truth)](#docs-source-of-truth)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

---

## Why this exists
Business cards are easy to **collect**, but hard to **use**:
- Photos pile up → zero structure → zero follow-up.
- Traditional CRMs are heavy → high friction → abandoned.

**BusinessCardAIAssistant** sits in the middle:
- as lightweight as your camera
- as structured as a CRM
- as connected as your actual network

---

## What makes it different

### ✅ Living profiles, not static scans
Contacts and companies are **first-class documents** that stay linked:
- People ↔ Companies are always connected
- Fast navigation across related entities
- Designed for scale: directory + filters + alphabetical indexing

### ✅ Vision-first parsing (OCR fallback)
Capture multiple photos (front/back/angles/brochures):
- Vision parsing first
- OCR fallback for robustness

### ✅ AI enrichment with accountability (no “mystery edits”)
Every change is transparent:
- field-level highlights
- original values shown next to new values
- **one-tap undo per field**

### ✅ Language-aware names (EN/中文)
Show the right name for the current language, with original as context when languages differ.

---

## Feature overview

**Core**
- Multi-photo capture per document (cards + brochures)
- Create/edit contact & company documents
- Cross-link contacts ↔ companies (select existing only)
- Directory: search + filters + A–Z indexing
- Notes + tags + tappable links (phone/email/web/LinkedIn)

**Designed for speed**
- Modular detail pages (edit one module at a time)
- Fixed-height related lists (scrollable, fast linking/unlinking)
- Destructive actions are confirmed (delete/unlink)

**Designed for trust**
- Enrichment highlights only what changed in the latest run
- Highlights clear on exit or after manual edits/save
- Per-field undo instead of “revert the whole run”

---

## AI enrichment (staged & accountable)

**Stages**
1) Photo analysis (mini model)  
2) Web search (thinking model, multi-pass)  
3) Merge + dedupe + output  

**Rules**
- Progress advances only after stages complete (no fake timers)
- Editing is disabled during enrichment for the current document
- If no valid info is found: show **“No information found online.”**

**Quality & safety**
- Validate against known info to reduce mismatches
- Mark uncertain info with **[Possibly inaccurate]**
- Prefer official sources (website / LinkedIn / personal site)
- China-related strategy: search Chinese sources first, then international

---

## Language-aware display (EN/中文)
- Default to system language
- If target language fields are missing: fall back to existing language and backfill translation
- Translation triggers on create/edit save/enrichment completion; cached and re-translate only when source changes
- Tags are **not translated** (generated in system language; proper nouns preserved)

---

## Local-first & privacy
- Documents + photos are stored **locally**
- Network requests happen only when you explicitly run AI parsing/enrichment/translation
- No server required for core functionality (by design)

> If you plan to add cloud sync or analytics, please keep it opt-in and document it clearly.

---

## Quick start

### 1) Add your API key (local only)
Create `BusinessCardAIAssisstant/Secrets.xcconfig`:

```txt
OPENAI_API_KEY = your_key_here
```

### 2) Run
Open `BusinessCardAIAssisstant.xcodeproj` and run.

**Notes**
- Models and prompts live in `BusinessCardAIAssisstant/App/AIConfig.swift`
- The file is gitignored / not committed (keep keys & prompt variants local)

---

## Project structure
```
BusinessCardAIAssisstant/
  App/          # entry, settings, global state, strings
  UI/           # screens & reusable components
  Models/       # data models and filters
  Services/     # parsing, enrichment, translation, search
  Storage/      # local persistence + photo store
  Resources/    # resources
  Assets.xcassets/
```

---

## Roadmap
- [ ] In-app memory usage display
- [ ] User-managed API keys/models per stage with validation
- [ ] Document sharing with import confirmation + duplicate resolution
- [ ] PDF export per document
- [ ] Paid distribution (no in-app purchase flow)

---

## Docs (source of truth)
This repo treats PRDs as the authoritative behavior spec:
- **EN:** [Product Requirement.en.md](Product%20Requirement.en.md)
- **中文：**[Product Requirement.md](Product%20Requirement.md)

If you contribute, please align with the PRDs (language display rules, tag rules, enrichment undo/highlights, linking rules, etc.).

---

## Contributing
Pull requests and issues are welcome.

Recommended contribution areas:
- UI polish (SwiftUI components, detail modules, navigation)
- Parsing robustness (multi-photo edge cases)
- Enrichment reliability (dedupe/merge quality, uncertainty marking)
- Local storage performance (indexing/search)

---

## License
See [LICENSE](LICENSE).

---

## Support
If this matches how you actually network, please **star the repo** ⭐  
Stars help visibility and attract contributors.
