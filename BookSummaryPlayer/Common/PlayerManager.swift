import Foundation
import Combine
import AVFoundation
import ComposableArchitecture

final class PlayerManager {
    
    enum Action: Equatable {
        case timeChanged(Double)
        case rateChanged(Double)
        case controlStatusChanged(AVPlayer.TimeControlStatus)
        case error(PlayerError)
    }
    
    // MARK: - Properties
    
    let delegateSubject = PassthroughSubject<Action, Never>()
    
    private var player: AVPlayer? {
        didSet {
            if player != nil {
                setupTimeObserver()
                setupRateObserver()
                setupTimeControlObserver()
            } else {
                observers.forEach { $0?.cancel() }
            }
        }
    }
    
    private let session = AVAudioSession.sharedInstance()
    
    private var timeObserver: AnyCancellable?
    private var rateObserver: AnyCancellable?
    private var timeControlObserver: AnyCancellable?
    var observers: [AnyCancellable?] {
        [timeObserver, rateObserver, timeControlObserver]
    }
    
    // MARK: Public
    
    public func delegate() -> Effect<Action> {
        return .publisher { self.delegateSubject.receive(on: DispatchQueue.main) }
    }
    
    public func setItem(link: String) {
        if let url = URL(string: link) {
            let playerItem: AVPlayerItem = AVPlayerItem(url: url)
            if let player {
                player.replaceCurrentItem(with: playerItem)
            } else {
                player = AVPlayer(playerItem: playerItem)
            }
            setupAudioSession()
        } else {
            player = nil
            delegateSubject.send(.error(.badUrl))
        }
    }
    
    public func startAudio() {
        player?.play()
    }
    
    public func pauseAudio() {
        player?.pause()
    }
    
    public func seek(to value: Double) {
        let time = CMTime(seconds: value, preferredTimescale: 60000)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    public func seekBackward(for value: Double) {
        if let currentTime = player?.currentTime().seconds {
            let time = CMTime(seconds: currentTime - value, preferredTimescale: 60000)
            player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }
    
    public func seekForward(for value: Double) {
        if let currentTime = player?.currentTime().seconds {
            let time = CMTime(seconds: currentTime + value, preferredTimescale: 60000)
            player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }
    
    public func changeRate(to rate: Double) {
        if let currentRate = player?.rate, currentRate > 0 {
            player?.rate = Float(rate)
        }
        player?.defaultRate = Float(rate)
    }
    
    // MARK: Private
    
    private func setupAudioSession() {
        do {
            if session.category != .playback, session.mode != .spokenAudio {
                try session.setCategory(.playback, mode: .spokenAudio)
            }
        } catch {
            delegateSubject.send(.error(.failedAudioSession))
        }
    }
    
    func setupTimeObserver() {
        timeObserver = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let player = self.player else { return }
                let currentTime = player.currentTime().seconds
                self.delegateSubject.send(.timeChanged(currentTime))
            }
    }
    
    private func setupRateObserver() {
        rateObserver = player?.publisher(for: \.defaultRate, options: [.initial, .new]).sink { [weak self] newValue in
            guard let self = self else { return }
            self.delegateSubject.send(.rateChanged(Double(newValue)))
        }
    }
    
    private func setupTimeControlObserver() {
        timeControlObserver = player?.publisher(for: \.timeControlStatus).sink { [weak self] newValue in
            guard let self = self else { return }
            self.delegateSubject.send(.controlStatusChanged(newValue))
        }
    }
}

extension PlayerManager {
    enum PlayerError: Error {
        case badUrl
        case failedAudioSession
        
        var message: String {
            switch self {
            case .badUrl:
                "There are some problems with summary's URL, please try again later."
            case .failedAudioSession:
                "Something went wrong with your audio session!"
            }
        }
    }
}

extension DependencyValues {
    var playerManager: PlayerManager {
        get { self[PlayerManager.self] }
        set { self[PlayerManager.self] = newValue }
    }
}

extension PlayerManager: DependencyKey {
    static var liveValue: PlayerManager {
        Self()
    }
    
    static var testValue: PlayerManager {
        Self()
    }
}
