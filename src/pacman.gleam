import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/duration
import pacman/constants as c
import pacman/game_state as gs
import pacman/maze
import pacman/rendering/assets
import pacman/systems/collision as col
import pacman/systems/ghost_ai as gai
import pacman/systems/ghost_mode as gm
import pacman/systems/movement as mv
import pacman/ui
import tiramisu
import tiramisu/camera
import tiramisu/effect
import tiramisu/input
import tiramisu/light
import tiramisu/scene
import tiramisu/transform
import vec/vec2
import vec/vec3

// Game Model
pub type Model {
  Model(
    game_state: gs.GameState,
    input_direction: Option(gs.Direction),
    assets: assets.RenderingAssets,
  )
}

// Game Messages
pub type Msg {
  Tick
}

// Entry point
pub fn main() {
  tiramisu.application(init, update, view)
  |> tiramisu.start("#app", tiramisu.FullScreen, option.None)
}

// Initialize game state
fn init(_ctx: tiramisu.Context) {
  let maze_data = maze.create_classic_maze()
  let player_spawn = maze.get_pacman_spawn()
  let player_world = gs.grid_to_world(player_spawn, c.tile_size)

  let player =
    gs.Player(
      grid_pos: player_spawn,
      world_pos: player_world,
      direction: gs.None,
      next_direction: None,
    )

  // Spawn all four ghosts
  let ghosts = [
    gai.spawn_ghost(gai.Blinky, maze_data),
    gai.spawn_ghost(gai.Pinky, maze_data),
    gai.spawn_ghost(gai.Inky, maze_data),
    gai.spawn_ghost(gai.Clyde, maze_data),
  ]

  let initial_state =
    gs.GameState(
      phase: gs.Playing,
      player: player,
      ghosts: ghosts,
      maze: maze_data,
      score: 0,
      lives: c.starting_lives,
      level: 1,
      dots_remaining: maze.count_dots(maze_data),
      ghost_mode: gs.Scatter,
      mode_timer: 0.0,
      mode_cycle_index: 0,
      frightened_timer: 0.0,
      ghosts_eaten_combo: 0,
    )

  // Create shared rendering assets once
  let rendering_assets = assets.create_assets()

  #(
    Model(
      game_state: initial_state,
      input_direction: None,
      assets: rendering_assets,
    ),
    effect.dispatch(Tick),
    option.None,
  )
}

// Update game state
fn update(model: Model, msg: Msg, ctx: tiramisu.Context) {
  case msg {
    Tick -> {
      let delta = duration.to_seconds(ctx.delta_time)

      // Read keyboard input from context
      let new_input_dir = {
        let up_pressed =
          input.is_key_pressed(ctx.input, input.KeyW)
          || input.is_key_pressed(ctx.input, input.ArrowUp)
        let down_pressed =
          input.is_key_pressed(ctx.input, input.KeyS)
          || input.is_key_pressed(ctx.input, input.ArrowDown)
        let left_pressed =
          input.is_key_pressed(ctx.input, input.KeyA)
          || input.is_key_pressed(ctx.input, input.ArrowLeft)
        let right_pressed =
          input.is_key_pressed(ctx.input, input.KeyD)
          || input.is_key_pressed(ctx.input, input.ArrowRight)

        case up_pressed, down_pressed, left_pressed, right_pressed {
          True, _, _, _ -> Some(gs.Up)
          _, True, _, _ -> Some(gs.Down)
          _, _, True, _ -> Some(gs.Left)
          _, _, _, True -> Some(gs.Right)
          _, _, _, _ -> None
        }
      }

      // Update player movement
      let new_player =
        mv.update_player_movement(
          model.game_state.player,
          new_input_dir,
          model.game_state.maze,
          c.pacman_speed,
          c.tile_size,
          c.turn_threshold,
          delta,
          c.maze_width,
          c.maze_height,
        )

      // Update ghost AI and movement
      let blinky_pos = case list.first(model.game_state.ghosts) {
        Ok(blinky) -> Some(blinky.grid_pos)
        Error(_) -> None
      }

      let new_ghosts =
        model.game_state.ghosts
        |> list.index_map(fn(ghost, idx) {
          let personality = case idx {
            0 -> gai.Blinky
            1 -> gai.Pinky
            2 -> gai.Inky
            3 -> gai.Clyde
            _ -> gai.Blinky
          }

          // Update AI
          let ghost_with_ai =
            gai.update_ghost_ai(
              ghost,
              personality,
              new_player,
              blinky_pos,
              model.game_state.maze,
            )

          // Update movement
          let speed = case ghost.mode {
            gs.Frightened -> c.ghost_speed_frightened
            _ -> c.ghost_speed_normal
          }

          mv.update_player_movement(
            gs.Player(
              grid_pos: ghost_with_ai.grid_pos,
              world_pos: ghost_with_ai.world_pos,
              direction: ghost_with_ai.direction,
              next_direction: None,
            ),
            Some(ghost_with_ai.direction),
            model.game_state.maze,
            speed,
            c.tile_size,
            c.turn_threshold,
            delta,
            c.maze_width,
            c.maze_height,
          )
          |> fn(updated_player) {
            gs.Ghost(
              ..ghost_with_ai,
              grid_pos: updated_player.grid_pos,
              world_pos: updated_player.world_pos,
            )
          }
        })

      let new_game_state =
        gs.GameState(..model.game_state, player: new_player, ghosts: new_ghosts)
        // Update ghost mode cycling
        |> gm.update_ghost_mode(delta)
        // Sync all ghost modes to match global mode
        |> gm.sync_ghost_modes
        // Handle collisions
        |> handle_collisions

      // Check for level complete
      let final_game_state = case col.check_level_complete(new_game_state) {
        True -> col.next_level(new_game_state)
        False -> new_game_state
      }

      // Update UI
      ui.update_ui(
        final_game_state.score,
        final_game_state.lives,
        final_game_state.level,
        ui.phase_to_string(final_game_state.phase),
      )

      #(
        Model(
          game_state: final_game_state,
          input_direction: new_input_dir,
          assets: model.assets,
        ),
        effect.dispatch(Tick),
        option.None,
      )
    }
  }
}

// Handle all collision types
fn handle_collisions(game_state: gs.GameState) -> gs.GameState {
  // Check dot/pellet collisions
  let after_dots = case
    col.check_dot_collision(game_state.player, game_state.maze)
  {
    Some(col.DotEaten(pos)) -> col.consume_dot(game_state, pos, False)
    Some(col.PowerPelletEaten(pos)) -> col.consume_dot(game_state, pos, True)
    _ -> game_state
  }

  // Check ghost collisions
  case col.check_ghost_collision(after_dots.player, after_dots.ghosts) {
    Some(col.GhostCollision(ghost_id)) ->
      col.handle_ghost_collision(after_dots, ghost_id)
    _ -> after_dots
  }
}

// Render scene
fn view(model: Model, _ctx: tiramisu.Context) {
  // Calculate camera position for 2D top-down view
  let camera_x = int.to_float(c.maze_width) *. c.tile_size /. 2.0
  let camera_y = int.to_float(c.maze_height) *. c.tile_size /. 2.0

  // Orthographic camera for 2D
  let cam =
    camera.camera_2d(size: vec2.Vec2(
      float.round(int.to_float(c.maze_width) *. c.tile_size),
      float.round(int.to_float(c.maze_height) *. c.tile_size),
    ))

  // Camera looks straight down
  let camera_transform =
    transform.at(position: vec3.Vec3(camera_x, camera_y, c.camera_distance))
    |> transform.rotate_x(-1.5708)

  // Ambient light for 2D
  let assert Ok(ambient) = light.ambient(intensity: 1.0, color: 0xFFFFFF)

  // Build scene nodes
  let maze_nodes = render_maze(model.game_state.maze, model.assets)
  let player_node = render_player(model.game_state.player, model.assets)
  let ghost_nodes = render_ghosts(model.game_state.ghosts, model.assets)

  let scene_children =
    list.flatten([
      [
        scene.camera(
          id: "main-camera",
          camera: cam,
          transform: camera_transform,
          active: True,
          viewport: option.None,
          postprocessing: option.None,
        ),
        scene.light(
          id: "ambient",
          light: ambient,
          transform: transform.identity,
        ),
      ],
      maze_nodes,
      [player_node],
      ghost_nodes,
    ])

  scene.empty(
    id: "scene",
    transform: transform.identity,
    children: scene_children,
  )
}

// Render the maze tiles
fn render_maze(
  maze: List(List(gs.Tile)),
  assets: assets.RenderingAssets,
) -> List(scene.Node) {
  let walls = render_walls(maze, assets)
  let dots = render_dots_instanced(maze, assets)
  let pellets = render_pellets(maze, assets)

  list.flatten([[dots], walls, pellets])
}

// Render walls individually (different positions)
fn render_walls(
  maze: List(List(gs.Tile)),
  assets: assets.RenderingAssets,
) -> List(scene.Node) {
  maze
  |> list.index_map(fn(row, y) {
    row
    |> list.index_map(fn(tile, x) {
      case tile {
        gs.Wall ->
          Some(scene.mesh(
            id: "wall-" <> int.to_string(x) <> "-" <> int.to_string(y),
            geometry: assets.wall_geometry,
            material: assets.wall_material,
            transform: transform.at(position: vec3.Vec3(
              int.to_float(x) *. c.tile_size +. c.tile_size /. 2.0,
              int.to_float(y) *. c.tile_size +. c.tile_size /. 2.0,
              0.0,
            )),
            physics: option.None,
          ))
        _ -> None
      }
    })
  })
  |> list.flatten
  |> list.filter_map(fn(opt) {
    case opt {
      Some(node) -> Ok(node)
      None -> Error(Nil)
    }
  })
}

// Render all dots using instanced meshes (1 draw call!)
fn render_dots_instanced(
  maze: List(List(gs.Tile)),
  assets: assets.RenderingAssets,
) -> scene.Node {
  let dot_transforms =
    maze
    |> list.index_map(fn(row, y) {
      row
      |> list.index_map(fn(tile, x) {
        case tile {
          gs.Dot ->
            Some(
              transform.at(position: vec3.Vec3(
                int.to_float(x) *. c.tile_size +. c.tile_size /. 2.0,
                int.to_float(y) *. c.tile_size +. c.tile_size /. 2.0,
                0.0,
              )),
            )
          _ -> None
        }
      })
    })
    |> list.flatten
    |> list.filter_map(fn(opt) {
      case opt {
        Some(t) -> Ok(t)
        None -> Error(Nil)
      }
    })

  scene.instanced_mesh(
    id: "dots",
    geometry: assets.dot_geometry,
    material: assets.dot_material,
    instances: dot_transforms,
  )
}

// Render power pellets individually
fn render_pellets(
  maze: List(List(gs.Tile)),
  assets: assets.RenderingAssets,
) -> List(scene.Node) {
  maze
  |> list.index_map(fn(row, y) {
    row
    |> list.index_map(fn(tile, x) {
      case tile {
        gs.PowerPellet ->
          Some(scene.mesh(
            id: "pellet-" <> int.to_string(x) <> "-" <> int.to_string(y),
            geometry: assets.pellet_geometry,
            material: assets.pellet_material,
            transform: transform.at(position: vec3.Vec3(
              int.to_float(x) *. c.tile_size +. c.tile_size /. 2.0,
              int.to_float(y) *. c.tile_size +. c.tile_size /. 2.0,
              0.0,
            )),
            physics: option.None,
          ))
        _ -> None
      }
    })
  })
  |> list.flatten
  |> list.filter_map(fn(opt) {
    case opt {
      Some(node) -> Ok(node)
      None -> Error(Nil)
    }
  })
}

// Render Pacman
fn render_player(
  player: gs.Player,
  assets: assets.RenderingAssets,
) -> scene.Node {
  scene.mesh(
    id: "pacman",
    geometry: assets.player_geometry,
    material: assets.player_material,
    transform: transform.at(position: vec3.Vec3(
      player.world_pos.x,
      player.world_pos.y,
      c.tile_size /. 2.0,
    )),
    physics: option.None,
  )
}

// Render all ghosts
fn render_ghosts(
  ghosts: List(gs.Ghost),
  assets: assets.RenderingAssets,
) -> List(scene.Node) {
  ghosts
  |> list.index_map(fn(ghost, idx) {
    let personality = case idx {
      0 -> gai.Blinky
      1 -> gai.Pinky
      2 -> gai.Inky
      3 -> gai.Clyde
      _ -> gai.Blinky
    }
    render_ghost(ghost, personality, assets)
  })
}

// Render individual ghost
fn render_ghost(
  ghost: gs.Ghost,
  personality: gai.GhostPersonality,
  assets: assets.RenderingAssets,
) -> scene.Node {
  let material = case ghost.mode {
    gs.Frightened -> assets.ghost_frightened
    gs.Dead -> assets.ghost_dead
    _ ->
      case personality {
        gai.Blinky -> assets.ghost_normal_blinky
        gai.Pinky -> assets.ghost_normal_pinky
        gai.Inky -> assets.ghost_normal_inky
        gai.Clyde -> assets.ghost_normal_clyde
      }
  }

  scene.mesh(
    id: ghost.id,
    geometry: assets.ghost_geometry,
    material: material,
    transform: transform.at(position: vec3.Vec3(
      ghost.world_pos.x,
      ghost.world_pos.y,
      c.tile_size /. 2.0,
    )),
    physics: option.None,
  )
}
