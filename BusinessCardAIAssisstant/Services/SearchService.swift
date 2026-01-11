import Foundation

struct SearchService {
    static func filterCompanies(_ companies: [CompanyDocument], query: String) -> [CompanyDocument] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return companies }
        return companies.filter { $0.matchesSearch(trimmed) }
    }

    static func filterContacts(_ contacts: [ContactDocument], query: String) -> [ContactDocument] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return contacts }
        return contacts.filter { $0.matchesSearch(trimmed) }
    }
}
