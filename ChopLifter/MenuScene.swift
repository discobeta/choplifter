import SpriteKit

class MenuScene: SKScene {

    private var isTransitioning = false
    private let menuHeliRightTexture: SKTexture = {
        let texture = SKTexture(imageNamed: "heli_left")
        texture.filteringMode = .nearest
        return texture
    }()
    private let menuHeliLeftTexture: SKTexture = {
        let texture = SKTexture(imageNamed: "heli_right")
        texture.filteringMode = .nearest
        return texture
    }()

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0)
        setupStarField()
        setupMovingClouds()
        setupTitle()
        setupSubtitle()
        setupHelicopterSilhouette()
        setupPressToStart()
        setupControlsHint()
    }

    // MARK: - Background: Star Field

    private func setupStarField() {
        let starCount = 120
        for _ in 0..<starCount {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2.0))
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.25...size.height)
            )
            star.alpha = CGFloat.random(in: 0.2...0.8)
            addChild(star)

            // Subtle twinkling
            let twinkleDuration = Double.random(in: 1.5...4.0)
            let fadeOut = SKAction.fadeAlpha(to: CGFloat.random(in: 0.05...0.3), duration: twinkleDuration)
            let fadeIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.5...1.0), duration: twinkleDuration)
            star.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
        }
    }

    // MARK: - Background: Moving Clouds

    private func setupMovingClouds() {
        let cloudCount = 5
        for i in 0..<cloudCount {
            let cloud = createCloud()
            let yPos = CGFloat.random(in: size.height * 0.15...size.height * 0.55)
            cloud.position = CGPoint(
                x: CGFloat.random(in: -200...size.width + 200),
                y: yPos
            )
            cloud.alpha = CGFloat.random(in: 0.04...0.12)
            cloud.zPosition = 1
            addChild(cloud)

            let speed = Double.random(in: 40...90)
            animateCloud(cloud, speed: speed, index: i)
        }
    }

    private func createCloud() -> SKNode {
        let cloud = SKNode()
        let widths: [CGFloat] = [120, 90, 80]
        let heights: [CGFloat] = [30, 25, 20]
        let offsets: [CGPoint] = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 50, y: 10),
            CGPoint(x: -40, y: 5)
        ]
        for i in 0..<3 {
            let puff = SKShapeNode(ellipseOf: CGSize(width: widths[i], height: heights[i]))
            puff.fillColor = UIColor(white: 0.7, alpha: 1.0)
            puff.strokeColor = .clear
            puff.position = offsets[i]
            cloud.addChild(puff)
        }
        return cloud
    }

    private func animateCloud(_ cloud: SKNode, speed: Double, index: Int) {
        let travelDistance = size.width + 400
        let duration = Double(travelDistance) / speed

        let moveRight = SKAction.moveTo(x: size.width + 200, duration: duration * Double(size.width + 200 - cloud.position.x) / travelDistance)
        let resetLeft = SKAction.moveTo(x: -200, duration: 0)
        let moveFull = SKAction.moveTo(x: size.width + 200, duration: duration)

        cloud.run(SKAction.sequence([
            moveRight,
            resetLeft,
            SKAction.repeatForever(SKAction.sequence([moveFull, resetLeft]))
        ]))
    }

    // MARK: - Title

    private func setupTitle() {
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.text = "CHOPLIFTER"
        title.fontSize = 72
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        title.zPosition = 10
        title.alpha = 0
        addChild(title)

        // Glow effect via duplicate label behind
        let glow = SKLabelNode(fontNamed: "Helvetica-Bold")
        glow.text = "CHOPLIFTER"
        glow.fontSize = 72
        glow.fontColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.4)
        glow.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        glow.zPosition = 9
        glow.alpha = 0
        glow.setScale(1.05)
        addChild(glow)

        let fadeIn = SKAction.fadeIn(withDuration: 1.2)
        title.run(fadeIn)
        glow.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            fadeIn
        ]))

        // Subtle glow pulse
        let pulseGlow = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 2.0),
            SKAction.fadeAlpha(to: 0.5, duration: 2.0)
        ])
        glow.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.repeatForever(pulseGlow)
        ]))
    }

    // MARK: - Subtitle

    private func setupSubtitle() {
        let subtitle = SKLabelNode(fontNamed: "Helvetica-Bold")
        subtitle.text = "HOSTAGE RESCUE"
        subtitle.fontSize = 36
        subtitle.fontColor = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.64)
        subtitle.zPosition = 10
        subtitle.alpha = 0
        addChild(subtitle)

        subtitle.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeIn(withDuration: 1.0)
        ]))
    }

    // MARK: - Animated Helicopter

    private func setupHelicopterSilhouette() {
        let heli = SKSpriteNode(texture: menuHeliRightTexture, size: CGSize(width: 210, height: 87))
        heli.zPosition = 10
        heli.alpha = 0.92

        // Position and animate flight path
        heli.position = CGPoint(x: -100, y: size.height * 0.48)
        addChild(heli)

        let flyRight = SKAction.group([
            SKAction.moveTo(x: size.width + 100, duration: 8.0),
            SKAction.sequence([
                SKAction.moveBy(x: 0, y: 20, duration: 1.5),
                SKAction.moveBy(x: 0, y: -20, duration: 1.5),
                SKAction.moveBy(x: 0, y: 15, duration: 1.2),
                SKAction.moveBy(x: 0, y: -15, duration: 1.3),
                SKAction.moveBy(x: 0, y: 20, duration: 1.5),
                SKAction.moveBy(x: 0, y: -20, duration: 1.5)
            ])
        ])

        let flyLeft = SKAction.group([
            SKAction.moveTo(x: -100, duration: 8.0),
            SKAction.sequence([
                SKAction.moveBy(x: 0, y: -15, duration: 1.3),
                SKAction.moveBy(x: 0, y: 15, duration: 1.2),
                SKAction.moveBy(x: 0, y: -20, duration: 1.5),
                SKAction.moveBy(x: 0, y: 20, duration: 1.5),
                SKAction.moveBy(x: 0, y: -15, duration: 1.3),
                SKAction.moveBy(x: 0, y: 15, duration: 1.2)
            ])
        ])

        let faceLeft = SKAction.run { [weak self] in
            guard let self = self else { return }
            heli.texture = self.menuHeliLeftTexture
        }
        let faceRight = SKAction.run { [weak self] in
            guard let self = self else { return }
            heli.texture = self.menuHeliRightTexture
        }

        let loop = SKAction.repeatForever(SKAction.sequence([
            flyRight,
            SKAction.wait(forDuration: 0.5),
            faceLeft,
            flyLeft,
            SKAction.wait(forDuration: 0.5),
            faceRight
        ]))

        heli.run(loop)
    }

    // MARK: - Press To Start

    private func setupPressToStart() {
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = "PRESS TO START"
        label.fontSize = 40
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.28)
        label.zPosition = 10
        label.alpha = 0
        addChild(label)

        let appear = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeIn(withDuration: 0.8)
        ])

        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 1.0),
            SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        ]))

        label.run(SKAction.sequence([appear, pulse]))
    }

    // MARK: - Controls Hint

    private func setupControlsHint() {
        let hint = SKLabelNode(fontNamed: "Helvetica")
        hint.text = "CONTROLLER: Stick=Move, A=Fire, LB/RB=Aim  |  REMOTE: Swipe=Move, Click=Fire, Play=Aim"
        hint.fontSize = 22
        hint.fontColor = UIColor(white: 0.5, alpha: 1.0)
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.06)
        hint.zPosition = 10
        hint.alpha = 0
        addChild(hint)

        hint.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeAlpha(to: 0.6, duration: 1.5)
        ]))
    }

    // MARK: - Ground Silhouette

    // MARK: - Input Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !touches.isEmpty else { return }
        startGame()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if isStartKeyPress(press) {
                startGame()
                return
            }

            switch press.type {
            case .select, .playPause:
                startGame()
                return
            default:
                break
            }
        }
    }

    // MARK: - Scene Transition

    func handlePrimaryAction() {
        startGame()
    }

    private func startGame() {
        guard !isTransitioning else { return }
        isTransitioning = true

        let gameScene = GameScene(size: GameConfig.sceneSize)
        gameScene.scaleMode = .aspectFit
        view?.presentScene(gameScene, transition: SKTransition.crossFade(withDuration: 1.0))
    }

    private func isStartKeyPress(_ press: UIPress) -> Bool {
        guard let input = press.key?.charactersIgnoringModifiers else { return false }
        return input == " " || input == "\r"
    }
}
