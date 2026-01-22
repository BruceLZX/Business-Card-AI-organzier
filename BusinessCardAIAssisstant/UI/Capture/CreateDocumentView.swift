import SwiftUI
import UIKit
import NaturalLanguage

struct CreateDocumentView: View {
    enum DocumentType: String, CaseIterable, Identifiable {
        case company
        case contact

        var id: String { rawValue }
    }

    enum CreationSource {
        case scan
        case manual
    }

    struct CreatedDocument: Identifiable, Hashable {
        enum Kind: Hashable {
            case company
            case contact
        }

        let id: UUID
        let kind: Kind
    }

    struct Prefill {
        let type: OCRParsedResult.ParsedType
        let contact: ContactPrefill?
        let company: CompanyPrefill?

        static func from(_ parsed: OCRParsedResult) -> Prefill {
            let contactPrefill = parsed.contact.map {
                ContactPrefill(
                    nameEN: $0.nameEN,
                    nameZH: $0.nameZH,
                    title: $0.title,
                    department: $0.department,
                    phone: $0.phone,
                    email: $0.email,
                    locationEN: $0.locationEN,
                    locationZH: $0.locationZH,
                    website: $0.website,
                    linkedin: $0.linkedin,
                    companyNameEN: $0.companyNameEN,
                    companyNameZH: $0.companyNameZH,
                    notes: $0.notes,
                    tags: $0.tags
                )
            }
            let companyPrefill = parsed.company.map {
                CompanyPrefill(
                    nameEN: $0.nameEN,
                    nameZH: $0.nameZH,
                    summary: $0.summary,
                    industry: $0.industry,
                    serviceType: $0.serviceType,
                    locationEN: $0.locationEN,
                    locationZH: $0.locationZH,
                    marketRegion: $0.marketRegion,
                    website: $0.website,
                    phone: $0.phone,
                    address: $0.address,
                    notes: $0.notes,
                    tags: $0.tags
                )
            }
            return Prefill(type: parsed.type, contact: contactPrefill, company: companyPrefill)
        }
    }

    struct ContactPrefill {
        let nameEN: String
        let nameZH: String
        let title: String
        let department: String?
        let phone: String
        let email: String
        let locationEN: String?
        let locationZH: String?
        let website: String?
        let linkedin: String?
        let companyNameEN: String
        let companyNameZH: String
        let notes: String?
        let tags: [String]
    }

    struct CompanyPrefill {
        let nameEN: String
        let nameZH: String
        let summary: String
        let industry: String?
        let serviceType: String?
        let locationEN: String?
        let locationZH: String?
        let marketRegion: String?
        let website: String?
        let phone: String?
        let address: String?
        let notes: String?
        let tags: [String]
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: AppSettings

    let images: [UIImage]
    let ocrText: String
    let initialType: DocumentType
    let source: CreationSource
    let prefill: Prefill?
    let onCreate: ((CreatedDocument) -> Void)?

    @State private var documentType: DocumentType
    @State private var contactName = ""
    @State private var contactOriginalName = ""
    @State private var contactTitle = ""
    @State private var contactDepartment = ""
    @State private var contactPhone = ""
    @State private var contactEmail = ""
    @State private var contactLocation = ""
    @State private var contactOriginalLocation = ""
    @State private var contactWebsite = ""
    @State private var contactLinkedin = ""
    @State private var contactNotes = ""
    @State private var contactTags: [String] = []

    @State private var companyName = ""
    @State private var companyOriginalName = ""
    @State private var companySummary = ""
    @State private var companyIndustry = ""
    @State private var companyServiceType = ""
    @State private var companyLocation = ""
    @State private var companyOriginalLocation = ""
    @State private var companyMarketRegion = ""
    @State private var companyTargetAudience = ""
    @State private var companyWebsite = ""
    @State private var companyLinkedin = ""
    @State private var companyPhone = ""
    @State private var companyAddress = ""
    @State private var companySize = ""
    @State private var companyRevenue = ""
    @State private var companyFoundedYear = ""
    @State private var companyHeadquarters = ""
    @State private var companyNotes = ""
    @State private var companyTags: [String] = []
    @State private var selectedCompanyID: UUID?
    @State private var selectedContactID: UUID?
    @State private var showCompanyPicker = false
    @State private var usingExistingCompany = false
    @State private var usingExistingContact = false
    @State private var companyMatches: [CompanyDocument] = []
    @State private var contactMatches: [ContactDocument] = []
    @State private var showCompanyMatchSheet = false
    @State private var showContactMatchSheet = false
    @State private var companyMatchResolved = false
    @State private var contactMatchResolved = false
    @State private var companyMatchConfirmed = false
    @State private var contactMatchConfirmed = false
    @State private var showCancelConfirm = false
    @State private var pendingCompanyMatchID: UUID?
    @State private var pendingContactMatchID: UUID?
    @State private var ocrLanguageCode: String?
    @State private var didApplyPrefill = false

    init(
        images: [UIImage],
        ocrText: String,
        initialType: DocumentType = .company,
        source: CreationSource = .scan,
        prefill: Prefill? = nil,
        onCreate: ((CreatedDocument) -> Void)? = nil
    ) {
        self.images = images
        self.ocrText = ocrText
        self.initialType = initialType
        self.source = source
        self.prefill = prefill
        self.onCreate = onCreate
        _documentType = State(initialValue: initialType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if allowDocumentTypeSwitch {
                        Picker(settings.text(.documentType), selection: $documentType) {
                            Text(settings.text(.company)).tag(DocumentType.company)
                            Text(settings.text(.contact)).tag(DocumentType.contact)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                if documentType == .company {
                    Section(settings.text(.company)) {
                        if showExistingCompanyInfo, let selectedCompany {
                            existingCompanyInfoView(selectedCompany)
                        }

                        HStack {
                            Button(settings.text(.selectCompany)) {
                                showCompanyPicker = true
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }

                        if !showExistingCompanyInfo {
                            companyFields(isBlue: false)
                        }
                    }
                    if showExistingCompanyInfo {
                        Section(settings.text(.newInfo)) {
                            companyFields(isBlue: true)
                        }
                    }
                } else {
                    Section(settings.text(.contact)) {
                        if showExistingContactInfo, let selectedContact {
                            existingContactInfoView(selectedContact)
                        }
                        if !showExistingContactInfo {
                            contactFields(isBlue: false)
                        }
                    }
                    if showExistingContactInfo {
                        Section(settings.text(.newInfo)) {
                            contactFields(isBlue: true)
                        }
                    }

                    if allowsCompanySelectionInContact {
                        Section(settings.text(.company)) {
                            if let selectedCompany {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(selectedCompany.name)
                                        .font(.headline)
                                    if let industry = selectedCompany.industry, !industry.isEmpty {
                                        Text(industry)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            } else {
                                Text(settings.text(.noCompanies))
                                    .foregroundStyle(.secondary)
                            }

                            Button(settings.text(.selectCompany)) {
                                showCompanyPicker = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Section(settings.text(.notes)) {
                    if documentType == .company {
                        TextField(settings.text(.notes), text: $companyNotes, axis: .vertical)
                    } else {
                        TextField(settings.text(.notes), text: $contactNotes, axis: .vertical)
                    }
                }

                Section(settings.text(.tags)) {
                    if documentType == .company {
                        TagPickerView(
                            availableTags: appState.tagPool,
                            selectedTags: $companyTags,
                            placeholder: settings.text(.tags),
                            addLabel: settings.text(.addButton),
                            selectLabel: settings.text(.selectTags),
                            titleLabel: settings.text(.tags),
                            doneLabel: settings.text(.done)
                        )
                    } else {
                        TagPickerView(
                            availableTags: appState.tagPool,
                            selectedTags: $contactTags,
                            placeholder: settings.text(.tags),
                            addLabel: settings.text(.addButton),
                            selectLabel: settings.text(.selectTags),
                            titleLabel: settings.text(.tags),
                            doneLabel: settings.text(.done)
                        )
                    }
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
                        showCancelConfirm = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(settings.text(.create)) {
                        attemptSave()
                    }
                    .disabled(!canCreate)
                }
            }
            .sheet(isPresented: $showCompanyMatchSheet) {
                companyMatchSheet
                    .onAppear { pendingCompanyMatchID = nil }
            }
            .sheet(isPresented: $showContactMatchSheet) {
                contactMatchSheet
                    .onAppear { pendingContactMatchID = nil }
            }
            .alert(settings.text(.discardCreateTitle), isPresented: $showCancelConfirm) {
                Button(settings.text(.cancel), role: .cancel) {}
                Button(settings.text(.discardCreateAction), role: .destructive) {
                    dismiss()
                }
            } message: {
                Text(settings.text(.discardCreateMessage))
            }
            .onAppear {
                if !didApplyPrefill {
                    applyPrefill()
                    didApplyPrefill = true
                }
                companyMatchResolved = false
                contactMatchResolved = false
                companyMatchConfirmed = false
                contactMatchConfirmed = false
                if documentType == .company {
                    if companyTags.isEmpty {
                        companyTags = suggestedTags()
                    }
                } else if contactTags.isEmpty {
                    contactTags = suggestedTags()
                }
                if ocrLanguageCode == nil, !ocrText.isEmpty {
                    ocrLanguageCode = detectLanguageCode(from: ocrText)
                }
            }
            .onChange(of: documentType) { _, _ in
                applyPrefillForCurrentType()
            }
            .sheet(isPresented: $showCompanyPicker) {
                NavigationStack {
                    List {
                        ForEach(appState.companies) { company in
                            Button {
                                selectedCompanyID = company.id
                                if documentType == .company {
                                    usingExistingCompany = true
                                    companyMatchResolved = true
                                    companyMatchConfirmed = true
                                } else {
                                    usingExistingCompany = false
                                }
                                showCompanyPicker = false
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(company.name)
                                    if let industry = company.industry, !industry.isEmpty {
                                        Text(industry)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle(settings.text(.companies))
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(settings.text(.done)) {
                                showCompanyPicker = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func attemptSave() {
        if needsCompanyMatch, !companyMatchResolved {
            let matches = findCompanyMatches()
            if !matches.isEmpty {
                companyMatches = matches
                showCompanyMatchSheet = true
                return
            }
            companyMatchResolved = true
        }

        if needsContactMatch, !contactMatchResolved {
            let matches = findContactMatches()
            if !matches.isEmpty {
                contactMatches = matches
                showContactMatchSheet = true
                return
            }
            contactMatchResolved = true
        }

        if let created = performCreate() {
            onCreate?(created)
        }
        dismiss()
    }

    private func performCreate() -> CreatedDocument? {
        switch prefillType {
        case .both:
            let companyID = resolveCompanyForCreate()
            let contactID = resolveContactForCreate(linkCompanyID: companyID)
            if let contactID {
                return CreatedDocument(id: contactID, kind: .contact)
            }
            if let companyID {
                return CreatedDocument(id: companyID, kind: .company)
            }
            return nil
        case .company:
            if let companyID = resolveCompanyForCreate() {
                return CreatedDocument(id: companyID, kind: .company)
            }
            return nil
        case .contact:
            if let contactID = resolveContactForCreate(linkCompanyID: selectedCompanyID) {
                return CreatedDocument(id: contactID, kind: .contact)
            }
            return nil
        }
    }

    private func saveCompany() -> UUID {
        let resolvedLocation = companyLocation.isEmpty ? companyOriginalLocation : companyLocation
        let company = CompanyDocument(
            id: UUID(),
            name: companyName,
            originalName: resolvedOriginalCompanyName(),
            summary: companySummary,
            serviceKeywords: companyTags,
            website: companyWebsite,
            linkedinURL: companyLinkedin.isEmpty ? nil : companyLinkedin,
            industry: companyIndustry.isEmpty ? nil : companyIndustry,
            companySize: companySize.isEmpty ? nil : companySize,
            revenue: companyRevenue.isEmpty ? nil : companyRevenue,
            foundedYear: companyFoundedYear.isEmpty ? nil : companyFoundedYear,
            headquarters: companyHeadquarters.isEmpty ? nil : companyHeadquarters,
            address: companyAddress,
            phone: companyPhone,
            location: resolvedLocation,
            originalLocation: companyOriginalLocation.isEmpty ? nil : companyOriginalLocation,
            serviceType: companyServiceType,
            targetAudience: companyTargetAudience,
            marketRegion: companyMarketRegion,
            notes: companyNotes,
            tags: companyTags,
            relatedContactIDs: [],
            photoIDs: [],
            sourceLanguageCode: ocrLanguageCode,
            enrichedAt: nil,
            createdAt: Date()
        )
        appState.addCompany(company)
        if !images.isEmpty {
            for image in images {
                _ = appState.addCompanyPhoto(companyID: company.id, image: image)
            }
        }
        triggerCompanyTagGeneration(companyID: company.id)
        return company.id
    }

    private func saveNewContact(linkCompanyID: UUID?) -> UUID? {
        let linkedCompany = linkCompanyID.flatMap { appState.company(for: $0) }
        let resolvedLocation = contactLocation.isEmpty ? contactOriginalLocation : contactLocation
        let contact = ContactDocument(
            id: UUID(),
            name: contactName,
            originalName: resolvedOriginalContactName(),
            title: contactTitle,
            department: contactDepartment.isEmpty ? nil : contactDepartment,
            phone: contactPhone,
            email: contactEmail,
            location: resolvedLocation.isEmpty ? nil : resolvedLocation,
            originalLocation: contactOriginalLocation.isEmpty ? nil : contactOriginalLocation,
            website: contactWebsite.isEmpty ? nil : contactWebsite,
            linkedinURL: contactLinkedin.isEmpty ? nil : contactLinkedin,
            notes: contactNotes,
            tags: contactTags,
            companyID: linkedCompany?.id,
            companyName: linkedCompany?.name ?? "",
            originalCompanyName: linkedCompany?.originalName,
            photoIDs: [],
            sourceLanguageCode: ocrLanguageCode,
            enrichedAt: nil,
            createdAt: Date()
        )
        appState.addContact(contact)
        if !images.isEmpty {
            for image in images {
                _ = appState.addContactPhoto(contactID: contact.id, image: image)
            }
        }
        if let linkedCompany {
            appState.linkContact(contact.id, to: linkedCompany.id)
        }
        triggerContactTagGeneration(contactID: contact.id)
        return contact.id
    }

    private func suggestedTags() -> [String] {
        var suggestions: [String] = []
        switch documentType {
        case .company:
            if !companyServiceType.isEmpty { suggestions.append(companyServiceType) }
            if !companyIndustry.isEmpty { suggestions.append(companyIndustry) }
            if !companyMarketRegion.isEmpty { suggestions.append(companyMarketRegion) }
            if !companyLocation.isEmpty { suggestions.append(companyLocation) }
        case .contact:
            if !contactTitle.isEmpty { suggestions.append(contactTitle) }
            if !contactDepartment.isEmpty { suggestions.append(contactDepartment) }
            if !contactLocation.isEmpty { suggestions.append(contactLocation) }
        }

        let normalized = suggestions
            .compactMap { suggestion -> String? in
                let trimmed = suggestion.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return nil }
                let firstToken = trimmed.split(whereSeparator: { $0.isWhitespace }).first
                return firstToken.map(String.init)
            }
        return Array(Set(normalized))
    }

    private func triggerCompanyTagGeneration(companyID: UUID) {
        guard companyTags.isEmpty else { return }
        let context = companyTagContext()
        appState.generateTagsForCreate(
            type: .company,
            documentID: companyID,
            name: companyName,
            summary: companySummary,
            notes: companyNotes,
            tags: companyTags,
            photos: images,
            context: context,
            tagLanguage: settings.language
        )
    }

    private func triggerContactTagGeneration(contactID: UUID) {
        guard contactTags.isEmpty else { return }
        let context = contactTagContext()
        appState.generateTagsForCreate(
            type: .contact,
            documentID: contactID,
            name: contactName,
            summary: contactTitle,
            notes: contactNotes,
            tags: contactTags,
            photos: images,
            context: context,
            tagLanguage: settings.language
        )
    }

    private func companyTagContext() -> String {
        [
            companySummary,
            companyIndustry,
            companyServiceType,
            companyTargetAudience,
            companyMarketRegion,
            companyLocation,
            companyWebsite,
            companyNotes
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " | ")
    }

    private func contactTagContext() -> String {
        [
            contactTitle,
            contactDepartment,
            selectedCompany?.name ?? "",
            contactLocation,
            contactWebsite,
            contactNotes
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " | ")
    }

    private func resolveCompanyForCreate() -> UUID? {
        guard prefillType != .contact else { return nil }

        if let selectedCompany, usingExistingCompany {
            updateExistingCompany(selectedCompany)
            return selectedCompany.id
        }

        let trimmedName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        return saveCompany()
    }

    private func resolveContactForCreate(linkCompanyID: UUID?) -> UUID? {
        guard prefillType != .company else { return nil }

        if let selectedContact, usingExistingContact {
            updateExistingContact(selectedContact, linkCompanyID: linkCompanyID)
            return selectedContact.id
        }

        let trimmedName = contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        return saveNewContact(linkCompanyID: linkCompanyID)
    }

    private func updateExistingCompany(_ company: CompanyDocument) {
        var updated = company
        if !companyName.isEmpty { updated.name = companyName }
        if let original = resolvedOriginalCompanyName(), !original.isEmpty { updated.originalName = original }
        if !companySummary.isEmpty { updated.summary = companySummary }
        if !companyIndustry.isEmpty { updated.industry = companyIndustry }
        if !companyServiceType.isEmpty { updated.serviceType = companyServiceType }
        let resolvedLocation = companyLocation.isEmpty ? companyOriginalLocation : companyLocation
        if !resolvedLocation.isEmpty { updated.location = resolvedLocation }
        if !companyOriginalLocation.isEmpty { updated.originalLocation = companyOriginalLocation }
        if !companyMarketRegion.isEmpty { updated.marketRegion = companyMarketRegion }
        if !companyTargetAudience.isEmpty { updated.targetAudience = companyTargetAudience }
        if !companyWebsite.isEmpty { updated.website = companyWebsite }
        if !companyLinkedin.isEmpty { updated.linkedinURL = companyLinkedin }
        if !companyPhone.isEmpty { updated.phone = companyPhone }
        if !companyAddress.isEmpty { updated.address = companyAddress }
        if !companySize.isEmpty { updated.companySize = companySize }
        if !companyRevenue.isEmpty { updated.revenue = companyRevenue }
        if !companyFoundedYear.isEmpty { updated.foundedYear = companyFoundedYear }
        if !companyHeadquarters.isEmpty { updated.headquarters = companyHeadquarters }
        if !companyTags.isEmpty {
            updated.tags = Array(Set(updated.tags + companyTags))
        }
        appState.updateCompany(updated)
    }

    private func updateExistingContact(_ contact: ContactDocument, linkCompanyID: UUID?) {
        var updated = contact
        if !contactName.isEmpty { updated.name = contactName }
        if let original = resolvedOriginalContactName(), !original.isEmpty { updated.originalName = original }
        if !contactTitle.isEmpty { updated.title = contactTitle }
        if let department = contactDepartment.isEmpty ? nil : contactDepartment { updated.department = department }
        if !contactPhone.isEmpty { updated.phone = contactPhone }
        if !contactEmail.isEmpty { updated.email = contactEmail }
        let resolvedLocation = contactLocation.isEmpty ? contactOriginalLocation : contactLocation
        if !resolvedLocation.isEmpty { updated.location = resolvedLocation }
        if !contactOriginalLocation.isEmpty { updated.originalLocation = contactOriginalLocation }
        if let website = contactWebsite.isEmpty ? nil : contactWebsite { updated.website = website }
        if let linkedin = contactLinkedin.isEmpty ? nil : contactLinkedin { updated.linkedinURL = linkedin }
        if !contactNotes.isEmpty {
            updated.notes = updated.notes.isEmpty ? contactNotes : "\(updated.notes)\n\n\(contactNotes)"
        }
        if !contactTags.isEmpty {
            updated.tags = Array(Set(updated.tags + contactTags))
        }
        if let companyID = linkCompanyID, let company = appState.company(for: companyID) {
            if updated.companyID == nil {
                updated.companyID = company.id
                updated.companyName = company.name
                updated.originalCompanyName = company.originalName
            } else if updated.companyID != company.id,
                      !updated.additionalCompanyIDs.contains(company.id) {
                updated.additionalCompanyIDs.append(company.id)
                updated.additionalCompanyNames.append(company.name)
            }
            appState.linkContact(updated.id, to: company.id)
        }
        appState.updateContact(updated)

        if !images.isEmpty {
            for image in images {
                _ = appState.addContactPhoto(contactID: updated.id, image: image)
            }
        }
    }

    private func findCompanyMatches() -> [CompanyDocument] {
        let inputVariants = companyNameVariants(companyName)
        guard !inputVariants.isEmpty else { return [] }

        let inputLocation = normalized("\(companyLocation) \(companyOriginalLocation) \(companyAddress)")
        let matches = appState.companies.compactMap { company -> (CompanyDocument, Double)? in
            let companyVariants = companyNameVariants(company.name) + companyNameVariants(company.originalName ?? "")
            let nameScore = bestNameScore(inputVariants: inputVariants, companyVariants: companyVariants)
            let companyLocation = normalized("\(company.location) \(company.originalLocation ?? "") \(company.address) \(company.headquarters ?? "")")
            let locationScore = inputLocation.isEmpty || companyLocation.isEmpty ? 0 : tokenJaccard(inputLocation, companyLocation)
            let score = inputLocation.isEmpty ? nameScore : (nameScore * 0.8 + locationScore * 0.2)
            return score >= 0.85 ? (company, score) : nil
        }
        return matches.sorted { $0.1 > $1.1 }.map { $0.0 }
    }

    private func findContactMatches() -> [ContactDocument] {
        let nameCandidate = normalized(contactName)
        let phoneCandidate = contactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailCandidate = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !nameCandidate.isEmpty || !phoneCandidate.isEmpty || !emailCandidate.isEmpty else { return [] }

        let matches = appState.contacts.compactMap { contact -> (ContactDocument, Double)? in
            let nameScore = nameCandidate.isEmpty ? 0 : jaroWinkler(normalized(contact.name), nameCandidate)
            let phoneMatch = !phoneCandidate.isEmpty && contact.phone == phoneCandidate
            let emailMatch = !emailCandidate.isEmpty && contact.email.lowercased() == emailCandidate
            let score = max(nameScore, phoneMatch ? 1.0 : 0, emailMatch ? 1.0 : 0)
            if (score >= 0.9 && (phoneMatch || emailMatch || nameScore >= 0.95)) {
                return (contact, score)
            }
            return nil
        }
        return matches.sorted { $0.1 > $1.1 }.map { $0.0 }
    }

    private func normalized(_ text: String) -> String {
        let lowered = text.lowercased()
        let filtered = lowered.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) || CharacterSet.whitespacesAndNewlines.contains(scalar)
        }
        return String(String.UnicodeScalarView(filtered))
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func companyNameVariants(_ text: String) -> [String] {
        let base = normalized(text)
        guard !base.isEmpty else { return [] }
        let stripped = stripCompanySuffix(base)
        if stripped.isEmpty || stripped == base {
            return [base]
        }
        return [base, stripped]
    }

    private func stripCompanySuffix(_ name: String) -> String {
        var result = name
        let suffixPatterns = [
            "\\binc\\b",
            "\\bincorporated\\b",
            "\\bltd\\b",
            "\\blimited\\b",
            "\\bllc\\b",
            "\\bplc\\b",
            "\\bco\\b",
            "\\bcorp\\b",
            "\\bcorporation\\b",
            "\\bcompany\\b",
            "\\bgroup\\b",
            "\\bholdings\\b"
        ]
        for pattern in suffixPatterns {
            result = result.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        result = result.replacingOccurrences(of: "(有限公司|有限責任公司|有限责任公司|股份有限公司|集团|公司)$", with: "", options: .regularExpression)
        return result
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func bestNameScore(inputVariants: [String], companyVariants: [String]) -> Double {
        var best = 0.0
        for input in inputVariants {
            for candidate in companyVariants {
                guard !candidate.isEmpty else { continue }
                let score = max(jaroWinkler(candidate, input), tokenJaccard(candidate, input))
                if score > best {
                    best = score
                }
            }
        }
        return best
    }

    private func tokenJaccard(_ lhs: String, _ rhs: String) -> Double {
        let leftTokens = Set(lhs.split(separator: " ").map(String.init))
        let rightTokens = Set(rhs.split(separator: " ").map(String.init))
        guard !leftTokens.isEmpty, !rightTokens.isEmpty else { return 0 }
        let intersection = leftTokens.intersection(rightTokens).count
        let union = leftTokens.union(rightTokens).count
        return union == 0 ? 0 : Double(intersection) / Double(union)
    }

    private func jaroWinkler(_ lhs: String, _ rhs: String) -> Double {
        if lhs == rhs { return 1 }
        let left = Array(lhs)
        let right = Array(rhs)
        let leftCount = left.count
        let rightCount = right.count
        if leftCount == 0 || rightCount == 0 { return 0 }

        let matchDistance = max(leftCount, rightCount) / 2 - 1
        var leftMatches = Array(repeating: false, count: leftCount)
        var rightMatches = Array(repeating: false, count: rightCount)

        var matches = 0
        for i in 0..<leftCount {
            let start = max(0, i - matchDistance)
            let end = min(i + matchDistance + 1, rightCount)
            if start >= end { continue }
            for j in start..<end where !rightMatches[j] {
                if left[i] == right[j] {
                    leftMatches[i] = true
                    rightMatches[j] = true
                    matches += 1
                    break
                }
            }
        }

        if matches == 0 { return 0 }

        var t = 0
        var k = 0
        for i in 0..<leftCount where leftMatches[i] {
            while k < rightCount && !rightMatches[k] {
                k += 1
            }
            if k < rightCount, left[i] != right[k] {
                t += 1
            }
            k += 1
        }

        let transpositions = Double(t) / 2.0
        let m = Double(matches)
        let jaro = (m / Double(leftCount) + m / Double(rightCount) + (m - transpositions) / m) / 3.0

        let prefixLimit = 4
        var prefix = 0
        for i in 0..<min(prefixLimit, min(leftCount, rightCount)) {
            if left[i] == right[i] {
                prefix += 1
            } else {
                break
            }
        }
        let scalingFactor = 0.1
        return jaro + Double(prefix) * scalingFactor * (1 - jaro)
    }

    private func resolvedOriginalContactName() -> String? {
        let trimmed = contactOriginalName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func resolvedOriginalCompanyName() -> String? {
        let trimmed = companyOriginalName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func detectLanguageCode(from text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else { return nil }
        return language.rawValue
    }

    private var allowDocumentTypeSwitch: Bool {
        return prefillType == .both
    }

    private var selectedCompany: CompanyDocument? {
        guard let selectedCompanyID else { return nil }
        return appState.company(for: selectedCompanyID)
    }

    private var selectedContact: ContactDocument? {
        guard let selectedContactID else { return nil }
        return appState.contact(for: selectedContactID)
    }

    private var prefillType: OCRParsedResult.ParsedType {
        prefill?.type ?? (documentType == .company ? .company : .contact)
    }

    private var needsCompanyMatch: Bool {
        guard source == .scan else { return false }
        guard selectedCompanyID == nil else { return false }
        return prefillType == .company || prefillType == .both
    }

    private var needsContactMatch: Bool {
        guard source == .scan else { return false }
        guard selectedContactID == nil else { return false }
        return prefillType == .contact || prefillType == .both
    }

    private var allowsCompanySelectionInContact: Bool {
        prefillType == .contact
    }

    private var showExistingCompanyInfo: Bool {
        companyMatchConfirmed && selectedCompany != nil
    }

    private var showExistingContactInfo: Bool {
        contactMatchConfirmed && selectedContact != nil
    }

    @ViewBuilder
    private func companyFields(isBlue: Bool) -> some View {
        styledTextField(settings.text(.name), text: $companyName, isBlue: isBlue)
        styledTextField(settings.text(.originalCompanyName), text: $companyOriginalName, isBlue: isBlue)
        styledTextField(settings.text(.summary), text: $companySummary, isBlue: isBlue, axis: .vertical)
        styledTextField(settings.text(.industry), text: $companyIndustry, isBlue: isBlue)
        styledTextField(settings.text(.companySize), text: $companySize, isBlue: isBlue)
        styledTextField(settings.text(.revenue), text: $companyRevenue, isBlue: isBlue)
        styledTextField(settings.text(.foundedYear), text: $companyFoundedYear, isBlue: isBlue)
        styledTextField(settings.text(.headquarters), text: $companyHeadquarters, isBlue: isBlue)
        styledTextField(settings.text(.serviceTypeLabel), text: $companyServiceType, isBlue: isBlue)
        styledTextField(settings.text(.targetAudience), text: $companyTargetAudience, isBlue: isBlue)
        styledTextField(settings.text(.location), text: companyLocationBinding, isBlue: isBlue)
        styledTextField(settings.text(.marketRegionLabel), text: $companyMarketRegion, isBlue: isBlue)
        styledTextField(settings.text(.website), text: $companyWebsite, isBlue: isBlue)
        styledTextField(settings.text(.linkedin), text: $companyLinkedin, isBlue: isBlue)
        styledTextField(settings.text(.phone), text: $companyPhone, isBlue: isBlue)
        styledTextField(settings.text(.address), text: $companyAddress, isBlue: isBlue)
    }

    @ViewBuilder
    private func contactFields(isBlue: Bool) -> some View {
        styledTextField(settings.text(.name), text: $contactName, isBlue: isBlue)
        styledTextField(settings.text(.originalName), text: $contactOriginalName, isBlue: isBlue)
        styledTextField(settings.text(.title), text: $contactTitle, isBlue: isBlue)
        styledTextField(settings.text(.department), text: $contactDepartment, isBlue: isBlue)
        styledTextField(settings.text(.location), text: contactLocationBinding, isBlue: isBlue)
        styledTextField(settings.text(.phone), text: $contactPhone, isBlue: isBlue)
        styledTextField(settings.text(.email), text: $contactEmail, isBlue: isBlue)
        styledTextField(settings.text(.personalSite), text: $contactWebsite, isBlue: isBlue)
        styledTextField(settings.text(.linkedin), text: $contactLinkedin, isBlue: isBlue)
    }

    private func styledTextField(_ title: String, text: Binding<String>, isBlue: Bool, axis: Axis = .horizontal) -> some View {
        TextField(title, text: text, axis: axis)
            .foregroundStyle(isBlue ? .blue : .primary)
            .tint(isBlue ? .blue : nil)
    }

    private var contactLocationBinding: Binding<String> {
        Binding(
            get: {
                settings.language == .chinese ? contactOriginalLocation : contactLocation
            },
            set: { newValue in
                if settings.language == .chinese {
                    contactOriginalLocation = newValue
                } else {
                    contactLocation = newValue
                }
            }
        )
    }

    private var companyLocationBinding: Binding<String> {
        Binding(
            get: {
                settings.language == .chinese ? companyOriginalLocation : companyLocation
            },
            set: { newValue in
                if settings.language == .chinese {
                    companyOriginalLocation = newValue
                } else {
                    companyLocation = newValue
                }
            }
        )
    }

    private func localizedDisplay(primary: String, fallback: String?) -> String {
        let preferred: String
        switch settings.language {
        case .chinese:
            preferred = fallback ?? primary
        case .english:
            preferred = primary.isEmpty ? (fallback ?? "") : primary
        }
        return preferred.isEmpty ? (fallback ?? primary) : preferred
    }

    private func existingCompanyInfoView(_ company: CompanyDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(settings.text(.existingCompany))
                .font(.caption)
            infoRow(settings.text(.name), company.name)
            if let original = company.originalName, !original.isEmpty {
                infoRow(settings.text(.originalCompanyName), original)
            }
            if !company.summary.isEmpty { infoRow(settings.text(.summary), company.summary) }
            if let industry = company.industry, !industry.isEmpty { infoRow(settings.text(.industry), industry) }
            if let size = company.companySize, !size.isEmpty { infoRow(settings.text(.companySize), size) }
            if let revenue = company.revenue, !revenue.isEmpty { infoRow(settings.text(.revenue), revenue) }
            if let founded = company.foundedYear, !founded.isEmpty { infoRow(settings.text(.foundedYear), founded) }
            if let hq = company.headquarters, !hq.isEmpty { infoRow(settings.text(.headquarters), hq) }
            if !company.serviceType.isEmpty { infoRow(settings.text(.serviceTypeLabel), company.serviceType) }
            let companyLocation = localizedDisplay(primary: company.location, fallback: company.originalLocation)
            if !companyLocation.isEmpty { infoRow(settings.text(.location), companyLocation) }
            if !company.marketRegion.isEmpty { infoRow(settings.text(.marketRegionLabel), company.marketRegion) }
            if !company.website.isEmpty { infoRow(settings.text(.website), company.website) }
            if let linkedin = company.linkedinURL, !linkedin.isEmpty { infoRow(settings.text(.linkedin), linkedin) }
            if !company.phone.isEmpty { infoRow(settings.text(.phone), company.phone) }
            if !company.address.isEmpty { infoRow(settings.text(.address), company.address) }
            if !company.notes.isEmpty { infoRow(settings.text(.notes), company.notes) }
            if !company.tags.isEmpty { infoRow(settings.text(.tags), company.tags.joined(separator: ", ")) }
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
    }

    private func existingContactInfoView(_ contact: ContactDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(settings.text(.existingContact))
                .font(.caption)
            infoRow(settings.text(.name), contact.name)
            if let original = contact.originalName, !original.isEmpty {
                infoRow(settings.text(.originalName), original)
            }
            if !contact.title.isEmpty { infoRow(settings.text(.title), contact.title) }
            if let department = contact.department, !department.isEmpty {
                infoRow(settings.text(.department), department)
            }
            let contactLocation = localizedDisplay(primary: contact.location ?? "", fallback: contact.originalLocation)
            if !contactLocation.isEmpty {
                infoRow(settings.text(.location), contactLocation)
            }
            if !contact.phone.isEmpty { infoRow(settings.text(.phone), contact.phone) }
            if !contact.email.isEmpty { infoRow(settings.text(.email), contact.email) }
            if let website = contact.website, !website.isEmpty { infoRow(settings.text(.personalSite), website) }
            if let linkedin = contact.linkedinURL, !linkedin.isEmpty { infoRow(settings.text(.linkedin), linkedin) }
            if !contact.notes.isEmpty { infoRow(settings.text(.notes), contact.notes) }
            if !contact.tags.isEmpty { infoRow(settings.text(.tags), contact.tags.joined(separator: ", ")) }
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        Text("\(label): \(value)")
    }

    private var companyMatchSheet: some View {
        VStack(spacing: 12) {
            Text(settings.text(.possibleCompanyMatchTitle))
                .font(.headline)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(companyMatches) { company in
                        Button {
                            pendingCompanyMatchID = company.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(company.name)
                                    if let industry = company.industry, !industry.isEmpty {
                                        Text(industry)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if pendingCompanyMatchID == company.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
            HStack {
                Button(settings.text(.cancel)) {
                    showCompanyMatchSheet = false
                }
                Spacer()
                Button(settings.text(.keepNewCompany)) {
                    companyMatchResolved = true
                    companyMatchConfirmed = false
                    usingExistingCompany = false
                    selectedCompanyID = nil
                    showCompanyMatchSheet = false
                }
                Button(settings.text(.confirm)) {
                    guard let pendingCompanyMatchID else { return }
                    selectedCompanyID = pendingCompanyMatchID
                    usingExistingCompany = true
                    companyMatchResolved = true
                    companyMatchConfirmed = true
                    showCompanyMatchSheet = false
                }
                .disabled(pendingCompanyMatchID == nil)
            }
        }
        .padding()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var contactMatchSheet: some View {
        VStack(spacing: 12) {
            Text(settings.text(.duplicateFoundTitle))
                .font(.headline)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(contactMatches) { contact in
                        Button {
                            pendingContactMatchID = contact.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contact.name)
                                    if !contact.email.isEmpty {
                                        Text(contact.email)
                                            .foregroundStyle(.secondary)
                                    } else if !contact.phone.isEmpty {
                                        Text(contact.phone)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if pendingContactMatchID == contact.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
            HStack {
                Button(settings.text(.cancel)) {
                    showContactMatchSheet = false
                }
                Spacer()
                Button(settings.text(.createNew)) {
                    contactMatchResolved = true
                    contactMatchConfirmed = false
                    usingExistingContact = false
                    selectedContactID = nil
                    showContactMatchSheet = false
                }
                Button(settings.text(.confirm)) {
                    guard let pendingContactMatchID else { return }
                    selectedContactID = pendingContactMatchID
                    usingExistingContact = true
                    contactMatchResolved = true
                    contactMatchConfirmed = true
                    showContactMatchSheet = false
                }
                .disabled(pendingContactMatchID == nil)
            }
        }
        .padding()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }


    private func applyPrefill() {
        guard let prefill else { return }
        if let contact = prefill.contact {
            applyContactPrefill(contact)
        }
        if let company = prefill.company {
            applyCompanyPrefill(company)
        } else if let contact = prefill.contact {
            let candidateEN = contact.companyNameEN.trimmingCharacters(in: .whitespacesAndNewlines)
            let candidateZH = contact.companyNameZH.trimmingCharacters(in: .whitespacesAndNewlines)
            applyNamePrefill(
                primary: &companyName,
                secondary: &companyOriginalName,
                nameEN: candidateEN,
                nameZH: candidateZH
            )
        }
        normalizeContactCompanyCollision()
    }

    private func applyPrefillForCurrentType() {
        applyPrefill()
    }

    private func applyContactPrefill(_ contact: ContactPrefill) {
        applyNamePrefill(
            primary: &contactName,
            secondary: &contactOriginalName,
            nameEN: contact.nameEN,
            nameZH: contact.nameZH
        )
        setIfEmpty(&contactTitle, contact.title)
        setIfEmpty(&contactDepartment, contact.department)
        setIfEmpty(&contactPhone, contact.phone)
        setIfEmpty(&contactEmail, contact.email)
        setIfEmpty(&contactLocation, contact.locationEN)
        setIfEmpty(&contactOriginalLocation, contact.locationZH)
        setIfEmpty(&contactWebsite, contact.website)
        setIfEmpty(&contactLinkedin, contact.linkedin)
        setIfEmpty(&contactNotes, contact.notes)
        if contactTags.isEmpty, !contact.tags.isEmpty {
            contactTags = normalizeAutoTags(contact.tags)
        }
    }

    private func applyCompanyPrefill(_ company: CompanyPrefill) {
        applyNamePrefill(
            primary: &companyName,
            secondary: &companyOriginalName,
            nameEN: company.nameEN,
            nameZH: company.nameZH
        )
        setIfEmpty(&companySummary, company.summary)
        setIfEmpty(&companyIndustry, company.industry)
        setIfEmpty(&companyServiceType, company.serviceType)
        setIfEmpty(&companyLocation, company.locationEN)
        setIfEmpty(&companyOriginalLocation, company.locationZH)
        setIfEmpty(&companyMarketRegion, company.marketRegion)
        setIfEmpty(&companyWebsite, company.website)
        setIfEmpty(&companyPhone, company.phone)
        setIfEmpty(&companyAddress, company.address)
        setIfEmpty(&companyNotes, company.notes)
        if companyTags.isEmpty, !company.tags.isEmpty {
            companyTags = normalizeAutoTags(company.tags)
        }
    }

    private func normalizeContactCompanyCollision() {
        guard companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let candidate = contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return }
        if looksLikeCompany(candidate) {
            companyName = candidate
            contactName = ""
        }
    }

    private func looksLikeCompany(_ value: String) -> Bool {
        let lowered = value.lowercased()
        let companyHints = ["inc", "llc", "ltd", "co.", "corp", "gmbh", "plc", "limited"]
        if companyHints.contains(where: { lowered.contains($0) }) { return true }
        if value.contains("公司") || value.contains("有限公司") || value.contains("集团") { return true }
        return false
    }

    private func setIfEmpty(_ target: inout String, _ value: String?) {
        guard target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        target = trimmed
    }

    private func applyNamePrefill(
        primary: inout String,
        secondary: inout String?,
        nameEN: String,
        nameZH: String
    ) {
        let en = nameEN.trimmingCharacters(in: .whitespacesAndNewlines)
        let zh = nameZH.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !en.isEmpty || !zh.isEmpty else { return }

        let primaryTrimmed = primary.trimmingCharacters(in: .whitespacesAndNewlines)
        let secondaryTrimmed = (secondary ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if !primaryTrimmed.isEmpty {
            if secondaryTrimmed.isEmpty {
                if !en.isEmpty, primaryTrimmed != en, primaryTrimmed != zh, containsChinese(primaryTrimmed) {
                    secondary = en
                } else if !zh.isEmpty, primaryTrimmed != en, primaryTrimmed != zh {
                    secondary = zh
                }
            }
            return
        }

        if !en.isEmpty, !zh.isEmpty {
            // When both exist and size is unknown, default Chinese as primary.
            primary = zh
            secondary = en
            return
        }

        if !zh.isEmpty {
            primary = zh
            return
        }
        if !en.isEmpty {
            primary = en
        }
    }

    private func containsChinese(_ value: String) -> Bool {
        value.range(of: "[\\p{Han}]", options: .regularExpression) != nil
    }


    private func normalizeAutoTags(_ input: [String]) -> [String] {
        let normalized = input.compactMap { tag -> String? in
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let firstToken = trimmed.split(whereSeparator: { $0.isWhitespace }).first
            return firstToken.map(String.init)
        }
        return Array(Set(normalized))
    }

    private var canCreate: Bool {
        switch prefillType {
        case .both:
            let hasContact = !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedContactID != nil
            let hasCompany = !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedCompanyID != nil
            return hasContact && hasCompany
        case .contact:
            return !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedContactID != nil
        case .company:
            return !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedCompanyID != nil
        }
    }
}

#Preview {
    NavigationStack {
        CreateDocumentView(images: [], ocrText: "Sample OCR text")
            .environmentObject(AppState())
            .environmentObject(AppSettings())
    }
}
