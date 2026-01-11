# Business Card AI Assistant

[中文说明 / Chinese](README.zh.md)

An iPhone app that captures business cards and company brochures to generate structured Company and Contact documents. Users can search by name, company, or business keywords, navigate between related entities, and manually edit extracted fields.

## Project Overview
The app turns offline business materials into a searchable relationship graph of people and companies, suitable for BD, sales, procurement, and partnership management.

## Product Requirements (PRD)
### Target Users
- BD, sales, marketing, PR, procurement, and anyone collecting business cards and company materials

### Core Value
- Convert paper cards and brochures into structured data
- Fast lookup by person, company, or business keywords
- Bidirectional links between companies and contacts

### Core Features
- Capture: photo scan for business cards and brochures
- OCR extraction: local text recognition via Apple Vision
- Document creation: create company/contact documents from OCR output
- GPT classification: determine contact vs company before creation
- Review before creation: user confirms fields and document type before saving
- Document generation:
  - Company document: company info, services, related contacts, contact links, original photos
  - Contact document: person info, role, contact methods, company link, original photos
- Search and filter: by name, company, business keywords
- Manual edit: users can correct and enrich extracted data
- Duplicate handling: detect existing contacts and confirm updates
- Manual enrichment: user-triggered online search for profile completion
- Recent documents: show latest created Company/Contact entries on the Capture page

### Information Architecture / Pages
- Capture
  - Large capture button and recent documents
- Directory
  - Search across companies/contacts and toggle list type
  - Filters: company location, service type, target audience (B2B/B2C), market region
- Settings
  - Appearance mode (system/light/dark), language, and default preferences
- Company detail page
  - Company profile and services
  - Related contacts with jump links
  - Photo gallery
  - Edit entry
- Contact detail page
  - Personal info, role, contact methods, notes
  - Jump to company document
  - Photo gallery
  - Edit entry

### Data Model (Suggested)
- CompanyDocument
  - Name, summary, service keywords, website/address/phone
  - Related contacts (ContactDocument ID list)
  - Photo list
- ContactDocument
  - Name, title, contact methods, email, notes
  - Company reference (CompanyDocument ID)
  - Photo list

### Non-Functional Requirements
- Privacy: local-first storage; cloud sync optional later
- Traceability: keep original photos; OCR text not stored by default
- Extensibility: swap or add extraction providers (Vision OCR now)

### Account & Sync (Future)
- Local-only storage in MVP
- Future login options: Google or phone number account creation

## Project Structure (Suggested)
- BusinessCardAIAssisstant/
  - App/: app entry, navigation, routing
  - UI/: screens and reusable components
  - Models/: CompanyDocument, ContactDocument, etc.
  - Services/
    - CaptureService: photo capture and image management
    - OCRService: Vision-based text recognition
    - EnrichmentService: online enrichment stub (API to be configured locally)
    - SearchService: indexing and query
  - Storage/
    - LocalStore: local DB and image store
  - Resources/: assets, fonts, configs
  - Tests/: unit and UI tests

## Timeline (Example)
| Phase | Time | Deliverables |
| --- | --- | --- |
| Requirement lock | Week 1 | PRD, IA, rough prototype |
| Data model & storage | Week 2 | Company/Contact models, local storage |
| Capture & extraction | Week 3 | Camera flow, AI extraction integration |
| Search & linking | Week 4 | Search, company-contact navigation |
| UI polish | Week 5 | Detail pages, edit flows, gallery |
| Test & iterate | Week 6 | Core flow tests, bug fixes |

## Status
- Done: OCR capture, review-before-create flow, document creation, and manual enrichment flow
- In progress: enrichment refinement and UI polish

## Next Steps
- Refine enrichment field mapping (website/phone/address)
- Add online enrichment client (configure API key locally; do not commit)
- Define search indexing strategy (CJK tokenization/keywords)
- Plan optional backup and sync

## Configuration (Local Only)
- Add your API key to `BusinessCardAIAssisstant/Secrets.xcconfig` with `OPENAI_API_KEY = ...`.
- The enrichment client uses the `gpt-4o-mini` model for cost efficiency.
- Do not commit secrets; `.gitignore` already excludes these files.
- Device run requires Camera permission (NSCameraUsageDescription is configured in the Xcode project).
 - First run starts with an empty dataset (no sample data).

## Assets
- App icon source: `BusinessCardAI.png` (copied into `BusinessCardAIAssisstant/Assets.xcassets/AppIcon.appiconset`).

## Changelog
- 2026-01-11: Added settings (appearance mode, language, defaults), Directory search, OCR service, GPT classification, and manual enrichment client (mini model).
- 2026-01-11: Removed sample data, added review-before-create flow, recent documents list, and updated app icon.
