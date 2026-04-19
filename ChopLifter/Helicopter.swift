import SpriteKit

class Helicopter: SKNode {

    // MARK: - Sprite textures

    private let texRight: SKTexture = {
        let t = SKTexture(imageNamed: "heli_left"); t.filteringMode = .nearest; return t
    }()
    private let texLeft: SKTexture = {
        let t = SKTexture(imageNamed: "heli_right"); t.filteringMode = .nearest; return t
    }()
    private let texHalfRight: SKTexture = {
        let t = SKTexture(imageNamed: "heli_half_left"); t.filteringMode = .nearest; return t
    }()
    private let texHalfLeft: SKTexture = {
        let t = SKTexture(imageNamed: "heli_half_right"); t.filteringMode = .nearest; return t
    }()

    // MARK: - Visual nodes

    private var bodyNode: SKSpriteNode!

    /// Display size when high in the air.
    private let flightSpriteSize = CGSize(width: 140, height: 58)

    /// Display size when close to the landing pad / grounded.
    private let groundSpriteSize = CGSize(width: 104, height: 43)
    private var isUsingCompactVisuals = false

    // MARK: - Properties

    var state: HeliState = .flying
    var facing: FacingDirection = .right
    var health: Int = GameConfig.helicopterHealth
    var passengers: Int = 0
    var isInvulnerable: Bool = false

    /// Tracks whether a facing-transition animation is playing
    private var isTransitioning = false

    /// Brief cooldown after a transition finishes to prevent ping-pong flicker
    private var transitionCooldown: TimeInterval = 0

    /// Remembers last lateral direction so forward-facing picks the right half sprite
    private var lastLateralFacing: FacingDirection = .right

    /// Current visual tilt angle (radians). Positive = nose tilts left-down, negative = nose tilts right-down.
    private var currentTiltAngle: CGFloat = 0

    // MARK: - Computed properties

    var isGrounded: Bool { state == .grounded }
    var isFull: Bool { passengers >= GameConfig.maxPassengers }
    var canBoard: Bool { isGrounded && !isFull && state != .destroyed }
    var maxHealth: Int { GameConfig.helicopterHealth }

    // MARK: - Init

    override init() {
        super.init()
        buildVisual()
        setupPhysics()
        zPosition = 5
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visual setup

    private func buildVisual() {
        bodyNode = SKSpriteNode(texture: texRight, size: flightSpriteSize)
        bodyNode.name = "heliBody"
        addChild(bodyNode)
        isUsingCompactVisuals = false
        updateVisualSize()
    }

    private func setupPhysics() {
        let physSize = CGSize(width: flightSpriteSize.width * 0.65, height: flightSpriteSize.height * 0.65)
        let body = SKPhysicsBody(rectangleOf: physSize)
        body.isDynamic = true
        body.allowsRotation = false
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.helicopter
        body.contactTestBitMask = PhysicsCategory.ground | PhysicsCategory.enemyBullet | PhysicsCategory.hostage
        body.collisionBitMask = PhysicsCategory.ground
        physicsBody = body
    }

    // MARK: - Movement

    func applyMovement(dx: CGFloat, dy: CGFloat, deltaTime: TimeInterval) {
        guard state != .destroyed else { return }

        if isGrounded {
            if dy > 0 {
                takeOff()
            } else {
                return
            }
        }

        // Tick down transition cooldown
        if transitionCooldown > 0 {
            transitionCooldown -= deltaTime
        }

        // Update facing based on horizontal input (wide dead zone to prevent jitter flicker)
        if dx < -0.3 {
            setFacing(.left)
        } else if dx > 0.3 {
            setFacing(.right)
        }

        let speed = GameConfig.helicopterSpeed
        var newX = position.x + dx * speed * CGFloat(deltaTime)
        var newY = position.y + dy * speed * CGFloat(deltaTime)

        // Apply gravity when not thrusting up
        if dy <= 0 && !isGrounded {
            newY -= 120.0 * CGFloat(deltaTime)
        }

        // Clamp to world bounds
        let minY = GameConfig.groundLevel + 20
        let maxY = GameConfig.sceneSize.height - 50
        newX = max(0, min(newX, GameConfig.worldWidth))
        newY = max(minY, min(newY, maxY))

        position = CGPoint(x: newX, y: newY)
        updateTilt(dx: dx, deltaTime: deltaTime)
        updateVisualSize()
    }

    // MARK: - Directional Tilt

    private func updateTilt(dx: CGFloat, deltaTime: TimeInterval) {
        // Target angle: moving right → negative (clockwise), left → positive (counter-clockwise)
        let targetAngle: CGFloat
        if dx > 0.3 {
            targetAngle = -GameConfig.helicopterTiltAngle
        } else if dx < -0.3 {
            targetAngle = GameConfig.helicopterTiltAngle
        } else {
            targetAngle = 0
        }

        // Lerp toward target
        let lerpSpeed = GameConfig.helicopterTiltLerpSpeed * CGFloat(deltaTime)
        currentTiltAngle += (targetAngle - currentTiltAngle) * min(lerpSpeed, 1.0)

        // Snap to zero when very close to avoid micro-jitter
        if abs(currentTiltAngle) < 0.001 && targetAngle == 0 {
            currentTiltAngle = 0
        }

        bodyNode.zRotation = currentTiltAngle
    }

    // MARK: - Facing with transition animation

    func setFacing(_ direction: FacingDirection) {
        guard direction != facing, !isTransitioning, transitionCooldown <= 0 else { return }

        let oldFacing = facing
        facing = direction

        if direction == .left || direction == .right {
            lastLateralFacing = direction
        }

        // Build the transition frame sequence
        switch (oldFacing, direction) {
        case (.right, .left):
            animateTransition(frames: [texHalfRight, texHalfLeft, texLeft])
        case (.left, .right):
            animateTransition(frames: [texHalfLeft, texHalfRight, texRight])
        case (.right, .forward):
            animateTransition(frames: [texHalfRight])
        case (.left, .forward):
            animateTransition(frames: [texHalfLeft])
        case (.forward, .right):
            animateTransition(frames: [texHalfRight, texRight])
        case (.forward, .left):
            animateTransition(frames: [texHalfLeft, texLeft])
        default:
            break
        }
    }

    private func animateTransition(frames: [SKTexture]) {
        isTransitioning = true
        bodyNode.removeAction(forKey: "facingTransition")

        let frameTime: TimeInterval = 0.08
        var actions: [SKAction] = []
        for tex in frames {
            actions.append(SKAction.setTexture(tex, resize: false))
            actions.append(SKAction.wait(forDuration: frameTime))
        }
        actions.append(SKAction.run { [weak self] in
            self?.isTransitioning = false
            self?.transitionCooldown = 0.2
            self?.updateVisualSize()
        })

        bodyNode.run(SKAction.sequence(actions), withKey: "facingTransition")
    }

    private func updateVisualSize() {
        let targetSize = currentDisplaySize()
        guard bodyNode.size != targetSize else { return }

        bodyNode.removeAction(forKey: "sizeTransition")
        let resizeDuration: TimeInterval = isTransitioning ? 0.14 : 0.08
        bodyNode.run(SKAction.resize(toWidth: targetSize.width, height: targetSize.height, duration: resizeDuration),
                     withKey: "sizeTransition")
    }

    private func currentDisplaySize() -> CGSize {
        if state == .grounded {
            isUsingCompactVisuals = true
            return groundSpriteSize
        }

        // Use hysteresis so hovering near the low-altitude boundary doesn't cause
        // frame-to-frame size popping while turning or bobbing.
        let compactEnterThreshold = GameConfig.groundLevel + 135
        let compactExitThreshold = GameConfig.groundLevel + 165

        if isUsingCompactVisuals {
            if position.y >= compactExitThreshold {
                isUsingCompactVisuals = false
            }
        } else if position.y <= compactEnterThreshold {
            isUsingCompactVisuals = true
        }

        return isUsingCompactVisuals ? groundSpriteSize : flightSpriteSize
    }

    // MARK: - Combat

    func fire() -> Bullet? {
        guard state != .destroyed else { return nil }

        let halfW = bodyNode.size.width / 2
        let halfH = bodyNode.size.height / 2
        let bulletOffset: CGPoint
        let bulletDirection: CGVector

        switch facing {
        case .right:
            // Tilt adjusts firing angle: negative tilt → nose down-right
            let angle = currentTiltAngle  // negative when tilting right
            bulletOffset = CGPoint(x: halfW + 5, y: 0)
            bulletDirection = CGVector(dx: cos(angle), dy: sin(angle))
        case .left:
            let angle = CGFloat.pi + currentTiltAngle  // positive tilt when moving left
            bulletOffset = CGPoint(x: -(halfW + 5), y: 0)
            bulletDirection = CGVector(dx: cos(angle), dy: sin(angle))
        case .forward:
            bulletOffset = CGPoint(x: 0, y: -(halfH + 5))
            bulletDirection = CGVector(dx: 0, dy: -1)
        }

        let bullet = Bullet(owner: .player, direction: bulletDirection, speed: GameConfig.playerBulletSpeed)
        bullet.position = CGPoint(x: position.x + bulletOffset.x, y: position.y + bulletOffset.y)
        return bullet
    }

    func dropBomb() -> Bullet? {
        guard state != .destroyed, !isGrounded else { return nil }

        let xDrift: CGFloat
        switch facing {
        case .left:
            xDrift = -0.25
        case .right:
            xDrift = 0.25
        case .forward:
            xDrift = 0
        }

        let bomb = Bullet(
            owner: .player,
            direction: CGVector(dx: xDrift, dy: -1),
            speed: GameConfig.playerBombSpeed,
            kind: .bomb
        )
        bomb.position = CGPoint(x: position.x, y: position.y - bodyNode.size.height / 2 - 10)
        return bomb
    }

    func takeDamage() -> Bool {
        guard !isInvulnerable, state != .destroyed else { return false }

        health -= 1
        isInvulnerable = true

        // Flash red
        let flashRed = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.05)
        ])
        bodyNode.run(SKAction.repeat(flashRed, count: 5))

        // Brief invulnerability
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in self?.isInvulnerable = false }
        ]), withKey: "invulnerability")

        if health <= 0 {
            destroy()
            return true
        }
        return false
    }

    func repairToFull() -> Bool {
        guard state != .destroyed, health < maxHealth else { return false }
        health = maxHealth
        bodyNode.colorBlendFactor = 0
        bodyNode.alpha = 1.0
        bodyNode.removeAction(forKey: "repairFlash")
        return true
    }

    private func destroy() {
        state = .destroyed
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.none

        // Explosion effect
        let flash = SKSpriteNode(color: .orange, size: CGSize(width: 120, height: 120))
        flash.zPosition = 10
        addChild(flash)

        let expand = SKAction.scale(to: 2.0, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        flash.run(SKAction.sequence([expand, fadeOut, SKAction.removeFromParent()]))

        bodyNode.run(SKAction.sequence([
            SKAction.colorize(with: .orange, colorBlendFactor: 1.0, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.8)
        ]))
    }

    // MARK: - Landing / takeoff

    func land() {
        state = .grounded
        currentTiltAngle = 0
        bodyNode.zRotation = 0
        updateVisualSize()
    }

    func takeOff() {
        state = .flying
        updateVisualSize()
    }

    // MARK: - Passengers

    func loadPassenger() {
        if passengers < GameConfig.maxPassengers {
            passengers += 1
        }
    }

    func unloadAll() -> Int {
        let count = passengers
        passengers = 0
        return count
    }

    // MARK: - Reset

    func reset(at newPosition: CGPoint) {
        position = newPosition
        health = GameConfig.helicopterHealth
        passengers = 0
        state = .flying
        facing = .right
        lastLateralFacing = .right
        isInvulnerable = false
        isTransitioning = false
        transitionCooldown = 0
        alpha = 1.0

        bodyNode.texture = texRight
        bodyNode.colorBlendFactor = 0
        bodyNode.alpha = 1.0
        bodyNode.zRotation = 0
        bodyNode.size = flightSpriteSize
        bodyNode.removeAllActions()
        isUsingCompactVisuals = false
        currentTiltAngle = 0

        removeAction(forKey: "invulnerability")
        setupPhysics()
        updateVisualSize()
    }
}
