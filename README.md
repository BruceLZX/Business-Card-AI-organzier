# BusinessCardAIAssisstant

[中文说明 / Chinese](README.zh.md)

An iPhone app for capturing business cards and company brochures, generating structured contact/company documents, and managing relationships with fast search and AI-assisted enrichment.

## Product Requirements
- Detailed use cases live in `Product Requirement.md` (Chinese).

## Key Features
- Capture photos (camera or library) and store them per document (up to 10 per document).
- Contact and company detail pages with modular editing and cross-links.
- Directory with alphabetical indexing and filters for both contacts and companies.
- Tag pool with searchable selection and AI tag suggestions.
- AI enrichment with multi-stage progress, field-level change tracking, and undo.

## AI Enrichment Summary
- Uses image analysis (mini model) and multi-stage web search (thinking model).
- Progress stages are shown globally; all interactions are blocked during enrichment.
- Updated fields are highlighted, original values are shown, and undo is available.
- Uncertain info is marked as "possibly inaccurate" with a yellow badge.

## Tech Stack
- SwiftUI + local storage.
- OpenAI Responses API for OCR parsing and enrichment (key in `Secrets.xcconfig`).

## Repository Structure
- `BusinessCardAIAssisstant/` app source
- `BusinessCardAIAssisstant/Services/` capture, OCR, enrichment, search
- `BusinessCardAIAssisstant/Storage/` local persistence and photo store
- `BusinessCardAIAssisstant/UI/` screens and reusable UI
- `BusinessCardAIAssisstant/Models/` document models
- `BusinessCardAIAssisstant/App/` app entry, settings, app state

## Setup
1. Create `BusinessCardAIAssisstant/Secrets.xcconfig` with:
   ```
   OPENAI_API_KEY = your_key_here
   ```
2. Open `BusinessCardAIAssisstant.xcodeproj` and run.

## AI Config (Local, Gitignored)
- AI models and prompts are centralized in `BusinessCardAIAssisstant/App/AIConfig.swift`.
- This file is gitignored so API choices and prompts stay local.
- Each prompt block includes comments describing where it is used and why.

## Status (Latest)
- Core document flow and directory are implemented.
- AI enrichment flow is implemented with progress, field tracking, and undo.
- Ongoing: verify end-to-end behavior and UX polish based on `Product Requirement.md`.

## Next Goals
- Enable paid features (subscription or one-time unlock).
- Allow sharing documents with other users who have the app.
- Generate a PDF report per document for sharing or saving.
- Select AI provider based on user region (e.g., alternate API in China).

## Notes
- App icon source: `BusinessCardAI.png`.
- Do not commit secrets; `.gitignore` excludes them.
