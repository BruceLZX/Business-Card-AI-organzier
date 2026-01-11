import Foundation

struct RecentDocument: Identifiable {
    enum Kind {
        case company
        case contact
    }

    let id: UUID
    let kind: Kind
    let title: String
    let subtitle: String
    let date: Date
}
