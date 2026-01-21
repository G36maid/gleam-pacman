import gleam/list
import pacman/constants as c
import pacman/game_state as gs

/// Ghost mode cycle timings (in seconds)
/// Classic Pacman cycles: Scatter -> Chase -> Scatter -> Chase -> ...
pub const mode_cycles = [
  #(gs.Scatter, 7.0),
  // Cycle 0: Scatter for 7s
  #(gs.Chase, 20.0),
  // Cycle 1: Chase for 20s
  #(gs.Scatter, 7.0),
  // Cycle 2: Scatter for 7s
  #(gs.Chase, 20.0),
  // Cycle 3: Chase for 20s
  #(gs.Scatter, 5.0),
  // Cycle 4: Scatter for 5s
  #(gs.Chase, 20.0),
  // Cycle 5: Chase for 20s
  #(gs.Scatter, 5.0),
  // Cycle 6: Scatter for 5s
  #(gs.Chase, 999.0),
  // Cycle 7: Chase forever
]

/// Update ghost mode based on timers
pub fn update_ghost_mode(game_state: gs.GameState, delta: Float) -> gs.GameState {
  // If in frightened mode, handle separately
  case game_state.ghost_mode {
    gs.Frightened -> update_frightened_mode(game_state, delta)
    _ -> update_normal_mode_cycle(game_state, delta)
  }
}

/// Update frightened mode timer
fn update_frightened_mode(
  game_state: gs.GameState,
  delta: Float,
) -> gs.GameState {
  let new_timer = game_state.frightened_timer +. delta

  case new_timer >=. c.frightened_duration {
    True -> {
      // Return to normal mode cycle
      gs.GameState(
        ..game_state,
        ghost_mode: get_current_cycle_mode(game_state.mode_cycle_index),
        frightened_timer: 0.0,
        ghosts_eaten_combo: 0,
      )
    }
    False -> gs.GameState(..game_state, frightened_timer: new_timer)
  }
}

/// Update normal Scatter/Chase mode cycling
fn update_normal_mode_cycle(
  game_state: gs.GameState,
  delta: Float,
) -> gs.GameState {
  let new_timer = game_state.mode_timer +. delta
  let cycle_duration = get_current_cycle_duration(game_state.mode_cycle_index)

  case new_timer >=. cycle_duration {
    True -> {
      // Advance to next cycle
      let next_cycle_index = game_state.mode_cycle_index + 1
      let next_mode = get_current_cycle_mode(next_cycle_index)

      gs.GameState(
        ..game_state,
        ghost_mode: next_mode,
        mode_timer: 0.0,
        mode_cycle_index: next_cycle_index,
      )
    }
    False -> gs.GameState(..game_state, mode_timer: new_timer)
  }
}

/// Get mode for current cycle index
fn get_current_cycle_mode(cycle_index: Int) -> gs.GhostMode {
  case get_cycle(cycle_index) {
    #(mode, _) -> mode
  }
}

/// Get duration for current cycle index
fn get_current_cycle_duration(cycle_index: Int) -> Float {
  case get_cycle(cycle_index) {
    #(_, duration) -> duration
  }
}

/// Get cycle tuple by index, clamp to last cycle if out of bounds
fn get_cycle(index: Int) -> #(gs.GhostMode, Float) {
  case index {
    0 -> #(gs.Scatter, 7.0)
    1 -> #(gs.Chase, 20.0)
    2 -> #(gs.Scatter, 7.0)
    3 -> #(gs.Chase, 20.0)
    4 -> #(gs.Scatter, 5.0)
    5 -> #(gs.Chase, 20.0)
    6 -> #(gs.Scatter, 5.0)
    _ -> #(gs.Chase, 999.0)
    // Chase forever after cycle 7
  }
}

/// Enter frightened mode (when Pacman eats power pellet)
pub fn enter_frightened_mode(game_state: gs.GameState) -> gs.GameState {
  gs.GameState(
    ..game_state,
    ghost_mode: gs.Frightened,
    frightened_timer: 0.0,
    ghosts_eaten_combo: 0,
  )
}

/// Update all ghosts to match the current global mode
pub fn sync_ghost_modes(game_state: gs.GameState) -> gs.GameState {
  let updated_ghosts =
    game_state.ghosts
    |> list.map(fn(ghost) {
      // Don't override Dead mode
      case ghost.mode {
        gs.Dead -> ghost
        _ -> gs.Ghost(..ghost, mode: game_state.ghost_mode)
      }
    })

  gs.GameState(..game_state, ghosts: updated_ghosts)
}
