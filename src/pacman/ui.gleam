import pacman/game_state as gs

/// FFI binding to update HTML UI overlay
@external(javascript, "./ui.ffi.mjs", "update_ui")
pub fn update_ui(score: Int, lives: Int, level: Int, phase: String) -> Nil

/// Convert GamePhase to string for FFI
pub fn phase_to_string(phase: gs.GamePhase) -> String {
  case phase {
    gs.Menu -> "Menu"
    gs.Playing -> "Playing"
    gs.LevelComplete -> "LevelComplete"
    gs.GameOver -> "GameOver"
  }
}
