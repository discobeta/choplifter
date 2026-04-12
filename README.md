# ChopLifter

A modern reimagining of the classic Choplifter arcade game, built with SpriteKit for Apple TV.

Pilot a combat helicopter behind enemy lines to rescue hostages from barracks and return them safely to base — all while dodging tanks, jets, and escalating enemy forces.

## Gameplay

- **Fly** your helicopter across a scrolling battlefield
- **Shoot open** barracks to release hostages (4 barracks, 16 hostages each — 64 total)
- **Land carefully** near hostages to load them (max 16 per trip)
- **Return to base** to drop off survivors
- **Repeat** until all hostages are rescued or lost

Watch out for:
- **Tanks** that patrol the ground and fire on your helicopter
- **Jets** that strafe from the air with missiles and bombs
- **Friendly fire** — your own bullets can kill hostages
- **Bad landings** — crush hostages by landing on them

Difficulty escalates with each successful rescue trip.

## Controls

Designed for the Apple TV Siri Remote:

| Input | Action |
|-------|--------|
| Swipe / Touchpad | Move helicopter |
| Click | Fire |
| Menu | Pause |

## Requirements

- Xcode 15+
- tvOS 17+
- Apple TV (4th generation or later)

## Building

1. Open `ChopLifter.xcodeproj` in Xcode
2. Select the Apple TV simulator or a connected Apple TV
3. Build and run (Cmd+R)

## Project Structure

```
ChopLifter/
├── GameScene.swift        # Main gameplay scene
├── GameViewController.swift
├── MenuScene.swift        # Title / start screen
├── GameOverScene.swift    # End-of-game screen
├── Helicopter.swift       # Player helicopter logic
├── Hostage.swift          # Hostage behavior & states
├── Barracks.swift         # Barracks building logic
├── Base.swift             # Home base / drop-off point
├── Tank.swift             # Tank enemy AI
├── Jet.swift              # Jet enemy AI
├── Bullet.swift           # Projectile handling
├── HUDNode.swift          # Heads-up display
├── InputManager.swift     # Siri Remote input handling
├── DifficultyManager.swift# Escalation system
├── MusicManager.swift     # Background music
├── Constants.swift        # Game configuration & enums
└── Assets.xcassets/       # Sprites and images
```

## License

All rights reserved.
