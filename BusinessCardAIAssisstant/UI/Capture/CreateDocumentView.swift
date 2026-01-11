import SwiftUI
import UIKit
import NaturalLanguage

struct CreateDocumentView: View {
    enum DocumentType: String, CaseIterable, Identifiable {
        case company
        case contact

        var id: String { rawValue }
    }

    struct CreatedDocument: Identifiable, Hashable {
        enum Kind: Hashable {
            case company
            case contact
        }

        let id: UUID
        let kind: Kind
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    let image: UIImage?
    let ocrText: String
    let initialType: DocumentType
    let onCreate: ((CreatedDocument) -> Void)?

    @State private var documentType: DocumentType
    @State private var name = ""
    @State private var originalName = ""
    @State private var summary = ""
    @State private var serviceType = ""
    @State private var location = ""
    @State private var marketRegion = ""
    @State private var website = ""
    @State private var linkedin = ""
    @State private var industry = ""
    @State private var companySize = ""
    @State private var revenue = ""
    @State private var foundedYear = ""
    @State private var headquarters = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var title = ""
    @State private var department = ""
    @State private var email = ""
    @State private var companyName = ""
    @State private var originalCompanyName = ""
    @State private var companySummary = ""
    @State private var companyIndustry = ""
    @State private var companyServiceType = ""
    @State private var companyLocation = ""
    @State private var companyWebsite = ""
    @State private var companyPhone = ""
    @State private var companyMarketRegion = ""
    @State private var notes = ""
    @State private var tags: [String] = []
    @State private var duplicateContact: ContactDocument?
    @State private var showDuplicateAlert = false
    @State private var ocrLanguageCode: String?

    init(
        image: UIImage?,
        ocrText: String,
        initialType: DocumentType = .company,
        onCreate: ((CreatedDocument) -> Void)? = nil
    ) {
        self.image = image
        self.ocrText = ocrText
        self.initialType = initialType
        self.onCreate = onCreate
        _documentType = State(initialValue: initialType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(settings.text(.documentType), selection: $documentType) {
                        Text(settings.text(.company)).tag(DocumentType.company)
                        Text(settings.text(.contact)).tag(DocumentType.contact)
                    }
                    .pickerStyle(.segmented)
                }

                if documentType == .company {
                    Section(settings.text(.company)) {
                        TextField(settings.text(.name), text: $name)
                        if shouldShowOriginalFields {
                            TextField(settings.text(.originalName), text: $originalName)
                        }
                        TextField(settings.text(.summary), text: $summary, axis: .vertical)
                        TextField(settings.text(.industry), text: $industry)
                        TextField(settings.text(.companySize), text: $companySize)
                        TextField(settings.text(.revenue), text: $revenue)
                        TextField(settings.text(.foundedYear), text: $foundedYear)
                        TextField(settings.text(.headquarters), text: $headquarters)
                        TextField(settings.text(.serviceTypeLabel), text: $serviceType)
                        TextField(settings.text(.location), text: $location)
                        TextField(settings.text(.marketRegionLabel), text: $marketRegion)
                        TextField(settings.text(.website), text: $website)
                        TextField(settings.text(.linkedin), text: $linkedin)
                        TextField(settings.text(.phone), text: $phone)
                        TextField(settings.text(.address), text: $address)
                    }
                } else {
                    Section(settings.text(.contact)) {
                        TextField(settings.text(.name), text: $name)
                        if shouldShowOriginalFields {
                            TextField(settings.text(.originalName), text: $originalName)
                        }
                        TextField(settings.text(.title), text: $title)
                        TextField(settings.text(.department), text: $department)
                        TextField(settings.text(.companyName), text: $companyName)
                        if shouldShowOriginalFields {
                            TextField(settings.text(.originalCompanyName), text: $originalCompanyName)
                        }
                        TextField(settings.text(.location), text: $location)
                        TextField(settings.text(.phone), text: $phone)
                        TextField(settings.text(.email), text: $email)
                        TextField(settings.text(.personalSite), text: $website)
                        TextField(settings.text(.linkedin), text: $linkedin)
                    }

                    if shouldShowCompanyReview {
                        Section(settings.text(.companyDetails)) {
                            TextField(settings.text(.companyName), text: $companyName)
                            if shouldShowOriginalFields {
                                TextField(settings.text(.originalCompanyName), text: $originalCompanyName)
                            }
                            TextField(settings.text(.summary), text: $companySummary, axis: .vertical)
                            TextField(settings.text(.industry), text: $companyIndustry)
                            TextField(settings.text(.serviceTypeLabel), text: $companyServiceType)
                            TextField(settings.text(.location), text: $companyLocation)
                            TextField(settings.text(.marketRegionLabel), text: $companyMarketRegion)
                            TextField(settings.text(.website), text: $companyWebsite)
                            TextField(settings.text(.phone), text: $companyPhone)
                        }
                    }
                }

                Section(settings.text(.notes)) {
                    TextField(settings.text(.notes), text: $notes, axis: .vertical)
                }

                Section(settings.text(.tags)) {
                    TagPickerView(
                        availableTags: appState.tagPool,
                        selectedTags: $tags,
                        placeholder: settings.text(.tags),
                        addLabel: settings.text(.addButton)
                    )
                }

                Section(settings.text(.ocrText)) {
                    Text(ocrText.isEmpty ? settings.text(.noOCRText) : ocrText)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(settings.text(.createDocumentTitle))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(settings.text(.cancel)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(settings.text(.create)) {
                        attemptSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert(settings.text(.duplicateFoundTitle), isPresented: $showDuplicateAlert) {
                Button(settings.text(.updateExisting)) {
                    if let duplicateContact {
                        mergeIntoExistingContact(duplicateContact)
                        onCreate?(CreatedDocument(id: duplicateContact.id, kind: .contact))
                    }
                    dismiss()
                }
                Button(settings.text(.createNew)) {
                    if let created = saveNewContact() {
                        onCreate?(created)
                    }
                    dismiss()
                }
                Button(settings.text(.cancel), role: .cancel) {}
            } message: {
                Text(settings.text(.duplicateFoundMessage))
            }
            .onAppear {
                if tags.isEmpty {
                    tags = suggestedTags()
                }
                if ocrLanguageCode == nil, !ocrText.isEmpty {
                    ocrLanguageCode = detectLanguageCode(from: ocrText)
                }
            }
        }
    }

    private func attemptSave() {
        if documentType == .contact {
            if let duplicate = appState.findDuplicateContact(name: name, phone: phone, email: email) {
                duplicateContact = duplicate
                showDuplicateAlert = true
                return
            }
        }

        if let created = saveDocument() {
            onCreate?(created)
        }
        dismiss()
    }

    private func saveDocument() -> CreatedDocument? {
        switch documentType {
        case .company:
            return saveCompany()
        case .contact:
            return saveNewContact()
        }
    }

    private func saveCompany() -> CreatedDocument {
        let company = CompanyDocument(
            id: UUID(),
            name: name,
            originalName: resolvedOriginalName(),
            summary: summary,
            serviceKeywords: tags,
            website: website,
            linkedinURL: linkedin.isEmpty ? nil : linkedin,
            industry: industry.isEmpty ? nil : industry,
            companySize: companySize.isEmpty ? nil : companySize,
            revenue: revenue.isEmpty ? nil : revenue,
            foundedYear: foundedYear.isEmpty ? nil : foundedYear,
            headquarters: headquarters.isEmpty ? nil : headquarters,
            address: address,
            phone: phone,
            location: location,
            serviceType: serviceType,
            targetAudience: .b2b,
            marketRegion: marketRegion,
            notes: notes,
            tags: tags,
            relatedContactIDs: [],
            photoIDs: [],
            sourceLanguageCode: ocrLanguageCode,
            enrichedAt: nil,
            createdAt: Date()
        )
        appState.addCompany(company)
        if let image {
            _ = appState.addCompanyPhoto(companyID: company.id, image: image)
        }
        return CreatedDocument(id: company.id, kind: .company)
    }

    private func saveNewContact() -> CreatedDocument? {
        let company = resolveCompanyForContact()

        let contact = ContactDocument(
            id: UUID(),
            name: name,
            originalName: resolvedOriginalName(),
            title: title,
            department: department.isEmpty ? nil : department,
            phone: phone,
            email: email,
            location: location.isEmpty ? nil : location,
            website: website.isEmpty ? nil : website,
            linkedinURL: linkedin.isEmpty ? nil : linkedin,
            notes: notes,
            tags: tags,
            companyID: company?.id,
            companyName: company?.name ?? companyName,
            originalCompanyName: resolvedOriginalCompanyName(),
            photoIDs: [],
            sourceLanguageCode: ocrLanguageCode,
            enrichedAt: nil,
            createdAt: Date()
        )
        appState.addContact(contact)
        if let companyID = company?.id {
            appState.linkContact(contact.id, to: companyID)
        }
        if let image {
            _ = appState.addContactPhoto(contactID: contact.id, image: image)
        }
        return CreatedDocument(id: contact.id, kind: .contact)
    }

    private func mergeIntoExistingContact(_ duplicate: ContactDocument) {
        let company = resolveCompanyForContact() ?? appState.ensureCompany(named: companyName)
        let newContact = ContactDocument(
            id: duplicate.id,
            name: name,
            originalName: resolvedOriginalName(),
            title: title,
            department: department.isEmpty ? nil : department,
            phone: phone,
            email: email,
            location: location.isEmpty ? nil : location,
            website: website.isEmpty ? nil : website,
            linkedinURL: linkedin.isEmpty ? nil : linkedin,
            notes: notes,
            tags: tags,
            companyID: company?.id ?? duplicate.companyID,
            companyName: company?.name ?? companyName,
            originalCompanyName: resolvedOriginalCompanyName(),
            photoIDs: [],
            sourceLanguageCode: ocrLanguageCode,
            enrichedAt: duplicate.enrichedAt,
            createdAt: duplicate.createdAt
        )
        appState.mergeContact(existingID: duplicate.id, newContact: newContact, image: image)
    }

    private func suggestedTags() -> [String] {
        var suggestions: [String] = []
        if !serviceType.isEmpty { suggestions.append(serviceType) }
        if !industry.isEmpty { suggestions.append(industry) }
        if !title.isEmpty { suggestions.append(title) }
        if !department.isEmpty { suggestions.append(department) }
        if !companyName.isEmpty { suggestions.append(companyName) }
        if !marketRegion.isEmpty { suggestions.append(marketRegion) }
        if !location.isEmpty { suggestions.append(location) }

        let normalized = suggestions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(Set(normalized))
    }

    private var shouldShowOriginalFields: Bool {
        guard let ocrLanguageCode else { return false }
        return ocrLanguageCode != settings.language.languageCode
    }

    private var shouldShowCompanyReview: Bool {
        guard documentType == .contact else { return false }
        let trimmed = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return existingCompany == nil
    }

    private var existingCompany: CompanyDocument? {
        let trimmed = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return appState.companies.first { $0.name.lowercased() == trimmed.lowercased() }
    }

    private func resolvedOriginalName() -> String? {
        let trimmed = originalName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        guard shouldShowOriginalFields else { return nil }
        let fallback = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallback.isEmpty ? nil : fallback
    }

    private func resolvedOriginalCompanyName() -> String? {
        let trimmed = originalCompanyName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        guard shouldShowOriginalFields else { return nil }
        let fallback = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallback.isEmpty ? nil : fallback
    }

    private func resolveCompanyForContact() -> CompanyDocument? {
        let trimmed = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let existingCompany {
            return existingCompany
        }

        let company = CompanyDocument(
            id: UUID(),
            name: trimmed,
            originalName: resolvedOriginalCompanyName(),
            summary: companySummary,
            serviceKeywords: [],
            website: companyWebsite,
            linkedinURL: nil,
            industry: companyIndustry.isEmpty ? nil : companyIndustry,
            companySize: nil,
            revenue: nil,
            foundedYear: nil,
            headquarters: nil,
            address: "",
            phone: companyPhone,
            location: companyLocation,
            serviceType: companyServiceType,
            targetAudience: .b2b,
            marketRegion: companyMarketRegion,
            notes: "",
            tags: [],
            relatedContactIDs: [],
            photoIDs: [],
            sourceLanguageCode: ocrLanguageCode,
            enrichedAt: nil,
            createdAt: Date()
        )
        appState.addCompany(company)
        return company
    }

    private func detectLanguageCode(from text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else { return nil }
        return language.rawValue
    }
}

#Preview {
    NavigationStack {
        CreateDocumentView(image: nil, ocrText: "Sample OCR text")
            .environmentObject(AppState())
            .environmentObject(AppSettings())
    }
}
