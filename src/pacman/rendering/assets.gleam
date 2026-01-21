import pacman/constants as c
import tiramisu/geometry
import tiramisu/material
import vec/vec2
import vec/vec3

/// Shared rendering assets for efficient rendering
/// Created once and reused across all frames
pub type RenderingAssets {
  RenderingAssets(
    // Geometry
    wall_geometry: geometry.Geometry,
    dot_geometry: geometry.Geometry,
    pellet_geometry: geometry.Geometry,
    player_geometry: geometry.Geometry,
    ghost_geometry: geometry.Geometry,
    // Materials
    wall_material: material.Material,
    dot_material: material.Material,
    pellet_material: material.Material,
    player_material: material.Material,
    ghost_normal_blinky: material.Material,
    ghost_normal_pinky: material.Material,
    ghost_normal_inky: material.Material,
    ghost_normal_clyde: material.Material,
    ghost_frightened: material.Material,
    ghost_dead: material.Material,
  )
}

/// Create all shared rendering assets
/// This should be called once at initialization
pub fn create_assets() -> RenderingAssets {
  // Geometry - optimized segments for small objects
  let assert Ok(wall_geo) =
    geometry.box(size: vec3.Vec3(c.tile_size, c.tile_size, c.tile_size))

  let assert Ok(dot_geo) =
    geometry.sphere(radius: c.tile_size /. 8.0, segments: vec2.Vec2(8, 6))

  let assert Ok(pellet_geo) =
    geometry.sphere(radius: c.tile_size /. 4.0, segments: vec2.Vec2(8, 6))

  // Reduced segments: 16,12 -> 8,6 (75% vertex reduction)
  let assert Ok(player_geo) =
    geometry.sphere(radius: c.tile_size /. 2.0, segments: vec2.Vec2(8, 6))

  let assert Ok(ghost_geo) =
    geometry.sphere(radius: c.tile_size /. 2.0, segments: vec2.Vec2(8, 6))

  // Materials - created once and reused
  let assert Ok(wall_mat) =
    material.new()
    |> material.with_color(c.color_wall)
    |> material.build()

  let assert Ok(dot_mat) =
    material.new()
    |> material.with_color(c.color_dot)
    |> material.build()

  let assert Ok(pellet_mat) =
    material.new()
    |> material.with_color(c.color_power_pellet)
    |> material.build()

  let assert Ok(player_mat) =
    material.new()
    |> material.with_color(c.color_pacman)
    |> material.build()

  // Ghost materials for each personality
  let assert Ok(blinky_mat) =
    material.new()
    |> material.with_color(c.color_blinky)
    |> material.build()

  let assert Ok(pinky_mat) =
    material.new()
    |> material.with_color(c.color_pinky)
    |> material.build()

  let assert Ok(inky_mat) =
    material.new()
    |> material.with_color(c.color_inky)
    |> material.build()

  let assert Ok(clyde_mat) =
    material.new()
    |> material.with_color(c.color_clyde)
    |> material.build()

  let assert Ok(frightened_mat) =
    material.new()
    |> material.with_color(c.color_frightened)
    |> material.build()

  let assert Ok(dead_mat) =
    material.new()
    |> material.with_color(0x888888)
    |> material.build()

  RenderingAssets(
    wall_geometry: wall_geo,
    dot_geometry: dot_geo,
    pellet_geometry: pellet_geo,
    player_geometry: player_geo,
    ghost_geometry: ghost_geo,
    wall_material: wall_mat,
    dot_material: dot_mat,
    pellet_material: pellet_mat,
    player_material: player_mat,
    ghost_normal_blinky: blinky_mat,
    ghost_normal_pinky: pinky_mat,
    ghost_normal_inky: inky_mat,
    ghost_normal_clyde: clyde_mat,
    ghost_frightened: frightened_mat,
    ghost_dead: dead_mat,
  )
}
