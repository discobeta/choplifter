import SpriteKit

class Bullet: SKNode {

    // MARK: - Visual nodes
    private var spriteNode: SKSpriteNode!

    // MARK: - Properties
    let owner: BulletOwner
    let kind: ProjectileKind
    var damage: Int = 1

    // MARK: - Init

    init(owner: BulletOwner, direction: CGVector, speed: CGFloat, kind: ProjectileKind = .bullet) {
        self.owner = owner
        self.kind = kind
        super.init()

        buildVisual()
        setupPhysics(direction: direction, speed: speed)

        // Auto-cleanup after 3 seconds
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.removeFromParent()
        ]))

        zPosition = 3
    }

    required init?(coder aDecoder: NSCoder) {
        self.owner = .player
        self.kind = .bullet
        super.init(coder: aDecoder)
    }

    // MARK: - Visual setup

    private func buildVisual() {
        let color: UIColor
        let size: CGSize

        switch (owner, kind) {
        case (.player, .bomb):
            color = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
            size = GameConfig.playerBombSize
        case (.player, .bullet):
            color = GameConfig.playerBulletColor
            size = GameConfig.bulletSize
        case (.enemy, _):
            color = GameConfig.enemyBulletColor
            size = GameConfig.bulletSize
        }

        spriteNode = SKSpriteNode(color: color, size: size)
        addChild(spriteNode)
    }

    private func setupPhysics(direction: CGVector, speed: CGFloat) {
        let bodySize = kind == .bomb ? GameConfig.playerBombSize : GameConfig.bulletSize
        let body = SKPhysicsBody(rectangleOf: bodySize)
        body.isDynamic = true
        body.affectedByGravity = kind == .bomb
        body.allowsRotation = false
        body.usesPreciseCollisionDetection = true

        switch owner {
        case .player:
            if kind == .bomb {
                body.categoryBitMask = PhysicsCategory.playerBomb
                body.contactTestBitMask = PhysicsCategory.ground | PhysicsCategory.tank | PhysicsCategory.barracks | PhysicsCategory.hostage
            } else {
                body.categoryBitMask = PhysicsCategory.playerBullet
                body.contactTestBitMask = PhysicsCategory.tank | PhysicsCategory.jet | PhysicsCategory.barracks | PhysicsCategory.hostage
            }
            body.collisionBitMask = PhysicsCategory.none
        case .enemy:
            body.categoryBitMask = PhysicsCategory.enemyBullet
            body.contactTestBitMask = PhysicsCategory.helicopter | PhysicsCategory.hostage
            body.collisionBitMask = PhysicsCategory.none
        }

        // Normalize direction and apply speed
        let length = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)
        guard length > 0 else {
            physicsBody = body
            return
        }

        let normalized = CGVector(dx: direction.dx / length, dy: direction.dy / length)
        body.velocity = CGVector(dx: normalized.dx * speed, dy: normalized.dy * speed)

        // Rotate sprite to match direction
        let angle = atan2(normalized.dy, normalized.dx)
        spriteNode.zRotation = angle

        physicsBody = body
    }
}
