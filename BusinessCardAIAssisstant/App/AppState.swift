import Foundation
import UIKit
import SwiftUI

enum EnrichmentStage: Equatable {
    case analyzing
    case searching(current: Int, total: Int)
    case merging
    case complete
}

struct EnrichmentProgressState: Equatable {
    let stage: EnrichmentStage
    let progress: Double
    let totalStages: Int
}

@MainActor
final class AppState: ObservableObject {
    @Published var companies: [CompanyDocument]
    @Published var contacts: [ContactDocument]
    @Published var recentCaptures: [UIImage] = []
    @Published var tagPool: [String] = []
    @Published var enrichmentProgress: EnrichmentProgressState?

    private var progressTask: Task<Void, Never>?

    var isEnrichingGlobal: Bool {
        enrichmentProgress != nil
    }

    var recentDocuments: [RecentDocument] {
        let companyItems = companies.map { company in
            RecentDocument(
                id: company.id,
                kind: .company,
                title: company.name,
                subtitle: company.industry?.isEmpty == false ? company.industry! : company.serviceType,
                date: company.createdAt ?? .distantPast
            )
        }

        let contactItems = contacts.map { contact in
            let primaryName = contact.companyName.isEmpty ? contact.additionalCompanyNames.first ?? "" : contact.companyName
            let subtitle = primaryName.isEmpty ? contact.title : "\(contact.title) · \(primaryName)"
            return RecentDocument(
                id: contact.id,
                kind: .contact,
                title: contact.name,
                subtitle: subtitle,
                date: contact.createdAt ?? .distantPast
            )
        }

        return (companyItems + contactItems)
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { $0 }
    }

    private let store: LocalStore
    private let enrichmentService = EnrichmentService()

    init(store: LocalStore = LocalStore()) {
        self.store = store
        let loadedCompanies = store.loadCompanies()
        let loadedContacts = store.loadContacts()

        let (cleanCompanies, cleanContacts) = Self.purgeSampleData(
            store: store,
            companies: loadedCompanies,
            contacts: loadedContacts
        )
        companies = cleanCompanies
        contacts = cleanContacts
        registerTags(cleanCompanies.flatMap(\.tags) + cleanContacts.flatMap(\.tags))
    }

    func company(for id: UUID) -> CompanyDocument? {
        companies.first { $0.id == id }
    }

    func contact(for id: UUID) -> ContactDocument? {
        contacts.first { $0.id == id }
    }

    func updateCompany(_ company: CompanyDocument) {
        guard let index = companies.firstIndex(where: { $0.id == company.id }) else { return }
        companies[index] = company
        store.saveCompany(company)
        registerTags(company.tags)
    }

    func updateContact(_ contact: ContactDocument) {
        guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else { return }
        contacts[index] = contact
        store.saveContact(contact)
        registerTags(contact.tags)
    }

    func addCompany(_ company: CompanyDocument) {
        companies.append(company)
        store.saveCompany(company)
        registerTags(company.tags)
    }

    func addContact(_ contact: ContactDocument) {
        contacts.append(contact)
        store.saveContact(contact)
        registerTags(contact.tags)
    }

    func deleteCompany(_ companyID: UUID) {
        let removedCompanyName = companies.first(where: { $0.id == companyID })?.name
        companies.removeAll { $0.id == companyID }
        store.deleteCompany(companyID)

        var updatedContacts: [ContactDocument] = []
        for contact in contacts {
            let needsUpdate = contact.companyID == companyID || contact.additionalCompanyIDs.contains(companyID)
            guard needsUpdate else { continue }
            var updated = contact
            if updated.companyID == companyID {
                if let replacementID = updated.additionalCompanyIDs.first {
                    updated.companyID = replacementID
                    updated.additionalCompanyIDs.removeAll { $0 == replacementID }
                    if let replacementName = updated.additionalCompanyNames.first {
                        updated.companyName = replacementName
                        updated.additionalCompanyNames.removeAll { $0 == replacementName }
                    } else if let company = company(for: replacementID) {
                        updated.companyName = company.name
                    } else {
                        updated.companyName = ""
                    }
                    if let company = company(for: updated.companyID ?? replacementID) {
                        updated.originalCompanyName = company.originalName
                    } else {
                        updated.originalCompanyName = nil
                    }
                } else {
                    updated.companyID = nil
                    updated.companyName = ""
                    updated.originalCompanyName = nil
                }
            }
            updated.additionalCompanyIDs.removeAll { $0 == companyID }
            if let removedCompanyName {
                updated.additionalCompanyNames.removeAll { $0 == removedCompanyName }
            }
            updatedContacts.append(updated)
            store.saveContact(updated)
        }
        if !updatedContacts.isEmpty {
            for updated in updatedContacts {
                if let index = contacts.firstIndex(where: { $0.id == updated.id }) {
                    contacts[index] = updated
                }
            }
        }

        refreshTagPool()
    }

    func deleteContact(_ contactID: UUID) {
        contacts.removeAll { $0.id == contactID }
        store.deleteContact(contactID)

        for index in companies.indices {
            if companies[index].relatedContactIDs.contains(contactID) {
                companies[index].relatedContactIDs.removeAll { $0 == contactID }
                store.saveCompany(companies[index])
            }
        }

        refreshTagPool()
    }

    func registerTags(_ tags: [String]) {
        let normalized = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let merged = Array(Set(tagPool + normalized)).sorted()
        tagPool = merged
    }

    private func refreshTagPool() {
        tagPool = Array(Set(companies.flatMap(\.tags) + contacts.flatMap(\.tags))).sorted()
    }

    func findDuplicateContact(name: String, phone: String, email: String) -> ContactDocument? {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return contacts.first { contact in
            if !normalizedEmail.isEmpty, contact.email.lowercased() == normalizedEmail {
                return true
            }
            if !normalizedPhone.isEmpty, contact.phone.lowercased() == normalizedPhone {
                return true
            }
            if !normalizedName.isEmpty, contact.name.lowercased() == normalizedName {
                return true
            }
            return false
        }
    }

    func ensureCompany(named name: String) -> CompanyDocument? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let existing = companies.first(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            return existing
        }

        let company = CompanyDocument(
            id: UUID(),
            name: trimmed,
            originalName: nil,
            summary: "",
            serviceKeywords: [],
            website: "",
            linkedinURL: nil,
            industry: nil,
            companySize: nil,
            revenue: nil,
            foundedYear: nil,
            headquarters: nil,
            address: "",
            phone: "",
            location: "",
            originalLocation: nil,
            serviceType: "",
            targetAudience: .b2b,
            marketRegion: "",
            notes: "",
            tags: [],
            relatedContactIDs: [],
            photoIDs: [],
            sourceLanguageCode: nil,
            enrichedAt: nil,
            createdAt: Date()
        )
        addCompany(company)
        return company
    }

    func linkContact(_ contactID: UUID, to companyID: UUID) {
        guard let index = companies.firstIndex(where: { $0.id == companyID }) else { return }
        if !companies[index].relatedContactIDs.contains(contactID) {
            companies[index].relatedContactIDs.insert(contactID, at: 0)
            store.saveCompany(companies[index])
        }
        guard let contactIndex = contacts.firstIndex(where: { $0.id == contactID }) else { return }
        let companyNameValue = companies[index].name
        var updated = contacts[contactIndex]
        if updated.companyID == nil {
            updated.companyID = companyID
            updated.companyName = companyNameValue
            updated.originalCompanyName = companies[index].originalName
        } else if updated.companyID != companyID,
                  !updated.additionalCompanyIDs.contains(companyID) {
            updated.additionalCompanyIDs.append(companyID)
            updated.additionalCompanyNames.append(companyNameValue)
        }
        contacts[contactIndex] = updated
        store.saveContact(updated)
    }

    func unlinkContact(_ contactID: UUID, from companyID: UUID) {
        if let companyIndex = companies.firstIndex(where: { $0.id == companyID }) {
            companies[companyIndex].relatedContactIDs.removeAll { $0 == contactID }
            store.saveCompany(companies[companyIndex])
        }

        guard let contactIndex = contacts.firstIndex(where: { $0.id == contactID }) else { return }
        var updated = contacts[contactIndex]
        if updated.companyID == companyID {
            if let replacementID = updated.additionalCompanyIDs.first {
                updated.companyID = replacementID
                updated.additionalCompanyIDs.removeAll { $0 == replacementID }
                if let replacementName = updated.additionalCompanyNames.first {
                    updated.companyName = replacementName
                    updated.additionalCompanyNames.removeAll { $0 == replacementName }
                } else if let company = company(for: replacementID) {
                    updated.companyName = company.name
                } else {
                    updated.companyName = ""
                }
                if let company = company(for: updated.companyID ?? replacementID) {
                    updated.originalCompanyName = company.originalName
                } else {
                    updated.originalCompanyName = nil
                }
            } else {
                updated.companyID = nil
                updated.companyName = ""
                updated.originalCompanyName = nil
            }
        } else {
            updated.additionalCompanyIDs.removeAll { $0 == companyID }
            if let name = companyName(for: companyID) {
                updated.additionalCompanyNames.removeAll { $0 == name }
            }
        }
        contacts[contactIndex] = updated
        store.saveContact(updated)
    }

    func mergeContact(existingID: UUID, newContact: ContactDocument, images: [UIImage]) {
        guard let index = contacts.firstIndex(where: { $0.id == existingID }) else { return }
        var updated = contacts[index]

        if !newContact.name.isEmpty { updated.name = newContact.name }
        if let originalName = newContact.originalName, !originalName.isEmpty {
            updated.originalName = originalName
        }
        if !newContact.title.isEmpty { updated.title = newContact.title }
        if let department = newContact.department, !department.isEmpty { updated.department = department }
        if !newContact.phone.isEmpty { updated.phone = newContact.phone }
        if !newContact.email.isEmpty { updated.email = newContact.email }
        if let location = newContact.location, !location.isEmpty { updated.location = location }
        if let website = newContact.website, !website.isEmpty { updated.website = website }
        if let linkedin = newContact.linkedinURL, !linkedin.isEmpty { updated.linkedinURL = linkedin }
        if !newContact.notes.isEmpty {
            updated.notes = updated.notes.isEmpty ? newContact.notes : "\(updated.notes)\n\n\(newContact.notes)"
        }
        if !newContact.tags.isEmpty {
            updated.tags = Array(Set(updated.tags + newContact.tags))
        }
        if let originalCompanyName = newContact.originalCompanyName, !originalCompanyName.isEmpty {
            updated.originalCompanyName = originalCompanyName
        }
        if updated.sourceLanguageCode == nil, let sourceLanguageCode = newContact.sourceLanguageCode {
            updated.sourceLanguageCode = sourceLanguageCode
        }

        if let company = ensureCompany(named: newContact.companyName) {
            linkContact(existingID, to: company.id)
        }

        contacts[index] = updated
        store.saveContact(updated)
        registerTags(updated.tags)

        if !images.isEmpty {
            for image in images {
                _ = addContactPhoto(contactID: existingID, image: image)
            }
        }
    }

    func addCapture(_ image: UIImage) {
        _ = store.saveCapture(image)
        recentCaptures.insert(image, at: 0)
    }

    @discardableResult
    func addCompanyPhoto(companyID: UUID, image: UIImage) -> UUID? {
        guard let index = companies.firstIndex(where: { $0.id == companyID }) else { return nil }
        guard companies[index].photoIDs.count < 10 else { return nil }
        guard let photoID = store.saveCompanyPhoto(image, companyID: companyID) else { return nil }
        companies[index].photoIDs.insert(photoID, at: 0)
        store.saveCompany(companies[index])
        return photoID
    }

    @discardableResult
    func addContactPhoto(contactID: UUID, image: UIImage) -> UUID? {
        guard let index = contacts.firstIndex(where: { $0.id == contactID }) else { return nil }
        guard contacts[index].photoIDs.count < 10 else { return nil }
        guard let photoID = store.saveContactPhoto(image, contactID: contactID) else { return nil }
        contacts[index].photoIDs.insert(photoID, at: 0)
        store.saveContact(contacts[index])
        return photoID
    }

    func loadCompanyPhoto(companyID: UUID, photoID: UUID) -> UIImage? {
        store.loadCompanyPhoto(companyID: companyID, photoID: photoID)
    }

    func loadContactPhoto(contactID: UUID, photoID: UUID) -> UIImage? {
        store.loadContactPhoto(contactID: contactID, photoID: photoID)
    }

    func deleteCompanyPhoto(companyID: UUID, photoID: UUID) {
        guard let index = companies.firstIndex(where: { $0.id == companyID }) else { return }
        companies[index].photoIDs.removeAll { $0 == photoID }
        store.deleteCompanyPhoto(companyID: companyID, photoID: photoID)
        store.saveCompany(companies[index])
    }

    func deleteContactPhoto(contactID: UUID, photoID: UUID) {
        guard let index = contacts.firstIndex(where: { $0.id == contactID }) else { return }
        contacts[index].photoIDs.removeAll { $0 == photoID }
        store.deleteContactPhoto(contactID: contactID, photoID: photoID)
        store.saveContact(contacts[index])
    }

    func enrichCompany(companyID: UUID, completion: ((Bool, String) -> Void)? = nil) {
        guard let company = company(for: companyID) else { return }
        guard !isEnrichingGlobal else { return }
        guard enrichmentService.hasValidAPIKey() else {
            completion?(false, "missing_api_key")
            return
        }
        startEnrichmentProgress()
        let context = [
            company.originalName,
            company.industry,
            company.companySize,
            company.revenue,
            company.headquarters,
            company.location,
            company.serviceType,
            company.marketRegion
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " | ")
        let request = EnrichmentRequest(
            type: .company,
            name: company.name,
            summary: company.summary,
            notes: company.notes,
            tags: company.tags,
            tagPool: tagPool,
            rawOCRText: "",
            preferredLinks: [company.website, company.linkedinURL],
            context: context
        )
        enrichmentService.enrich(request) { [weak self] result in
            guard let self else { return }
            guard let result else {
                Task { @MainActor in
                    self.finishEnrichmentProgress()
                    completion?(false, "failed")
                }
                return
            }
            Task { @MainActor in
                guard let current = self.company(for: companyID) else {
                    self.finishEnrichmentProgress()
                    return
                }
                var updated = current
                var enrichedFields: [String] = []
                var backups: [String: String] = [:]
                var didChange = false

                func applyField(_ key: String, current: String, new: String, assign: (String) -> Void) {
                    guard !new.isEmpty, new != current else { return }
                    enrichedFields.append(key)
                    if !current.isEmpty {
                        backups[key] = current
                    }
                    assign(new)
                    didChange = true
                }

                func applyOptionalField(_ key: String, current: String?, new: String?, assign: (String) -> Void) {
                    applyField(key, current: current ?? "", new: new ?? "", assign: assign)
                }

                if !result.summaryEN.isEmpty, result.summaryEN != updated.aiSummaryEN {
                    updated.aiSummaryEN = result.summaryEN
                    didChange = true
                }
                if !result.summaryZH.isEmpty, result.summaryZH != updated.aiSummaryZH {
                    updated.aiSummaryZH = result.summaryZH
                    didChange = true
                }
                if !updated.aiSummaryEN.isEmpty || !updated.aiSummaryZH.isEmpty {
                    updated.aiSummaryUpdatedAt = Date()
                }
                if !result.tags.isEmpty {
                    let filteredTags = result.tags.filter { !$0.contains(" ") && !$0.contains("\t") }
                    let pool = self.tagPool
                    let poolMap = Dictionary(uniqueKeysWithValues: pool.map { ($0.lowercased(), $0) })
                    let normalizedTags = filteredTags.map { tag in
                        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return "" }
                        return poolMap[trimmed.lowercased()] ?? trimmed
                    }.filter { !$0.isEmpty }
                    let combinedTags = Array(Set(updated.tags + normalizedTags))
                    if Set(combinedTags) != Set(updated.tags) {
                        if !updated.tags.isEmpty {
                            backups["tags"] = updated.tags.joined(separator: " · ")
                        }
                        updated.tags = combinedTags
                        enrichedFields.append("tags")
                        didChange = true
                    }
                }
                applyField("website", current: updated.website, new: result.website ?? "") { updated.website = $0 }
                applyOptionalField("linkedin", current: updated.linkedinURL, new: result.linkedin) { updated.linkedinURL = $0 }
                applyField("phone", current: updated.phone, new: result.phone ?? "") { updated.phone = $0 }
                applyField("address", current: updated.address, new: result.address ?? "") { updated.address = $0 }
                applyOptionalField("industry", current: updated.industry, new: result.industry) { updated.industry = $0 }
                applyOptionalField("companySize", current: updated.companySize, new: result.companySize) { updated.companySize = $0 }
                applyOptionalField("revenue", current: updated.revenue, new: result.revenue) { updated.revenue = $0 }
                applyOptionalField("foundedYear", current: updated.foundedYear, new: result.foundedYear) { updated.foundedYear = $0 }
                applyOptionalField("headquarters", current: updated.headquarters, new: result.headquarters) { updated.headquarters = $0 }

                if !didChange {
                    self.finishEnrichmentProgress()
                    completion?(false, "no_changes")
                    return
                }

                updated.lastEnrichedFields = enrichedFields
                updated.lastEnrichedValues = backups
                updated.enrichedAt = Date()
                self.updateCompany(updated)
                self.finishEnrichmentProgress()
                completion?(true, "")
            }
        }
    }

    func enrichContact(contactID: UUID, completion: ((Bool, String) -> Void)? = nil) {
        guard let contact = contact(for: contactID) else { return }
        guard !isEnrichingGlobal else { return }
        guard enrichmentService.hasValidAPIKey() else {
            completion?(false, "missing_api_key")
            return
        }
        startEnrichmentProgress()
        let contextParts: [String?] = [
            contact.title,
            contact.department,
            contact.location,
            contact.companyName,
            contact.originalCompanyName
        ]
        let context = contextParts
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
        let request = EnrichmentRequest(
            type: .contact,
            name: contact.name,
            summary: contact.title,
            notes: contact.notes,
            tags: contact.tags,
            tagPool: tagPool,
            rawOCRText: "",
            preferredLinks: [contact.website, contact.linkedinURL],
            context: context
        )
        enrichmentService.enrich(request) { [weak self] result in
            guard let self else { return }
            guard let result else {
                Task { @MainActor in
                    self.finishEnrichmentProgress()
                    completion?(false, "failed")
                }
                return
            }
            Task { @MainActor in
                guard let current = self.contact(for: contactID) else {
                    self.finishEnrichmentProgress()
                    return
                }
                var updated = current
                var enrichedFields: [String] = []
                var backups: [String: String] = [:]
                var didChange = false

                func applyField(_ key: String, current: String, new: String, assign: (String) -> Void) {
                    guard !new.isEmpty, new != current else { return }
                    enrichedFields.append(key)
                    if !current.isEmpty {
                        backups[key] = current
                    }
                    assign(new)
                    didChange = true
                }

                func applyOptionalField(_ key: String, current: String?, new: String?, assign: (String) -> Void) {
                    applyField(key, current: current ?? "", new: new ?? "", assign: assign)
                }

                if !result.summaryEN.isEmpty, result.summaryEN != updated.aiSummaryEN {
                    updated.aiSummaryEN = result.summaryEN
                    didChange = true
                }
                if !result.summaryZH.isEmpty, result.summaryZH != updated.aiSummaryZH {
                    updated.aiSummaryZH = result.summaryZH
                    didChange = true
                }
                if !updated.aiSummaryEN.isEmpty || !updated.aiSummaryZH.isEmpty {
                    updated.aiSummaryUpdatedAt = Date()
                }
                if !result.tags.isEmpty {
                    let filteredTags = result.tags.filter { !$0.contains(" ") && !$0.contains("\t") }
                    let pool = self.tagPool
                    let poolMap = Dictionary(uniqueKeysWithValues: pool.map { ($0.lowercased(), $0) })
                    let normalizedTags = filteredTags.map { tag in
                        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return "" }
                        return poolMap[trimmed.lowercased()] ?? trimmed
                    }.filter { !$0.isEmpty }
                    let combinedTags = Array(Set(updated.tags + normalizedTags))
                    if Set(combinedTags) != Set(updated.tags) {
                        if !updated.tags.isEmpty {
                            backups["tags"] = updated.tags.joined(separator: " · ")
                        }
                        updated.tags = combinedTags
                        enrichedFields.append("tags")
                        didChange = true
                    }
                }
                applyField("title", current: updated.title, new: result.title ?? "") { updated.title = $0 }
                applyOptionalField("department", current: updated.department, new: result.department) { updated.department = $0 }
                applyOptionalField("location", current: updated.location, new: result.location) { updated.location = $0 }
                applyField("phone", current: updated.phone, new: result.phone ?? "") { updated.phone = $0 }
                applyField("email", current: updated.email, new: result.email ?? "") { updated.email = $0 }
                applyOptionalField("website", current: updated.website, new: result.website) { updated.website = $0 }
                applyOptionalField("linkedin", current: updated.linkedinURL, new: result.linkedin) { updated.linkedinURL = $0 }

                if !didChange {
                    self.finishEnrichmentProgress()
                    completion?(false, "no_changes")
                    return
                }

                updated.lastEnrichedFields = enrichedFields
                updated.lastEnrichedValues = backups
                updated.enrichedAt = Date()
                self.updateContact(updated)
                self.finishEnrichmentProgress()
                completion?(true, "")
            }
        }
    }

    private func startEnrichmentProgress() {
        progressTask?.cancel()
        let totalStages = 5
        let searchStages = max(1, totalStages - 2)
        enrichmentProgress = EnrichmentProgressState(
            stage: .analyzing,
            progress: 1.0 / Double(totalStages),
            totalStages: totalStages
        )
        progressTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            for index in 1...searchStages {
                enrichmentProgress = EnrichmentProgressState(
                    stage: .searching(current: index, total: searchStages),
                    progress: Double(1 + index) / Double(totalStages),
                    totalStages: totalStages
                )
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
            enrichmentProgress = EnrichmentProgressState(
                stage: .merging,
                progress: Double(totalStages - 1) / Double(totalStages),
                totalStages: totalStages
            )
        }
    }

    private func finishEnrichmentProgress() {
        progressTask?.cancel()
        progressTask = nil
        enrichmentProgress = EnrichmentProgressState(stage: .complete, progress: 1.0, totalStages: 5)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            enrichmentProgress = nil
        }
    }

    private func companyName(for companyID: UUID) -> String? {
        companies.first(where: { $0.id == companyID })?.name
    }

    private static func purgeSampleData(
        store: LocalStore,
        companies: [CompanyDocument],
        contacts: [ContactDocument]
    ) -> ([CompanyDocument], [ContactDocument]) {
        let sampleCompanyNames: Set<String> = [
            "Aster Labs",
            "Harbor Logistics",
            "Summit Wellness"
        ]
        let sampleContactNames: Set<String> = [
            "Lena Zhao",
            "Arjun Patel",
            "Yuki Tanaka"
        ]

        let removedCompanies = companies.filter { sampleCompanyNames.contains($0.name) }
        let removedContacts = contacts.filter { sampleContactNames.contains($0.name) }

        if !removedCompanies.isEmpty || !removedContacts.isEmpty {
            removedCompanies.forEach { store.deleteCompany($0.id) }
            removedContacts.forEach { store.deleteContact($0.id) }
        }

        let cleanedCompanies = companies.filter { !sampleCompanyNames.contains($0.name) }
        let cleanedContacts = contacts.filter { !sampleContactNames.contains($0.name) }
        return (cleanedCompanies, cleanedContacts)
    }
}
