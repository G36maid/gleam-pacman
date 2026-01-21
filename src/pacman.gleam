import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/duration
import pacman/constants as c
import pacman/game_state as gs
import pacman/maze
import pacman/systems/movement as mv
import tiramisu
import tiramisu/camera
import tiramisu/effect
import tiramisu/geometry
import tiramisu/input
import tiramisu/light
import tiramisu/material
import tiramisu/scene
import tiramisu/transform
import vec/vec2
import vec/vec3

// Game Model
pub type Model {
  Model(game_state: gs.GameState, input_direction: Option(gs.Direction))
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

  let initial_state =
    gs.GameState(
      phase: gs.Playing,
      player: player,
      ghosts: [],
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

  #(
    Model(game_state: initial_state, input_direction: None),
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

      let new_game_state = gs.GameState(..model.game_state, player: new_player)

      #(
        Model(game_state: new_game_state, input_direction: new_input_dir),
        effect.dispatch(Tick),
        option.None,
      )
    }
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
  let maze_nodes = render_maze(model.game_state.maze)
  let player_node = render_player(model.game_state.player)

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
    ])

  scene.empty(
    id: "scene",
    transform: transform.identity,
    children: scene_children,
  )
}

// Render the maze tiles
fn render_maze(maze: List(List(gs.Tile))) -> List(scene.Node) {
  maze
  |> list.index_map(fn(row, y) {
    row
    |> list.index_map(fn(tile, x) { render_tile(tile, x, y) })
  })
  |> list.flatten
  |> list.filter(fn(node_opt) {
    case node_opt {
      Some(_) -> True
      None -> False
    }
  })
  |> list.map(fn(node_opt) {
    let assert Some(node) = node_opt
    node
  })
}

// Render individual tile
fn render_tile(tile: gs.Tile, x: Int, y: Int) -> Option(scene.Node) {
  case tile {
    gs.Wall -> {
      let assert Ok(wall_geo) =
        geometry.box(size: vec3.Vec3(c.tile_size, c.tile_size, c.tile_size))
      let assert Ok(wall_mat) =
        material.new()
        |> material.with_color(c.color_wall)
        |> material.build()

      Some(scene.mesh(
        id: "wall-" <> int.to_string(x) <> "-" <> int.to_string(y),
        geometry: wall_geo,
        material: wall_mat,
        transform: transform.at(position: vec3.Vec3(
          int.to_float(x) *. c.tile_size +. c.tile_size /. 2.0,
          int.to_float(y) *. c.tile_size +. c.tile_size /. 2.0,
          0.0,
        )),
        physics: option.None,
      ))
    }

    gs.Dot -> {
      let assert Ok(dot_geo) =
        geometry.sphere(radius: c.tile_size /. 8.0, segments: vec2.Vec2(8, 6))
      let assert Ok(dot_mat) =
        material.new()
        |> material.with_color(c.color_dot)
        |> material.build()

      Some(scene.mesh(
        id: "dot-" <> int.to_string(x) <> "-" <> int.to_string(y),
        geometry: dot_geo,
        material: dot_mat,
        transform: transform.at(position: vec3.Vec3(
          int.to_float(x) *. c.tile_size +. c.tile_size /. 2.0,
          int.to_float(y) *. c.tile_size +. c.tile_size /. 2.0,
          0.0,
        )),
        physics: option.None,
      ))
    }

    gs.PowerPellet -> {
      let assert Ok(pellet_geo) =
        geometry.sphere(radius: c.tile_size /. 4.0, segments: vec2.Vec2(12, 8))
      let assert Ok(pellet_mat) =
        material.new()
        |> material.with_color(c.color_power_pellet)
        |> material.build()

      Some(scene.mesh(
        id: "pellet-" <> int.to_string(x) <> "-" <> int.to_string(y),
        geometry: pellet_geo,
        material: pellet_mat,
        transform: transform.at(position: vec3.Vec3(
          int.to_float(x) *. c.tile_size +. c.tile_size /. 2.0,
          int.to_float(y) *. c.tile_size +. c.tile_size /. 2.0,
          0.0,
        )),
        physics: option.None,
      ))
    }

    _ -> None
  }
}

// Render Pacman
fn render_player(player: gs.Player) -> scene.Node {
  let assert Ok(pacman_geo) =
    geometry.sphere(radius: c.tile_size /. 2.0, segments: vec2.Vec2(16, 12))
  let assert Ok(pacman_mat) =
    material.new()
    |> material.with_color(c.color_pacman)
    |> material.build()

  scene.mesh(
    id: "pacman",
    geometry: pacman_geo,
    material: pacman_mat,
    transform: transform.at(position: vec3.Vec3(
      player.world_pos.x,
      player.world_pos.y,
      c.tile_size /. 2.0,
    )),
    physics: option.None,
  )
}
