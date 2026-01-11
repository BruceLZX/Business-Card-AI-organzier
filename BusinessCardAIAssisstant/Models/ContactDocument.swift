import Foundation

struct ContactDocument: Identifiable, Hashable {
    let id: UUID
    var name: String
    var title: String
    var phone: String
    var email: String
    var notes: String
    var companyID: UUID?
    var companyName: String
    var photoIDs: [UUID]

    func matchesSearch(_ query: String) -> Bool {
        let lowered = query.lowercased()
        if name.lowercased().contains(lowered) { return true }
        if title.lowercased().contains(lowered) { return true }
        if companyName.lowercased().contains(lowered) { return true }
        return false
    }
}
