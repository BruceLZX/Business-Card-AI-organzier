import Foundation
import UIKit

@MainActor
final class AppState: ObservableObject {
    @Published var companies: [CompanyDocument]
    @Published var contacts: [ContactDocument]
    @Published var recentCaptures: [UIImage] = []
    @Published var tagPool: [String] = []

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
            let subtitle = contact.companyName.isEmpty ? contact.title : "\(contact.title) · \(contact.companyName)"
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

        let (cleanCompanies, cleanContacts) = purgeSampleData(
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

    func registerTags(_ tags: [String]) {
        let normalized = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let merged = Array(Set(tagPool + normalized)).sorted()
        tagPool = merged
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
    }

    func mergeContact(existingID: UUID, newContact: ContactDocument, image: UIImage?) {
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
            updated.companyID = company.id
            updated.companyName = company.name
            linkContact(existingID, to: company.id)
        }

        contacts[index] = updated
        store.saveContact(updated)
        registerTags(updated.tags)

        if let image {
            _ = addContactPhoto(contactID: existingID, image: image)
        }
    }

    func addCapture(_ image: UIImage) {
        _ = store.saveCapture(image)
        recentCaptures.insert(image, at: 0)
    }

    @discardableResult
    func addCompanyPhoto(companyID: UUID, image: UIImage) -> UUID? {
        guard let index = companies.firstIndex(where: { $0.id == companyID }) else { return nil }
        guard let photoID = store.saveCompanyPhoto(image, companyID: companyID) else { return nil }
        companies[index].photoIDs.insert(photoID, at: 0)
        store.saveCompany(companies[index])
        return photoID
    }

    @discardableResult
    func addContactPhoto(contactID: UUID, image: UIImage) -> UUID? {
        guard let index = contacts.firstIndex(where: { $0.id == contactID }) else { return nil }
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

    func enrichCompany(companyID: UUID) {
        guard let company = company(for: companyID) else { return }
        let request = EnrichmentRequest(
            type: .company,
            name: company.name,
            summary: company.summary,
            notes: company.notes,
            tags: company.tags,
            rawOCRText: ""
        )
        enrichmentService.enrich(request) { [weak self] result in
            guard let result, let self else { return }
            Task { @MainActor in
                guard let current = self.company(for: companyID) else { return }
                var updated = current
                if !result.summary.isEmpty {
                    updated.summary = result.summary
                }
                if !result.tags.isEmpty {
                    updated.tags = Array(Set(updated.tags + result.tags))
                }
                if let website = result.website, !website.isEmpty {
                    updated.website = website
                }
                if let linkedin = result.linkedin, !linkedin.isEmpty {
                    updated.linkedinURL = linkedin
                }
                if let phone = result.phone, !phone.isEmpty {
                    updated.phone = phone
                }
                if let address = result.address, !address.isEmpty {
                    updated.address = address
                }
                if let industry = result.industry, !industry.isEmpty {
                    updated.industry = industry
                }
                if let size = result.companySize, !size.isEmpty {
                    updated.companySize = size
                }
                if let revenue = result.revenue, !revenue.isEmpty {
                    updated.revenue = revenue
                }
                if let founded = result.foundedYear, !founded.isEmpty {
                    updated.foundedYear = founded
                }
                if let hq = result.headquarters, !hq.isEmpty {
                    updated.headquarters = hq
                }
                if !result.suggestedLinks.isEmpty {
                    let linkText = result.suggestedLinks.joined(separator: "\n")
                    updated.notes = updated.notes.isEmpty ? linkText : "\(updated.notes)\n\n\(linkText)"
                }
                updated.enrichedAt = Date()
                self.updateCompany(updated)
            }
        }
    }

    func enrichContact(contactID: UUID) {
        guard let contact = contact(for: contactID) else { return }
        let request = EnrichmentRequest(
            type: .contact,
            name: contact.name,
            summary: contact.title,
            notes: contact.notes,
            tags: contact.tags,
            rawOCRText: ""
        )
        enrichmentService.enrich(request) { [weak self] result in
            guard let result, let self else { return }
            Task { @MainActor in
                guard let current = self.contact(for: contactID) else { return }
                var updated = current
                if !result.summary.isEmpty {
                    updated.title = result.summary
                }
                if !result.tags.isEmpty {
                    updated.tags = Array(Set(updated.tags + result.tags))
                }
                if let title = result.title, !title.isEmpty {
                    updated.title = title
                }
                if let department = result.department, !department.isEmpty {
                    updated.department = department
                }
                if let location = result.location, !location.isEmpty {
                    updated.location = location
                }
                if let phone = result.phone, !phone.isEmpty {
                    updated.phone = phone
                }
                if let email = result.email, !email.isEmpty {
                    updated.email = email
                }
                if let website = result.website, !website.isEmpty {
                    updated.website = website
                }
                if let linkedin = result.linkedin, !linkedin.isEmpty {
                    updated.linkedinURL = linkedin
                }
                if !result.suggestedLinks.isEmpty {
                    let linkText = result.suggestedLinks.joined(separator: "\n")
                    updated.notes = updated.notes.isEmpty ? linkText : "\(updated.notes)\n\n\(linkText)"
                }
                updated.enrichedAt = Date()
                self.updateContact(updated)
            }
        }
    }

    private func purgeSampleData(
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
