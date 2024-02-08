import Foundation

extension Mock {
    fileprivate static var link: String {
        "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3"
    }
    
    static func bookSummary(
        name: String = "BookSummary",
        cover: Data = .init(),
        keyPoints: [BookSummary.KeyPoint]? = [
            .init(name: "First", duration: 348, link: Self.link),
            .init(name: "Second", duration: 348, link: Self.link),
            .init(name: "Third", duration: 348, link: ""),
            .init(name: "Fourth", duration: 348, link: Self.link),
            .init(name: "Fifth", duration: 348, link: Self.link)
        ]
    ) -> BookSummary {
        BookSummary(name: name, cover: cover, keyPoints: keyPoints)
    }
}
