# BusinessCardAIAssisstant — Product Requirements (EN)

This document is the single source of truth for product behavior.

---

## 0) Scope
- Contact/company detail pages
- Create flow (scan/manual)
- Directory
- AI enrichment, tags, and language rules
- Issue list, solutions, and execution checklist

---

## 1) Terms
- **Original name**: the name in the original language.
- **Translated name**: AI-generated translation used for display.
- **Document**: a structured record for a contact or company.
- **Enrichment**: AI-assisted data augmentation (multi-stage search/merge/output).

---

## 2) Global Rules

### 2.1 System Language & Display
- Default to system language.
- If target language is missing, show the existing language and backfill translation in the background.
- **Name display rules**:
  - If system language matches the single-language name, show that name only.
  - If system language differs, show “translated name (primary) + original name (secondary)”.
  - Translation is generated at creation time by AI.

### 2.2 Non-translated Fields
- Address, URLs, email, phone numbers, codes/IDs, WeChat ID, tags.

### 2.3 Tag Rules
- Tags are not translated; generation uses system language (proper nouns may remain original).
- Tags must be single words (no spaces/punctuation); manual tags may include spaces/punctuation.
- Match against tag pool first; only create new if no match.

### 2.4 Error Messages
- All errors must have EN/ZH variants, shown by system language.

---

## 3) Contact Detail Page

### 3.1 Structure
- Header: name in system language, with original name as secondary when needed.
- Language toggle: EN/中文 segmented control (page-local).
- Title + company (tap to company detail).
- AI summary module: placeholder before enrichment; summary after.
- Contact info: phone/email/WeChat/website/LinkedIn (tappable).
- Company links: list + “link existing company”.
- Notes.
- Tags (not translated).
- Photos (full-screen view).
- Delete contact (red button).

### 3.2 Key Interactions
1. Edit one module at a time (excluding association module).
2. AI-updated fields are highlighted in blue; clear after re-enter or save.
3. Per-field “Undo replace” for AI updates.
4. AI completion updates the page immediately.
5. AI must not write to notes.
6. If WeChat exists, show “Open WeChat Search”; on tap, copy first and ask whether to open WeChat.

### 3.3 Photo Interaction
- Thumbnails with full-screen viewer.
- Swipe navigation + back.
- Deletion supported.
- Max 10 photos.

---

## 4) Company Detail Page

### 4.1 Structure
- Header: name in system language, original name as secondary when needed.
- Language toggle: EN/中文 segmented control (page-local).
- Summary + industry.
- AI summary module.
- Company basics: size/revenue/founded/HQ/address/phone.
- Business: service type/target audience/market region.
- Links: website/company email/LinkedIn.
- Linked contacts list + “link existing contact”.
- Notes, tags, photos.
- Delete company (red button).

### 4.2 Key Interactions
1. AI summary must add new information: products/features/specs/competitors/pros/cons/funding/partners/positioning (when available).
2. AI-updated fields are highlighted; clear after re-enter or save.
3. Per-field undo.
4. AI completion updates the page immediately.
5. AI must not write to notes.

### 4.3 Photo Interaction
- Max 20 photos.
- Fixed-height thumbnail area, scrollable.
- Full-screen viewer with swipe.

---

## 5) Association Module (Shared)
1. Scrollable list with fixed height (~3 items).
2. “Link new / Remove link” buttons fixed below list.
3. Remove link is destructive (red).
4. Multi-select delete with confirmation.

---

## 6) Create Flow

### 6.1 Base Rules
1. Page name is “Create”.
2. Recent list uses system language.
3. Re-tapping any bottom tab returns to its root.
4. Recent list supports long-press delete with confirmation.
5. Tags auto-generate after creation (failure does not block).
6. Scan flow: vision first (multi-image), OCR text fallback.
7. Name = original; Original Name = original-language name.
8. If only one-language name is detected, auto-translate during creation (do not override manual edits).
9. QR codes are extracted for prefill + enrichment context.

### 6.2 Add Mode (Photo Pool)
1. Enter add mode → show photo pool first.
2. Camera/Album buttons below the pool.
3. Album supports multi-select; user must tap confirm to proceed.
4. Max 10 photos.

### 6.3 Manual Create
- No “select existing” button.
- After name input, run fuzzy match and show prompt: “Open existing / Continue create”.

---

## 7) Directory
1. Names shown in system language.
2. If missing target language, show fallback and backfill translation.
3. Tags are not translated in list.
4. Long-press delete with confirmation.
5. Filters: location/service type/target audience/tags/market region.

---

## 8) AI Enrichment

### 8.1 Entry & Interaction
- Entry button at top; becomes progress indicator.
- Editing/critical buttons disabled during enrichment (navigation allowed).
- Progress advances by stage completion only.

### 8.2 Stages & Search Strategy
1. Photo analysis (mini model).
2. Web search (thinking model, multi-stage).
3. Merge/dedupe/output.
4. If Chinese signals detected, search Chinese sources first.

### 8.3 Output & Comparison
- Updated fields highlighted in blue.
- Show previous values for comparison.
- Per-field undo when replaced.

### 8.4 Quality & Safety
- Validate identity against known details.
- Mark uncertain info with 【可能不准确】 at field/paragraph level.
- Prioritize official site/LinkedIn/personal site/QR links.
- Summary must include products/features/specs/competitors/pros/cons/funding/partners/positioning when info exists.
- If web is empty but photo/known info exists, summary must be generated from those.
- AI must not write to notes.

### 8.5 Tag Generation
- Use mini model.
- Generate in system language (proper nouns preserved).
- Prefer tag pool matches first.
- Generate on create, not only on enrichment.

### 8.6 Uncertainty Marker Rules
- Only write 【可能不准确】 when AI is uncertain.
- Highlight only for current update; clear after save or re-enter.

---

## 9) Language & Translation Strategy
1. Trigger translation after create/edit/enrichment; also on detail open if missing.
2. Cache translations locally; re-translate only when source changes.
3. Tags are not translated.
4. English personal names → transliteration in Chinese (no invented Chinese names).
5. WeChat ID and email are not translated.

---

## 10) Issue List (Current)
1. English company names not showing “Chinese translation + English original” in Chinese system language.
2. AI Summary too short and repetitive, missing products/features/specs/competitors/pros/cons.
3. AI enrichment removes old tags or creates duplicates.
4. “Uncertain” marker duplicates and never clears.
5. AI writes notes.
6. Create flow lacks camera/album dual entry and multi-select confirmation.
7. Add-mode photo pool hierarchy/interaction unclear.
8. Manual create shows “select existing”; should be fuzzy match prompt.
9. Missing WeChat field + WeChat search entry for contacts; missing company email field.
10. QR content not used for prefill/enrichment.

---

## 11) Solutions (Engineering)
1. **Bilingual display**: if system language matches single-language name, show it only; otherwise show translated + original (translation generated on create).
2. **Summary expansion**: stronger prompt with business model/positioning/competitors/pros/cons/specs.
3. **Tag merge**: AI only adds; normalize and dedupe.
4. **Uncertainty cleanup**: only mark when uncertain; clear highlights after save/re-enter.
5. **Notes protection**: AI never writes notes.
6. **Create entry**: photo pool + camera/album dual entry + multi-select confirm.
7. **Photo pool UX**: tap to full-screen, delete on thumbnail, consistent visual style.
8. **Duplicate prompt**: remove “select existing”; replace with fuzzy match modal.
9. **WeChat + Company Email**: add contact WeChat + search entry; add company email.
10. **QR parsing**: use QR data for prefill/enrichment.

---

## 12) To Do List
1. Align bilingual name display with creation-time translation.
2. Strengthen AI summary prompt.
3. Tag merge + normalization.
4. Uncertainty marker logic and highlight clearing.
5. Block AI from writing notes.
6. Add camera/album dual entry + multi-select confirmation.
7. Add-mode pool interactions + 10 photo limit.
8. Manual create duplicate prompt.
9. Contact WeChat + company email + WeChat prompt.
10. QR parsing for prefill/enrichment context.
