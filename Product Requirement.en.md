# BusinessCardAIAssisstant — Product Requirements (EN)

This document is the authoritative product specification. It covers:
- Contact/company detail structure, interaction, and use cases
- Directory and creation flows
- AI enrichment, tag rules, and language display logic

---

## 0) Global Rules

1. **System language & display**
   - Default to system language.
   - If the target language is missing, fall back to the available language and fill translation in the background.
   - Name display follows the “primary name + original name” rule (see 1.3/2.3/5.1).

2. **Do not translate fields**
   - Addresses, URLs, emails, phone numbers, IDs/codes, tags.

3. **Tag rules**
   - Tags are not translated; generate in the user’s current system language (proper nouns may remain original).
   - Tags must be single words (no spaces/punctuation); manual tags may include spaces/punctuation.
   - Match from tag pool first, only create new tags when needed.

4. **Error messages**
   - All error messages must have English/Chinese versions and follow system language.

---

## 1) Contact Detail Page

### 1.1 Goal
Let users quickly understand who the person is, what they do, how to reach them, and which company they belong to.

### 1.2 Module Structure (recommended order)
- Header: display name in system language; show original name under it when languages differ.
- Language toggle: segmented EN/中文; only affects the current page.
- Title and company name (jump to company details).
- AI summary: placeholder before enrichment; show AI summary after; show “No information found online” if empty.
- Contact info: phone/email/website/LinkedIn (tappable).
- Company links: related company list + “link company” (select existing only).
- Notes.
- Tags (not translated).
- Photos: card/profile images (fullscreen viewer).
- Bottom action: delete contact (destructive).

### 1.3 Primary Use Cases
1. View contact info (name/title/contact/company).
2. Edit a single module (linking excluded).
3. Language display follows system; top EN/中文 toggle only affects this page.
4. Link existing company (multi-select).
5. Unlink a single company (long press/menu).
6. Manage photos (add/delete/fullscreen).
7. Delete contact: remove from linked companies.
8. Name display: show name in system language; show original name under it if languages differ.
9. AI summary: if no valid info, show “No information found online.”
10. Enriched fields: only highlight fields updated in the latest run; clear on page exit; clear when the user edits and saves.
11. Per-field undo: each replaced field has its own undo button.
12. Edit inputs: clearly styled with borders/fill to indicate edit mode.

### 1.4 Photo Interaction (Contact)
- Thumbnail grid + tap to fullscreen.
- Fullscreen supports swipe and back.
- Allow deletion.

---

## 2) Company Detail Page

### 2.1 Goal
Let users quickly understand what the company does, its scale/positioning, how to reach it, and which people are related.

### 2.2 Module Structure (recommended order)
- Header: company name in system language; show original name under it when languages differ.
- Language toggle: segmented EN/中文; only affects the current page.
- Summary and industry.
- AI summary: same as contact.
- Company basics: size/revenue/founding year/HQ/address/phone.
- Business: service type / target audience (free text, suggested format B2B/B2C/B2G) / market region.
- Links: website/LinkedIn (tappable).
- Contacts: related contacts + “link contact” (select existing only).
- Notes.
- Tags (not translated).
- Photos: brochures/materials (limit 20).
- Bottom action: delete company (destructive).

### 2.3 Primary Use Cases
1. View company info (name/summary/industry/size/revenue/etc.).
2. Edit a single module (linking excluded).
3. Language display follows system; top EN/中文 toggle only affects this page.
4. Link existing contacts (multi-select).
5. Unlink a single contact (long press/menu).
6. Manage photos (add/delete/fullscreen).
7. Delete company: clear company fields on linked contacts.
8. Company enrichment summary: include product/funding/partnerships/positioning (avoid repeating base fields).
9. Enriched fields: only highlight fields updated in the latest run; clear on page exit; clear when the user edits and saves.
10. Per-field undo: each replaced field has its own undo button.
11. Edit inputs: clearly styled with borders/fill to indicate edit mode.

### 2.4 Photo Interaction (Company)
- Limit 20 photos.
- Fixed-height grid with scrolling.
- Tap for fullscreen with swipe/back.

---

## 3) Linking Module Interaction Rules

1. Related list is scrollable (fixed height ~3 rows).
2. “Link new / remove link” buttons stick below the list.
3. Remove link is destructive (red).
4. Batch unlink: selection mode + confirm.

---

## 4) Directory

1. List shows contact/company names in system language.
2. If target language is missing, fall back to existing language and backfill translation.
3. Tags are not translated in lists.
4. List items support long-press delete (confirm required).
5. Search & filters: location / service type / target audience / tags / market region.

---

## 5) Create (Capture)

1. Tab name is “Create”.
2. Recent list shows name + subtitle in system language.
3. Tapping a tab returns to that tab’s root view.
4. Recent list supports long-press delete (confirm required).
5. Auto-generate tags after creation (system language; non-blocking).
6. If both English/Chinese names exist: default Chinese as primary; if size is detectable, choose the larger as primary.
7. Scan flow: vision parsing first; OCR fallback if parsing fails.
8. Name fields: Name = primary name, Original Name = original name (prefilled based on parsing).

---

## 6) AI Enrichment

### 6.1 Entry & Interaction
- Entry button at top; becomes progress bar on tap.
- During enrichment, editing for the current document is disabled.
- Progress only advances after stages complete (no fake timers).
- No central overlay.
- If no valid info is found, AI summary shows “No information found online.”

### 6.2 Stages
1. Photo analysis (mini model).
2. Web search (thinking model, multi-pass).
3. Merge, dedupe, and output.
4. Search strategy: if China-related (Chinese text, .cn domain, China locations), search Chinese sources first then international; otherwise prioritize international.

### 6.3 Results & Comparison
- Updated fields are highlighted.
- Original values are shown for comparison.
- Each replaced field has its own undo button.
- New fields are highlighted only for the current run; clear on exit or after user edits/saves.

### 6.4 Quality & Safety
- Validate against known info to avoid mismatches.
- Mark uncertain info with [Possibly inaccurate] at field/segment level.
- If official website/LinkedIn/personal site is detected, prioritize those.
- Enrichment should reflect a potential user/investor/partner view (products, funding, partners, positioning), without duplicating base fields.

### 6.5 Tags
- Use mini model for tag generation.
- Generate tags in system language (proper nouns preserved).
- Match tag pool first; create new tags only when necessary.
- Tags should also be generated on create, not only during enrichment.

### 6.6 Failure Messages (EN/ZH)
- Missing API key
- Network error
- Parse failed
- Empty result

---

## 7) Language & Translation Strategy

1. Translation triggers on create/edit save/enrichment completion; also on detail open if missing.
2. Translation results are cached; re-translate only when source fields change.
3. Tags are not translated.
4. English personal names should be transliterated into Chinese, not localized.

---

## 8) Issue List
(placeholder)

### 8.1 Solutions & Logic (Engineering)
(placeholder)

### 8.2 To Do
(placeholder)

---

## 9) Engineering & Configuration

### 9.1 Tech Stack
- SwiftUI + local storage.
- OpenAI Responses API (vision parsing, enrichment, translation).

### 9.2 Project Structure
- `BusinessCardAIAssisstant/` app source
- `BusinessCardAIAssisstant/App/` entry, settings, global state, strings
- `BusinessCardAIAssisstant/UI/` screens and components
- `BusinessCardAIAssisstant/Models/` data models and filters
- `BusinessCardAIAssisstant/Services/` parsing, enrichment, translation, search
- `BusinessCardAIAssisstant/Storage/` local persistence and photo store
- `BusinessCardAIAssisstant/Resources/` resources
- `BusinessCardAIAssisstant/Assets.xcassets/` icons and colors

### 9.3 Local Setup
1. Create `BusinessCardAIAssisstant/Secrets.xcconfig`:
   ```
   OPENAI_API_KEY = your_key_here
   ```
2. Open `BusinessCardAIAssisstant.xcodeproj` and run.

### 9.4 AI Config (Local, Gitignored)
- Models and prompts live in `BusinessCardAIAssisstant/App/AIConfig.swift`.
- The file is gitignored and not committed.
- Each prompt block documents its usage and context.

This README is the single source of truth for implementation.
