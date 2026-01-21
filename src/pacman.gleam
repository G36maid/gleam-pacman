/// Pac-Man Game - Classic Arcade Recreation
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/time/duration
import pacman/constants as c
import pacman/game_state as gs
import pacman/maze
import pacman/movement
import tiramisu
import tiramisu/background
import tiramisu/camera
import tiramisu/effect.{type Effect}
import tiramisu/geometry
import tiramisu/input
import tiramisu/light
import tiramisu/material
import tiramisu/scene
import tiramisu/transform
import vec/vec2
import vec/vec3

pub type Model {
  Model(
    player: gs.Player,
    ghosts: List(gs.Ghost),
    phase: gs.GamePhase,
    maze_tiles: List(List(gs.Tile)),
    // Dynamic maze state
    time: Float,
    input_bindings: input.InputBindings(gs.Direction),
  )
}

pub type Msg {
  Tick
  BackgroundSet
}

pub fn main() -> Nil {
  let assert Ok(Nil) =
    tiramisu.application(init:, update:, view:)
    |> tiramisu.start("#app", tiramisu.FullScreen, option.None)
  Nil
}

fn init(ctx: tiramisu.Context) -> #(Model, Effect(Msg), option.Option(_)) {
  let bg_effect =
    background.set(
      ctx.scene,
      background.Color(c.color_background),
      BackgroundSet,
      BackgroundSet,
    )

  // Convert static maze to dynamic tile state
  let initial_maze_tiles = maze_to_tiles(maze.create_classic_maze())
  let dots_count = count_dots(initial_maze_tiles)

  // Setup input bindings for direction
  let bindings =
    input.new_bindings()
    |> input.bind_key(input.ArrowUp, gs.Up)
    |> input.bind_key(input.ArrowDown, gs.Down)
    |> input.bind_key(input.ArrowLeft, gs.Left)
    |> input.bind_key(input.ArrowRight, gs.Right)
    |> input.bind_key(input.KeyW, gs.Up)
    |> input.bind_key(input.KeyS, gs.Down)
    |> input.bind_key(input.KeyA, gs.Left)
    |> input.bind_key(input.KeyD, gs.Right)

  #(
    Model(
      player: gs.initial_player(),
      ghosts: gs.initial_ghosts(),
      phase: gs.Playing(
        score: 0,
        lives: 3,
        level: 1,
        dots_remaining: dots_count,
      ),
      maze_tiles: initial_maze_tiles,
      time: 0.0,
      input_bindings: bindings,
    ),
    effect.batch([bg_effect, effect.dispatch(Tick)]),
    option.None,
  )
}

fn update(
  model: Model,
  msg: Msg,
  ctx: tiramisu.Context,
) -> #(Model, Effect(Msg), option.Option(_)) {
  case msg {
    Tick -> {
      let delta_seconds = duration.to_seconds(ctx.delta_time)
      let new_time = model.time +. delta_seconds

      // Check input and buffer turn direction
      let player_with_input =
        check_and_buffer_input(model.player, ctx.input, model.input_bindings)

      // Move player
      let new_player =
        movement.move_player(player_with_input, model.maze_tiles, delta_seconds)

      #(
        Model(..model, player: new_player, time: new_time),
        effect.dispatch(Tick),
        option.None,
      )
    }

    BackgroundSet -> #(model, effect.none(), option.None)
  }
}

fn view(model: Model, ctx: tiramisu.Context) -> scene.Node {
  // Use canvas size for camera (simpler approach)
  let cam =
    camera.camera_2d(size: vec2.Vec2(
      float.round(ctx.canvas_size.x),
      float.round(ctx.canvas_size.y),
    ))

  // Camera at origin looking straight ahead (no rotation needed for 2D)
  let camera_transform = transform.at(position: vec3.Vec3(0.0, 0.0, 20.0))

  // Create ambient light
  let assert Ok(ambient_light) = light.ambient(color: 0xFFFFFF, intensity: 1.0)

  // Render maze
  let maze_nodes = render_maze(model.maze_tiles)

  // Render player
  let player_node = render_player(model.player)

  scene.empty(
    id: "Scene",
    transform: transform.identity,
    children: list.flatten([
      [
        scene.camera(
          id: "camera",
          camera: cam,
          transform: camera_transform,
          active: True,
          viewport: option.None,
          postprocessing: option.None,
        ),
        scene.light(
          id: "ambient",
          light: ambient_light,
          transform: transform.identity,
        ),
        player_node,
      ],
      maze_nodes,
    ]),
  )
}

// Render the entire maze
fn render_maze(maze: List(List(gs.Tile))) -> List(scene.Node) {
  maze
  |> list.index_map(fn(row, y) {
    row
    |> list.index_map(fn(tile, x) { render_tile(tile, x, y) })
  })
  |> list.flatten
  |> list.filter_map(fn(node_opt) {
    case node_opt {
      option.Some(node) -> Ok(node)
      option.None -> Error(Nil)
    }
  })
}

// Render individual tile
fn render_tile(tile: gs.Tile, x: Int, y: Int) -> option.Option(scene.Node) {
  // Center maze at origin by offsetting
  let offset_x = int.to_float(c.maze_width) *. c.tile_size /. 2.0
  let offset_y = int.to_float(c.maze_height) *. c.tile_size /. 2.0

  let world_x = int.to_float(x) *. c.tile_size +. c.tile_size /. 2.0 -. offset_x
  // Negate Y to flip vertical axis
  let world_y =
    -1.0 *. { int.to_float(y) *. c.tile_size +. c.tile_size /. 2.0 -. offset_y }

  case tile {
    gs.Wall -> {
      let assert Ok(wall_geo) =
        geometry.box(size: vec3.Vec3(c.tile_size, c.tile_size, c.tile_size))
      let assert Ok(wall_mat) =
        material.new()
        |> material.with_color(c.color_wall)
        |> material.build()

      option.Some(scene.mesh(
        id: "wall-" <> int.to_string(x) <> "-" <> int.to_string(y),
        geometry: wall_geo,
        material: wall_mat,
        transform: transform.at(position: vec3.Vec3(world_x, world_y, 0.0)),
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

      option.Some(scene.mesh(
        id: "dot-" <> int.to_string(x) <> "-" <> int.to_string(y),
        geometry: dot_geo,
        material: dot_mat,
        transform: transform.at(position: vec3.Vec3(world_x, world_y, 0.0)),
        physics: option.None,
      ))
    }

    gs.PowerPellet -> {
      let assert Ok(pellet_geo) =
        geometry.sphere(radius: c.tile_size /. 4.0, segments: vec2.Vec2(8, 6))
      let assert Ok(pellet_mat) =
        material.new()
        |> material.with_color(c.color_power_pellet)
        |> material.build()

      option.Some(scene.mesh(
        id: "pellet-" <> int.to_string(x) <> "-" <> int.to_string(y),
        geometry: pellet_geo,
        material: pellet_mat,
        transform: transform.at(position: vec3.Vec3(world_x, world_y, 0.0)),
        physics: option.None,
      ))
    }

    gs.Empty -> option.None
  }
}

// Render player at grid position
fn render_player(player: gs.Player) -> scene.Node {
  let world_pos = grid_to_world(player.grid_pos)

  let assert Ok(player_geo) =
    geometry.sphere(radius: c.tile_size /. 2.5, segments: vec2.Vec2(16, 12))
  let assert Ok(player_mat) =
    material.new()
    |> material.with_color(c.color_pacman)
    |> material.build()

  scene.mesh(
    id: "player",
    geometry: player_geo,
    material: player_mat,
    transform: transform.at(position: vec3.Vec3(world_pos.x, world_pos.y, 0.0)),
    physics: option.None,
  )
}

// Convert grid position to world coordinates
fn grid_to_world(grid_pos: vec2.Vec2(Int)) -> vec2.Vec2(Float) {
  let offset_x = int.to_float(c.maze_width) *. c.tile_size /. 2.0
  let offset_y = int.to_float(c.maze_height) *. c.tile_size /. 2.0

  let world_x =
    int.to_float(grid_pos.x) *. c.tile_size +. c.tile_size /. 2.0 -. offset_x
  // Negate Y to flip vertical axis (row 0 at top, increasing downward)
  let world_y =
    -1.0
    *. {
      int.to_float(grid_pos.y) *. c.tile_size +. c.tile_size /. 2.0 -. offset_y
    }

  vec2.Vec2(world_x, world_y)
}

// Convert static maze layout to dynamic tile state
fn maze_to_tiles(maze: List(List(maze.Tile))) -> List(List(gs.Tile)) {
  maze
  |> list.map(fn(row) {
    row
    |> list.map(fn(tile) {
      case tile {
        maze.Wall -> gs.Wall
        maze.Empty -> gs.Empty
        maze.Dot -> gs.Dot
        maze.PowerPellet -> gs.PowerPellet
      }
    })
  })
}

// Count total dots in maze
fn count_dots(maze: List(List(gs.Tile))) -> Int {
  maze
  |> list.fold(0, fn(acc, row) {
    row
    |> list.fold(acc, fn(row_acc, tile) {
      case tile {
        gs.Dot | gs.PowerPellet -> row_acc + 1
        _ -> row_acc
      }
    })
  })
}

// Check input and buffer turn direction (using action bindings)
fn check_and_buffer_input(
  player: gs.Player,
  input_state: input.InputState,
  bindings: input.InputBindings(gs.Direction),
) -> gs.Player {
  // Check each direction using action bindings
  case input.is_action_just_pressed(input_state, bindings, gs.Up) {
    True -> gs.Player(..player, next_direction: gs.Up)
    False ->
      case input.is_action_just_pressed(input_state, bindings, gs.Down) {
        True -> gs.Player(..player, next_direction: gs.Down)
        False ->
          case input.is_action_just_pressed(input_state, bindings, gs.Left) {
            True -> gs.Player(..player, next_direction: gs.Left)
            False ->
              case
                input.is_action_just_pressed(input_state, bindings, gs.Right)
              {
                True -> gs.Player(..player, next_direction: gs.Right)
                False -> player
              }
          }
      }
  }
}
