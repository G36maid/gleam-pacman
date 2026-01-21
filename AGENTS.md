# Agent Operational Guide - Gleam Pacman

This document defines the operational parameters, code style, and development workflow for AI agents working on the `pacman` repository.

## 1. Project Context
- **Language**: Gleam (Type-safe, functional language on Erlang VM/JavaScript runtime).
- **Engine**: [Tiramisu](https://hexdocs.pm/tiramisu/) (Game engine) + [Lustre](https://hexdocs.pm/lustre/) (UI).
- **Architecture**: Functional MVU (Model-View-Update) pattern.
- **Target**: JavaScript (runs in browser).

## 2. Development Workflow

### Build & Run
- **Live Dev Server**: `gleam run -m lustre/dev start` (Compiles, watches, serves at localhost:1234).
- **Manual Build**: `gleam build --target javascript`.
- **Check Types**: `gleam check` (Fast type checking without running).
- **Format Code**: `gleam format` (ALWAYS run this before committing).

### Testing
- **Run All Tests**: `gleam test`
- **Run Specific Test Module**: `gleam test test/pacman_test.gleam`
- **Testing Library**: `gleeunit`. Use `should.equal`, `should.be_ok`.

### Dependency Management
- **Add Package**: `gleam add <package>`
- **Remove Package**: `gleam remove <package>`
- **Update**: `gleam update`

## 3. Code Style & Conventions

### General Gleam Patterns
- **Pipe Operator**: Heavily prefer `|>` for chaining.
  ```gleam
  // Good
  list.map(items, fn(x) { x * 2 }) |> list.filter(fn(x) { x > 10 })
  ```
- **Pattern Matching**: Use `case` for control flow, `Result`, and `Option`.
- **Immutability**: Functions return *new* versions of state. No mutation.

### Naming Conventions
- **Modules**: `snake_case` (e.g., `game_state.gleam`).
- **Functions/Variables**: `snake_case` (e.g., `update_player`).
- **Types/Constructors**: `CamelCase` (e.g., `GameState`, `Tick`).
- **Constants**: `snake_case` (in `constants.gleam`).

### Imports
- Group: stdlib -> external -> internal.
- Aliasing: `import gleam/option.{type Option, Some, None}`.

### Project Architecture
- **State**: `src/pacman/game_state.gleam` (Core types).
- **Systems**: `src/pacman/systems/` (Pure logic: movement, AI, collision).
- **Rendering**: Tiramisu scene nodes built in `view` (declarative).
- **UI**: Lustre UI overlays in `src/pacman/game_ui.gleam`.
- **Entry**: `src/pacman.gleam` (MVU loop wiring).

### Error Handling
- Prefer `Result(Ok, Error)`.
- Use `let assert` ONLY when mathematically certain (e.g., static data).
- Handle `None`/`Error` gracefully in game logic loop.

## 4. Implementation Guidelines

1.  **Pure Logic**: Logic in `systems/` must be pure (State + Inputs -> New State).
2.  **No Side Effects**: I/O only via `Effect` return types.
3.  **Tiramisu Setup**:
    - Orthographic Camera (2D view).
    - Scene graph built fresh each frame (functional declarative style).
    - Assets/Geometry created via `tiramisu/geometry` and `tiramisu/material`.
4.  **Lustre Integration**: UI and Game Loop talk via `BridgeMsg`.

## 5. File Structure Strategy
- `src/pacman/constants.gleam`: Magic numbers.
- `src/pacman/maze.gleam`: Static level data.
- `src/pacman/bridge_msg.gleam`: Inter-process communication types.

## 6. Commit Message Format
- `feat: add ghost scatter mode`
- `fix: correct collision box`
- `refactor: move movement logic`
- `docs: update readme`
