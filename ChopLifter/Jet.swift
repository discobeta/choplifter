import SpriteKit

class Jet: SKNode {

    // MARK: - Visual nodes
    private var bodyNode: SKShapeNode!

    // MARK: - Properties
    var flyingRight: Bool
    var hasDroppedBomb: Bool = false
    var flySpeed: CGFloat = GameConfig.jetSpeed
    private(set) var isCrashing = false
    private(set) var isDestroyed = false

    // MARK: - Init

    init(flyingRight: Bool, atY: CGFloat) {
        self.flyingRight = flyingRight
        super.init()

        let startX: CGFloat = flyingRight ? -100 : GameConfig.worldWidth + 100
        position = CGPoint(x: startX, y: atY)

        buildVisual()
        setupPhysics()
        zPosition = 4
    }

    required init?(coder aDecoder: NSCoder) {
        self.flyingRight = true
        super.init(coder: aDecoder)
    }

    // MARK: - Visual setup

    private func buildVisual() {
        let size = GameConfig.jetSize

        // Triangular jet shape
        let path = CGMutablePath()
        if flyingRight {
            // Points right
            path.move(to: CGPoint(x: -size.width / 2, y: -size.height / 2))
            path.addLine(to: CGPoint(x: size.width / 2, y: 0))
            path.addLine(to: CGPoint(x: -size.width / 2, y: size.height / 2))
            path.closeSubpath()
        } else {
            // Points left
            path.move(to: CGPoint(x: size.width / 2, y: -size.height / 2))
            path.addLine(to: CGPoint(x: -size.width / 2, y: 0))
            path.addLine(to: CGPoint(x: size.width / 2, y: size.height / 2))
            path.closeSubpath()
        }

        bodyNode = SKShapeNode(path: path)
        bodyNode.fillColor = GameConfig.jetColor
        bodyNode.strokeColor = .clear
        addChild(bodyNode)

        // Small wing detail
        let wingSize = CGSize(width: size.width * 0.4, height: size.height * 1.4)
        let wing = SKSpriteNode(color: GameConfig.jetColor.withAlphaComponent(0.8), size: wingSize)
        wing.position = CGPoint(x: flyingRight ? -size.width * 0.15 : size.width * 0.15, y: 0)
        addChild(wing)
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: GameConfig.jetSize)
        body.isDynamic = true
        body.allowsRotation = false
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.jet
        body.contactTestBitMask = PhysicsCategory.playerBullet
        body.collisionBitMask = PhysicsCategory.none
        physicsBody = body
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval) {
        guard !isCrashing, !isDestroyed else { return }

        let direction: CGFloat = flyingRight ? 1.0 : -1.0
        position.x += direction * flySpeed * CGFloat(deltaTime)

        // Remove if past world bounds (with margin)
        if flyingRight && position.x > GameConfig.worldWidth + 200 {
            removeFromParent()
        } else if !flyingRight && position.x < -200 {
            removeFromParent()
        }
    }

    // MARK: - Combat

    func fire(toward target: CGPoint) -> Bullet? {
        guard !isCrashing, !isDestroyed else { return nil }
        let dx = target.x - position.x
        let dy = target.y - position.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return nil }

        let direction = CGVector(dx: dx / length, dy: dy / length)
        let bullet = Bullet(owner: .enemy, direction: direction, speed: GameConfig.jetBulletSpeed)
        bullet.position = position
        return bullet
    }

    func dropBomb(atX targetX: CGFloat) -> Bullet? {
        guard !hasDroppedBomb, !isCrashing, !isDestroyed else { return nil }
        hasDroppedBomb = true

        let direction = CGVector(dx: 0, dy: -1)
        let bullet = Bullet(owner: .enemy, direction: direction, speed: GameConfig.jetBulletSpeed * 0.5)
        bullet.position = CGPoint(x: position.x, y: position.y - GameConfig.jetSize.height / 2 - 5)
        return bullet
    }

    func takeDamage() -> Bool {
        guard !isCrashing, !isDestroyed else { return false }
        isDestroyed = true
        explode()
        return true
    }

    func shootDown() -> Bool {
        guard !isCrashing, !isDestroyed else { return false }
        isCrashing = true
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.none
        flySpeed = 0

        let flash = SKSpriteNode(color: .orange, size: CGSize(width: 44, height: 44))
        flash.zPosition = 10
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.8, duration: 0.18),
                SKAction.fadeOut(withDuration: 0.22)
            ]),
            SKAction.removeFromParent()
        ]))

        let crashTargetY = GameConfig.groundLevel + GameConfig.jetSize.height / 2
        let fallDistance = max(position.y - crashTargetY, 0)
        let horizontalDrift: CGFloat = flyingRight ? 180 : -180
        let crashDuration = max(0.8, min(1.8, Double(fallDistance / 280)))

        let smoke = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in self?.spawnCrashSmoke() },
            SKAction.wait(forDuration: 0.06)
        ]))
        run(smoke, withKey: "crashSmoke")

        run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: horizontalDrift, y: -fallDistance, duration: crashDuration),
                SKAction.rotate(byAngle: flyingRight ? -.pi * 1.6 : .pi * 1.6, duration: crashDuration)
            ]),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.removeAction(forKey: "crashSmoke")
                self.crashImpact()
            }
        ]))
        return true
    }

    private func explode() {
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.none
        flySpeed = 0

        // Explosion effect
        let explosion = SKSpriteNode(color: .orange, size: CGSize(width: 50, height: 50))
        explosion.zPosition = 10
        addChild(explosion)

        let expand = SKAction.scale(to: 2.0, duration: 0.2)
        let fadeExplosion = SKAction.fadeOut(withDuration: 0.3)
        explosion.run(SKAction.sequence([SKAction.group([expand, fadeExplosion]), SKAction.removeFromParent()]))

        // Body fades and falls
        let fall = SKAction.moveBy(x: 0, y: -200, duration: 0.8)
        let fade = SKAction.fadeOut(withDuration: 0.8)
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([SKAction.group([fall, fade]), remove]))
    }

    private func spawnCrashSmoke() {
        guard parent != nil else { return }
        let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...7))
        puff.fillColor = UIColor(white: 0.25, alpha: 0.7)
        puff.strokeColor = .clear
        puff.position = position
        puff.zPosition = zPosition - 0.1
        parent?.addChild(puff)

        puff.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 20...40), duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.scale(to: 2.2, duration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func crashImpact() {
        isDestroyed = true

        let explosion = SKSpriteNode(color: .orange, size: CGSize(width: 65, height: 65))
        explosion.zPosition = 10
        explosion.position = .zero
        addChild(explosion)
        explosion.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.4, duration: 0.25),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        bodyNode.run(SKAction.colorize(with: .black, colorBlendFactor: 0.7, duration: 0.1))
        run(SKAction.fadeOut(withDuration: 0.35))

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.removeFromParent()
        ]))
    }
}
