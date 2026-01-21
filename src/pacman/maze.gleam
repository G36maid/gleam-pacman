//// Classic Pacman maze layout and tile utilities.
////
//// The maze is a 28x31 grid representing the classic arcade layout.
//// Legend: 
////   W = Wall
////   . = Dot
////   o = Power Pellet
////   _ = Empty (paths without dots)
////   G = Ghost House
////   P = Pacman spawn point (replaced with Empty after init)

import gleam/list
import gleam/string
import pacman/game_state.{
  type GridPosition, type Tile, Dot, Empty, GhostHouse, GridPosition,
  PowerPellet, Wall,
}

/// Parse the classic Pacman maze from string representation
pub fn create_classic_maze() -> List(List(Tile)) {
  let rows = [
    "WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
    "W............WW............W",
    "W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
    "WoWWWW.WWWWW.WW.WWWWW.WWWWoW",
    "W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
    "W..........................W",
    "W.WWWW.WW.WWWWWWWW.WW.WWWW.W",
    "W.WWWW.WW.WWWWWWWW.WW.WWWW.W",
    "W......WW....WW....WW......W",
    "WWWWWW.WWWWW_WW_WWWWW.WWWWWW",
    "WWWWWW.WWWWW_WW_WWWWW.WWWWWW",
    "WWWWWW.WW__________WW.WWWWWW",
    "WWWWWW.WW_WWW__WWW_WW.WWWWWW",
    "WWWWWW.WW_W______W_WW.WWWWWW",
    "______.__W_GGGGGG_W____.____",
    "WWWWWW.WW_W______W_WW.WWWWWW",
    "WWWWWW.WW_WWWWWWWW_WW.WWWWWW",
    "WWWWWW.WW__________WW.WWWWWW",
    "WWWWWW.WW_WWWWWWWW_WW.WWWWWW",
    "WWWWWW.WW_WWWWWWWW_WW.WWWWWW",
    "W............WW............W",
    "W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
    "W.WWWW.WWWWW.WW.WWWWW.WWWW.W",
    "Wo..WW...P........WW..WW..oW",
    "WWW.WW.WW.WWWWWWWW.WW.WW.WWW",
    "WWW.WW.WW.WWWWWWWW.WW.WW.WWW",
    "W......WW....WW....WW......W",
    "W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
    "W.WWWWWWWWWW.WW.WWWWWWWWWW.W",
    "W..........................W",
    "WWWWWWWWWWWWWWWWWWWWWWWWWWWW",
  ]

  list.map(rows, parse_row)
}

/// Parse a single row string into list of tiles
fn parse_row(row: String) -> List(Tile) {
  row
  |> string.to_graphemes
  |> list.map(char_to_tile)
}

/// Convert character to tile type
fn char_to_tile(char: String) -> Tile {
  case char {
    "W" -> Wall
    "." -> Dot
    "o" -> PowerPellet
    "_" -> Empty
    "G" -> GhostHouse
    "P" -> Empty
    // Pacman spawn becomes empty
    _ -> Empty
  }
}

/// Get tile at grid position (with bounds checking)
pub fn get_tile(maze: List(List(Tile)), pos: GridPosition) -> Result(Tile, Nil) {
  // Drop rows until we reach the desired y position
  let row_result =
    maze
    |> list.drop(pos.y)
    |> list.first

  case row_result {
    Ok(row) -> {
      // Drop columns until we reach the desired x position
      row
      |> list.drop(pos.x)
      |> list.first
    }
    Error(_) -> Error(Nil)
  }
}

/// Check if tile is walkable
pub fn is_walkable(tile: Tile) -> Bool {
  case tile {
    Wall -> False
    _ -> True
  }
}

/// Check if tile blocks movement
pub fn is_wall_at(maze: List(List(Tile)), pos: GridPosition) -> Bool {
  case get_tile(maze, pos) {
    Ok(Wall) -> True
    _ -> False
  }
}

/// Count total dots in maze (for tracking completion)
pub fn count_dots(maze: List(List(Tile))) -> Int {
  maze
  |> list.flat_map(fn(row) { row })
  |> list.filter(fn(tile) {
    case tile {
      Dot | PowerPellet -> True
      _ -> False
    }
  })
  |> list.length
}

/// Get Pacman starting position (P in maze string)
pub fn get_pacman_spawn() -> GridPosition {
  GridPosition(x: 14, y: 23)
}

/// Get ghost starting positions
pub fn get_blinky_spawn() -> GridPosition {
  GridPosition(x: 14, y: 11)
}

pub fn get_pinky_spawn() -> GridPosition {
  GridPosition(x: 14, y: 14)
}

pub fn get_inky_spawn() -> GridPosition {
  GridPosition(x: 12, y: 14)
}

pub fn get_clyde_spawn() -> GridPosition {
  GridPosition(x: 16, y: 14)
}

/// Get scatter target corners for each ghost
pub fn get_blinky_scatter_target() -> GridPosition {
  GridPosition(x: 25, y: 0)
}

// Top-right corner

pub fn get_pinky_scatter_target() -> GridPosition {
  GridPosition(x: 2, y: 0)
}

// Top-left corner

pub fn get_inky_scatter_target() -> GridPosition {
  GridPosition(x: 27, y: 30)
}

// Bottom-right corner

pub fn get_clyde_scatter_target() -> GridPosition {
  GridPosition(x: 0, y: 30)
}
// Bottom-left corner
