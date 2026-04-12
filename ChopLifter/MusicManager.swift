import AVFoundation

final class MusicManager {
    static let shared = MusicManager()

    private var backgroundPlayer: AVAudioPlayer?

    private init() {}

    func startBackgroundMusic() {
        guard backgroundPlayer == nil else {
            if backgroundPlayer?.isPlaying == false {
                backgroundPlayer?.play()
            }
            return
        }

        guard let url = Bundle.main.url(forResource: "fortunate-son", withExtension: "mp3") else {
            assertionFailure("Missing soundtrack resource: fortunate-son.mp3")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.7
            player.prepareToPlay()
            player.play()
            backgroundPlayer = player
        } catch {
            assertionFailure("Failed to load soundtrack: \(error)")
        }
    }
}
