# BusinessCardAIAssistant — AI-Powered Business Card Hub (iOS, Local-First)

[中文 README](README.zh.md) · [Product Requirements (EN)](Product%20Requirement.en.md) · [产品需求 (中文)](Product%20Requirement.md)

**Capture once, structure forever.**  
Turn business cards + brochures into **living profiles**—contacts and companies that stay linked, searchable, and enrichable.

If your **camera roll is full of business card photos** and your **CRM is empty**, this is for you.

---

## What makes it different

### Living profiles, not static scans
- Contacts and companies are **linked entities**, not isolated photos
- Jump between people ↔ organizations in one tap
- Built for volume: directory + search + filters + A–Z indexing

### Vision-first parsing (OCR fallback)
- Multi-photo capture per document (front/back, angles, brochures)
- Vision parsing first; **OCR fallback** for robustness

### AI enrichment with accountability
- Highlights **only fields changed** in the latest run
- Shows **original values** next to enriched values
- **Per-field undo** (one tap, no “revert everything” guessing)

### Language-aware names (EN/中文)
- Default display follows system language
- Show **primary name + original name** when languages differ
- Translation cached; re-translate only when source fields change
- **Tags are never translated** (by design)

---

## Product scope

- Capture, create, and edit **contact/company documents**
- Cross-link contacts and companies with fast navigation
- Directory view with search, filters, and alphabetical indexing
- AI enrichment with staged progress and field-level tracking
- Local-first storage for documents and photos

---

## Docs (authoritative)

- Product requirements (English): `Product Requirement.en.md`
- 产品需求（中文）: `Product Requirement.md`

If you’re contributing, please align product behavior with these docs.

---

## AI enrichment (staged, no fake progress)

Stages:
1. Photo analysis (mini model)
2. Web search (thinking model, multi-pass)
3. Merge, dedupe, and output

Quality & safety:
- Validate against known info to reduce mismatches
- Mark uncertain info with **[Possibly inaccurate]**
- Prefer official sources (website / LinkedIn / personal site)
- China-related queries prioritize Chinese sources first

---

## Tech stack

- SwiftUI
- Local storage (documents + photo store)
- OpenAI Responses API (vision parsing, enrichment, translation)

---

## Project structure

