import Foundation
import ComposableArchitecture

struct BookSummary: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let cover: Data
    let keyPoints: [KeyPoint]?
    let duration: Double
    let link: String
    
    struct KeyPoint: Equatable {
        let name: String
        let startTime: Double
    }
}

struct Mock { }
extension Mock {
    static func bookSummary(
        name: String = "BookSummary",
        cover: Data = .init(),
        keyPoints: [BookSummary.KeyPoint]? = [
            .init(name: "First", startTime: 0),
            .init(name: "Second", startTime: 15),
            .init(name: "Third", startTime: 55),
            .init(name: "Fourth", startTime: 131),
            .init(name: "Fifth", startTime: 215)
        ],
        duration: Double = 348,
        link: String = "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3"
    ) -> BookSummary {
        BookSummary(name: name, cover: cover, keyPoints: keyPoints, duration: duration, link: link)
    }
}

@Reducer
struct Player {
    @ObservableState
    struct State: Equatable {
        var bookSummary: BookSummary?
        var rate: Rate = .full
        var isPlaying = false
        var currentTime: Double = 0.0
        var totalTime: Double = 0.0
        var currentKeyPointIndex: Int? {
            bookSummary?.keyPoints?.lastIndex(where: { $0.startTime <= self.currentTime })
        }
    }
    
    enum Rate: Double, CaseIterable {
        case half = 0.5
        case full = 1
        case oneAndHalf = 1.5
        case twice = 2
    }
    
    enum Action {
        case onAppear
        case playerManager(PlayerManager.Action)
        case playPauseTapped
        case seekForwardTapped
        case seekBackwardTapped
        case rateTapped
        case currentTimeChanged(Double)
    }
    
    enum CancelID {
        case playerManager
        case playStatusThrottle
    }
    
    @Dependency(\.playerManager) var playerManager
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                do {
                    // Emulating like we're opening some book summary
                    let item = Mock.bookSummary()
                    try playerManager.setItem(link: item.link)
                    state.bookSummary = item
                } catch {
                    #warning("Throw error here")
                }
                
                return subscribeOnPlayerManager()
                
            case .playerManager(let playerManagerActions):
                switch playerManagerActions {
                case .timeChanged(let time):
                    state.currentTime = time
                    return .none
                case .rateChanged(let rate):
                    state.rate = Rate(rawValue: rate) ?? .full
                    return .none
                }
                
            case .playPauseTapped:
                state.isPlaying.toggle()
                state.isPlaying ? playerManager.startAudio() : playerManager.pauseAudio()
                return .none
                
            case .seekBackwardTapped:
                playerManager.seekBackward(for: 5)
                return .none
                
            case .seekForwardTapped:
                playerManager.seekForward(for: 10)
                return .none
                
            case .currentTimeChanged(let currentTime):
                state.currentTime = currentTime
                playerManager.seek(to: currentTime)
                return .none
                
            case .rateTapped:
                if let currentRateIndex = Rate.allCases.firstIndex(of: state.rate) {
                    playerManager.changeRate(
                        to: Rate.allCases[(currentRateIndex + 1) % Rate.allCases.count].rawValue
                    )
                }
                return .none
            }
        }
    }
    
    private func subscribeOnPlayerManager() -> Effect<Action> {
        playerManager
            .delegate()
            .map(Player.Action.playerManager)
            .cancellable(id: CancelID.playerManager, cancelInFlight: true)
    }
}
