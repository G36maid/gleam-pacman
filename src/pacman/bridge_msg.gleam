/// Bridge messages for Tiramisu-Lustre communication
pub type BridgeMsg {
  // Game -> UI (display updates)
  UpdateScore(Int)
  UpdateLives(Int)
  UpdateLevel(Int)
  ShowStartMenu
  ShowLevelComplete(score: Int, level: Int)
  ShowGameOver(Int)
  HideAllScreens
  // UI -> Game (player actions)
  StartGame
  ContinueToNextLevel
  RestartGame
}
