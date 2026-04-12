import SpriteKit

class GameOverScene: SKScene {

    private var isTransitioning = false

    // MARK: - Game Result Properties

    var finalScore: Int = 0
    var rescued: Int = 0
    var totalHostages: Int = 64
    var dead: Int = 0
    var won: Bool = false

    // MARK: - Convenience Init

    convenience init(size: CGSize, score: Int, rescued: Int, totalHostages: Int, dead: Int, won: Bool) {
        self.init(size: size)
        self.finalScore = score
        self.rescued = rescued
        self.totalHostages = totalHostages
        self.dead = dead
        self.won = won
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0)
        setupStarField()
        setupTitle()
        setupStats()
        setupActions()
    }

    // MARK: - Star Field Background

    private func setupStarField() {
        for _ in 0..<80 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.8))
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.alpha = CGFloat.random(in: 0.15...0.6)
            addChild(star)

            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.05...0.2), duration: Double.random(in: 1.5...3.5)),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.4...0.8), duration: Double.random(in: 1.5...3.5))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
    }

    // MARK: - Title

    private func setupTitle() {
        let titleText = won ? "MISSION COMPLETE" : "GAME OVER"
        let titleColor = won
            ? UIColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)

        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.text = titleText
        title.fontSize = 72
        title.fontColor = titleColor
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.82)
        title.zPosition = 10
        title.alpha = 0
        addChild(title)

        // Glow
        let glow = SKLabelNode(fontNamed: "Helvetica-Bold")
        glow.text = titleText
        glow.fontSize = 72
        glow.fontColor = titleColor.withAlphaComponent(0.3)
        glow.position = title.position
        glow.zPosition = 9
        glow.alpha = 0
        glow.setScale(1.05)
        addChild(glow)

        title.run(SKAction.fadeIn(withDuration: 0.8))
        glow.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.8),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.15, duration: 2.0),
                SKAction.fadeAlpha(to: 0.4, duration: 2.0)
            ]))
        ]))
    }

    // MARK: - Stats Display

    private func setupStats() {
        let rating = calculateRating()
        let ratingColor = colorForRating(rating)

        let statLines: [(String, UIColor)] = [
            ("Score:  \(String(format: "%05d", finalScore))", .white),
            ("Hostages Rescued:  \(rescued) / \(totalHostages)", UIColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0)),
            ("Hostages Lost:  \(dead)", dead > 0 ? UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) : UIColor(white: 0.7, alpha: 1.0)),
            ("Rating:  \(rating)", ratingColor)
        ]

        let startY = size.height * 0.65
        let lineSpacing: CGFloat = 60

        for (index, stat) in statLines.enumerated() {
            let label = SKLabelNode(fontNamed: "Courier-Bold")
            label.text = stat.0
            label.fontSize = 36
            label.fontColor = stat.1
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: size.width / 2, y: startY - CGFloat(index) * lineSpacing)
            label.zPosition = 10
            label.alpha = 0
            addChild(label)

            // Staggered appearance
            let delay = 1.0 + Double(index) * 0.5
            label.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.4),
                    SKAction.moveBy(x: 0, y: 10, duration: 0.0),
                    SKAction.moveBy(x: 0, y: -10, duration: 0.4)
                ])
            ]))
        }

        // Decorative divider line below stats
        let divider = SKShapeNode(rectOf: CGSize(width: 500, height: 2), cornerRadius: 1)
        divider.fillColor = UIColor(white: 0.3, alpha: 1.0)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: size.width / 2, y: startY - CGFloat(statLines.count) * lineSpacing + 10)
        divider.zPosition = 10
        divider.alpha = 0
        addChild(divider)

        let dividerDelay = 1.0 + Double(statLines.count) * 0.5
        divider.run(SKAction.sequence([
            SKAction.wait(forDuration: dividerDelay),
            SKAction.fadeAlpha(to: 0.5, duration: 0.4)
        ]))
    }

    // MARK: - Action Prompts

    private func setupActions() {
        let appearDelay = 3.5

        // Play Again
        let playAgain = SKLabelNode(fontNamed: "Helvetica-Bold")
        playAgain.text = "PRESS TO PLAY AGAIN"
        playAgain.fontSize = 36
        playAgain.fontColor = .white
        playAgain.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        playAgain.zPosition = 10
        playAgain.alpha = 0
        addChild(playAgain)

        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 1.0),
            SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        ]))

        playAgain.run(SKAction.sequence([
            SKAction.wait(forDuration: appearDelay),
            SKAction.fadeIn(withDuration: 0.6),
            pulse
        ]))

        // Menu hint
        let menuHint = SKLabelNode(fontNamed: "Helvetica")
        menuHint.text = "MENU to return to title"
        menuHint.fontSize = 24
        menuHint.fontColor = UIColor(white: 0.5, alpha: 1.0)
        menuHint.position = CGPoint(x: size.width / 2, y: size.height * 0.14)
        menuHint.zPosition = 10
        menuHint.alpha = 0
        addChild(menuHint)

        menuHint.run(SKAction.sequence([
            SKAction.wait(forDuration: appearDelay + 0.5),
            SKAction.fadeAlpha(to: 0.6, duration: 0.6)
        ]))
    }

    // MARK: - Rating Calculation

    private func calculateRating() -> String {
        guard totalHostages > 0 else { return "F" }
        let percentage = Double(rescued) / Double(totalHostages)
        switch percentage {
        case 0.95...1.0: return "S"
        case 0.85..<0.95: return "A"
        case 0.70..<0.85: return "B"
        case 0.50..<0.70: return "C"
        case 0.25..<0.50: return "D"
        default: return "F"
        }
    }

    private func colorForRating(_ rating: String) -> UIColor {
        switch rating {
        case "S": return UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)   // Gold
        case "A": return UIColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0)     // Green
        case "B": return UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)     // Blue
        case "C": return UIColor(white: 0.8, alpha: 1.0)                           // Light gray
        case "D": return UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)     // Orange
        default:  return UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)     // Red
        }
    }

    // MARK: - Input Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !touches.isEmpty else { return }
        restartGame()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if isRestartKeyPress(press) {
                restartGame()
                return
            }

            switch press.type {
            case .select, .playPause:
                restartGame()
                return
            case .menu:
                goToMenu()
                return
            default:
                break
            }
        }
    }

    // MARK: - Scene Transitions

    func handlePrimaryAction() {
        restartGame()
    }

    func handleMenuAction() {
        goToMenu()
    }

    private func restartGame() {
        guard !isTransitioning else { return }
        isTransitioning = true

        let gameScene = GameScene(size: GameConfig.sceneSize)
        gameScene.scaleMode = .aspectFit
        view?.presentScene(gameScene, transition: SKTransition.crossFade(withDuration: 1.0))
    }

    private func goToMenu() {
        guard !isTransitioning else { return }
        isTransitioning = true

        let menuScene = MenuScene(size: GameConfig.sceneSize)
        menuScene.scaleMode = .aspectFit
        view?.presentScene(menuScene, transition: SKTransition.crossFade(withDuration: 1.0))
    }

    private func isRestartKeyPress(_ press: UIPress) -> Bool {
        guard let input = press.key?.charactersIgnoringModifiers else { return false }
        return input == " " || input == "\r"
    }
}
