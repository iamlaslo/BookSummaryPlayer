import SwiftUI
import ComposableArchitecture

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
            .frame(height: geometry.size.height)
            .background { Color.background.ignoresSafeArea() }
        }
        .onAppear { store.send(.onAppear) }
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
            let keyPointIndex = store.currentKeyPointIndex,
            let keyPoint = store.bookSummary?.keyPoints?[keyPointIndex],
            let totalCount = store.bookSummary?.keyPoints?.count
        {
            VStack(spacing: 12) {
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
        if let bookSummary = store.bookSummary {
            HStack {
                Text(Formatter.time(from: store.currentTime))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.textGrey)
                
                Slider(value: $store.currentTime.sending(\.currentTimeChanged), in: 0...(bookSummary.duration))
                    .animation(.linear, value: store.currentTime)
                    .tint(.accent)
                
                Text(Formatter.time(from: bookSummary.duration))
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
        HStack(spacing: 40) {
            Button {
                store.send(.seekBackwardTapped)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.black)
            }
            
            playPauseButton
            
            Button {
                store.send(.seekForwardTapped)
            } label: {
                Image(systemName: "arrow.clockwise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.black)
            }
        }
        .buttonStyle(PressEffectButtonStyle())
    }
    
    private var playPauseButton: some View {
        Button {
            store.send(.playPauseTapped)
        } label: {
            Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundStyle(.black)
                .offset(x: store.isPlaying ? 0 : 4)
        }
//        .buttonStyle(PressEffectButtonStyle())
        .contentTransition(.symbolEffect(.replace))
    }
}

struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut, value: configuration.isPressed)
            .background {
                Circle()
                    .foregroundStyle(.pressed)
                    .scaleEffect(configuration.isPressed ? 0.9 : 1, anchor: .center)
                    .opacity(configuration.isPressed ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            }
    }
}

#Preview {
    PlayerView(store: Store(
        initialState: Player.State(),
        reducer: { Player() }
    ))
}
