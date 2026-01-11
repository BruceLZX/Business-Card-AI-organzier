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
- AI extraction: parse company info, services, and contact details (provider TBD)
- Document generation:
  - Company document: company info, services, related contacts, contact links, original photos
  - Contact document: person info, role, contact methods, company link, original photos
- Search and filter: by name, company, business keywords
- Manual edit: users can correct and enrich extracted data

### Information Architecture / Pages
- Home
  - Global search bar for people, companies, and keywords
- Yellow Pages
  - Toggle between Company and Contact lists
  - Filters: company location, service type, target audience (B2B/B2C), market region
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
- Traceability: keep original photos and extraction sources
- Extensibility: swap or add AI extraction providers

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
    - OCRService: AI extraction and parsing (provider TBD)
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
- Done: baseline structure and documentation
- In progress: AI extraction provider selection

## Next Steps
- Decide AI provider and field mapping
- Define search indexing strategy (CJK tokenization/keywords)
- Plan optional backup and sync
