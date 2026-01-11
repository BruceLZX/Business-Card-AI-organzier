import Foundation
import UIKit

@MainActor
final class AppState: ObservableObject {
    @Published var companies: [CompanyDocument]
    @Published var contacts: [ContactDocument]
    @Published var recentCaptures: [UIImage] = []

    private let store: LocalStore

    init(store: LocalStore = LocalStore()) {
        self.store = store
        let loadedCompanies = store.loadCompanies()
        let loadedContacts = store.loadContacts()

        if !loadedCompanies.isEmpty || !loadedContacts.isEmpty {
            companies = loadedCompanies
            contacts = loadedContacts
            return
        }

        let asterID = UUID(uuidString: "A03F02B2-6C51-4A23-9B87-1A0D44C5A9A1")!
        let harborID = UUID(uuidString: "C42C2A86-2A3F-4D1C-8F1A-7A0E4E7F6731")!
        let summitID = UUID(uuidString: "5E7C9A33-8B6F-4E1F-A6E4-8D6B8A1F9E2B")!

        let lenaID = UUID(uuidString: "DEB1A0E4-8E6A-4B61-9C6C-9E0B0AB1E2D4")!
        let arjunID = UUID(uuidString: "8C4C2B2E-6B4C-4B58-9A55-78E57F9E12F2")!
        let yukiID = UUID(uuidString: "0C9D8C4B-5C9B-46B6-9B3C-5F8E8A7B3E72")!

        let aster = CompanyDocument(
            id: asterID,
            name: "Aster Labs",
            summary: "AI-driven card and brochure OCR for enterprise teams.",
            serviceKeywords: ["OCR", "Sales Enablement", "Knowledge Base"],
            website: "https://asterlabs.example",
            address: "88 Huaihai Rd",
            phone: "+86 21 5555 1234",
            location: "Shanghai",
            serviceType: "AI OCR",
            targetAudience: .b2b,
            marketRegion: "APAC",
            notes: "High-priority OCR partner candidate.",
            tags: ["ocr", "ai", "b2b"],
            relatedContactIDs: [lenaID],
            photoIDs: []
        )

        let harbor = CompanyDocument(
            id: harborID,
            name: "Harbor Logistics",
            summary: "Cross-border warehousing and fulfillment for consumer brands.",
            serviceKeywords: ["Warehousing", "Fulfillment", "Cross-border"],
            website: "https://harborlogistics.example",
            address: "1200 Harbor Ave",
            phone: "+1 415 555 0188",
            location: "San Francisco",
            serviceType: "Logistics",
            targetAudience: .b2b,
            marketRegion: "North America",
            notes: "Evaluate for coastal distribution.",
            tags: ["logistics", "warehouse"],
            relatedContactIDs: [arjunID],
            photoIDs: []
        )

        let summit = CompanyDocument(
            id: summitID,
            name: "Summit Wellness",
            summary: "Employee wellness programs and on-site fitness solutions.",
            serviceKeywords: ["Wellness", "Fitness", "HR Benefits"],
            website: "https://summitwellness.example",
            address: "16 Queen St",
            phone: "+44 20 7946 0010",
            location: "London",
            serviceType: "Wellness",
            targetAudience: .b2b,
            marketRegion: "EMEA",
            notes: "Pilot fit for APAC offices.",
            tags: ["wellness", "benefits"],
            relatedContactIDs: [yukiID],
            photoIDs: []
        )

        let lena = ContactDocument(
            id: lenaID,
            name: "Lena Zhao",
            title: "Business Development",
            phone: "+86 138 0000 0000",
            email: "lena.zhao@example.com",
            notes: "Met at fintech expo.",
            tags: ["bd", "fintech"],
            companyID: asterID,
            companyName: "Aster Labs",
            photoIDs: []
        )

        let arjun = ContactDocument(
            id: arjunID,
            name: "Arjun Patel",
            title: "Partnerships Lead",
            phone: "+1 650 555 0112",
            email: "arjun.patel@example.com",
            notes: "Interested in APAC expansion.",
            tags: ["partnerships", "logistics"],
            companyID: harborID,
            companyName: "Harbor Logistics",
            photoIDs: []
        )

        let yuki = ContactDocument(
            id: yukiID,
            name: "Yuki Tanaka",
            title: "Enterprise Account Manager",
            phone: "+44 20 7000 1234",
            email: "yuki.tanaka@example.com",
            notes: "Follow up on wellness pilot.",
            tags: ["enterprise", "wellness"],
            companyID: summitID,
            companyName: "Summit Wellness",
            photoIDs: []
        )

        companies = [aster, harbor, summit]
        contacts = [lena, arjun, yuki]

        [aster, harbor, summit].forEach { store.saveCompany($0) }
        [lena, arjun, yuki].forEach { store.saveContact($0) }
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
    }

    func updateContact(_ contact: ContactDocument) {
        guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else { return }
        contacts[index] = contact
        store.saveContact(contact)
    }

    func addCompany(_ company: CompanyDocument) {
        companies.append(company)
        store.saveCompany(company)
    }

    func addContact(_ contact: ContactDocument) {
        contacts.append(contact)
        store.saveContact(contact)
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
}
