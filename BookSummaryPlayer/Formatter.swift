import Foundation

struct Formatter {
    static let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static func time(from seconds: Double) -> String {
        return timeFormatter.string(from: TimeInterval(seconds)) ?? "00:00"
    }
}
