"use strict"

App.Player = Ember.Object.extend({
  isIdle: (->
    return @get("status") is App.Player.status.idle
  ).property("status")
  
  isChallenged: (->
    return @get("status") is App.Player.status.challenged
  ).property("status")

  isWaiting: (->
    return @get("status") is App.Player.status.waiting
  ).property("status")
})

App.Player.reopenClass({
  status: {
    idle: "IDLE"
    ingame: "IN_GAME"
    waiting: "WAITING" # waiting for opponent to accept play request
    challenged: "CHALLENGED" # a player has requested a game against this player
  }
})

App.LobbyController = Ember.Controller.extend({
  currentPlayer: null
  allPlayers: null
  otherPlayers: ( ->
    currentId = @get("currentPlayer.id")
    if currentId?
      return _.filter(@get("allPlayers"), (player) ->
        player.get("id") isnt currentId
      )
    else
      return @get("allPlayers")
  ).property("currentPlayer.id", "allPlayers.@each")

  init: ->
    @_super()

    socket.emit("getDefaultName")
    socket.once("defaultName", ({defaultName}) =>
      @set("currentPlayer", App.Player.create({
        name: defaultName
        status: App.Player.status.idle
        # status: App.Player.status.challenged
        id: socket.socket.sessionid
      }))
    )

    socket.emit("getPlayersList")
    socket.once("playersList", ({playersList}) =>
      @set("allPlayers", _.map(playersList, (raw) ->
        # raw.status = App.Player.status.challenged
        App.Player.create(raw)
      ))
    )

    # manage new/leaving player from the lobby
    socket.on("addPlayer", ({player}) => @addPlayer(App.Player.create(player)))
    socket.on("bye", ({id}) => @removePlayer(id))

    socket.on("changeName", ({id, name}) =>
      player = _.find(@get("otherPlayers"), (p) -> p.get("id") is id)
      player.set("name", name)
      return
    )

    socket.on("gameRequest", ({opponentId}) =>
      opponent = _.find(@get("allPlayers"), (p) -> p.get("id") is opponentId)
      return unless opponent?

      console.log "game request with opponent: ", opponent
      opponent.set("status", App.Player.status.waiting)
      @get("currentPlayer").setProperties(
        status: App.Player.status.challenged
        opponent: opponent
      )
    )


  # add a player if not already in the list
  addPlayer: (player) ->
    players = @get("allPlayers")
    return unless players?

    playerId = player.get("id")
    if _.contains(players, (player) -> player.get("id") is playerId)
      return

    players.addObject(player)
    return
    

  # remove a player from the list
  removePlayer: (id) ->
    @set("allPlayers", _.filter(@get("allPlayers"), (player) -> player.get("id") isnt id))
    currentOpponent = @get("currentPlayer.opponent")
    if currentOpponent and currentOpponent.get("id") is id
      @set("currentPlayer.opponent", null)
      @set("currentPlayer.status", App.Player.status.idle)
    return

  changeName: (newName) ->
    console.log "set new name"
    @set("currentPlayer.name", newName)
    socket.emit("setName", {name: newName})

  playAgainst: (opponent) ->
    console.log "play against ", opponent
    opponent.set("status", App.Player.status.challenged)
    @set("currentPlayer.status", App.Player.status.waiting)
    socket.emit("gameRequest", {opponentId: opponent.get("id")}, ((err) =>
      if err?
        @set("currentPlayer.status", App.Player.status.idle)
        console.log "error: ", err
      else
        @set("currentPlayer.opponent", opponent)
      return
    ))

})

App.PlayerNameView = Ember.TextField.extend({
  focusOut: ->
    @get("controller").send("changeName", @get("value"))
})
