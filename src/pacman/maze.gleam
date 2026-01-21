/// Classic Pac-Man maze layout
pub type Tile {
  Wall
  Empty
  Dot
  PowerPellet
  Door
  // Ghost house entrance
}

/// Create the classic Pac-Man maze (28x31 grid)
pub fn create_classic_maze() -> List(List(Tile)) {
  [
    // Row 0
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall,
      Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall,
      Wall, Wall, Wall, Wall,
    ],
    // Row 1
    [
      Wall, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Wall,
      Wall, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Wall,
    ],
    // Row 2
    [
      Wall, Dot, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Dot,
      Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall,
      Dot, Wall,
    ],
    // Row 3
    [
      Wall, PowerPellet, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall,
      Wall, Dot, Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall,
      Wall, Wall, PowerPellet, Wall,
    ],
    // Row 4
    [
      Wall, Dot, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Dot,
      Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall,
      Dot, Wall,
    ],
    // Row 5
    [
      Wall, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot,
      Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Wall,
    ],
    // Row 6
    [
      Wall, Dot, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Dot, Wall, Wall, Wall,
      Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Dot, Wall, Wall, Wall, Wall,
      Dot, Wall,
    ],
    // Row 7
    [
      Wall, Dot, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Dot, Wall, Wall, Wall,
      Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Dot, Wall, Wall, Wall, Wall,
      Dot, Wall,
    ],
    // Row 8
    [
      Wall, Dot, Dot, Dot, Dot, Dot, Dot, Wall, Wall, Dot, Dot, Dot, Dot, Wall,
      Wall, Dot, Dot, Dot, Dot, Wall, Wall, Dot, Dot, Dot, Dot, Dot, Dot, Wall,
    ],
    // Row 9
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall,
      Empty, Wall, Wall, Empty, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall,
      Wall, Wall, Wall, Wall,
    ],
    // Row 10
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall,
      Empty, Wall, Wall, Empty, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall,
      Wall, Wall, Wall, Wall,
    ],
    // Row 11
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Empty, Empty, Empty,
      Empty, Empty, Empty, Empty, Empty, Empty, Empty, Wall, Wall, Dot, Wall,
      Wall, Wall, Wall, Wall, Wall,
    ],
    // Row 12 - Ghost house door (center columns 13-14)
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Empty, Wall, Wall,
      Wall, Door, Door, Wall, Wall, Wall, Empty, Wall, Wall, Dot, Wall, Wall,
      Wall, Wall, Wall, Wall,
    ],
    // Row 13
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Empty, Wall, Empty,
      Empty, Empty, Empty, Empty, Empty, Wall, Empty, Wall, Wall, Dot, Wall,
      Wall, Wall, Wall, Wall, Wall,
    ],
    // Row 14 - Ghost house center
    [
      Empty, Empty, Empty, Empty, Empty, Empty, Dot, Empty, Empty, Empty, Wall,
      Empty, Empty, Empty, Empty, Empty, Empty, Wall, Empty, Empty, Empty, Dot,
      Empty, Empty, Empty, Empty, Empty, Empty,
    ],
    // Row 15
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Empty, Wall, Empty,
      Empty, Empty, Empty, Empty, Empty, Wall, Empty, Wall, Wall, Dot, Wall,
      Wall, Wall, Wall, Wall, Wall,
    ],
    // Row 16
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Empty, Wall, Wall,
      Wall, Wall, Wall, Wall, Wall, Wall, Empty, Wall, Wall, Dot, Wall, Wall,
      Wall, Wall, Wall, Wall,
    ],
    // Row 17
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Empty, Empty, Empty,
      Empty, Empty, Empty, Empty, Empty, Empty, Empty, Wall, Wall, Dot, Wall,
      Wall, Wall, Wall, Wall, Wall,
    ],
    // Row 18
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Empty, Wall, Wall,
      Wall, Wall, Wall, Wall, Wall, Wall, Empty, Wall, Wall, Dot, Wall, Wall,
      Wall, Wall, Wall, Wall,
    ],
    // Row 19
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Empty, Wall, Wall,
      Wall, Wall, Wall, Wall, Wall, Wall, Empty, Wall, Wall, Dot, Wall, Wall,
      Wall, Wall, Wall, Wall,
    ],
    // Row 20
    [
      Wall, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Wall,
      Wall, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Wall,
    ],
    // Row 21
    [
      Wall, Dot, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Dot,
      Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall,
      Dot, Wall,
    ],
    // Row 22
    [
      Wall, Dot, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Dot,
      Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Wall, Wall,
      Dot, Wall,
    ],
    // Row 23
    [
      Wall, PowerPellet, Dot, Dot, Wall, Wall, Dot, Dot, Dot, Dot, Dot, Dot, Dot,
      Empty, Empty, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Wall, Wall, Dot, Dot,
      PowerPellet, Wall,
    ],
    // Row 24
    [
      Wall, Wall, Wall, Dot, Wall, Wall, Dot, Wall, Wall, Dot, Wall, Wall, Wall,
      Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Dot, Wall, Wall, Dot, Wall,
      Wall, Wall,
    ],
    // Row 25
    [
      Wall, Wall, Wall, Dot, Wall, Wall, Dot, Wall, Wall, Dot, Wall, Wall, Wall,
      Wall, Wall, Wall, Wall, Wall, Dot, Wall, Wall, Dot, Wall, Wall, Dot, Wall,
      Wall, Wall,
    ],
    // Row 26
    [
      Wall, Dot, Dot, Dot, Dot, Dot, Dot, Wall, Wall, Dot, Dot, Dot, Dot, Wall,
      Wall, Dot, Dot, Dot, Dot, Wall, Wall, Dot, Dot, Dot, Dot, Dot, Dot, Wall,
    ],
    // Row 27
    [
      Wall, Dot, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Dot,
      Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall,
      Wall, Dot, Wall,
    ],
    // Row 28
    [
      Wall, Dot, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Dot,
      Wall, Wall, Dot, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall,
      Wall, Dot, Wall,
    ],
    // Row 29
    [
      Wall, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot,
      Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Dot, Wall,
    ],
    // Row 30
    [
      Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall,
      Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall, Wall,
      Wall, Wall, Wall, Wall,
    ],
  ]
}
