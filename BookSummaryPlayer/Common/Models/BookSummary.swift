import Foundation

struct BookSummary: Identifiable, Equatable {
    let id: Int
    let name: String
    let cover: Data
    let keyPoints: [KeyPoint]?
    
    struct KeyPoint: Equatable {
        let name: String
        let duration: Double
        let link: String
    }
}
