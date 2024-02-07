import Foundation
import Combine
import AVFoundation
import ComposableArchitecture

final class PlayerManager {
    
    enum PlayerError: Error {
        case invalidUrl
    }
    
    enum Action {
        case timeChanged(Double)
        case rateChanged(Double)
    }
    
    // MARK: - Properties
    
    private let delegateSubject = PassthroughSubject<Action, Never>()
    private var statusObserver: NSKeyValueObservation?
    private var timeObserver: AnyCancellable?
    private var rateObserver: NSKeyValueObservation?
    
    private var player: AVPlayer? {
        didSet {
            setupRateObserver()
        }
    }
    private var session = AVAudioSession.sharedInstance()
    
    // MARK: - Initialization
    
    init() {
        setupTimeObserver()
    }
    
    deinit {
        timeObserver?.cancel()
        rateObserver?.invalidate()
    }
    
    // MARK: Public
    
    public func delegate() -> Effect<Action> {
        return .publisher { self.delegateSubject.receive(on: DispatchQueue.main) }
    }
    
    public func setItem(link: String) throws {
        if let url = URL(string: link) {
            let playerItem: AVPlayerItem = AVPlayerItem(url: url)
            if let player {
                player.replaceCurrentItem(with: playerItem)
            } else {
                player = AVPlayer(playerItem: playerItem)
            }
        } else {
            throw PlayerError.invalidUrl
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
    
    private func setupTimeObserver() {
        timeObserver = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let player = self.player else { return }
                let currentTime = player.currentTime().seconds
                self.delegateSubject.send(.timeChanged(currentTime))
            }
    }
    
    private func setupRateObserver() {
        rateObserver = player?.observe(\.defaultRate, options: [.initial, .new]) { [weak self] player, change in
            guard let self = self else { return }
            if let newRate = change.newValue {
                print("### newRate \(newRate)")
                self.delegateSubject.send(.rateChanged(Double(newRate)))
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
}
