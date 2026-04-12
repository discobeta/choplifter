import SpriteKit

class DifficultyManager {

    var dangerLevel: Int = 0
    var rescueTrips: Int = 0
    var barracksOpenedCount: Int = 0

    // MARK: - Computed Difficulty Properties

    /// Tank spawn interval: starts at 12s, decreases by 1s per danger level, min 4s.
    var tankSpawnInterval: TimeInterval {
        return max(4.0, 12.0 - Double(dangerLevel) * 1.0)
    }

    /// Jet spawn interval: starts at 20s, decreases by 2s per danger level, min 6s.
    var jetSpawnInterval: TimeInterval {
        return max(6.0, 20.0 - Double(dangerLevel) * 2.0)
    }

    /// Tank fire interval: starts at 2.5s, decreases by 0.2s per danger level, min 1s.
    var tankFireInterval: TimeInterval {
        return max(1.0, 2.5 - Double(dangerLevel) * 0.2)
    }

    /// Max active tanks: starts at 2, +1 per danger level, max 8.
    var maxActiveTanks: Int {
        return min(8, 2 + dangerLevel)
    }

    /// Max active jets: starts at 1, +1 per 2 danger levels, max 4.
    var maxActiveJets: Int {
        return min(4, 1 + dangerLevel / 2)
    }

    /// Jet speed: starts at base jetSpeed, +30 per danger level, max 700.
    var jetSpeed: CGFloat {
        return min(700, GameConfig.jetSpeed + CGFloat(dangerLevel) * 30)
    }

    // MARK: - Events

    func onHostagesDelivered() {
        rescueTrips += 1
        dangerLevel += 1
    }

    func onBarracksOpened() {
        barracksOpenedCount += 1
        dangerLevel += 1
    }

    func reset() {
        dangerLevel = 0
        rescueTrips = 0
        barracksOpenedCount = 0
    }
}
