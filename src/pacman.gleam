/// Pac-Man Game - Classic Arcade Recreation
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/time/duration
import pacman/constants as c
import pacman/maze
import tiramisu
import tiramisu/background
import tiramisu/camera
import tiramisu/effect.{type Effect}
import tiramisu/geometry
import tiramisu/light
import tiramisu/material
import tiramisu/scene
import tiramisu/transform
import vec/vec2
import vec/vec3

pub type Model {
  Model(time: Float)
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
  #(
    Model(time: 0.0),
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
      #(Model(time: new_time), effect.dispatch(Tick), option.None)
    }
    BackgroundSet -> #(model, effect.none(), option.None)
  }
}

fn view(_model: Model, ctx: tiramisu.Context) -> scene.Node {
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

  // Render maze (positioned at origin for now)
  let maze_data = maze.create_classic_maze()
  let maze_nodes = render_maze(maze_data)

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
      ],
      maze_nodes,
    ]),
  )
}

// Render the entire maze
fn render_maze(maze: List(List(maze.Tile))) -> List(scene.Node) {
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
fn render_tile(tile: maze.Tile, x: Int, y: Int) -> option.Option(scene.Node) {
  // Center maze at origin by offsetting
  let offset_x = int.to_float(c.maze_width) *. c.tile_size /. 2.0
  let offset_y = int.to_float(c.maze_height) *. c.tile_size /. 2.0

  let world_x = int.to_float(x) *. c.tile_size +. c.tile_size /. 2.0 -. offset_x
  let world_y = int.to_float(y) *. c.tile_size +. c.tile_size /. 2.0 -. offset_y

  case tile {
    maze.Wall -> {
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

    maze.Dot -> {
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

    maze.PowerPellet -> {
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

    maze.Empty -> option.None
  }
}
