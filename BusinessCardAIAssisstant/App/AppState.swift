import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var companies: [CompanyDocument]
    @Published var contacts: [ContactDocument]

    init() {
        let companyID = UUID(uuidString: "A03F02B2-6C51-4A23-9B87-1A0D44C5A9A1")!
        let contactID = UUID(uuidString: "DEB1A0E4-8E6A-4B61-9C6C-9E0B0AB1E2D4")!

        let sampleCompany = CompanyDocument(
            id: companyID,
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
            relatedContactIDs: [contactID],
            photoIDs: []
        )

        let sampleContact = ContactDocument(
            id: contactID,
            name: "Lena Zhao",
            title: "Business Development",
            phone: "+86 138 0000 0000",
            email: "lena.zhao@example.com",
            notes: "Met at fintech expo.",
            companyID: companyID,
            companyName: "Aster Labs",
            photoIDs: []
        )

        companies = [sampleCompany]
        contacts = [sampleContact]
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
    }

    func updateContact(_ contact: ContactDocument) {
        guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else { return }
        contacts[index] = contact
    }
}
