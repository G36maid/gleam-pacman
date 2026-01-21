import gleam/list
import gleam/option.{type Option, None, Some}
import pacman/constants as c
import pacman/game_state as gs
import pacman/maze
import pacman/systems/ghost_mode as gm

/// Collision result type
pub type CollisionResult {
  NoCollision
  DotEaten(position: gs.GridPosition)
  PowerPelletEaten(position: gs.GridPosition)
  GhostCollision(ghost_id: String)
}

/// Check collision between Pacman and dots/pellets
pub fn check_dot_collision(
  player: gs.Player,
  maze: List(List(gs.Tile)),
) -> Option(CollisionResult) {
  case maze.get_tile(maze, player.grid_pos) {
    Ok(gs.Dot) -> Some(DotEaten(player.grid_pos))
    Ok(gs.PowerPellet) -> Some(PowerPelletEaten(player.grid_pos))
    _ -> None
  }
}

/// Check collision between Pacman and ghosts
pub fn check_ghost_collision(
  player: gs.Player,
  ghosts: List(gs.Ghost),
) -> Option(CollisionResult) {
  ghosts
  |> list.find(fn(ghost) {
    // Check if on same tile
    ghost.grid_pos.x == player.grid_pos.x
    && ghost.grid_pos.y == player.grid_pos.y
    // Ignore dead ghosts
    && ghost.mode != gs.Dead
  })
  |> option.from_result
  |> option.map(fn(ghost) { GhostCollision(ghost.id) })
}

/// Handle dot/pellet consumption
pub fn consume_dot(
  game_state: gs.GameState,
  position: gs.GridPosition,
  is_power_pellet: Bool,
) -> gs.GameState {
  // Update maze to remove the dot
  let new_maze =
    game_state.maze
    |> list.index_map(fn(row, y) {
      case y == position.y {
        True ->
          row
          |> list.index_map(fn(tile, x) {
            case x == position.x {
              True -> gs.Empty
              False -> tile
            }
          })
        False -> row
      }
    })

  // Calculate score
  let points = case is_power_pellet {
    True -> c.power_pellet_points
    False -> c.dot_points
  }

  let new_score = game_state.score + points
  let new_dots = game_state.dots_remaining - 1

  // Enter frightened mode if power pellet
  let updated_state = case is_power_pellet {
    True ->
      gs.GameState(
        ..game_state,
        maze: new_maze,
        score: new_score,
        dots_remaining: new_dots,
      )
      |> gm.enter_frightened_mode
    False ->
      gs.GameState(
        ..game_state,
        maze: new_maze,
        score: new_score,
        dots_remaining: new_dots,
      )
  }

  updated_state
}

/// Handle Pacman-Ghost collision
pub fn handle_ghost_collision(
  game_state: gs.GameState,
  ghost_id: String,
) -> gs.GameState {
  // Find the ghost
  case list.find(game_state.ghosts, fn(g) { g.id == ghost_id }) {
    Error(_) -> game_state
    // Ghost not found, no change
    Ok(ghost) -> {
      case ghost.mode {
        gs.Frightened -> eat_ghost(game_state, ghost_id)
        gs.Dead -> game_state
        // Already dead, ignore
        _ -> lose_life(game_state)
      }
    }
  }
}

/// Pacman eats a frightened ghost
fn eat_ghost(game_state: gs.GameState, ghost_id: String) -> gs.GameState {
  // Calculate score based on combo
  let ghost_value = case game_state.ghosts_eaten_combo {
    0 -> c.ghost_points_1
    1 -> c.ghost_points_2
    2 -> c.ghost_points_3
    _ -> c.ghost_points_4
  }

  // Set ghost to Dead mode
  let new_ghosts =
    game_state.ghosts
    |> list.map(fn(g) {
      case g.id == ghost_id {
        True -> gs.Ghost(..g, mode: gs.Dead)
        False -> g
      }
    })

  gs.GameState(
    ..game_state,
    ghosts: new_ghosts,
    score: game_state.score + ghost_value,
    ghosts_eaten_combo: game_state.ghosts_eaten_combo + 1,
  )
}

/// Pacman loses a life
fn lose_life(game_state: gs.GameState) -> gs.GameState {
  let new_lives = game_state.lives - 1

  case new_lives <= 0 {
    True ->
      // Game over
      gs.GameState(..game_state, lives: 0, phase: gs.GameOver)
    False -> {
      // Reset positions but keep maze state and score
      let player_spawn = maze.get_pacman_spawn()
      let player_world = gs.grid_to_world(player_spawn, c.tile_size)

      let reset_player =
        gs.Player(
          grid_pos: player_spawn,
          world_pos: player_world,
          direction: gs.None,
          next_direction: None,
        )

      // Reset ghosts to spawn positions
      let reset_ghosts =
        game_state.ghosts
        |> list.index_map(fn(ghost, idx) {
          let spawn_pos = case idx {
            0 -> maze.get_blinky_spawn()
            1 -> maze.get_pinky_spawn()
            2 -> maze.get_inky_spawn()
            3 -> maze.get_clyde_spawn()
            _ -> maze.get_blinky_spawn()
          }
          let world_pos = gs.grid_to_world(spawn_pos, c.tile_size)

          gs.Ghost(
            ..ghost,
            grid_pos: spawn_pos,
            world_pos: world_pos,
            direction: gs.Left,
            mode: gs.Scatter,
          )
        })

      gs.GameState(
        ..game_state,
        player: reset_player,
        ghosts: reset_ghosts,
        lives: new_lives,
        ghost_mode: gs.Scatter,
        mode_timer: 0.0,
        mode_cycle_index: 0,
        frightened_timer: 0.0,
        ghosts_eaten_combo: 0,
      )
    }
  }
}

/// Check if level is complete (all dots eaten)
pub fn check_level_complete(game_state: gs.GameState) -> Bool {
  game_state.dots_remaining == 0
}

/// Advance to next level
pub fn next_level(game_state: gs.GameState) -> gs.GameState {
  let new_maze = maze.create_classic_maze()
  let player_spawn = maze.get_pacman_spawn()
  let player_world = gs.grid_to_world(player_spawn, c.tile_size)

  let reset_player =
    gs.Player(
      grid_pos: player_spawn,
      world_pos: player_world,
      direction: gs.None,
      next_direction: None,
    )

  // Reset ghosts
  let reset_ghosts =
    game_state.ghosts
    |> list.index_map(fn(ghost, idx) {
      let spawn_pos = case idx {
        0 -> maze.get_blinky_spawn()
        1 -> maze.get_pinky_spawn()
        2 -> maze.get_inky_spawn()
        3 -> maze.get_clyde_spawn()
        _ -> maze.get_blinky_spawn()
      }
      let world_pos = gs.grid_to_world(spawn_pos, c.tile_size)

      gs.Ghost(
        ..ghost,
        grid_pos: spawn_pos,
        world_pos: world_pos,
        direction: gs.Left,
        mode: gs.Scatter,
      )
    })

  gs.GameState(
    ..game_state,
    player: reset_player,
    ghosts: reset_ghosts,
    maze: new_maze,
    level: game_state.level + 1,
    dots_remaining: maze.count_dots(new_maze),
    ghost_mode: gs.Scatter,
    mode_timer: 0.0,
    mode_cycle_index: 0,
    frightened_timer: 0.0,
    ghosts_eaten_combo: 0,
    phase: gs.Playing,
  )
}
