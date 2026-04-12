import GameController
import SpriteKit

class InputManager {

    weak var delegate: InputDelegate?

    /// Current movement values polled each frame by GameScene.
    private(set) var moveX: CGFloat = 0
    private(set) var moveY: CGFloat = 0

    /// Whether the Siri Remote touch surface is actively being touched.
    private(set) var isTouchingPad: Bool = false

    /// Tracks which facing direction index the Siri Remote cycles through.
    private var facingCycleIndex: Int = 0

    // MARK: - Setup

    func setupControllers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect),
            name: .GCControllerDidDisconnect,
            object: nil
        )

        setupConnectedControllers()
    }

    // MARK: - Polling

    /// Called each frame by GameScene to get the current movement vector.
    func pollMovement() -> (CGFloat, CGFloat) {
        return (moveX, moveY)
    }

    // MARK: - Controller Notifications

    @objc private func controllerDidConnect(_ notification: Notification) {
        setupConnectedControllers()
    }

    @objc private func controllerDidDisconnect(_ notification: Notification) {
        moveX = 0
        moveY = 0
        isTouchingPad = false
    }

    // MARK: - Controller Configuration

    func setupConnectedControllers() {
        for controller in GCController.controllers() {
            if let extendedGamepad = controller.extendedGamepad {
                configureExtendedGamepad(extendedGamepad)
            } else if let microGamepad = controller.microGamepad {
                configureMicroGamepad(microGamepad)
            }
        }
    }

    // MARK: - Extended Gamepad (MFi / Xbox / PS controllers)

    private func configureExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        // Left thumbstick for movement
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, xValue, yValue in
            self?.moveX = CGFloat(xValue)
            self?.moveY = CGFloat(yValue)
        }

        // D-pad as fallback for movement
        gamepad.dpad.valueChangedHandler = { [weak self] _, xValue, yValue in
            guard let self = self else { return }
            // Only use dpad if thumbstick is centered
            let thumbstickActive = abs(self.moveX) > 0.1 || abs(self.moveY) > 0.1
            if !thumbstickActive {
                self.moveX = CGFloat(xValue)
                self.moveY = CGFloat(yValue)
            }
        }

        // Button A -> fire
        gamepad.buttonA.valueChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.delegate?.inputFire()
            } else {
                self?.delegate?.inputStopFire()
            }
        }

        // Shoulder buttons -> facing direction
        gamepad.leftShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.delegate?.inputFacingChanged(.left) }
        }

        gamepad.rightShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.delegate?.inputFacingChanged(.right) }
        }

        // Button Y -> face forward
        gamepad.buttonY.valueChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.delegate?.inputFacingChanged(.forward) }
        }

        // Menu button -> pause
        gamepad.buttonMenu.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.delegate?.inputPause() }
        }
    }

    // MARK: - Micro Gamepad (Siri Remote)
    //
    // Control scheme:
    //   Touch pad (don't click) = helicopter steers directly from pad position.
    //                             Top = up, bottom = down, left/right = horizontal steering.
    //   Release pad             = no direct input; helicopter descends via gravity.
    //   Click pad (press down)  = fire weapon.
    //   Play/Pause button       = cycle facing direction (left / right / forward).
    //   Menu button             = pause game.

    private func configureMicroGamepad(_ gamepad: GCMicroGamepad) {
        gamepad.allowsRotation = true
        gamepad.reportsAbsoluteDpadValues = true

        // Touch surface position -> direct movement.
        gamepad.dpad.valueChangedHandler = { [weak self] _, xValue, yValue in
            guard let self = self else { return }

            let touching = abs(xValue) > 0.05 || abs(yValue) > 0.05

            if touching {
                self.isTouchingPad = true
                self.moveX = CGFloat(xValue)
                self.moveY = CGFloat(yValue)
            } else {
                self.isTouchingPad = false
                self.moveX = 0
                self.moveY = 0
            }
        }

        // Click (press) touch pad -> fire
        gamepad.buttonA.valueChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.delegate?.inputFire()
            } else {
                self?.delegate?.inputStopFire()
            }
        }

        // Play/Pause -> cycle facing direction
        gamepad.buttonX.valueChangedHandler = { [weak self] _, _, pressed in
            guard let self = self, pressed else { return }
            let directions: [FacingDirection] = [.right, .left, .forward]
            let direction = directions[self.facingCycleIndex % directions.count]
            self.facingCycleIndex += 1
            self.delegate?.inputFacingChanged(direction)
        }

        // Menu button -> pause
        gamepad.buttonMenu.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.delegate?.inputPause() }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
