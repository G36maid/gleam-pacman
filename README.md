# Gleam Pacman 🕹️

A fully functional **classic Pac-Man game** built with [Gleam](https://gleam.run/) and the [Tiramisu game engine](https://hexdocs.pm/tiramisu/).

**🎮 Play Now**: [https://G36maid.github.io/gleam-pacman/pacman/](https://G36maid.github.io/gleam-pacman/pacman/)

## Features

- 🎯 **Classic Gameplay** - Faithful recreation of the original Pac-Man with complete menu system
- 👻 **Smart Ghost AI** - Four unique ghost personalities (Blinky, Pinky, Inky, Clyde)
- 🏠 **Ghost House System** - Authentic ghost release timing and return-to-home behavior
- 🔄 **Mode Cycling** - Authentic scatter/chase/frightened mode system
- 🏆 **Scoring System** - Points, combos, lives, and level progression
- 🎨 **3D Rendering** - Smooth orthographic 2D view using Tiramisu 3D engine
- ⚡ **Functional MVU Architecture** - Immutable state, pure functions
- 📱 **Menu System** - Start menu, level complete, game over screens

## How to Play

- **Start Game**: Press `SPACE` at the start menu
- **Move**: `WASD` or `Arrow Keys`
- **Goal**: Eat all dots to complete the level
- **Power Pellets**: Turn ghosts blue and eat them for bonus points (200/400/800/1600)
- **Lives**: 3 starting lives, lose one when caught by a ghost
- **Level Complete**: Press `SPACE` to continue to next level
- **Game Over**: Press `SPACE` to restart

### Ghost Personalities

| Ghost | Color | Behavior |
|-------|-------|----------|
| **Blinky** 🔴 | Red | Aggressive direct chaser (starts outside) |
| **Pinky** 🩷 | Pink | Ambusher (targets 4 tiles ahead, exits immediately) |
| **Inky** 🩵 | Cyan | Flanker (complex targeting with Blinky, exits after 30 dots) |
| **Clyde** 🟠 | Orange | Shy patrol (retreats when close, exits after 82 dots) |

**Ghost House Mechanics:**
- Ghosts exit the house at specific timings based on dots eaten
- Eaten ghosts turn blue and flee at 50% speed
- After being eaten, ghosts return to the house at 2x speed
- Returning ghosts phase through all walls to navigate back home

## Development

### Prerequisites

- [Gleam](https://gleam.run/getting-started/installing/) (v1.6.0+)

### Run Locally (Recommended: Lustre Dev Server)

The easiest way to run the game is using the Lustre dev server with live-reload:

```sh
gleam run -m lustre/dev start
```

This automatically:
- Compiles the Gleam code to JavaScript
- Starts a dev server on http://localhost:1234
- Opens your browser
- Watches for file changes and reloads automatically

**Just run the command above and start playing!**

### Alternative: Manual Build

If you prefer manual control or need to serve from a specific location:

```sh
gleam build
cp index.html build/dev/javascript/pacman/
cd build/dev/javascript

# Then start a dev server (choose one):
python3 -m http.server 1234
# OR
php -S localhost:1234
# OR
npx -y live-server@1.2.2 . --port=1234 --open=pacman/

# Open http://localhost:1234/pacman/ in your browser
```

**Note**: `gleam run` won't work directly (Tiramisu uses browser APIs and CDN imports)

### Format Code

```sh
gleam format
```

### Type Check

```sh
gleam check
```

### Run Tests

```sh
gleam test
```

## Architecture

```
src/
├── pacman.gleam                    # Main MVU game loop with menu state machine
└── pacman/
    ├── constants.gleam             # Game constants (speeds, colors, scores)
    ├── game_state.gleam            # State types (Player, Ghost, GamePhase)
    ├── maze.gleam                  # Classic 28x31 maze layout
    ├── game_ui.gleam               # Lustre UI (menus, overlays)
    ├── bridge_msg.gleam            # Tiramisu-Lustre bridge messages
    └── systems/
        ├── movement.gleam          # Grid-based movement with turn buffering
        ├── ghost_ai.gleam          # Ghost personalities, pathfinding, house logic
        ├── ghost_collision.gleam   # Ghost collision detection & eating
        └── collision.gleam         # Dot/pellet collision & scoring
```

### Key Technologies

- **Language**: [Gleam](https://gleam.run/) - Type-safe functional programming
- **Game Engine**: [Tiramisu 7.0.0](https://hexdocs.pm/tiramisu/) - 3D game engine on Three.js
- **UI Framework**: [Lustre](https://hexdocs.pm/lustre/) - Gleam web framework
- **Pattern**: MVU (Model-View-Update) - Immutable state architecture
- **Target**: JavaScript (runs in browser)

### Performance Optimizations

The game uses several rendering optimizations for smooth 60 FPS gameplay:

- **Shared Geometry/Materials** - Assets created once and reused across frames (100x reduction in allocations)
- **Instanced Mesh Rendering** - All dots rendered in 1 draw call instead of 240+
- **Optimized Polygon Count** - Low-poly spheres (8×6 segments) for small objects
- **Efficient Scene Graph** - Minimal hierarchy depth for fast transform calculations

These optimizations ensure smooth performance even on lower-end devices.

## Game Mechanics

### Movement & Speed
- **Tile Size**: 16px (2x classic size for readability)
- **Pacman Speed**: 8.0 tiles/second
- **Ghost Speed**: 
  - Chase: 7.5 tiles/second
  - Scatter: 7.5 tiles/second
  - Frightened: 4.0 tiles/second
  - Eaten (returning): 15.0 tiles/second (2x normal)

### Timing
- **Power Mode Duration**: 8 seconds
- **Mode Cycles**: 7s scatter → 20s chase (repeating 4x, then infinite chase)
- **Ghost House Release**: Based on dots eaten (Blinky out, Pinky 0, Inky 30, Clyde 82)

### Scoring
- **Dot**: 10 points
- **Power Pellet**: 50 points
- **Ghosts** (combo multiplier): 200 → 400 → 800 → 1600 points

## Deployment

The game auto-deploys to GitHub Pages via GitHub Actions on push to `main`.

**Live Demo**: [https://G36maid.github.io/gleam-pacman/pacman/](https://G36maid.github.io/gleam-pacman/pacman/)

**CI/CD**: `.github/workflows/deploy.yml`

## License

This project is open source.
