/// Bridge messages for Tiramisu-Lustre communication
pub type BridgeMsg {
  // Game -> UI
  UpdateScore(Int)
  UpdateLives(Int)
  UpdateLevel(Int)
  ShowGameOver(Int)
  HideGameOver
  // UI -> Game (none for now, UI is display-only)
}
