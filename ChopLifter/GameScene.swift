import SpriteKit
import GameController

class GameScene: SKScene, SKPhysicsContactDelegate, InputDelegate {

    // MARK: - Game Object References

    var worldNode = SKNode()
    var helicopter: Helicopter!
    var base: Base!
    var barracksArray: [Barracks] = []
    var hostages: [Hostage] = []
    var tanks: [Tank] = []
    var jets: [Jet] = []
    var hud: HUDNode!
    var difficultyManager = DifficultyManager()
    var inputManager = InputManager()
    var cameraNode = SKCameraNode()

    // MARK: - Game State

    var lives = GameConfig.playerLives
    var score = 0
    var totalRescued = 0
    var totalDead = 0
    var gameOver = false
    var missionWon = false

    // MARK: - Input State

    var moveInputX: CGFloat = 0
    var moveInputY: CGFloat = 0
    var keyboardInputX: CGFloat = 0
    var keyboardInputY: CGFloat = 0
    var isFiring = false
    var lastFireTime: TimeInterval = 0
    var lastBombTime: TimeInterval = 0

    // MARK: - Timing

    var lastUpdateTime: TimeInterval = 0
    var lastTankSpawnTime: TimeInterval = 0
    var lastJetSpawnTime: TimeInterval = 0
    var lastMissileLaunchTime: TimeInterval = 0
    var lastAirMissileLaunchTime: TimeInterval = 0

    /// Tanks currently being targeted by a base missile (don't double-target).
    var missileTargets: Set<ObjectIdentifier> = []
    var airMissileTargets: Set<ObjectIdentifier> = []

    // MARK: - Computed Properties

    var totalHostages: Int { GameConfig.hostagesPerBarracks * GameConfig.totalBarracks }
    var remainingHostages: Int { totalHostages - totalRescued - totalDead }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = GameConfig.skyColor

        // Physics world
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        physicsWorld.contactDelegate = self

        // World node
        addChild(worldNode)

        // Camera
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)

        // Build world
        buildGround()
        buildBackground()
        buildBase()
        buildBarracks()

        // Helicopter
        helicopter = Helicopter()
        helicopter.position = CGPoint(x: GameConfig.baseX, y: GameConfig.groundLevel + 60)
        worldNode.addChild(helicopter)

        // HUD (child of camera so it stays on screen)
        hud = HUDNode(sceneSize: size)
        cameraNode.addChild(hud)

        // Input
        inputManager.delegate = self
        inputManager.setupControllers()

        // Initial HUD values
        hud.updateLives(lives)
        hud.updateHealth(helicopter.health, maxHealth: helicopter.maxHealth)
        hud.updatePassengers(0)
        hud.updateRescued(0)
        hud.updateRemaining(totalHostages)
        hud.updateScore(0)
        hud.updateDangerLevel(0)
        hud.showMessage("RESCUE THE HOSTAGES!", duration: 3.0)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard !gameOver else { return }
        guard touches.contains(where: { $0.tapCount >= 2 }) else { return }
        dropPlayerBomb()
    }

    // MARK: - World Building

    private func buildGround() {
        // Main ground
        let ground = SKSpriteNode(
            color: GameConfig.groundColor,
            size: CGSize(width: GameConfig.worldWidth, height: GameConfig.groundLevel)
        )
        ground.position = CGPoint(x: GameConfig.worldWidth / 2, y: GameConfig.groundLevel / 2)
        ground.zPosition = 0

        let groundBody = SKPhysicsBody(rectangleOf: ground.size)
        groundBody.isDynamic = false
        groundBody.categoryBitMask = PhysicsCategory.ground
        groundBody.contactTestBitMask = PhysicsCategory.none
        groundBody.collisionBitMask = PhysicsCategory.helicopter | PhysicsCategory.hostage | PhysicsCategory.tank
        ground.physicsBody = groundBody
        worldNode.addChild(ground)

        // Dirt layer on top of ground
        let dirt = SKSpriteNode(
            color: GameConfig.dirtColor,
            size: CGSize(width: GameConfig.worldWidth, height: 6)
        )
        dirt.position = CGPoint(x: GameConfig.worldWidth / 2, y: GameConfig.groundLevel + 3)
        dirt.zPosition = 0.5
        worldNode.addChild(dirt)

        // Ground variation strips
        for i in 0..<16 {
            let stripWidth = CGFloat.random(in: 200...600)
            let strip = SKSpriteNode(
                color: GameConfig.groundColor.withAlphaComponent(0.7),
                size: CGSize(width: stripWidth, height: CGFloat.random(in: 3...8))
            )
            strip.position = CGPoint(
                x: CGFloat(i) * 500 + CGFloat.random(in: 0...200),
                y: CGFloat.random(in: 20...GameConfig.groundLevel - 10)
            )
            strip.zPosition = 0.1
            worldNode.addChild(strip)
        }
    }

    private func buildBackground() {
        // Mountains
        let mountainData: [(x: CGFloat, baseWidth: CGFloat, height: CGFloat, color: UIColor)] = [
            (1200, 800, 350, UIColor(red: 0.25, green: 0.35, blue: 0.5, alpha: 0.4)),
            (3000, 1200, 500, UIColor(red: 0.2, green: 0.3, blue: 0.45, alpha: 0.35)),
            (5200, 900, 400, UIColor(red: 0.22, green: 0.32, blue: 0.48, alpha: 0.38)),
            (7200, 700, 320, UIColor(red: 0.28, green: 0.38, blue: 0.52, alpha: 0.4))
        ]

        for mtn in mountainData {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -mtn.baseWidth / 2, y: 0))
            path.addLine(to: CGPoint(x: CGFloat.random(in: -50...50), y: mtn.height))
            path.addLine(to: CGPoint(x: mtn.baseWidth / 2, y: 0))
            path.closeSubpath()

            let mountain = SKShapeNode(path: path)
            mountain.fillColor = mtn.color
            mountain.strokeColor = .clear
            mountain.position = CGPoint(x: mtn.x, y: GameConfig.groundLevel)
            mountain.zPosition = -10
            worldNode.addChild(mountain)
        }

        // Clouds
        for _ in 0..<6 {
            let cloud = createCloud()
            let cloudX = CGFloat.random(in: 0...GameConfig.worldWidth)
            let cloudY = CGFloat.random(in: 400...900)
            cloud.position = CGPoint(x: cloudX, y: cloudY)
            cloud.zPosition = -5
            worldNode.addChild(cloud)

            // Slow drift
            let driftDistance: CGFloat = CGFloat.random(in: 60...150)
            let driftDuration = Double.random(in: 20...40)
            let driftRight = SKAction.moveBy(x: driftDistance, y: 0, duration: driftDuration)
            let driftLeft = SKAction.moveBy(x: -driftDistance, y: 0, duration: driftDuration)
            cloud.run(SKAction.repeatForever(SKAction.sequence([driftRight, driftLeft])))
        }
    }

    private func createCloud() -> SKNode {
        let cloud = SKNode()
        let puffCount = Int.random(in: 2...4)
        for i in 0..<puffCount {
            let w = CGFloat.random(in: 80...160)
            let h = CGFloat.random(in: 25...50)
            let puff = SKShapeNode(ellipseOf: CGSize(width: w, height: h))
            puff.fillColor = UIColor(white: 1.0, alpha: 0.25)
            puff.strokeColor = .clear
            puff.position = CGPoint(x: CGFloat(i) * 40 - 40, y: CGFloat.random(in: -10...10))
            cloud.addChild(puff)
        }
        return cloud
    }

    private func buildBase() {
        base = Base()
        worldNode.addChild(base)
    }

    private func buildBarracks() {
        for posX in GameConfig.barracksPositions {
            let barracks = Barracks(positionX: posX)
            barracksArray.append(barracks)
            worldNode.addChild(barracks)
        }
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }

        // Calculate delta time
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let deltaTime = min(currentTime - lastUpdateTime, 1.0 / 30.0) // Cap at ~30fps worth
        lastUpdateTime = currentTime

        // Poll input
        let (controllerX, controllerY) = inputManager.pollMovement()
        moveInputX = keyboardInputX != 0 ? keyboardInputX : controllerX
        moveInputY = keyboardInputY != 0 ? keyboardInputY : controllerY

        // Move helicopter
        if helicopter.state != .destroyed {
            helicopter.applyMovement(
                dx: moveInputX,
                dy: moveInputY,
                deltaTime: deltaTime
            )

            // Landing: touch ground while not thrusting up
            if helicopter.state == .flying &&
               helicopter.position.y <= GameConfig.groundLevel + 25 &&
               moveInputY <= 0 {
                helicopter.land()
            }
        }

        // Firing
        if isFiring && helicopter.state != .destroyed {
            if currentTime - lastFireTime > GameConfig.playerFireRate {
                if let bullet = helicopter.fire() {
                    worldNode.addChild(bullet)
                    lastFireTime = currentTime
                }
            }
        }

        // Update camera
        let minCamX = size.width / 2
        let maxCamX = GameConfig.worldWidth - size.width / 2
        cameraNode.position.x = max(minCamX, min(helicopter.position.x, maxCamX))
        cameraNode.position.y = size.height / 2

        // Update hostages
        updateHostages(deltaTime: deltaTime)

        // Check base support actions
        checkBaseSupport()

        // Update enemies
        updateTanks(currentTime: currentTime, deltaTime: deltaTime)
        updateJets(currentTime: currentTime, deltaTime: deltaTime)

        // Spawn enemies
        spawnEnemies(currentTime: currentTime)

        // Base defense - launch missiles at tanks that get too close
        updateBaseDefense(currentTime: currentTime)

        // Clean up dead entities
        cleanupEntities()

        // Check mission status
        checkMissionStatus()

        // Update HUD
        hud.updateLives(lives)
        hud.updateHealth(helicopter.health, maxHealth: helicopter.maxHealth)
        hud.updatePassengers(helicopter.passengers)
        hud.updateRescued(totalRescued)
        hud.updateRemaining(remainingHostages)
        hud.updateScore(score)
        hud.updateDangerLevel(difficultyManager.dangerLevel)
    }

    // MARK: - Hostage Management

    private func updateHostages(deltaTime: TimeInterval) {
        for hostage in hostages {
            guard hostage.state == .released || hostage.state == .walking else { continue }

            let heliPos: CGPoint? = (helicopter.state != .destroyed) ? helicopter.position : nil

            // Set up boarding callback before update so we capture the boarding event
            hostage.onBoard = { [weak self, weak hostage] in
                guard let self = self, hostage != nil else { return }
                guard !self.helicopter.isFull else { return }
                self.helicopter.loadPassenger()
                self.score += GameConfig.scorePerHostageLoaded
                self.hud.updatePassengers(self.helicopter.passengers)
            }

            hostage.update(
                deltaTime: deltaTime,
                helicopterPosition: heliPos,
                helicopterCanBoard: helicopter.canBoard
            )
        }
    }

    private func checkBaseSupport() {
        guard helicopter.isGrounded,
              base.isHelicopterInZone(helicopter.position) else { return }

        let repaired = helicopter.repairToFull()

        if helicopter.passengers > 0 {
            let count = helicopter.unloadAll()
            totalRescued += count
            score += count * GameConfig.scorePerHostageRescued
            difficultyManager.onHostagesDelivered()

            // Mark hostages as rescued
            for hostage in hostages where hostage.state == .onboard {
                hostage.rescue()
            }

            let message = repaired ? "DELIVERED \(count) HOSTAGES! CHOPPER REPAIRED!" : "DELIVERED \(count) HOSTAGES!"
            hud.showMessage(message, duration: 2.0)
            hud.updatePassengers(0)
            hud.updateRescued(totalRescued)
            hud.updateRemaining(remainingHostages)
        } else if repaired {
            hud.showMessage("CHOPPER REPAIRED!", duration: 1.5)
        }
    }

    // MARK: - Enemy Updates

    private func updateTanks(currentTime: TimeInterval, deltaTime: TimeInterval) {
        for tank in tanks {
            guard tank.parent != nil else { continue }
            tank.update(deltaTime: deltaTime, helicopterPosition: helicopter.position)

            if let bullet = tank.fire(at: currentTime, toward: helicopter.position) {
                worldNode.addChild(bullet)
            }
        }
    }

    private func updateJets(currentTime: TimeInterval, deltaTime: TimeInterval) {
        for jet in jets {
            guard jet.parent != nil else { continue }
            jet.update(deltaTime: deltaTime)

            // Fire if jet is within horizontal range of helicopter
            let horizDistance = abs(jet.position.x - helicopter.position.x)
            let vertDistance = abs(jet.position.y - helicopter.position.y)

            if horizDistance < 600 && vertDistance < 400 {
                if let bullet = jet.fire(toward: helicopter.position) {
                    worldNode.addChild(bullet)
                }
            }

            // Drop bomb when passing over helicopter
            if horizDistance < 100 && jet.position.y > helicopter.position.y {
                if let bomb = jet.dropBomb(atX: helicopter.position.x) {
                    worldNode.addChild(bomb)
                }
            }
        }
    }

    // MARK: - Enemy Spawning

    private func spawnEnemies(currentTime: TimeInterval) {
        // Initialize spawn timers on first frame
        if lastTankSpawnTime == 0 { lastTankSpawnTime = currentTime }
        if lastJetSpawnTime == 0 { lastJetSpawnTime = currentTime }

        // Tanks
        let activeTanks = tanks.filter { $0.parent != nil }
        if currentTime - lastTankSpawnTime > difficultyManager.tankSpawnInterval &&
           activeTanks.count < difficultyManager.maxActiveTanks {
            spawnTank()
            lastTankSpawnTime = currentTime
        }

        // Jets
        let activeJets = jets.filter { $0.parent != nil }
        if currentTime - lastJetSpawnTime > difficultyManager.jetSpawnInterval &&
           activeJets.count < difficultyManager.maxActiveJets {
            spawnJet()
            lastJetSpawnTime = currentTime
        }
    }

    private func spawnTank() {
        // Spawn near a barracks — keep tanks out of the base defense zone
        let minSafeX = GameConfig.baseX + GameConfig.baseDefenseRadius + 100
        let spawnPositions = GameConfig.barracksPositions.filter { $0 >= minSafeX }
        guard let spawnX = spawnPositions.randomElement() else { return }
        let offset = CGFloat.random(in: -300...300)
        let finalX = max(minSafeX, min(spawnX + offset, GameConfig.worldWidth - 200))

        let tank = Tank(at: finalX)
        tank.patrolMinX = max(minSafeX, finalX - 500)
        tank.patrolMaxX = min(GameConfig.worldWidth - 100, finalX + 500)
        worldNode.addChild(tank)
        tanks.append(tank)
    }

    private func spawnJet() {
        let flyRight = Bool.random()
        let altitude = CGFloat.random(in: 300...800)
        let jet = Jet(flyingRight: flyRight, atY: altitude)
        jet.flySpeed = difficultyManager.jetSpeed
        worldNode.addChild(jet)
        jets.append(jet)
    }

    // MARK: - Base Defense System

    private func updateBaseDefense(currentTime: TimeInterval) {
        updateBaseGroundDefense(currentTime: currentTime)
        updateBaseAirDefense(currentTime: currentTime)
    }

    private func updateBaseGroundDefense(currentTime: TimeInterval) {
        if lastMissileLaunchTime == 0 { lastMissileLaunchTime = currentTime - GameConfig.baseMissileInterval }

        guard currentTime - lastMissileLaunchTime >= GameConfig.baseMissileInterval else { return }

        // Find the closest tank inside the defense radius
        let defenseLimit = GameConfig.baseX + GameConfig.baseDefenseRadius
        var closestTank: Tank?
        var closestDist: CGFloat = .greatestFiniteMagnitude

        for tank in tanks {
            guard tank.parent != nil, tank.health > 0 else { continue }
            guard !missileTargets.contains(ObjectIdentifier(tank)) else { continue }
            let dist = abs(tank.position.x - GameConfig.baseX)
            if dist < GameConfig.baseDefenseRadius && tank.position.x < defenseLimit && dist < closestDist {
                closestDist = dist
                closestTank = tank
            }
        }

        guard let target = closestTank else { return }

        missileTargets.insert(ObjectIdentifier(target))
        lastMissileLaunchTime = currentTime
        launchBaseMissile(at: target)
    }

    private func updateBaseAirDefense(currentTime: TimeInterval) {
        if lastAirMissileLaunchTime == 0 { lastAirMissileLaunchTime = currentTime - GameConfig.baseAirMissileInterval }
        guard currentTime - lastAirMissileLaunchTime >= GameConfig.baseAirMissileInterval else { return }

        let defenseLimit = GameConfig.baseX + GameConfig.baseAirDefenseRadius
        var closestJet: Jet?
        var closestDist: CGFloat = .greatestFiniteMagnitude

        for jet in jets {
            guard jet.parent != nil, !jet.isCrashing, !jet.isDestroyed else { continue }
            guard !airMissileTargets.contains(ObjectIdentifier(jet)) else { continue }
            let dist = abs(jet.position.x - GameConfig.baseX)
            if dist < GameConfig.baseAirDefenseRadius && jet.position.x < defenseLimit && dist < closestDist {
                closestDist = dist
                closestJet = jet
            }
        }

        guard let target = closestJet else { return }

        airMissileTargets.insert(ObjectIdentifier(target))
        lastAirMissileLaunchTime = currentTime
        launchBaseAirMissile(at: target)
    }

    private func launchBaseMissile(at tank: Tank) {
        let missile = SKNode()
        missile.zPosition = 8

        // Missile body — small white rocket shape
        let body = SKSpriteNode(color: .white, size: CGSize(width: 16, height: 6))
        missile.addChild(body)

        // Nose cone
        let nose = SKSpriteNode(color: UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0), size: CGSize(width: 5, height: 6))
        nose.position = CGPoint(x: 10, y: 0)
        missile.addChild(nose)

        // Engine flame
        let flame = SKSpriteNode(color: .orange, size: CGSize(width: 10, height: 5))
        flame.position = CGPoint(x: -12, y: 0)
        missile.addChild(flame)
        let flicker = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.04),
            SKAction.fadeAlpha(to: 1.0, duration: 0.04)
        ])
        flame.run(SKAction.repeatForever(flicker))

        // Start at the base missile silo
        let startPos = base.missileLaunchPoint
        missile.position = startPos
        worldNode.addChild(missile)

        // Arc path: launch up then curve down to the tank
        let endPos = tank.position
        let controlY = max(startPos.y, endPos.y) + 400
        let controlX = (startPos.x + endPos.x) / 2

        let path = CGMutablePath()
        path.move(to: .zero)
        path.addQuadCurve(
            to: CGPoint(x: endPos.x - startPos.x, y: endPos.y - startPos.y),
            control: CGPoint(x: controlX - startPos.x, y: controlY - startPos.y)
        )

        // Smoke trail — spawn puffs along the flight path
        let smokeAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self, weak missile] in
                guard let self = self, let missile = missile, missile.parent != nil else { return }
                self.spawnMissileSmoke(at: missile.position)
            },
            SKAction.wait(forDuration: 0.04)
        ]))
        missile.run(smokeAction, withKey: "smoke")

        // Fly along the arc
        let follow = SKAction.follow(path, asOffset: true, orientToPath: true,
                                     duration: GameConfig.baseMissileFlightTime)

        let tankId = ObjectIdentifier(tank)
        missile.run(SKAction.sequence([follow, SKAction.run { [weak self, weak tank] in
            guard let self = self else { return }
            missile.removeAction(forKey: "smoke")
            missile.removeFromParent()

            self.missileTargets.remove(tankId)

            // Impact — big explosion and destroy the tank
            let impactPos = tank?.parent != nil ? tank!.position : endPos
            self.spawnBaseExplosion(at: impactPos)

            if let tank = tank, tank.parent != nil {
                // Disable physics immediately so it stops interacting
                tank.physicsBody?.categoryBitMask = PhysicsCategory.none
                tank.physicsBody?.contactTestBitMask = PhysicsCategory.none
                // Visual: flash white then disintegrate
                tank.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))
                self.score += GameConfig.scorePerTankKill
            }
        }]))
    }

    private func launchBaseAirMissile(at jet: Jet) {
        let missile = SKNode()
        missile.zPosition = 8.5

        let body = SKSpriteNode(color: .white, size: CGSize(width: 20, height: 6))
        missile.addChild(body)

        let nose = SKSpriteNode(color: UIColor(red: 0.9, green: 0.15, blue: 0.15, alpha: 1.0), size: CGSize(width: 6, height: 6))
        nose.position = CGPoint(x: 12, y: 0)
        missile.addChild(nose)

        let flame = SKSpriteNode(color: .orange, size: CGSize(width: 12, height: 5))
        flame.position = CGPoint(x: -14, y: 0)
        missile.addChild(flame)
        flame.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.35, duration: 0.03),
            SKAction.fadeAlpha(to: 1.0, duration: 0.03)
        ])))

        missile.position = base.missileLaunchPoint
        worldNode.addChild(missile)

        let jetId = ObjectIdentifier(jet)
        var lastElapsed: CGFloat = 0
        var impacted = false

        let home = SKAction.customAction(withDuration: GameConfig.baseAirMissileMaxFlightTime) { [weak self, weak jet] node, elapsedTime in
            guard let self = self, let missileNode = node as? SKNode, missileNode.parent != nil, !impacted else { return }

            let dt = max(CGFloat(elapsedTime) - lastElapsed, 1.0 / 120.0)
            lastElapsed = CGFloat(elapsedTime)

            guard let jet = jet, jet.parent != nil, !jet.isCrashing, !jet.isDestroyed else {
                impacted = true
                self.airMissileTargets.remove(jetId)
                missileNode.removeFromParent()
                return
            }

            self.spawnMissileSmoke(at: missileNode.position)

            let dx = jet.position.x - missileNode.position.x
            let dy = jet.position.y - missileNode.position.y
            let distance = hypot(dx, dy)
            if distance <= 26 {
                impacted = true
                self.airMissileTargets.remove(jetId)
                missileNode.removeFromParent()
                self.spawnBaseExplosion(at: jet.position)
                if jet.shootDown() {
                    self.score += GameConfig.scorePerJetKill
                }
                return
            }

            let vx = dx / max(distance, 1) * GameConfig.baseAirMissileSpeed
            let vy = dy / max(distance, 1) * GameConfig.baseAirMissileSpeed
            missileNode.position = CGPoint(
                x: missileNode.position.x + vx * dt,
                y: missileNode.position.y + vy * dt
            )
            missileNode.zRotation = atan2(vy, vx)
        }

        missile.run(SKAction.sequence([
            home,
            SKAction.run { [weak self, weak missile] in
                guard let self = self else { return }
                self.airMissileTargets.remove(jetId)
                if !impacted {
                    missile?.removeFromParent()
                }
            }
        ]))
    }

    private func spawnMissileSmoke(at pos: CGPoint) {
        let radius = CGFloat.random(in: 3...7)
        let smoke = SKShapeNode(circleOfRadius: radius)
        smoke.fillColor = UIColor(white: 0.75, alpha: 0.6)
        smoke.strokeColor = .clear
        smoke.position = pos
        smoke.zPosition = 7
        worldNode.addChild(smoke)

        smoke.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.6),
                SKAction.scale(to: 2.5, duration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnBaseExplosion(at point: CGPoint) {
        let explosion = SKNode()
        explosion.position = point
        explosion.zPosition = 10
        worldNode.addChild(explosion)

        // Bright flash
        let flash = SKShapeNode(circleOfRadius: 30)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 1.0
        explosion.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 5.0, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.25)
            ]),
            SKAction.removeFromParent()
        ]))

        // Fireballs
        let colors: [UIColor] = [.yellow, .orange, .red, UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)]
        for i in 0..<4 {
            let fireball = SKShapeNode(circleOfRadius: 18)
            fireball.fillColor = colors[i]
            fireball.strokeColor = .clear
            fireball.alpha = 0.9
            explosion.addChild(fireball)

            let delay = Double(i) * 0.05
            fireball.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: CGFloat(3.5 + Double(i) * 1.2), duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.55)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Flying debris chunks
        for _ in 0..<10 {
            let size = CGFloat.random(in: 3...7)
            let debris = SKSpriteNode(color: .darkGray, size: CGSize(width: size, height: size))
            debris.zPosition = 11
            explosion.addChild(debris)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 80...200)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist + 60  // bias upward

            debris.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.7),
                    SKAction.fadeOut(withDuration: 0.7)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Ground scorch mark that lingers
        let scorch = SKShapeNode(ellipseOf: CGSize(width: 70, height: 20))
        scorch.fillColor = UIColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 0.6)
        scorch.strokeColor = .clear
        scorch.position = point
        scorch.zPosition = 0.6
        worldNode.addChild(scorch)
        scorch.run(SKAction.sequence([
            SKAction.wait(forDuration: 5.0),
            SKAction.fadeOut(withDuration: 2.0),
            SKAction.removeFromParent()
        ]))

        explosion.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Entity Cleanup

    private func cleanupEntities() {
        tanks.removeAll { $0.parent == nil }
        jets.removeAll { $0.parent == nil }
        hostages.removeAll { $0.state == .dead && $0.parent == nil }
    }

    // MARK: - Mission Status

    private func checkMissionStatus() {
        // Win condition: all hostages accounted for, all alive ones rescued
        let allBarracksOpened = barracksArray.allSatisfy { $0.state != .closed }
        let livingHostagesInField = hostages.filter {
            $0.state == .released || $0.state == .walking || $0.state == .boarding
        }

        if totalRescued > 0 &&
           allBarracksOpened &&
           livingHostagesInField.isEmpty &&
           helicopter.passengers == 0 &&
           remainingHostages <= 0 {
            endGame(won: true)
            return
        }

        // Also win if we rescued every single hostage
        if totalRescued == totalHostages {
            endGame(won: true)
            return
        }

        // Lose condition: no lives left (handled in helicopterDestroyed)
        // Lose condition: all hostages dead
        if totalDead >= totalHostages {
            endGame(won: false)
            return
        }

        // Lose condition: no remaining rescuable hostages and none onboard and none in field
        if allBarracksOpened && remainingHostages <= 0 && livingHostagesInField.isEmpty &&
           helicopter.passengers == 0 && totalRescued == 0 {
            endGame(won: false)
            return
        }
    }

    // MARK: - Helicopter Destruction

    private func helicopterDestroyed() {
        lives -= 1

        // Kill any passengers onboard
        let lostPassengers = helicopter.passengers
        totalDead += lostPassengers

        // Explosion effect
        spawnExplosion(at: helicopter.position)

        if lives > 0 {
            hud.showMessage("HELICOPTER DESTROYED! LIVES: \(lives)", duration: 2.0)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run { [weak self] in
                    guard let self = self, !self.gameOver else { return }
                    self.helicopter.reset(at: CGPoint(
                        x: GameConfig.baseX,
                        y: GameConfig.groundLevel + 60
                    ))
                }
            ]))
        } else {
            hud.showMessage("GAME OVER", duration: 2.0)
            endGame(won: false)
        }
    }

    private func spawnExplosion(at point: CGPoint) {
        let explosion = SKNode()
        explosion.position = point
        explosion.zPosition = 10

        // Multiple expanding circles for a nice effect
        let colors: [UIColor] = [.orange, .red, .yellow]
        for i in 0..<3 {
            let circle = SKShapeNode(circleOfRadius: 15)
            circle.fillColor = colors[i]
            circle.strokeColor = .clear
            circle.alpha = 0.9
            explosion.addChild(circle)

            let delay = Double(i) * 0.08
            let expand = SKAction.scale(to: CGFloat(3.0 + Double(i) * 0.5), duration: 0.3)
            let fade = SKAction.fadeOut(withDuration: 0.4)
            circle.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([expand, fade]),
                SKAction.removeFromParent()
            ]))
        }

        worldNode.addChild(explosion)
        explosion.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Game End

    func endGame(won: Bool) {
        guard !gameOver else { return }
        gameOver = true
        missionWon = won

        let message = won ? "MISSION COMPLETE!" : "MISSION FAILED"
        hud.showMessage(message, duration: 3.0)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let scene = GameOverScene(size: GameConfig.sceneSize)
                scene.finalScore = self.score
                scene.rescued = self.totalRescued
                scene.totalHostages = self.totalHostages
                scene.dead = self.totalDead
                scene.won = won
                scene.scaleMode = .aspectFit
                self.view?.presentScene(scene, transition: SKTransition.crossFade(withDuration: 1.5))
            }
        ]))
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        guard !gameOver else { return }

        let catA = contact.bodyA.categoryBitMask
        let catB = contact.bodyB.categoryBitMask

        // Helper to find which body matches a given category
        func node(for category: UInt32) -> SKNode? {
            if catA == category { return contact.bodyA.node }
            if catB == category { return contact.bodyB.node }
            return nil
        }

        let combined = catA | catB

        // Player bullet + barracks
        if combined == PhysicsCategory.playerBullet | PhysicsCategory.barracks {
            handleBulletHitBarracks(bullet: node(for: PhysicsCategory.playerBullet),
                                    barracks: node(for: PhysicsCategory.barracks))
            return
        }

        // Player bullet + tank
        if combined == PhysicsCategory.playerBullet | PhysicsCategory.tank {
            handleBulletHitTank(bullet: node(for: PhysicsCategory.playerBullet),
                                tank: node(for: PhysicsCategory.tank))
            return
        }

        // Player bullet + jet
        if combined == PhysicsCategory.playerBullet | PhysicsCategory.jet {
            handleBulletHitJet(bullet: node(for: PhysicsCategory.playerBullet),
                               jet: node(for: PhysicsCategory.jet))
            return
        }

        // Player bullet + hostage (friendly fire)
        if combined == PhysicsCategory.playerBullet | PhysicsCategory.hostage {
            handleBulletHitHostage(bullet: node(for: PhysicsCategory.playerBullet),
                                   hostage: node(for: PhysicsCategory.hostage))
            return
        }

        // Enemy bullet + helicopter
        if combined == PhysicsCategory.enemyBullet | PhysicsCategory.helicopter {
            handleEnemyBulletHitHelicopter(bullet: node(for: PhysicsCategory.enemyBullet))
            return
        }

        // Player bomb + ground
        if combined == PhysicsCategory.playerBomb | PhysicsCategory.ground {
            handlePlayerBombImpact(bomb: node(for: PhysicsCategory.playerBomb), contactPoint: contact.contactPoint)
            return
        }

        // Player bomb + tank
        if combined == PhysicsCategory.playerBomb | PhysicsCategory.tank {
            handlePlayerBombImpact(bomb: node(for: PhysicsCategory.playerBomb), contactPoint: contact.contactPoint)
            return
        }

        // Player bomb + barracks
        if combined == PhysicsCategory.playerBomb | PhysicsCategory.barracks {
            handlePlayerBombImpact(bomb: node(for: PhysicsCategory.playerBomb), contactPoint: contact.contactPoint)
            return
        }

        // Player bomb + hostage
        if combined == PhysicsCategory.playerBomb | PhysicsCategory.hostage {
            handlePlayerBombImpact(bomb: node(for: PhysicsCategory.playerBomb), contactPoint: contact.contactPoint)
            return
        }

        // Enemy bullet + hostage
        if combined == PhysicsCategory.enemyBullet | PhysicsCategory.hostage {
            handleEnemyBulletHitHostage(bullet: node(for: PhysicsCategory.enemyBullet),
                                        hostage: node(for: PhysicsCategory.hostage))
            return
        }
    }

    // MARK: - Contact Handlers

    private func handleBulletHitBarracks(bullet: SKNode?, barracks: SKNode?) {
        bullet?.removeFromParent()
        guard let barracksNode = barracks as? Barracks else { return }

        if barracksNode.hit() {
            let released = barracksNode.releaseHostages()
            for hostage in released {
                worldNode.addChild(hostage)
                hostages.append(hostage)
            }
            score += GameConfig.scorePerBarracksOpened
            difficultyManager.onBarracksOpened()
            hud.showMessage("BARRACKS OPENED! \(released.count) HOSTAGES!", duration: 2.0)
        }
    }

    private func handleBulletHitTank(bullet: SKNode?, tank: SKNode?) {
        bullet?.removeFromParent()
        guard let tankNode = tank as? Tank else { return }

        if tankNode.takeDamage() {
            score += GameConfig.scorePerTankKill
        }
    }

    private func handleBulletHitJet(bullet: SKNode?, jet: SKNode?) {
        bullet?.removeFromParent()
        guard let jetNode = jet as? Jet else { return }

        if jetNode.takeDamage() {
            score += GameConfig.scorePerJetKill
        }
    }

    private func handleBulletHitHostage(bullet: SKNode?, hostage: SKNode?) {
        bullet?.removeFromParent()
        guard let hostageNode = hostage as? Hostage else { return }
        guard hostageNode.state != .dead && hostageNode.state != .onboard && hostageNode.state != .rescued else { return }

        hostageNode.kill()
        totalDead += 1
        hud.showMessage("HOSTAGE KILLED!", duration: 2.0)
    }

    private func handleEnemyBulletHitHelicopter(bullet: SKNode?) {
        bullet?.removeFromParent()
        guard !helicopter.isInvulnerable, helicopter.state != .destroyed else { return }

        if helicopter.takeDamage() {
            helicopterDestroyed()
        }
    }

    private func handleEnemyBulletHitHostage(bullet: SKNode?, hostage: SKNode?) {
        bullet?.removeFromParent()
        guard let hostageNode = hostage as? Hostage else { return }
        guard hostageNode.state != .dead && hostageNode.state != .onboard && hostageNode.state != .rescued else { return }

        hostageNode.kill()
        totalDead += 1
    }

    private func handlePlayerBombImpact(bomb: SKNode?, contactPoint: CGPoint) {
        guard let bombNode = bomb as? Bullet, bombNode.parent != nil else { return }

        bombNode.physicsBody?.categoryBitMask = PhysicsCategory.none
        bombNode.physicsBody?.contactTestBitMask = PhysicsCategory.none
        bombNode.removeFromParent()

        spawnExplosion(at: contactPoint)
        applyBombBlast(at: contactPoint)
    }

    private func applyBombBlast(at point: CGPoint) {
        let blastRadius = GameConfig.playerBombBlastRadius

        for tank in tanks {
            guard tank.parent != nil else { continue }
            if hypot(tank.position.x - point.x, tank.position.y - point.y) <= blastRadius {
                if tank.takeDamage() {
                    score += GameConfig.scorePerTankKill
                }
            }
        }

        for barracks in barracksArray {
            guard barracks.parent != nil else { continue }
            if hypot(barracks.position.x - point.x, barracks.position.y - point.y) <= blastRadius, barracks.hit() {
                let released = barracks.releaseHostages()
                for hostage in released {
                    worldNode.addChild(hostage)
                    hostages.append(hostage)
                }
                score += GameConfig.scorePerBarracksOpened
                difficultyManager.onBarracksOpened()
                hud.showMessage("BARRACKS OPENED! \(released.count) HOSTAGES!", duration: 2.0)
            }
        }

        for hostage in hostages {
            guard hostage.parent != nil else { continue }
            guard hostage.state != .dead && hostage.state != .onboard && hostage.state != .rescued else { continue }
            if hypot(hostage.position.x - point.x, hostage.position.y - point.y) <= blastRadius {
                hostage.kill()
                totalDead += 1
            }
        }
    }

    // MARK: - InputDelegate

    func inputMovement(dx: CGFloat, dy: CGFloat) {
        moveInputX = dx
        moveInputY = dy
    }

    func inputFire() {
        isFiring = true
    }

    func inputStopFire() {
        isFiring = false
    }

    func inputFacingChanged(_ direction: FacingDirection) {
        helicopter.setFacing(direction)
    }

    func inputPause() {
        isPaused = !isPaused
    }

    private func dropPlayerBomb() {
        guard helicopter.state != .destroyed else { return }

        let currentTime = CACurrentMediaTime()
        guard currentTime - lastBombTime >= GameConfig.playerBombCooldown else { return }
        guard let bomb = helicopter.dropBomb() else { return }

        worldNode.addChild(bomb)
        lastBombTime = currentTime
    }

    func keyboardMove(x: CGFloat, y: CGFloat) {
        keyboardInputX = x
        keyboardInputY = y
        moveInputX = keyboardInputX
        moveInputY = keyboardInputY
    }

    func keyboardSetFire(_ active: Bool) {
        isFiring = active
    }

    func keyboardFaceLeft() {
        helicopter.setFacing(.left)
    }

    func keyboardFaceRight() {
        helicopter.setFacing(.right)
    }

    func keyboardFaceForward() {
        helicopter.setFacing(.forward)
    }

    // MARK: - Keyboard / Remote Presses (Fallback)

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if handleKeyboardPressBegan(press) {
                continue
            }

            switch press.type {
            case .select:
                isFiring = true
            case .playPause:
                cycleFacing()
            case .upArrow:
                moveInputY = 1.0
            case .downArrow:
                moveInputY = -1.0
            case .leftArrow:
                moveInputX = -1.0
            case .rightArrow:
                moveInputX = 1.0
            case .menu:
                inputPause()
            default:
                break
            }
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if handleKeyboardPressEnded(press) {
                continue
            }

            switch press.type {
            case .select:
                isFiring = false
            case .upArrow:
                if moveInputY > 0 { moveInputY = 0 }
            case .downArrow:
                if moveInputY < 0 { moveInputY = 0 }
            case .leftArrow:
                if moveInputX < 0 { moveInputX = 0 }
            case .rightArrow:
                if moveInputX > 0 { moveInputX = 0 }
            default:
                break
            }
        }
    }

    private var facingCycleIndex = 0

    private func cycleFacing() {
        let directions: [FacingDirection] = [.right, .left, .forward]
        facingCycleIndex = (facingCycleIndex + 1) % directions.count
        helicopter.setFacing(directions[facingCycleIndex])
    }

    private func handleKeyboardPressBegan(_ press: UIPress) -> Bool {
        guard let input = press.key?.charactersIgnoringModifiers.lowercased() else { return false }

        switch input {
        case " ":
            isFiring = true
            return true
        case "w":
            moveInputY = 1.0
            return true
        case "s":
            moveInputY = -1.0
            return true
        case "a":
            moveInputX = -1.0
            return true
        case "d":
            moveInputX = 1.0
            return true
        case "q":
            helicopter.setFacing(.left)
            return true
        case "e":
            helicopter.setFacing(.right)
            return true
        case "f":
            helicopter.setFacing(.forward)
            return true
        case "p":
            inputPause()
            return true
        default:
            return false
        }
    }

    private func handleKeyboardPressEnded(_ press: UIPress) -> Bool {
        guard let input = press.key?.charactersIgnoringModifiers.lowercased() else { return false }

        switch input {
        case " ":
            isFiring = false
            return true
        case "w":
            if moveInputY > 0 { moveInputY = 0 }
            return true
        case "s":
            if moveInputY < 0 { moveInputY = 0 }
            return true
        case "a":
            if moveInputX < 0 { moveInputX = 0 }
            return true
        case "d":
            if moveInputX > 0 { moveInputX = 0 }
            return true
        default:
            return false
        }
    }
}
