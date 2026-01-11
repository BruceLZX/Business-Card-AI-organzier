import Foundation

struct FilterOptions: Equatable {
    var location: String = ""
    var serviceType: String = ""
    var tag: String = ""
    var targetAudience: TargetAudienceFilter = .any
    var marketRegion: String = ""

    var isEmpty: Bool {
        location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && serviceType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && targetAudience == .any
        && marketRegion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
