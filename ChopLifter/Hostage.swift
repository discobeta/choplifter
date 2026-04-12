import SpriteKit

class Hostage: SKNode {

    // MARK: - Visual nodes
    private var spriteRoot: SKNode!
    private var torsoNode: SKSpriteNode!
    private var leftLegNode: SKSpriteNode!
    private var rightLegNode: SKSpriteNode!

    // MARK: - Properties
    var state: HostageState = .inBuilding

    /// Called when the hostage is ready to board the helicopter.
    var onBoard: (() -> Void)?

    // MARK: - Init

    override init() {
        super.init()
        buildVisual()
        isHidden = true
        zPosition = 2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visual setup

    private func buildVisual() {
        spriteRoot = SKNode()
        spriteRoot.zPosition = 1
        addChild(spriteRoot)

        let helmetColor = UIColor(red: 0.32, green: 0.44, blue: 0.22, alpha: 1.0)
        let faceColor = UIColor(red: 0.92, green: 0.78, blue: 0.62, alpha: 1.0)
        let shirtColor = UIColor(red: 0.66, green: 0.61, blue: 0.45, alpha: 1.0)
        let pantsColor = UIColor(red: 0.28, green: 0.38, blue: 0.2, alpha: 1.0)
        let bootColor = UIColor(red: 0.14, green: 0.1, blue: 0.08, alpha: 1.0)
        let rifleColor = UIColor(red: 0.22, green: 0.16, blue: 0.1, alpha: 1.0)

        let helmet = SKSpriteNode(color: helmetColor, size: CGSize(width: 10, height: 4))
        helmet.position = CGPoint(x: 0, y: 10)
        spriteRoot.addChild(helmet)

        let head = SKSpriteNode(color: faceColor, size: CGSize(width: 8, height: 5))
        head.position = CGPoint(x: 0, y: 6)
        spriteRoot.addChild(head)

        torsoNode = SKSpriteNode(color: shirtColor, size: CGSize(width: 8, height: 7))
        torsoNode.position = CGPoint(x: 0, y: 0)
        spriteRoot.addChild(torsoNode)

        let leftArm = SKSpriteNode(color: shirtColor, size: CGSize(width: 2, height: 6))
        leftArm.position = CGPoint(x: -5, y: 0)
        spriteRoot.addChild(leftArm)

        let rightArm = SKSpriteNode(color: shirtColor, size: CGSize(width: 2, height: 6))
        rightArm.position = CGPoint(x: 5, y: 0)
        spriteRoot.addChild(rightArm)

        leftLegNode = SKSpriteNode(color: pantsColor, size: CGSize(width: 3, height: 7))
        leftLegNode.position = CGPoint(x: -2, y: -8)
        spriteRoot.addChild(leftLegNode)

        rightLegNode = SKSpriteNode(color: pantsColor, size: CGSize(width: 3, height: 7))
        rightLegNode.position = CGPoint(x: 2, y: -8)
        spriteRoot.addChild(rightLegNode)

        let leftBoot = SKSpriteNode(color: bootColor, size: CGSize(width: 3, height: 2))
        leftBoot.position = CGPoint(x: -2, y: -12)
        spriteRoot.addChild(leftBoot)

        let rightBoot = SKSpriteNode(color: bootColor, size: CGSize(width: 3, height: 2))
        rightBoot.position = CGPoint(x: 2, y: -12)
        spriteRoot.addChild(rightBoot)

        let rifle = SKSpriteNode(color: rifleColor, size: CGSize(width: 10, height: 2))
        rifle.position = CGPoint(x: 7, y: 1)
        rifle.zRotation = -0.15
        spriteRoot.addChild(rifle)

        spriteRoot.setScale(1.1)
    }

    // MARK: - State management

    func release(at releasePosition: CGPoint) {
        position = releasePosition
        state = .released
        isHidden = false

        // Set up physics body
        let body = SKPhysicsBody(rectangleOf: GameConfig.hostageSize)
        body.isDynamic = true
        body.allowsRotation = false
        body.affectedByGravity = true
        body.categoryBitMask = PhysicsCategory.hostage
        body.contactTestBitMask = PhysicsCategory.playerBullet | PhysicsCategory.enemyBullet | PhysicsCategory.helicopter
        body.collisionBitMask = PhysicsCategory.ground
        physicsBody = body
    }

    func update(deltaTime: TimeInterval, helicopterPosition: CGPoint?, helicopterCanBoard: Bool) {
        switch state {
        case .released:
            // Stand still; wait for helicopter to land nearby
            physicsBody?.velocity = CGVector(dx: 0, dy: physicsBody?.velocity.dy ?? 0)
            if let heliPos = helicopterPosition, helicopterCanBoard {
                let distance = abs(heliPos.x - position.x)
                if distance < GameConfig.hostageBoardingRange {
                    state = .walking
                }
            }

        case .walking:
            guard let heliPos = helicopterPosition else { return }

            let direction: CGFloat = heliPos.x > position.x ? 1.0 : -1.0
            let moveSpeed = GameConfig.hostageWalkSpeed
            position.x += direction * moveSpeed * CGFloat(deltaTime)
            spriteRoot.xScale = direction * abs(spriteRoot.xScale)

            // Keep on ground
            if position.y < GameConfig.groundLevel + GameConfig.hostageSize.height / 2 {
                position.y = GameConfig.groundLevel + GameConfig.hostageSize.height / 2
            }

            // Simple walk animation
            let bob = sin(CACurrentMediaTime() * 10.0) * 1.5
            torsoNode.position.y = CGFloat(bob)
            leftLegNode.zRotation = sin(CACurrentMediaTime() * 10.0) * 0.18
            rightLegNode.zRotation = -sin(CACurrentMediaTime() * 10.0) * 0.18

            let distanceToHeli = abs(heliPos.x - position.x)
            if distanceToHeli < 30 {
                state = .boarding
                board()
            }

        case .boarding:
            // Handled in board()
            break

        default:
            break
        }
    }

    private func board() {
        onBoard?()
        state = .onboard

        // Shrink and disappear
        let shrink = SKAction.scale(to: 0.1, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([SKAction.group([shrink, fadeOut]), remove]))
    }

    // MARK: - Kill

    func kill() {
        guard state != .dead && state != .onboard && state != .rescued else { return }
        state = .dead
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.none

        // Red burst effect
        let burst = SKShapeNode(circleOfRadius: 10)
        burst.fillColor = .red
        burst.strokeColor = .clear
        burst.zPosition = 10
        burst.position = .zero
        addChild(burst)

        let expand = SKAction.scale(to: 2.0, duration: 0.2)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        burst.run(SKAction.sequence([SKAction.group([expand, fade]), SKAction.removeFromParent()]))

        // Flash sprite red and fade out
        colorizeSprite(spriteRoot, color: .red)
        let bodyFade = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([bodyFade, remove]))
    }

    // MARK: - Rescue

    func rescue() {
        state = .rescued
    }

    private func colorizeSprite(_ node: SKNode, color: UIColor) {
        for child in node.children {
            if let sprite = child as? SKSpriteNode {
                sprite.color = color
                sprite.colorBlendFactor = 1.0
            }
            colorizeSprite(child, color: color)
        }
    }
}
