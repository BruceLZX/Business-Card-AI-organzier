import Foundation

enum EnrichmentStage: Equatable {
    case analyzing
    case searching(current: Int, total: Int)
    case merging
    case complete
}

struct EnrichmentProgressState: Equatable {
    let stage: EnrichmentStage
    let progress: Double
    let totalStages: Int
}
