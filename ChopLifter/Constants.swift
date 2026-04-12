import SpriteKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none: UInt32 = 0
    static let helicopter: UInt32 = 1 << 0
    static let ground: UInt32 = 1 << 1
    static let hostage: UInt32 = 1 << 2
    static let playerBullet: UInt32 = 1 << 3
    static let playerBomb: UInt32 = 1 << 4
    static let enemyBullet: UInt32 = 1 << 5
    static let tank: UInt32 = 1 << 6
    static let jet: UInt32 = 1 << 7
    static let barracks: UInt32 = 1 << 8
    static let base: UInt32 = 1 << 9
}

// MARK: - Game Configuration
struct GameConfig {
    // World
    static let worldWidth: CGFloat = 8000
    static let groundLevel: CGFloat = 100
    static let sceneSize = CGSize(width: 1920, height: 1080)

    // Positions
    static let baseX: CGFloat = 600
    static let barracksPositions: [CGFloat] = [2500, 4000, 5500, 7000]

    // Helicopter
    static let maxPassengers = 16
    static let playerLives = 3
    static let helicopterHealth = 3
    static let helicopterSpeed: CGFloat = 350
    static let helicopterSize = CGSize(width: 80, height: 35)
    static let rotorWidth: CGFloat = 70

    // Hostages
    static let hostagesPerBarracks = 16
    static let totalBarracks = 4
    static let hostageWalkSpeed: CGFloat = 50
    static let hostageBoardingRange: CGFloat = 250
    static let hostageSize = CGSize(width: 12, height: 24)

    // Bullets
    static let playerBulletSpeed: CGFloat = 800
    static let bulletSize = CGSize(width: 6, height: 3)
    static let playerFireRate: TimeInterval = 0.15
    static let playerBombSpeed: CGFloat = 220
    static let playerBombSize = CGSize(width: 12, height: 16)
    static let playerBombCooldown: TimeInterval = 0.35
    static let playerBombBlastRadius: CGFloat = 130

    // Tanks
    static let tankSpeed: CGFloat = 60
    static let tankBulletSpeed: CGFloat = 300
    static let tankSize = CGSize(width: 60, height: 30)
    static let tankTurretSize = CGSize(width: 30, height: 12)
    static let tankHealth = 2
    static let tankFireInterval: TimeInterval = 2.5

    // Jets
    static let jetSpeed: CGFloat = 450
    static let jetBulletSpeed: CGFloat = 400
    static let jetSize = CGSize(width: 50, height: 20)

    // Base
    static let baseSize = CGSize(width: 200, height: 20)
    static let basePadSize = CGSize(width: 120, height: 8)
    static let baseDefenseRadius: CGFloat = 1000
    static let baseMissileInterval: TimeInterval = 2.5
    static let baseMissileFlightTime: TimeInterval = 1.2
    static let baseAirDefenseRadius: CGFloat = 1500
    static let baseAirMissileInterval: TimeInterval = 1.0
    static let baseAirMissileSpeed: CGFloat = 950
    static let baseAirMissileMaxFlightTime: TimeInterval = 3.0

    // Barracks
    static let barracksSize = CGSize(width: 100, height: 60)

    // Scoring
    static let scorePerTankKill = 100
    static let scorePerJetKill = 200
    static let scorePerHostageRescued = 500
    static let scorePerHostageLoaded = 50
    static let scorePerBarracksOpened = 150

    // Colors
    static let skyColor = UIColor(red: 0.35, green: 0.55, blue: 0.85, alpha: 1.0)
    static let groundColor = UIColor(red: 0.3, green: 0.5, blue: 0.2, alpha: 1.0)
    static let dirtColor = UIColor(red: 0.45, green: 0.35, blue: 0.2, alpha: 1.0)
    static let heliColor = UIColor(red: 0.25, green: 0.45, blue: 0.25, alpha: 1.0)
    static let heliDarkColor = UIColor(red: 0.15, green: 0.3, blue: 0.15, alpha: 1.0)
    static let hostageColor = UIColor.yellow
    static let tankColor = UIColor(red: 0.35, green: 0.35, blue: 0.3, alpha: 1.0)
    static let tankDarkColor = UIColor(red: 0.25, green: 0.25, blue: 0.2, alpha: 1.0)
    static let jetColor = UIColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0)
    static let barracksColor = UIColor(red: 0.5, green: 0.3, blue: 0.2, alpha: 1.0)
    static let barracksOpenColor = UIColor(red: 0.35, green: 0.2, blue: 0.12, alpha: 1.0)
    static let baseColor = UIColor(red: 0.25, green: 0.25, blue: 0.55, alpha: 1.0)
    static let basePadColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    static let playerBulletColor = UIColor.yellow
    static let enemyBulletColor = UIColor.red
    static let rotorColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
}

// MARK: - Enums
enum HeliState {
    case flying, hovering, landing, grounded, takingOff, destroyed
}

enum FacingDirection {
    case left, right, forward
}

enum HostageState {
    case inBuilding, released, walking, boarding, onboard, rescued, dead
}

enum BarracksState {
    case closed, opened, empty
}

enum BulletOwner {
    case player, enemy
}

enum ProjectileKind {
    case bullet, bomb
}

// MARK: - Input Delegate
protocol InputDelegate: AnyObject {
    func inputMovement(dx: CGFloat, dy: CGFloat)
    func inputFire()
    func inputStopFire()
    func inputFacingChanged(_ direction: FacingDirection)
    func inputPause()
}
