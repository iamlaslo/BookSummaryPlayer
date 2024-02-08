import Foundation
import ComposableArchitecture

@Reducer
struct Player {
    @ObservableState
    struct State: Equatable {
        var bookSummary: BookSummary?
        var rate: Rate = .full
        var isLoading = false
        var isPlaying = false
        var currentTime: Double = 0.0
        var totalTime: Double = 0.0
        var currentKeyPoint: BookSummary.KeyPoint?
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
        case seekBackwardTapped
        case seekForwardTapped
        case moveBackwardTapped
        case moveForwardTapped
        case rateTapped
        case seekingStatusChanged(Bool)
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
                    if let firstKeyPoint = item.keyPoints?.first {
                        state.currentKeyPoint = firstKeyPoint
                        try playerManager.setItem(link: firstKeyPoint.link)
                    }
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
                case .controlStatusChanged(let newValue):
                    state.isLoading = newValue == .waitingToPlayAtSpecifiedRate
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
                
            case .moveBackwardTapped:
                if 
                    let keyPoints = state.bookSummary?.keyPoints,
                    let currentKeyPoint = state.currentKeyPoint,
                    let index = keyPoints.firstIndex(of: currentKeyPoint),
                    index > 0
                {
                    state.currentKeyPoint = keyPoints[index - 1]
                }
                return .none
                
            case .moveForwardTapped:
                if
                    let keyPoints = state.bookSummary?.keyPoints,
                    let currentKeyPoint = state.currentKeyPoint,
                    let index = keyPoints.firstIndex(of: currentKeyPoint),
                    index < keyPoints.count - 1
                {
                    state.currentKeyPoint = keyPoints[index + 1]
                }
                return .none
                
            case .rateTapped:
                if let currentRateIndex = Rate.allCases.firstIndex(of: state.rate) {
                    playerManager.changeRate(
                        to: Rate.allCases[(currentRateIndex + 1) % Rate.allCases.count].rawValue
                    )
                }
                return .none
                
            case .seekingStatusChanged(let newValue):
                if state.isPlaying {
                    newValue ? playerManager.pauseAudio() : playerManager.startAudio()
                }
                return .none
                
            case .currentTimeChanged(let currentTime):
                state.currentTime = currentTime
                playerManager.seek(to: currentTime)
                return .none
            }
        }
        .onChange(of: \.currentKeyPoint) { _, currentKeyPoint in
            Reduce { _, _ in
                if let link = currentKeyPoint?.link {
                    do {
                        try playerManager.setItem(link: link)
                    } catch {
                        #warning("Throw error here")
                    }
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
