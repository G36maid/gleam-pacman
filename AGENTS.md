# Agent Operational Guide - Gleam Pacman

This document defines the operational parameters, code style, and development workflow for AI agents working on the `gleam-pacman` repository.

## 1. Project Context
- **Language**: Gleam (Type-safe, functional language on the Erlang VM/JavaScript runtime).
- **Engine**: [Tiramisu](https://hexdocs.pm/tiramisu/) (Game engine).
- **Architecture**: Functional MVU (Model-View-Update) pattern.
- **Target**: JavaScript (configured in `gleam.toml`).

## 2. Development Workflow

### Build & Run
- **Run Game**: `gleam run` (starts the development server/window).
- **Check Types**: `gleam check` (fast type checking without running).
- **Format Code**: `gleam format` (ALWAYS run this before committing).

### Testing
- **Run All Tests**: `gleam test`
- **Run Specific Test Module**: `gleam test test/my_module_test.gleam`
- **Testing Library**: `gleeunit` is used. Use `should.equal`, `should.be_ok`, etc.

### Dependency Management
- **Add Package**: `gleam add <package>`
- **Remove Package**: `gleam remove <package>`
- **Update deps**: `gleam update`

## 3. Code Style & Conventions

### General Gleam Patterns
- **Pipe Operator**: Heavily prefer the pipe operator (`|>`) for chaining function calls.
  ```gleam
  // Good
  list.map(items, fn(x) { x * 2 })
  |> list.filter(fn(x) { x > 10 })
  
  // Avoid nested calls
  list.filter(list.map(items, fn(x) { x * 2 }), fn(x) { x > 10 })
  ```
- **Pattern Matching**: Use `case` expressions for control flow, especially with `Result` and `Option` types.
- **Immutability**: All data structures are immutable. Functions return *new* versions of state.

### Naming Conventions
- **Modules**: `snake_case` (e.g., `game_state.gleam`, `ghost_ai.gleam`).
- **Functions/Variables**: `snake_case` (e.g., `update_player`, `grid_pos`).
- **Types/Constructors**: `CamelCase` (e.g., `GameState`, `GridPosition`, `Tick`).
- **Constants**: `snake_case` (usually defined in `constants.gleam`).

### Imports
- Group imports by standard library, external packages, then internal modules.
- Use explicit type imports when helpful for clarity.
- Aliasing: `import gleam/option.{type Option, Some, None}` is common.

### Project Architecture
- **State Management**: `src/pacman/game_state.gleam` holds core types (`Model`, `GameState`, `Ghost`).
- **Logic Systems**: `src/pacman/systems/` contains pure functions for game logic (AI, movement).
- **Rendering**: `src/pacman/rendering/` converts state to Tiramisu scene nodes.
- **Entry Point**: `src/pacman.gleam` wires the `init`, `update`, `view` loop.

### Error Handling
- Prefer `Result(Ok, Error)` over crashing.
- Use `let assert` ONLY when you are mathematically certain the value exists (e.g., static initialization).
- In game logic, handle `None` or `Error` cases gracefully (e.g., if a ghost target is invalid, default to current position).

## 4. Implementation Guidelines for Agents

1.  **Functional Core**: Keep game logic pure. Functions in `systems/` should take state + params and return new state.
2.  **No Side Effects**: Do not perform I/O inside `update` or helper functions unless returning a `Command/Effect` (supported by Tiramisu/Lustre architecture).
3.  **Type Safety**: Never use `todo` as a permanent solution. Define types that make illegal states impossible.
4.  **Tiramisu Specifics**:
    - The camera is set up as Orthographic for 2D.
    - 2D rendering is achieved by looking at the XY plane from a Z distance.
    - Assets/Scenes are built declaratively in the `view` function.

## 5. File Structure Strategy
- `src/pacman/constants.gleam`: Magic numbers (speeds, colors, dimensions).
- `src/pacman/maze.gleam`: Level generation and static data.
- `src/pacman/entities/`: (Optional) Specific definitions for complex entities if `game_state` grows too large.

## 6. Commit Message Format
Follow Conventional Commits:
- `feat: add ghost scatter mode logic`
- `fix: correct collision bounding box`
- `refactor: move movement logic to separate module`
- `docs: update readme`
