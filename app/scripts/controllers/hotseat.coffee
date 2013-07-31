"use strict"

# window.stored = {
#   marks: [
#     "x", "x", "x", null, null, null, null, null, "o",
#     "x", "x", "x", null, null, null, null, null, null,
#     "x", "x", null, null, null, null, null, null, null,
#     null, null, null, null, "o", null, null, null, null,
#     null, null, "o", null, "x", null, null, null, null,
#     null, null, null, null, null, null, null, null, null,
#     null, null, null, null, null, null, null, null, null,
#     null, null, null, null, null, null, null, null, null,
#     null, "x", null, null, null, null, null, null, null]
#   lastMove: {x: 5, y: 3}
# }

App.HotseatController = Em.Controller.extend({
  needs: "game"
  boardBinding: "controllers.game.board"
  currentXBinding: "controllers.game.currentX"
  currentOBinding: "controllers.game.currentO"

  isWonByXBinding: "controllers.game.isWonByX"
  isWonByOBinding: "controllers.game.isWonByO"

})
