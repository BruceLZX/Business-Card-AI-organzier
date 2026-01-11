import Foundation

struct CompanyDocument: Identifiable, Hashable {
    let id: UUID
    var name: String
    var summary: String
    var serviceKeywords: [String]
    var website: String
    var address: String
    var phone: String
    var location: String
    var serviceType: String
    var targetAudience: TargetAudience
    var marketRegion: String
    var relatedContactIDs: [UUID]
    var photoIDs: [UUID]

    func matchesSearch(_ query: String) -> Bool {
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        if summary.lowercased().contains(lowered) { return true }
        if serviceKeywords.joined(separator: " ").lowercased().contains(lowered) { return true }
        return false
    }

    func matches(filters: FilterOptions) -> Bool {
        if !filters.location.isEmpty && !location.lowercased().contains(filters.location.lowercased()) {
            return false
        }
        if !filters.serviceType.isEmpty && !serviceType.lowercased().contains(filters.serviceType.lowercased()) {
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
