import SwiftUI
import ComposableArchitecture

fileprivate extension Player.State {
    var currentKeyPointIndex: Int? {
        if let currentKeyPoint {
            return bookSummary?.keyPoints?.firstIndex(of: currentKeyPoint)
        } else {
            return nil
        }
    }
    
    var moveBackwardDisabled: Bool {
        if let currentKeyPointIndex {
            return currentKeyPointIndex < 1
        } else {
            return false
        }
    }
    
    var moveForwardDisabled: Bool {
        if let currentKeyPointIndex, let keyPointsCount = bookSummary?.keyPoints?.count {
            return currentKeyPointIndex >= keyPointsCount - 1
        } else {
            return false
        }
    }
}

struct PlayerView: View {
    
    // MARK: Properties
    
    @Bindable var store: StoreOf<Player>
    
    // MARK: Body
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 35) {
                coverView(height: geometry.size.height / 2)
                keyPointView
                sliderView
                rateView
                buttonsView
            }
            .padding(20)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background { Color.background.ignoresSafeArea() }
        }
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
    
    // MARK: Views
    
    private func coverView(height: CGFloat) -> some View {
        Image(.cover)
            .resizable()
            .scaledToFit()
            .frame(height: height)
    }
    
    @ViewBuilder
    private var keyPointView: some View {
        if
            let keyPoint = store.currentKeyPoint,
            let keyPointIndex = store.currentKeyPointIndex,
            let totalCount = store.bookSummary?.keyPoints?.count
        {
            VStack(spacing: 8) {
                Text("KEY POINT \(keyPointIndex + 1) OF \(totalCount)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.textGrey)
                
                Text(keyPoint.name)
                    .font(.system(size: 16))
                    .foregroundStyle(.main)
                    .lineLimit(2)
            }
        }
    }
    
    @ViewBuilder
    private var sliderView: some View {
        if let currentKeyPoint = store.currentKeyPoint {
            HStack {
                Text(Formatter.time(from: store.currentTime))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.textGrey)
                
                Slider(
                    value: $store.currentTime.sending(\.currentTimeChanged),
                    in: 0...(currentKeyPoint.duration)
                ) { editing in
                    store.send(.seekingStatusChanged(editing))
                }
                .animation(.linear, value: store.currentTime)
                .tint(.accent)
                .disabled(store.isLoading)
                
                Text(Formatter.time(from: currentKeyPoint.duration))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.textGrey)
            }
        }
    }
    
    private var rateView: some View {
        HStack {
            Button {
                store.send(.rateTapped)
            } label: {
                Text("\(store.rate.rawValue.formatted())x speed ")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.main)
                    .padding(8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.backgroundSecondary)
                    }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var buttonsView: some View {
        HStack(spacing: 10) {
            Button {
                store.send(.moveBackwardTapped)
            } label: {
                Image(systemName: "backward.end.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundStyle(.main)
                    .fontWeight(.ultraLight)
            }
            .disabled(store.moveBackwardDisabled)
            
            Button {
                store.send(.seekBackwardTapped)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.main)
            }
            .disabled(store.isLoading)
            
            playPauseButton
            
            Button {
                store.send(.seekForwardTapped)
            } label: {
                Image(systemName: "arrow.clockwise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.main)
            }
            .disabled(store.isLoading)
            
            Button {
                store.send(.moveForwardTapped)
            } label: {
                Image(systemName: "forward.end.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundStyle(.main)
                    .fontWeight(.ultraLight)
            }
            .disabled(store.moveForwardDisabled)
        }
        .buttonStyle(PlayerButtonStyle())
    }
    
    private var loaderView: some View {
        ProgressView()
            .foregroundStyle(.main)
            .controlSize(.extraLarge)
    }
    
    private var playPauseButton: some View {
        Button {
            store.send(.playPauseTapped)
        } label: {
            if store.isLoading {
                loaderView
            } else {
                Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.main)
                    .frame(width: 40, height: 40)
                    .offset(x: store.isPlaying ? 0 : 4)
            }
        }
        .frame(width: 60, height: 60)
        .contentTransition(.symbolEffect(.replace))
        .disabled(store.isLoading)
    }
}

#Preview {
    PlayerView(store: Store(
        initialState: Player.State(),
        reducer: { Player() }
    ))
}
