import SpriteKit

class Barracks: SKNode {

    // MARK: - Visual nodes
    private var buildingNode: SKSpriteNode!
    private var roofNode: SKShapeNode!
    private var doorNode: SKSpriteNode!

    // MARK: - Properties
    var state: BarracksState = .closed
    var hostageCount: Int = GameConfig.hostagesPerBarracks

    /// The point where hostages emerge from.
    var exitPoint: CGPoint {
        return CGPoint(x: position.x, y: GameConfig.groundLevel + 12)
    }

    // MARK: - Init

    init(positionX: CGFloat) {
        super.init()
        let barracksHeight = GameConfig.barracksSize.height
        position = CGPoint(x: positionX, y: GameConfig.groundLevel + barracksHeight / 2)
        buildVisual()
        setupPhysics()
        zPosition = 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visual setup

    private func buildVisual() {
        let size = GameConfig.barracksSize

        // Building body
        buildingNode = SKSpriteNode(color: GameConfig.barracksColor, size: size)
        addChild(buildingNode)

        // Roof (triangle on top)
        let roofPath = CGMutablePath()
        let roofHalfWidth = size.width / 2 + 5
        let roofHeight: CGFloat = 20
        let roofBaseY = size.height / 2
        roofPath.move(to: CGPoint(x: -roofHalfWidth, y: roofBaseY))
        roofPath.addLine(to: CGPoint(x: 0, y: roofBaseY + roofHeight))
        roofPath.addLine(to: CGPoint(x: roofHalfWidth, y: roofBaseY))
        roofPath.closeSubpath()

        roofNode = SKShapeNode(path: roofPath)
        roofNode.fillColor = UIColor(red: 0.4, green: 0.22, blue: 0.14, alpha: 1.0)
        roofNode.strokeColor = .clear
        addChild(roofNode)

        // Door (bottom-center)
        let doorSize = CGSize(width: size.width * 0.3, height: size.height * 0.4)
        doorNode = SKSpriteNode(color: UIColor(red: 0.35, green: 0.2, blue: 0.12, alpha: 1.0), size: doorSize)
        doorNode.position = CGPoint(x: 0, y: -size.height / 2 + doorSize.height / 2)
        addChild(doorNode)
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: GameConfig.barracksSize)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.barracks
        body.contactTestBitMask = PhysicsCategory.playerBullet
        body.collisionBitMask = PhysicsCategory.none
        physicsBody = body
    }

    // MARK: - Interaction

    /// Call when hit by a player bullet. Returns true if the barracks was just opened.
    func hit() -> Bool {
        guard state == .closed else { return false }

        state = .opened

        // Visual change: building changes color to show damage
        buildingNode.color = GameConfig.barracksOpenColor

        // Door opens (becomes black to show open doorway)
        doorNode.color = .black

        // Slight shake effect
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 3, y: 0, duration: 0.03),
            SKAction.moveBy(x: -6, y: 0, duration: 0.03),
            SKAction.moveBy(x: 3, y: 0, duration: 0.03)
        ])
        buildingNode.run(SKAction.repeat(shake, count: 3))

        return true
    }

    /// Creates and returns hostage nodes positioned at the exit point.
    func releaseHostages() -> [Hostage] {
        guard state == .opened else { return [] }

        var hostages: [Hostage] = []
        for i in 0..<hostageCount {
            let hostage = Hostage()
            // Slight random horizontal spread so they don't all stack
            let spreadX = CGFloat(i - hostageCount / 2) * 6.0 + CGFloat.random(in: -3...3)
            let releasePos = CGPoint(x: exitPoint.x + spreadX, y: exitPoint.y)
            hostage.release(at: releasePos)
            hostages.append(hostage)
        }

        state = .empty
        hostageCount = 0
        return hostages
    }
}
