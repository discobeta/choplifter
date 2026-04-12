Here’s a solid PRD draft you can hand to Codex and refine.

---

# PRD: ChipLifter-Inspired Hostage Rescue Game

## Document status

Draft v1

## Purpose

Define the product requirements for a modern implementation of a **ChipLifter-inspired arcade action game** in which the player pilots a combat helicopter to rescue hostages from enemy territory and return them safely to base while under escalating attack.

## Product summary

The game is a side-view arcade action game centered on a repeating rescue loop:

1. Fly into hostile territory.
2. Destroy a barracks building to release hostages.
3. Land safely near the hostages.
4. Load as many hostages as possible.
5. Return them to base.
6. Repeat until all hostages are rescued or the player is destroyed.

The challenge comes from tight helicopter controls, directional aiming, fragile hostages, limited passenger capacity, and escalating enemy pressure across multiple rescue trips.

## Goals

Create a game that:

* Preserves the core feel of classic hostage rescue helicopter gameplay.
* Is immediately playable and understandable.
* Emphasizes skillful flying, careful landing, and risk-reward decision making.
* Scales difficulty over the course of a mission.
* Is structured cleanly enough for Codex to implement in phases.

## Non-goals

This version does not need:

* A full campaign mode
* Narrative cutscenes
* Online multiplayer
* Complex progression systems
* Realistic simulation-grade flight physics
* Perfect historical recreation of any one original platform version

---

# 1. Core player fantasy

The player is an elite helicopter pilot conducting repeated extractions behind enemy lines. They must balance aggression and precision: attack enemy forces, release hostages, land carefully, load survivors, and escape before the battlefield becomes overwhelmed.

---

# 2. Target experience

The game should feel:

* Tense
* Responsive
* Arcadey
* Increasingly chaotic over time
* Punishing of sloppy landings and reckless fire
* Rewarding when the player executes clean rescue runs

---

# 3. Core gameplay loop

## Mission loop

During a mission, the player:

* Starts at base.
* Travels to one of several hostage barracks.
* Fires on a barracks to release its hostages.
* Lands near the building exit.
* Waits while hostages board the helicopter.
* Returns to base to unload them.
* Repeats until all hostages are rescued or dead, or until the player loses all lives / is destroyed.

## Loop constraints

* Each barracks contains 16 hostages.
* There are 4 barracks total.
* Total hostages per mission: 64.
* The helicopter can carry a maximum of 16 hostages at once.
* This requires multiple rescue trips.
* Each successive rescue trip should increase danger.

---

# 4. Gameplay requirements

## 4.1 Player helicopter

### Functional requirements

The helicopter must:

* Move horizontally left and right.
* Ascend and descend.
* Hover.
* Land on the ground.
* Face in three aiming directions:

  * Left
  * Right
  * Forward (toward the camera / screen)
* Fire while facing any of those directions.
* Move independently of facing direction.

### Design intent

The player should be able to:

* Fly left while aiming right.
* Hover while aiming forward to attack tanks.
* Retreat while firing in a different direction from movement.

### Suggested controls

* Move: WASD or arrow keys
* Aim/facing left/right/forward: separate input or automatic with manual override
* Fire: primary action
* Optional: land is achieved by controlled descent rather than a dedicated button

### Acceptance criteria

* Helicopter movement is responsive and readable.
* Aiming direction is visually clear at all times.
* The helicopter can fire while stationary or moving.
* Facing direction does not forcibly determine movement direction.

---

## 4.2 Landing and takeoff

### Functional requirements

The helicopter must be able to:

* Land on reasonably flat landing zones.
* Remain grounded.
* Take off again after boarding.

### Failure conditions

Hostages die if:

* The helicopter lands directly on them.
* The helicopter completely blocks the building exit.
* The helicopter is not landed properly during boarding.

For the first implementation, “not landed properly” should mean:

* The helicopter is outside the safe landing zone, or
* The helicopter’s tilt exceeds an allowed threshold while boarding.

### Design recommendation

Codex should implement a simple landing validation system:

* Safe landing zone rectangle near each barracks exit
* Grounded state only if velocity is low and helicopter is aligned within tolerance
* Unsafe landing causes hostage casualties if boarding is attempted

### Acceptance criteria

* Players can clearly tell when landing is safe versus unsafe.
* Unsafe landings can kill hostages.
* Grounded helicopters cannot effectively shoot tanks unless they lift off first.

---

## 4.3 Hostages

### Functional requirements

Hostages must:

* Remain inside a barracks until that barracks is shot open.
* Exit the barracks once released.
* Walk toward the helicopter if it is safely landed nearby and has capacity.
* Board one at a time or in a small stream.
* Stop attempting to board once helicopter capacity is full.
* Wait for the helicopter’s return if more hostages remain.

### Capacity rules

* Each barracks starts with 16 hostages.
* Helicopter max capacity: 16.
* When helicopter is full, additional hostages should wave off or remain idle near the barracks.

### Death rules

Hostages die if:

* Hit by enemy fire
* Hit by player fire
* Crushed by the helicopter
* Blocked in a way that causes boarding failure

### Acceptance criteria

* Barracks release exactly 16 hostages each.
* Helicopter never exceeds 16 passengers.
* Unboarded hostages persist in the level until rescued or killed.
* Friendly fire can kill hostages.

---

## 4.4 Barracks / hostage buildings

### Functional requirements

* There are 4 hostage barracks in enemy territory.
* Each begins closed and occupied.
* Shooting a barracks opens it and releases its hostages.
* A barracks should only need to be opened once.
* Destroying or opening the barracks must not kill all hostages by default.

### Open question for implementation

To preserve the described behavior, the building should likely transition from:

* Closed state
* Opened/released state

rather than being fully removed from the game world.

### Acceptance criteria

* Shooting a closed barracks triggers hostage release.
* Released hostages appear at the building exit.
* Each building can only release its group once.

---

## 4.5 Base / drop-off point

### Functional requirements

* The player starts at base.
* The player unloads rescued hostages at base.
* Returning to base safely converts onboard hostages into rescued score/state.

### Acceptance criteria

* Landing at base unloads all currently onboard hostages.
* Unloaded hostages count as rescued and are removed from the helicopter.
* Mission progress updates immediately after unloading.

---

# 5. Enemy systems

## 5.1 Tanks

### Functional requirements

* Tanks patrol or position themselves on the ground.
* Tanks attack the helicopter while it is near or grounded.
* Tanks are primarily targeted by the helicopter’s forward-facing firing mode.

### Key rule

While grounded, the helicopter cannot effectively shoot tanks and must take off to engage them.

### Acceptance criteria

* Tanks can threaten landing zones.
* Tanks force the player to manage timing around landings.
* Forward-facing attack mode is useful and sometimes necessary.

---

## 5.2 Enemy jets

### Functional requirements

* Enemy jets appear after some delay or based on mission escalation.
* Jets attack the helicopter in the air with missiles.
* Jets can attack grounded helicopters with bombs.

### Acceptance criteria

* Jets become a major threat after early rescue trips.
* Airborne attacks and grounded attacks are distinct and readable.
* Jets increase urgency and reduce safe hovering.

---

## 5.3 Alien spacecraft

### Functional requirements

* A late-stage high-threat enemy appears after sufficient escalation.
* It is significantly harder to avoid than earlier enemies.
* It should act as a climax threat for prolonged missions.

### Design recommendation

For first implementation:

* Spawn condition based on rescue progress or elapsed danger level
* Faster movement and/or harder-to-evade projectile pattern than jets

### Acceptance criteria

* Alien enemy appears only in advanced danger states.
* Encounter feels more dangerous than jets.
* It materially changes player behavior.

---

## 5.4 Enemy escalation

### Functional requirements

The game must become more dangerous after each successive rescue trip.

### Escalation levers

Difficulty may increase by:

* Higher enemy spawn rate
* More tanks active
* More frequent jet attacks
* Faster projectile speed
* Reduced delay between enemy waves
* Earlier alien appearance

### Recommendation

Use a mission danger level that increments whenever:

* The player successfully unloads hostages at base, or
* A new barracks is opened

### Acceptance criteria

* The first rescue run is noticeably safer than later runs.
* Later runs feel more crowded and punishing.
* Difficulty increase is steady and understandable.

---

# 6. Combat

## 6.1 Player weapons

The helicopter can fire in:

* Left direction
* Right direction
* Forward direction

### Firing rules

* Left/right fire hits airborne or lateral threats in those directions.
* Forward fire is intended for tanks or frontal threats.
* Fire rate should be arcade-fast and responsive.

### Acceptance criteria

* All 3 firing directions are distinct in gameplay value.
* Projectiles spawn from the correct firing mode.
* Firing feedback is immediate.

## 6.2 Friendly fire

The player can kill hostages with their own weapons.

### Acceptance criteria

* Player bullets can damage hostages.
* Friendly fire is clearly communicated.
* Hostage casualties affect score and mission outcome.

---

# 7. Mission structure

## Mission completion

A mission is completed when:

* All surviving hostages have been rescued and delivered to base, and
* No unreleased or uncollected surviving hostages remain in the field

## Mission failure

A mission fails when:

* The helicopter is destroyed and the player has no remaining lives, or
* All hostages are dead and no rescue is possible

## Optional lives system

For MVP, choose one:

* Single-life mission restart, or
* 3 lives per game session

### Recommendation

Use 3 lives for arcade accessibility.

---

# 8. Scoring

## Required scoring events

Award points for:

* Destroying enemy vehicles
* Releasing hostages
* Loading hostages
* Successfully delivering hostages to base

Penalize or track:

* Hostages killed by enemy fire
* Hostages killed by player fire
* Hostages crushed during bad landing

### Recommendation

Primary score weights:

* Small reward for combat
* Large reward for successful rescues
* Bigger bonus for perfect or near-perfect extractions

### Acceptance criteria

* Score increases reliably on rescue progress.
* Saving hostages is more valuable than farming enemies.
* Hostage losses are reflected in score and end-of-mission stats.

---

# 9. HUD / UI

## Required HUD elements

Display:

* Remaining lives
* Current onboard hostage count
* Total rescued hostages
* Total remaining hostages
* Score
* Danger level or wave intensity
* Optional fuel/health if implemented

## Feedback requirements

The UI should clearly communicate:

* When the helicopter is safe to land
* When the helicopter is full
* When hostages are boarding
* When base unloading occurs
* When a barracks has already been opened

### Acceptance criteria

* Player can always tell mission progress at a glance.
* Capacity limit is obvious.
* Rescue and loss events are clearly signaled.

---

# 10. Camera and perspective

## Perspective

* Primary gameplay view: 2D side-view battlefield
* Helicopter sprite/art supports left, right, and forward-facing presentation

## Camera behavior

* Camera follows helicopter smoothly.
* Base and rescue targets are reachable without confusion.
* Player can understand where they are relative to base and barracks.

### Recommendation

Use a horizontal scrolling map with fixed world landmarks.

---

# 11. World layout

## Minimum world requirements

The level must include:

* 1 player base / drop-off zone
* 4 hostage barracks
* Ground surfaces for tanks
* Air space for helicopter and jets
* Adequate separation between base and enemy barracks to require meaningful travel

## Recommendation

A single horizontally scrolling battlefield:

* Base on one side
* Barracks distributed across hostile territory
* Enemy spawns intensify farther from base or later in mission

---

# 12. Game states

Required game states:

* Main menu
* In mission
* Paused
* Mission complete
* Game over

Optional:

* Briefing screen
* High score screen
* Restart checkpoint or retry screen

---

# 13. MVP scope

## Must-have

* Helicopter movement and 3-direction facing
* Shooting in all 3 directions
* 4 barracks with 16 hostages each
* Base loading/unloading loop
* Landing validation
* Hostage boarding behavior
* Friendly fire
* Tanks
* Jets
* Difficulty escalation
* Win/lose conditions
* Basic HUD
* Scoring

## Nice-to-have

* Alien spacecraft
* Multiple levels
* Multiple helicopter damage states
* Audio polish
* Particle effects
* Performance stats screen
* Leaderboard

## Defer

* Campaign progression
* Save system
* Advanced AI behaviors
* Narrative scenes

---

# 14. Technical recommendations for Codex

## Suggested architecture

Implement with separate systems/modules for:

* Player controller
* Helicopter state machine
* Weapon/firing system
* Hostage manager
* Building/barracks manager
* Enemy spawner
* Enemy AI
* Scoring/state manager
* UI/HUD
* Mission progression manager

## Recommended helicopter states

* Flying
* Hovering
* Landing
* Grounded
* Taking off
* Destroyed

## Recommended hostage states

* InBuilding
* Released
* Waiting
* Boarding
* Onboard
* Rescued
* Dead

## Recommended barracks states

* Closed
* Opened
* Empty

## Recommended enemy classes

* Tank
* Jet
* AlienCraft

---

# 15. Acceptance criteria for MVP

The MVP is complete when a tester can:

1. Start a mission from base.
2. Fly to a barracks.
3. Shoot it open.
4. Watch hostages emerge.
5. Land safely nearby.
6. Load hostages up to max capacity 16.
7. Return to base and unload them.
8. Repeat multiple trips.
9. Fight tanks and jets during the process.
10. Lose hostages through enemy fire, friendly fire, or bad landing.
11. Observe difficulty increasing over time.
12. Finish the mission by rescuing survivors or lose by destruction / total hostage loss.

---

# 16. Open design decisions

These should be resolved before implementation begins:

## A. Exact tone

* Serious military
* Retro arcade
* Light parody / homage

## B. Visual style

* Pixel art remake
* Clean retro vector style
* Modern 2D stylized

## C. Health model

* One-hit death
* Multi-hit helicopter health
* Damage states with smoke/fire

## D. Respawn model

* Instant respawn at base
* Limited lives with reset
* Full mission restart on death

## E. Enemy spawn logic

* Time-based only
* Rescue-progress based
* Hybrid

## F. Alien inclusion

* Included in MVP
* Included in v1.1

---

# 17. Suggested implementation phases for Codex

## Phase 1: Core flight and map

* Helicopter movement
* Camera
* Basic level with base and barracks
* World collisions

## Phase 2: Rescue loop

* Barracks opening
* Hostage spawning
* Landing validation
* Boarding
* Base unloading

## Phase 3: Combat

* Directional firing
* Tanks
* Jets
* Damage and destruction

## Phase 4: Game rules

* Capacity limits
* Scoring
* Win/loss logic
* Difficulty escalation

## Phase 5: Polish

* Effects
* Audio
* UI improvements
* Alien craft
* Balancing

---

# 18. Prompt-ready summary for Codex

Build a 2D side-scrolling arcade helicopter rescue game inspired by Choplifter. The player controls a helicopter that can move freely and aim/fire in three directions: left, right, and forward. The map contains a base and four hostage barracks. Each barracks contains 16 hostages. The player must shoot a barracks to release hostages, land safely near the exit, load up to 16 hostages, and transport them back to base. Hostages can be killed by enemy fire, player fire, being crushed by the helicopter, or by unsafe landing/blocked exits. Enemies include tanks, which are best attacked with the helicopter’s forward-facing shot, and jets, which attack airborne helicopters with missiles and grounded helicopters with bombs. Difficulty should escalate with each rescue trip. Implement clear win/loss conditions, HUD, score tracking, and a complete playable loop.
