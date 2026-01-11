import Foundation

struct CompanyDocument: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var originalName: String?
    var summary: String
    var serviceKeywords: [String]
    var website: String
    var linkedinURL: String?
    var industry: String?
    var companySize: String?
    var revenue: String?
    var foundedYear: String?
    var headquarters: String?
    var address: String
    var phone: String
    var location: String
    var serviceType: String
    var targetAudience: TargetAudience
    var marketRegion: String
    var notes: String
    var tags: [String]
    var relatedContactIDs: [UUID]
    var photoIDs: [UUID]
    var sourceLanguageCode: String?
    var enrichedAt: Date?
    var createdAt: Date?

    func matchesSearch(_ query: String) -> Bool {
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        if (originalName ?? "").lowercased().contains(lowered) { return true }
        if summary.lowercased().contains(lowered) { return true }
        if serviceKeywords.joined(separator: " ").lowercased().contains(lowered) { return true }
        if (industry ?? "").lowercased().contains(lowered) { return true }
        if (companySize ?? "").lowercased().contains(lowered) { return true }
        if (revenue ?? "").lowercased().contains(lowered) { return true }
        if (headquarters ?? "").lowercased().contains(lowered) { return true }
        if notes.lowercased().contains(lowered) { return true }
        if tags.joined(separator: " ").lowercased().contains(lowered) { return true }
        return false
    }

    func matches(filters: FilterOptions) -> Bool {
        if !filters.location.isEmpty && !location.lowercased().contains(filters.location.lowercased()) {
            return false
        }
        if !filters.serviceType.isEmpty && !serviceType.lowercased().contains(filters.serviceType.lowercased()) {
            return false
        }
        if !filters.tag.isEmpty && !tags.joined(separator: " ").lowercased().contains(filters.tag.lowercased()) {
            return false
        }
        if let audience = filters.targetAudience.asAudience, audience != targetAudience {
            return false
        }
        if !filters.marketRegion.isEmpty && !marketRegion.lowercased().contains(filters.marketRegion.lowercased()) {
            return false
        }
        return true
    }
}
