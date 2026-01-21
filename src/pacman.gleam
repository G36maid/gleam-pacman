import gleam/option
import gleam/time/duration
import tiramisu
import tiramisu/camera
import tiramisu/effect
import tiramisu/geometry
import tiramisu/light
import tiramisu/material
import tiramisu/scene
import tiramisu/transform
import vec/vec3

// Game Model
pub type Model {
  Model(rotation: Float)
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
  #(Model(rotation: 0.0), effect.dispatch(Tick), option.None)
}

// Update game state
fn update(model: Model, msg: Msg, ctx: tiramisu.Context) {
  case msg {
    Tick -> {
      let delta_seconds = duration.to_seconds(ctx.delta_time)
      let new_rotation = model.rotation +. delta_seconds
      #(Model(rotation: new_rotation), effect.dispatch(Tick), option.None)
    }
  }
}

// Render scene
fn view(model: Model, _ctx: tiramisu.Context) {
  // Camera setup
  let assert Ok(cam) =
    camera.perspective(field_of_view: 75.0, near: 0.1, far: 1000.0)

  // Create a cube geometry (takes size as Vec3)
  let assert Ok(cube_geo) = geometry.box(size: vec3.Vec3(1.0, 1.0, 1.0))

  // Create green material for the cube
  let assert Ok(cube_mat) =
    material.new()
    |> material.with_color(0x00FF00)
    |> material.with_metalness(1.0)
    |> material.with_roughness(0.3)
    |> material.build()

  // Create directional light
  let assert Ok(sun) = light.directional(intensity: 1.0, color: 0xFFFFFF)

  // Camera position and look direction
  let camera_position = transform.at(position: vec3.Vec3(0.0, 2.0, 5.0))
  let look_target = transform.at(position: vec3.Vec3(0.0, 0.0, 0.0))
  let camera_transform =
    transform.look_at(from: camera_position, to: look_target, up: option.None)

  // Build scene graph
  scene.empty(id: "scene", transform: transform.identity, children: [
    scene.camera(
      id: "main-camera",
      camera: cam,
      transform: camera_transform,
      active: True,
      viewport: option.None,
      postprocessing: option.None,
    ),
    scene.mesh(
      id: "cube",
      geometry: cube_geo,
      material: cube_mat,
      transform: transform.identity |> transform.rotate_y(model.rotation),
      physics: option.None,
    ),
    scene.light(
      id: "sun",
      light: sun,
      transform: transform.at(position: vec3.Vec3(5.0, 5.0, 5.0)),
    ),
  ])
}
