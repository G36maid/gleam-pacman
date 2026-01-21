/// Lustre UI for Pac-Man game overlay
import gleam/int
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import pacman/bridge_msg
import tiramisu/ui

pub type Model {
  Model(
    bridge: ui.Bridge(bridge_msg.BridgeMsg),
    score: Int,
    lives: Int,
    level: Int,
    game_over: Bool,
    final_score: Int,
  )
}

pub type Msg {
  FromBridge(bridge_msg.BridgeMsg)
}

pub fn start(bridge: ui.Bridge(bridge_msg.BridgeMsg)) {
  lustre.application(init(bridge, _), update, view)
  |> lustre.start("#ui", Nil)
}

fn init(
  bridge: ui.Bridge(bridge_msg.BridgeMsg),
  _flags,
) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      bridge: bridge,
      score: 0,
      lives: 3,
      level: 1,
      game_over: False,
      final_score: 0,
    ),
    ui.register_lustre(bridge, FromBridge),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    FromBridge(bridge_msg.UpdateScore(score)) -> #(
      Model(..model, score: score),
      effect.none(),
    )
    FromBridge(bridge_msg.UpdateLives(lives)) -> #(
      Model(..model, lives: lives),
      effect.none(),
    )
    FromBridge(bridge_msg.UpdateLevel(level)) -> #(
      Model(..model, level: level),
      effect.none(),
    )
    FromBridge(bridge_msg.ShowGameOver(final_score)) -> #(
      Model(..model, game_over: True, final_score: final_score),
      effect.none(),
    )
    FromBridge(bridge_msg.HideGameOver) -> #(
      Model(..model, game_over: False),
      effect.none(),
    )
  }
}

fn view(model: Model) -> element.Element(Msg) {
  html.div([], [
    // Score/Lives/Level overlay
    html.div(
      [
        attribute.style("position", "absolute"),
        attribute.style("top", "20px"),
        attribute.style("left", "20px"),
        attribute.style("font-size", "24px"),
        attribute.style("font-family", "'Courier New', monospace"),
        attribute.style("color", "white"),
        attribute.style("text-shadow", "2px 2px 4px rgba(0,0,0,0.8)"),
      ],
      [
        html.div([], [element.text("SCORE: " <> int.to_string(model.score))]),
        html.div([], [element.text("LIVES: " <> int.to_string(model.lives))]),
        html.div([], [element.text("LEVEL: " <> int.to_string(model.level))]),
      ],
    ),
    // Game Over overlay
    case model.game_over {
      True ->
        html.div(
          [
            attribute.style("position", "absolute"),
            attribute.style("top", "50%"),
            attribute.style("left", "50%"),
            attribute.style("transform", "translate(-50%, -50%)"),
            attribute.style("text-align", "center"),
            attribute.style("font-family", "'Courier New', monospace"),
            attribute.style("text-shadow", "3px 3px 6px rgba(0,0,0,0.9)"),
          ],
          [
            html.div(
              [
                attribute.style("font-size", "48px"),
                attribute.style("color", "red"),
                attribute.style("margin-bottom", "20px"),
              ],
              [element.text("GAME OVER")],
            ),
            html.div(
              [
                attribute.style("font-size", "24px"),
                attribute.style("color", "white"),
              ],
              [
                element.text(
                  "FINAL SCORE: " <> int.to_string(model.final_score),
                ),
              ],
            ),
          ],
        )
      False -> element.none()
    },
  ])
}
