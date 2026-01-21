# Gleam Pacman 🕹️

A fully functional **classic Pac-Man game** built with [Gleam](https://gleam.run/) and the [Tiramisu game engine](https://hexdocs.pm/tiramisu/).

**🎮 Play Now**: [https://g36maid.github.io/gleam-pacman/pacman/](https://g36maid.github.io/gleam-pacman/pacman/)

## Features

- 🎯 **Classic Gameplay** - Faithful recreation of the original Pac-Man
- 👻 **Smart Ghost AI** - Four unique ghost personalities (Blinky, Pinky, Inky, Clyde)
- 🔄 **Mode Cycling** - Authentic scatter/chase/frightened mode system
- 🏆 **Scoring System** - Points, combos, lives, and level progression
- 🎨 **Orthographic 2D Rendering** - Clean top-down view using Tiramisu 3D engine
- ⚡ **Functional MVU Architecture** - Immutable state, pure functions

## How to Play

- **Move**: `WASD` or `Arrow Keys`
- **Goal**: Eat all dots to complete the level
- **Power Pellets**: Eat ghosts for bonus points (200/400/800/1600)
- **Lives**: 3 starting lives, lose one when caught by a ghost
- **Game Over**: Reach 0 lives

### Ghost Personalities

| Ghost | Color | Behavior |
|-------|-------|----------|
| **Blinky** 🔴 | Red | Aggressive direct chaser |
| **Pinky** 🩷 | Pink | Ambusher (targets 4 tiles ahead) |
| **Inky** 🩵 | Cyan | Flanker (complex targeting with Blinky) |
| **Clyde** 🟠 | Orange | Shy patrol (retreats when close) |

## Development

### Prerequisites

- [Gleam](https://gleam.run/getting-started/installing/) (v1.6.0+)
- [Node.js](https://nodejs.org/) (for live-server)

### Run Locally

Tiramisu games require a browser environment with module support. Use a local dev server:

```sh
# Quick start (automatically picks an available server)
./dev.sh

# Then open in browser:
# http://localhost:1234/pacman/  <-- Don't forget the /pacman/ part!

# Or manually:
gleam build
cp index.html build/dev/javascript/pacman/
cd build/dev/javascript

# Then start a dev server (choose one):
# Python
python3 -m http.server 1234

# PHP
php -S localhost:1234

# npx (no installation)
npx -y live-server@1.2.2 . --port=1234 --open=pacman/

# Open http://localhost:1234/pacman/ in your browser
```

**Important**: 
- `gleam run` won't work (Tiramisu uses browser APIs and CDN imports)
- Serve from `build/dev/javascript/` not `pacman/` subdirectory (module imports need parent paths)
- Access via http://localhost:1234/pacman/ not root

### Format Code

```sh
gleam format
```

### Type Check

```sh
gleam check
```

## Architecture

```
src/
├── pacman.gleam                    # Main MVU game loop
└── pacman/
    ├── constants.gleam             # Game constants (speeds, colors, scores)
    ├── game_state.gleam            # State types & conversions
    ├── maze.gleam                  # Classic 28x31 maze layout
    ├── ui.gleam / ui.ffi.mjs       # UI overlay (score, lives, level)
    └── systems/
        ├── movement.gleam          # Grid-based movement with turn buffering
        ├── ghost_ai.gleam          # Ghost personalities & pathfinding
        ├── ghost_mode.gleam        # Scatter/chase/frightened mode cycling
        └── collision.gleam         # Collision detection & scoring
```

### Key Technologies

- **Language**: [Gleam](https://gleam.run/) - Type-safe functional programming
- **Engine**: [Tiramisu 7.0.0](https://hexdocs.pm/tiramisu/) - Game engine on Three.js
- **Pattern**: MVU (Model-View-Update) - Immutable state architecture
- **Target**: JavaScript (runs in browser)

## Game Mechanics

- **Tile Size**: 16px (2x classic size)
- **Pacman Speed**: 8.0 tiles/second
- **Ghost Speed**: 7.5 (chase) / 6.0 (scatter) / 4.0 (frightened)
- **Frightened Duration**: 6 seconds
- **Mode Cycles**: 7s scatter → 20s chase (repeating 4x, then infinite chase)

## Deployment

The game auto-deploys to GitHub Pages via GitHub Actions on push to `main`.

**CI/CD**: `.github/workflows/deploy.yml`

## License

This project is open source.

## Credits

Built with ❤️ using Gleam and Tiramisu by [G36maid](https://github.com/G36maid)
