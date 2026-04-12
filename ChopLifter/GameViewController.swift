import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override var canBecomeFirstResponder: Bool { true }

    override func loadView() {
        let skView = SKView(frame: UIScreen.main.bounds)
        self.view = skView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }

        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true

        let scene = MenuScene(size: GameConfig.sceneSize)
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)

        MusicManager.shared.startBackgroundMusic()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(primaryActionKeyDown)),
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(primaryActionKeyDown)),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(moveUp)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(moveDown)),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(moveLeft)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(moveRight)),
            UIKeyCommand(input: "w", modifierFlags: [], action: #selector(moveUp)),
            UIKeyCommand(input: "a", modifierFlags: [], action: #selector(moveLeft)),
            UIKeyCommand(input: "s", modifierFlags: [], action: #selector(moveDown)),
            UIKeyCommand(input: "d", modifierFlags: [], action: #selector(moveRight)),
            UIKeyCommand(input: "q", modifierFlags: [], action: #selector(faceLeft)),
            UIKeyCommand(input: "e", modifierFlags: [], action: #selector(faceRight)),
            UIKeyCommand(input: "f", modifierFlags: [], action: #selector(faceForward)),
            UIKeyCommand(input: "p", modifierFlags: [], action: #selector(togglePause)),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(menuAction))
        ]
    }

    @objc private func primaryActionKeyDown() {
        guard let scene = currentScene else { return }

        switch scene {
        case let menu as MenuScene:
            menu.handlePrimaryAction()
        case let game as GameScene:
            game.keyboardSetFire(true)
        case let gameOver as GameOverScene:
            gameOver.handlePrimaryAction()
        default:
            break
        }
    }

    @objc private func moveUp() {
        guard let game = currentScene as? GameScene else { return }
        game.keyboardMove(x: game.keyboardInputX, y: 1)
    }

    @objc private func moveDown() {
        guard let game = currentScene as? GameScene else { return }
        game.keyboardMove(x: game.keyboardInputX, y: -1)
    }

    @objc private func moveLeft() {
        guard let game = currentScene as? GameScene else { return }
        game.keyboardMove(x: -1, y: game.keyboardInputY)
    }

    @objc private func moveRight() {
        guard let game = currentScene as? GameScene else { return }
        game.keyboardMove(x: 1, y: game.keyboardInputY)
    }

    @objc private func faceLeft() {
        (currentScene as? GameScene)?.keyboardFaceLeft()
    }

    @objc private func faceRight() {
        (currentScene as? GameScene)?.keyboardFaceRight()
    }

    @objc private func faceForward() {
        (currentScene as? GameScene)?.keyboardFaceForward()
    }

    @objc private func togglePause() {
        (currentScene as? GameScene)?.inputPause()
    }

    @objc private func menuAction() {
        (currentScene as? GameOverScene)?.handleMenuAction()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)

        for press in presses {
            guard let input = press.key?.charactersIgnoringModifiers.lowercased() else { continue }

            if let game = currentScene as? GameScene {
                switch input {
                case " ", "\r":
                    game.keyboardSetFire(true)
                case "w", UIKeyCommand.inputUpArrow.lowercased():
                    game.keyboardMove(x: game.keyboardInputX, y: 1)
                case "s", UIKeyCommand.inputDownArrow.lowercased():
                    game.keyboardMove(x: game.keyboardInputX, y: -1)
                case "a", UIKeyCommand.inputLeftArrow.lowercased():
                    game.keyboardMove(x: -1, y: game.keyboardInputY)
                case "d", UIKeyCommand.inputRightArrow.lowercased():
                    game.keyboardMove(x: 1, y: game.keyboardInputY)
                default:
                    break
                }
            }
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)

        guard let game = currentScene as? GameScene else { return }
        for press in presses {
            guard let input = press.key?.charactersIgnoringModifiers.lowercased() else { continue }
            switch input {
            case " ", "\r":
                game.keyboardSetFire(false)
            case "w", UIKeyCommand.inputUpArrow.lowercased():
                if game.keyboardInputY > 0 {
                    game.keyboardMove(x: game.keyboardInputX, y: 0)
                }
            case "s", UIKeyCommand.inputDownArrow.lowercased():
                if game.keyboardInputY < 0 {
                    game.keyboardMove(x: game.keyboardInputX, y: 0)
                }
            case "a", UIKeyCommand.inputLeftArrow.lowercased():
                if game.keyboardInputX < 0 {
                    game.keyboardMove(x: 0, y: game.keyboardInputY)
                }
            case "d", UIKeyCommand.inputRightArrow.lowercased():
                if game.keyboardInputX > 0 {
                    game.keyboardMove(x: 0, y: game.keyboardInputY)
                }
            default:
                break
            }
        }
    }

    private var currentScene: SKScene? {
        (view as? SKView)?.scene
    }
}
