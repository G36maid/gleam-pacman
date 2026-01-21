/// Ghost collision detection - player death and eating ghosts
import gleam/list
import pacman/game_state as gs
import vec/vec2

pub type CollisionResult {
  CollisionResult(
    player_hit: Bool,
    // Player hit by non-frightened ghost
    ghosts: List(gs.Ghost),
    // Updated ghosts (eaten ones become Eaten mode)
    ghosts_eaten: Int,
    // Number of ghosts eaten this frame
  )
}

/// Check collision between player and ghosts
pub fn check_ghost_collision(
  player_pos: vec2.Vec2(Int),
  player_power_mode: Bool,
  ghosts: List(gs.Ghost),
) -> CollisionResult {
  // Check each ghost for collision
  let result =
    ghosts
    |> list.fold(
      CollisionResult(player_hit: False, ghosts: [], ghosts_eaten: 0),
      fn(acc, ghost) {
        // Check if player and ghost are on same tile
        case player_pos == ghost.grid_pos {
          True -> {
            // Collision detected!
            case ghost.mode, player_power_mode {
              // Player in power mode, ghost is frightened -> eat ghost
              gs.Frightened, True -> {
                let eaten_ghost =
                  gs.Ghost(
                    ..ghost,
                    mode: gs.Eaten,
                    mode_timer: 0.0,
                    house_state: gs.Returning,
                  )
                CollisionResult(
                  ..acc,
                  ghosts: [eaten_ghost, ..acc.ghosts],
                  ghosts_eaten: acc.ghosts_eaten + 1,
                )
              }
              // Ghost is already eaten -> no effect
              gs.Eaten, _ ->
                CollisionResult(..acc, ghosts: [ghost, ..acc.ghosts])
              // Ghost is not frightened -> player dies
              _, _ ->
                CollisionResult(..acc, player_hit: True, ghosts: [
                  ghost,
                  ..acc.ghosts
                ])
            }
          }
          False ->
            // No collision, keep ghost as is
            CollisionResult(..acc, ghosts: [ghost, ..acc.ghosts])
        }
      },
    )

  // Reverse ghosts list to maintain original order
  CollisionResult(..result, ghosts: list.reverse(result.ghosts))
}
