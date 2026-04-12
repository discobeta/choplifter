import SpriteKit

class HUDNode: SKNode {

    // MARK: - Label References

    private let livesLabel = SKLabelNode()
    private let livesShadow = SKLabelNode()

    private let healthLabel = SKLabelNode()
    private let healthShadow = SKLabelNode()
    private let healthBarFrame = SKShapeNode()
    private let healthBarFill = SKShapeNode()

    private let scoreLabel = SKLabelNode()
    private let scoreShadow = SKLabelNode()

    private let dangerLabel = SKLabelNode()
    private let dangerShadow = SKLabelNode()

    private let passengersLabel = SKLabelNode()
    private let passengersShadow = SKLabelNode()

    private let messageLabel = SKLabelNode()
    private let messageShadow = SKLabelNode()

    private let rescuedLabel = SKLabelNode()
    private let rescuedShadow = SKLabelNode()

    // MARK: - State

    private var currentRescued: Int = 0
    private var currentRemaining: Int = GameConfig.hostagesPerBarracks * GameConfig.totalBarracks

    // MARK: - Constants

    private static let fontName = "Courier-Bold"
    private static let fontSize: CGFloat = 28
    private static let shadowOffset: CGFloat = 2
    private static let healthBarSize = CGSize(width: 220, height: 18)

    // MARK: - Init

    init(sceneSize: CGSize) {
        super.init()

        let halfWidth = sceneSize.width / 2
        let halfHeight = sceneSize.height / 2
        let topY = halfHeight - 40
        let bottomY = -halfHeight + 40

        // Top-left: Lives
        configureLabelPair(
            label: livesLabel, shadow: livesShadow,
            text: "LIVES: \(GameConfig.playerLives)",
            position: CGPoint(x: -halfWidth + 40, y: topY),
            alignment: .left
        )

        configureLabelPair(
            label: healthLabel, shadow: healthShadow,
            text: "CHOPPER HP",
            position: CGPoint(x: -110, y: topY),
            alignment: .center
        )

        configureHealthBar(position: CGPoint(x: 0, y: topY - 34))

        // Top-center: Score
        configureLabelPair(
            label: scoreLabel, shadow: scoreShadow,
            text: "SCORE: 0",
            position: CGPoint(x: 0, y: topY - 72),
            alignment: .center
        )

        // Top-right: Danger Level
        configureLabelPair(
            label: dangerLabel, shadow: dangerShadow,
            text: "DANGER: 0",
            position: CGPoint(x: halfWidth - 40, y: topY),
            alignment: .left
        )
        dangerLabel.horizontalAlignmentMode = .right
        dangerShadow.horizontalAlignmentMode = .right

        // Bottom-left: Passengers onboard
        configureLabelPair(
            label: passengersLabel, shadow: passengersShadow,
            text: "ONBOARD: 0/\(GameConfig.maxPassengers)",
            position: CGPoint(x: -halfWidth + 40, y: bottomY),
            alignment: .left
        )

        // Bottom-center: Message area
        configureLabelPair(
            label: messageLabel, shadow: messageShadow,
            text: "",
            position: CGPoint(x: 0, y: bottomY),
            alignment: .center
        )
        messageLabel.fontSize = 32
        messageShadow.fontSize = 32
        messageLabel.alpha = 0
        messageShadow.alpha = 0

        // Bottom-right: Rescued / Remaining
        let totalHostages = GameConfig.hostagesPerBarracks * GameConfig.totalBarracks
        configureLabelPair(
            label: rescuedLabel, shadow: rescuedShadow,
            text: "RESCUED: 0 / REMAINING: \(totalHostages)",
            position: CGPoint(x: halfWidth - 40, y: bottomY),
            alignment: .right
        )

        zPosition = 1000
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update Methods

    func updateLives(_ lives: Int) {
        let text = "LIVES: \(lives)"
        livesLabel.text = text
        livesShadow.text = text
    }

    func updateHealth(_ health: Int, maxHealth: Int) {
        let text = "CHOPPER HP \(health)/\(maxHealth)"
        healthLabel.text = text
        healthShadow.text = text

        let clampedMax = max(maxHealth, 1)
        let ratio = max(0, min(CGFloat(health) / CGFloat(clampedMax), 1))
        let fullWidth = HUDNode.healthBarSize.width
        let fillWidth = max(0, fullWidth * ratio)

        let x = -fullWidth / 2 + fillWidth / 2
        let path = CGPath(rect: CGRect(x: -fillWidth / 2, y: -HUDNode.healthBarSize.height / 2, width: fillWidth, height: HUDNode.healthBarSize.height), transform: nil)
        healthBarFill.path = path
        healthBarFill.position = CGPoint(x: x, y: healthBarFill.position.y)
        healthBarFill.fillColor = ratio > 0.6 ? UIColor.systemGreen : (ratio > 0.3 ? UIColor.systemYellow : UIColor.systemRed)
        healthBarFill.strokeColor = .clear
    }

    func updatePassengers(_ count: Int) {
        let text = "ONBOARD: \(count)/\(GameConfig.maxPassengers)"
        passengersLabel.text = text
        passengersShadow.text = text
    }

    func updateRescued(_ count: Int) {
        currentRescued = count
        updateRescuedRemainingText()
    }

    func updateRemaining(_ count: Int) {
        currentRemaining = count
        updateRescuedRemainingText()
    }

    func updateScore(_ score: Int) {
        let text = "SCORE: \(score)"
        scoreLabel.text = text
        scoreShadow.text = text
    }

    func updateDangerLevel(_ level: Int) {
        let text = "DANGER: \(level)"
        dangerLabel.text = text
        dangerShadow.text = text
    }

    func showMessage(_ text: String, duration: TimeInterval = 2.0) {
        messageLabel.text = text
        messageShadow.text = text

        messageLabel.removeAllActions()
        messageShadow.removeAllActions()

        messageLabel.alpha = 1.0
        messageShadow.alpha = 1.0

        let wait = SKAction.wait(forDuration: duration)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let sequence = SKAction.sequence([wait, fadeOut])

        messageLabel.run(sequence)
        messageShadow.run(sequence)
    }

    // MARK: - Private Helpers

    private func updateRescuedRemainingText() {
        let text = "RESCUED: \(currentRescued) / REMAINING: \(currentRemaining)"
        rescuedLabel.text = text
        rescuedShadow.text = text
    }

    private func configureHealthBar(position: CGPoint) {
        let frameRect = CGRect(
            x: -HUDNode.healthBarSize.width / 2,
            y: -HUDNode.healthBarSize.height / 2,
            width: HUDNode.healthBarSize.width,
            height: HUDNode.healthBarSize.height
        )

        healthBarFrame.path = CGPath(rect: frameRect, transform: nil)
        healthBarFrame.fillColor = UIColor(white: 0.08, alpha: 0.8)
        healthBarFrame.strokeColor = UIColor.white.withAlphaComponent(0.9)
        healthBarFrame.lineWidth = 2
        healthBarFrame.position = position
        healthBarFrame.zPosition = 0
        addChild(healthBarFrame)

        healthBarFill.position = position
        healthBarFill.zPosition = 1
        addChild(healthBarFill)

        updateHealth(GameConfig.helicopterHealth, maxHealth: GameConfig.helicopterHealth)
    }

    private func configureLabelPair(
        label: SKLabelNode,
        shadow: SKLabelNode,
        text: String,
        position: CGPoint,
        alignment: SKLabelHorizontalAlignmentMode
    ) {
        // Shadow
        shadow.fontName = HUDNode.fontName
        shadow.fontSize = HUDNode.fontSize
        shadow.fontColor = .black
        shadow.horizontalAlignmentMode = alignment
        shadow.verticalAlignmentMode = .center
        shadow.text = text
        shadow.position = CGPoint(
            x: position.x + HUDNode.shadowOffset,
            y: position.y - HUDNode.shadowOffset
        )
        shadow.zPosition = 0
        addChild(shadow)

        // Foreground
        label.fontName = HUDNode.fontName
        label.fontSize = HUDNode.fontSize
        label.fontColor = .white
        label.horizontalAlignmentMode = alignment
        label.verticalAlignmentMode = .center
        label.text = text
        label.position = position
        label.zPosition = 1
        addChild(label)
    }
}
