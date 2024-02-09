import XCTest
import ComposableArchitecture
@testable import BookSummaryPlayer

@MainActor
final class BookSummaryPlayerTests: XCTestCase {
    func testInitValues() async {
        let testScheduler = DispatchQueue.test
        let store = TestStore(initialState: Player.State()) {
            Player()
                .dependency(\.mainQueue, testScheduler.eraseToAnyScheduler())
        }
        
        await store.send(.onAppear) {
            $0.bookSummary = Mock.bookSummary()
            $0.currentKeyPoint = Mock.bookSummary().keyPoints?.first
            $0.isPlaying = false
        }
        
        await store.send(.cancel(.playerManager))
        
        await store.send(.moveForwardTapped) {
            $0.currentKeyPoint = Mock.bookSummary().keyPoints?[1]
        }
        
        await store.send(.moveBackwardTapped) {
            $0.currentKeyPoint = Mock.bookSummary().keyPoints?.first
        }
    }
    
    func testPlayPauseTapped() async {
        let store = TestStore(initialState: Player.State(isPlaying: false)) {
            Player()
        }
        
        await store.send(.playPauseTapped) {
            $0.isPlaying = true
        }
        
        await store.send(.playPauseTapped) {
            $0.isPlaying = false
        }
    }
    
    func testErrorHandling() async {
        let store = TestStore(initialState: Player.State()) {
            Player()
        }

        await store.send(.playerManager(.error(.badUrl))) {
            $0.isPlaying = false
            $0.isLoading = true
            $0.alert = .init(title: {
                TextState("Alert!")
            }, actions: {
                .default(TextState("OK"), action: .send(.dismissTapped))
            }, message: {
                TextState(PlayerManager.PlayerError.badUrl.message)
            })
        }
    }
}
