import Foundation

struct ContactDocument: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var originalName: String?
    var title: String
    var department: String?
    var phone: String
    var email: String
    var location: String?
    var website: String?
    var linkedinURL: String?
    var notes: String
    var tags: [String]
    var companyID: UUID?
    var companyName: String
    var originalCompanyName: String?
    var additionalCompanyIDs: [UUID] = []
    var additionalCompanyNames: [String] = []
    var aiSummaryEN: String = ""
    var aiSummaryZH: String = ""
    var aiSummaryUpdatedAt: Date?
    var lastEnrichedFields: [String] = []
    var lastEnrichedValues: [String: String] = [:]
    var photoIDs: [UUID]
    var sourceLanguageCode: String?
    var enrichedAt: Date?
    var createdAt: Date?

    func matchesSearch(_ query: String) -> Bool {
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        if (originalName ?? "").lowercased().contains(lowered) { return true }
        if title.lowercased().contains(lowered) { return true }
        if companyName.lowercased().contains(lowered) { return true }
        if (originalCompanyName ?? "").lowercased().contains(lowered) { return true }
        if (department ?? "").lowercased().contains(lowered) { return true }
        if (location ?? "").lowercased().contains(lowered) { return true }
        if additionalCompanyNames.joined(separator: " ").lowercased().contains(lowered) { return true }
        if notes.lowercased().contains(lowered) { return true }
        if tags.joined(separator: " ").lowercased().contains(lowered) { return true }
        return false
    }
}
