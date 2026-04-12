import SpriteKit

class Tank: SKNode {

    // MARK: - Sprite textures

    private let texLeftUp: SKTexture = {
        let t = SKTexture(imageNamed: "tank_left_up"); t.filteringMode = .nearest; return t
    }()
    private let texRightUp: SKTexture = {
        let t = SKTexture(imageNamed: "tank_right_up"); t.filteringMode = .nearest; return t
    }()
    private let texLeftLevel: SKTexture = {
        let t = SKTexture(imageNamed: "tank_left_level"); t.filteringMode = .nearest; return t
    }()
    private let texRightLevel: SKTexture = {
        let t = SKTexture(imageNamed: "tank_right_level"); t.filteringMode = .nearest; return t
    }()

    // MARK: - Visual nodes

    private var bodyNode: SKSpriteNode!

    /// Display size on screen
    private let spriteSize = CGSize(width: 100, height: 45)

    // MARK: - Properties

    var health: Int = GameConfig.tankHealth
    var lastFireTime: TimeInterval = 0
    var movingRight: Bool = Bool.random()
    var patrolMinX: CGFloat = 0
    var patrolMaxX: CGFloat = GameConfig.worldWidth

    /// Track which texture is currently shown to avoid redundant swaps.
    private var currentTextureName: String = ""
    private var isTurretElevated = false

    // MARK: - Init

    init(at positionX: CGFloat) {
        super.init()
        position = CGPoint(x: positionX, y: GameConfig.groundLevel + spriteSize.height / 2)
        buildVisual()
        setupPhysics()
        zPosition = 2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visual setup

    private func buildVisual() {
        let startTex = movingRight ? texRightLevel : texLeftLevel
        bodyNode = SKSpriteNode(texture: startTex, size: spriteSize)
        bodyNode.name = "tankBody"
        addChild(bodyNode)
        currentTextureName = movingRight ? "rl" : "ll"
    }

    private func setupPhysics() {
        let physSize = CGSize(width: spriteSize.width * 0.8, height: spriteSize.height * 0.7)
        let body = SKPhysicsBody(rectangleOf: physSize)
        body.isDynamic = true
        body.allowsRotation = false
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.tank
        body.contactTestBitMask = PhysicsCategory.playerBullet
        body.collisionBitMask = PhysicsCategory.ground
        physicsBody = body
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval, helicopterPosition: CGPoint) {
        // Patrol movement
        let speed = GameConfig.tankSpeed
        let moveDir: CGFloat = movingRight ? 1.0 : -1.0
        position.x += moveDir * speed * CGFloat(deltaTime)

        // Reverse at patrol bounds
        if position.x >= patrolMaxX {
            position.x = patrolMaxX
            setMovingRight(false)
        } else if position.x <= patrolMinX {
            position.x = patrolMinX
            setMovingRight(true)
        }

        // Keep on ground
        position.y = GameConfig.groundLevel + spriteSize.height / 2

        // Pick the correct sprite based on direction and aim angle
        updateTexture(helicopterPosition: helicopterPosition)
    }

    private func updateTexture(helicopterPosition: CGPoint) {
        let dy = helicopterPosition.y - position.y
        let dx = abs(helicopterPosition.x - position.x)
        // Barrel elevated when helicopter is significantly above and not too far away
        let aimAngle = atan2(dy, max(dx, 1))
        let elevated = aimAngle > 0.35  // roughly 20 degrees
        isTurretElevated = elevated

        applyTexture(movingRight: movingRight, elevated: elevated)
    }

    private func setMovingRight(_ movingRight: Bool) {
        guard self.movingRight != movingRight else { return }
        self.movingRight = movingRight
        applyTexture(movingRight: movingRight, elevated: isTurretElevated)
    }

    private func applyTexture(movingRight: Bool, elevated: Bool) {
        let key: String
        let tex: SKTexture
        if movingRight {
            if elevated {
                key = "ru"; tex = texRightUp
            } else {
                key = "rl"; tex = texRightLevel
            }
        } else {
            if elevated {
                key = "lu"; tex = texLeftUp
            } else {
                key = "ll"; tex = texLeftLevel
            }
        }

        if key != currentTextureName {
            currentTextureName = key
            bodyNode.texture = tex
        }
    }

    // MARK: - Combat

    func fire(at currentTime: TimeInterval, toward helicopterPosition: CGPoint) -> Bullet? {
        guard currentTime - lastFireTime >= GameConfig.tankFireInterval else { return nil }

        lastFireTime = currentTime

        let dx = helicopterPosition.x - position.x
        let dy = helicopterPosition.y - position.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return nil }

        let direction = CGVector(dx: dx / length, dy: dy / length)

        let bullet = Bullet(owner: .enemy, direction: direction, speed: GameConfig.tankBulletSpeed)
        // Spawn bullet from barrel tip area
        let barrelTipX: CGFloat = movingRight ? spriteSize.width * 0.55 : -spriteSize.width * 0.55
        bullet.position = CGPoint(
            x: position.x + barrelTipX,
            y: position.y + spriteSize.height * 0.2
        )

        return bullet
    }

    func takeDamage() -> Bool {
        health -= 1

        // Flash white
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.05)
        ])
        bodyNode.run(SKAction.repeat(flash, count: 3))

        if health <= 0 {
            explode()
            return true
        }
        return false
    }

    private func explode() {
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.none

        // Explosion effect
        let explosion = SKSpriteNode(color: .orange, size: CGSize(width: 70, height: 70))
        explosion.zPosition = 10
        addChild(explosion)

        let expand = SKAction.scale(to: 2.5, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        explosion.run(SKAction.sequence([SKAction.group([expand, fadeOut]), SKAction.removeFromParent()]))

        // Body fades out
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
}
