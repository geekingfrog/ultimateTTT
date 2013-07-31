"use strict"

App.ChatroomController = Ember.Controller.extend({
  msgList: []

  postMsg: ->
    msg = @get "msg"
    if msg
      msg ="[#{App.get("username")}] #{msg}"
      socket.emit("postMsg", ({msg: msg}))
      @get("msgList").addObject msg
      @set("msg", "")

  init: ->
    @_super()
    socket.on("newMsg", ({msg}) =>
      @get("msgList").addObject msg
    )
})
