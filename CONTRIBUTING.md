# Contributing to ChopLifter

Thanks for your interest in contributing! Here's how to get started.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone git@github.com:YOUR_USERNAME/choplifter.git
   cd choplifter
   ```
3. Open `ChopLifter.xcodeproj` in Xcode
4. Create a feature branch:
   ```bash
   git checkout -b my-feature
   ```

## Development Setup

- **Xcode 15+** is required
- Target platform is **tvOS 17+**
- The project uses **SpriteKit** with no external dependencies

Build and run on the Apple TV simulator to test your changes.

## Making Changes

### Code Style

- Follow existing Swift conventions in the codebase
- Use meaningful names for variables and functions
- Keep files focused — one major type per file

### What to Work On

Check the open issues for things that need help. Good first contributions:

- Bug fixes
- New enemy types
- Visual polish and particle effects
- Sound effects
- Gameplay balancing tweaks
- Documentation improvements

### Game Architecture

The game uses a component-based approach with SpriteKit:

- **Scenes** (`GameScene`, `MenuScene`, `GameOverScene`) manage game states
- **Entity files** (`Helicopter`, `Tank`, `Jet`, `Hostage`, `Barracks`, `Base`) each own their sprite nodes and behavior
- **Managers** (`DifficultyManager`, `MusicManager`, `InputManager`) handle cross-cutting concerns
- **Constants.swift** centralizes all tuning values — adjust gameplay here

### Testing Your Changes

- Run the game on the tvOS simulator
- Verify the full rescue loop works: fly out, open barracks, land, load hostages, return to base
- Check that existing enemies and scoring still work
- Test with the Siri Remote (simulator supports keyboard input)

## Submitting Changes

1. Commit your changes with a clear message:
   ```bash
   git commit -m "Add particle effects for helicopter explosion"
   ```
2. Push to your fork:
   ```bash
   git push origin my-feature
   ```
3. Open a Pull Request against `main`
4. Describe what you changed and why

## Reporting Bugs

Open an issue with:

- What you expected to happen
- What actually happened
- Steps to reproduce
- tvOS version and device/simulator info

## Code of Conduct

Be respectful and constructive. We're all here to make a fun game.
