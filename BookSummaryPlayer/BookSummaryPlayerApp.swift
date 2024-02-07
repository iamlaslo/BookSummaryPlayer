import SwiftUI
import ComposableArchitecture

@main
struct BookSummaryPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            PlayerView(store: Store(
                initialState: Player.State(),
                reducer: { Player()._printChanges() }
            ))
        }
    }
}
