"use strict"

App.GameChatroomController = Ember.Controller.extend({
  msgList: []

  postMsg: ->
    msg = @get "msg"
    if msg
      msg ="[#{App.get("username")}] #{msg}"
      socket.emit("postGameMsg", {
        msg: msg
        opponentId: App.get("currentPlayer.opponent.id")
      }, (err) ->
        console.error err if err
      )
      @get("msgList").addObject msg
      @set("msg", "")

  init: ->
    @_super()
    socket.on("newGameMsg", ({msg}) =>
      @get("msgList").addObject msg
    )
})
