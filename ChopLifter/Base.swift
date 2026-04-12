import SpriteKit

class Base: SKNode {

    // MARK: - Visual nodes
    private var platformNode: SKSpriteNode!
    private var padNode: SKSpriteNode!
    private var hLabel: SKLabelNode!
    private var flagPole: SKSpriteNode!
    private var flag: SKNode!

    /// World-space point where defense missiles launch from (set during buildVisual).
    var missileLaunchPoint: CGPoint = .zero

    // MARK: - Computed properties

    /// The rectangle area where the helicopter can land.
    var landingZone: CGRect {
        let padWidth = GameConfig.basePadSize.width + 40 // generous horizontal bounds
        let zoneHeight: CGFloat = 60
        return CGRect(
            x: position.x - padWidth / 2,
            y: GameConfig.groundLevel,
            width: padWidth,
            height: zoneHeight
        )
    }

    // MARK: - Init

    override init() {
        super.init()
        position = CGPoint(x: GameConfig.baseX, y: GameConfig.groundLevel + GameConfig.baseSize.height / 2)
        buildVisual()
        setupPhysics()
        zPosition = 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visual setup

    private func buildVisual() {
        let baseSize = GameConfig.baseSize
        let padSize = GameConfig.basePadSize

        // Platform
        platformNode = SKSpriteNode(color: GameConfig.baseColor, size: baseSize)
        addChild(platformNode)

        // Landing pad
        padNode = SKSpriteNode(color: GameConfig.basePadColor, size: padSize)
        padNode.position = CGPoint(x: 0, y: baseSize.height / 2 + padSize.height / 2)
        addChild(padNode)

        // "H" label on pad
        hLabel = SKLabelNode(text: "H")
        hLabel.fontName = "Helvetica-Bold"
        hLabel.fontSize = 20
        hLabel.fontColor = .white
        hLabel.verticalAlignmentMode = .center
        hLabel.horizontalAlignmentMode = .center
        hLabel.position = CGPoint(x: 0, y: baseSize.height / 2 + padSize.height / 2)
        hLabel.zPosition = 1
        addChild(hLabel)

        // Missile silo on the left side of the base
        let siloSize = CGSize(width: 18, height: 28)
        let silo = SKSpriteNode(color: UIColor(red: 0.35, green: 0.35, blue: 0.4, alpha: 1.0), size: siloSize)
        silo.position = CGPoint(x: -baseSize.width / 2 + 20, y: baseSize.height / 2 + siloSize.height / 2)
        addChild(silo)

        // Silo door (top detail)
        let door = SKSpriteNode(color: UIColor(red: 0.5, green: 0.15, blue: 0.15, alpha: 1.0), size: CGSize(width: 14, height: 4))
        door.position = CGPoint(x: silo.position.x, y: silo.position.y + siloSize.height / 2 - 2)
        addChild(door)

        // Missile launch point stored for reference
        missileLaunchPoint = CGPoint(x: position.x + silo.position.x, y: position.y + silo.position.y + siloSize.height / 2)

        // Flag pole on one side of the base
        let poleHeight: CGFloat = 30
        flagPole = SKSpriteNode(color: .gray, size: CGSize(width: 2, height: poleHeight))
        flagPole.position = CGPoint(x: baseSize.width / 2 - 10, y: baseSize.height / 2 + poleHeight / 2)
        addChild(flagPole)

        flag = buildAmericanFlag()
        flag.position = CGPoint(x: baseSize.width / 2 + 8, y: baseSize.height / 2 + poleHeight - 5)
        addChild(flag)
    }

    private func buildAmericanFlag() -> SKNode {
        let flagNode = SKNode()
        let flagSize = CGSize(width: 22, height: 14)

        let background = SKShapeNode(rectOf: flagSize)
        background.fillColor = .white
        background.strokeColor = UIColor(white: 0.85, alpha: 1.0)
        background.lineWidth = 0.5
        flagNode.addChild(background)

        let stripeHeight = flagSize.height / 7
        for index in 0..<7 {
            guard index % 2 == 0 else { continue }
            let stripe = SKShapeNode(rectOf: CGSize(width: flagSize.width, height: stripeHeight))
            stripe.fillColor = UIColor(red: 0.74, green: 0.1, blue: 0.16, alpha: 1.0)
            stripe.strokeColor = .clear
            stripe.position = CGPoint(
                x: 0,
                y: flagSize.height / 2 - stripeHeight / 2 - CGFloat(index) * stripeHeight
            )
            flagNode.addChild(stripe)
        }

        let cantonSize = CGSize(width: flagSize.width * 0.45, height: stripeHeight * 4)
        let canton = SKShapeNode(rectOf: cantonSize)
        canton.fillColor = UIColor(red: 0.0, green: 0.24, blue: 0.53, alpha: 1.0)
        canton.strokeColor = .clear
        canton.position = CGPoint(
            x: -flagSize.width / 2 + cantonSize.width / 2,
            y: flagSize.height / 2 - cantonSize.height / 2
        )
        flagNode.addChild(canton)

        let starRows = 3
        let starCols = 4
        for row in 0..<starRows {
            for col in 0..<starCols {
                let star = SKShapeNode(circleOfRadius: 0.45)
                star.fillColor = .white
                star.strokeColor = .clear
                star.position = CGPoint(
                    x: canton.position.x - cantonSize.width / 2 + 2.2 + CGFloat(col) * 2.2,
                    y: canton.position.y + cantonSize.height / 2 - 1.8 - CGFloat(row) * 1.8
                )
                flagNode.addChild(star)
            }
        }

        let wave = SKAction.sequence([
            SKAction.rotate(toAngle: 0.02, duration: 0.7),
            SKAction.rotate(toAngle: -0.03, duration: 0.9),
            SKAction.rotate(toAngle: 0.01, duration: 0.7)
        ])
        flagNode.run(SKAction.repeatForever(wave))
        flagNode.zPosition = 2

        return flagNode
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: GameConfig.baseSize)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.base
        body.contactTestBitMask = PhysicsCategory.helicopter
        body.collisionBitMask = PhysicsCategory.none
        physicsBody = body
    }

    // MARK: - Landing zone check

    func isHelicopterInZone(_ heliPosition: CGPoint) -> Bool {
        return landingZone.contains(heliPosition)
    }
}
