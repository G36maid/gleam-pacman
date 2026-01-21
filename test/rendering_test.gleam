import gleam/list
import gleeunit
import gleeunit/should
import pacman/constants as c
import pacman/game_state as gs
import pacman/maze

pub fn main() {
  gleeunit.main()
}

// Test that constants are sane
pub fn constants_test() {
  c.maze_width |> should.equal(28)
  c.maze_height |> should.equal(31)
  c.tile_size |> should.equal(16.0)
}

// Test maze generation
pub fn maze_generation_test() {
  let maze_data = maze.create_classic_maze()

  // Check maze dimensions
  maze_data
  |> list.length
  |> should.equal(c.maze_height)

  // Check first row length
  let assert [first_row, ..] = maze_data
  first_row
  |> list.length
  |> should.equal(c.maze_width)
}

// Test spawn points
pub fn spawn_points_test() {
  let pacman_spawn = maze.get_pacman_spawn()

  // Pacman spawn should be valid
  { pacman_spawn.x >= 0 && pacman_spawn.x < c.maze_width } |> should.be_true
  { pacman_spawn.y >= 0 && pacman_spawn.y < c.maze_height } |> should.be_true
}

// Test grid to world conversion
pub fn grid_to_world_test() {
  let grid_pos = gs.GridPosition(x: 1, y: 1)
  let world_pos = gs.grid_to_world(grid_pos, c.tile_size)

  // World position should be centered on tile
  world_pos.x |> should.equal(1.0 *. c.tile_size +. c.tile_size /. 2.0)
  world_pos.y |> should.equal(1.0 *. c.tile_size +. c.tile_size /. 2.0)
}
