"use strict"

App.Player = Ember.StateManager.extend({
  initialState: "idle"

  # define states and transitions
  idle: Ember.State.create({
    challenges: (player, opponent) -> player.transitionTo "wait"
    getChallenge: (player, opponent) -> player.transitionTo "challenged"
  })
  wait: Ember.State.create({ # wait for an opponent to accept or decline a challenge
    challengeDeclined: (player) ->
      player.transitionTo "idle"
      player.set("opponent", null)
    challengeAccepted: (player) -> player.transitionTo "inGame"
    cancelChallenge: (player) -> player.transitionTo "idle"
  })
  challenged: Ember.State.create({
    declineChallenge: (player) -> player.transitionTo "idle"
    challengeCanceled: (player) ->
      player.transitionTo "idle"
      player.set("opponent", null)
    acceptChallenge: (player) -> player.transitionTo "inGame"
  })
  inGame: Ember.State.create({
    finishGame: (player) -> player.transitionTo "idle"
  })

  # define other properties for a player
  opponent: null

  isIdle: (->
    return @get("currentState.name") is "idle"
  ).property("currentState.name")
  
  isChallenged: (->
    return @get("currentState.name") is "challenged"
  ).property("currentState.name")

  isWaiting: (->
    return @get("currentState.name") is "wait"
  ).property("currentState.name")

  isInGame: (->
    return @get("currentState.name") is "inGame"
  ).property("currentState.name")

  canBeChallenged: (->
    @get("isIdle") and @get("currentPlayer.isIdle")
  ).property("isIdle", "currentPlayer.isIdle")

  challengePlayer: (opponent) ->
    window.opp = opponent
    @set("opponent", opponent)
    @send("challenges")
    socket.emit("challenges", {opponentId: opponent.get("id")}, (err)  =>
      if err?
        @transitionTo("idle")
        console.error err
      else
        @set("opponent", opponent)
        opponent.set("opponent", this)
        opponent.send("getChallenge", this)
    )
})

App.Player.reopenClass({
  createPlayer: (hash) ->
    state = hash.state or "idle"
    hash.initialState = state
    delete hash.state
    player = @create(hash)
})

App.LobbyController = Ember.Controller.extend({
  allPlayers: null
  otherPlayers: ( ->
    currentId = socket.socket.sessionid
    if currentId?
      return _.filter(@get("allPlayers"), (player) ->
        player.get("id") isnt currentId
      )
    else
      return @get("allPlayers")
  ).property("allPlayers.@each")

  currentPlayer: (->
    _.find(@get("allPlayers"), (p) -> p.get("id") is socket.socket.sessionid)
  ).property("allPlayers.@each")

  setCurrentPlayer: (->
    @get("allPlayers").forEach((p) => p.set("currentPlayer", @get("currentPlayer")))
  ).observes("allPlayers.@each", "currentPlayer")

  init: ->
    @_super()

    socket.emit("getDefaultName")
    socket.once("defaultName", ({defaultName}) =>
      currentPlayer = @get("currentPlayer")
      if currentPlayer
        currentPlayer.set("name", defaultName)
      return
    )

    socket.emit("getPlayersList")
    socket.once("playersList", ({playersList}) =>
      @set("allPlayers", _.map(playersList, (raw) ->
        App.Player.createPlayer(raw)
      ))
      window.list = @get("allPlayers")
      return
    )

    # manage new/leaving player from the lobby
    socket.on("addPlayer", ({player}) => @addPlayer(App.Player.create(player)))
    socket.on("bye", ({id}) => @removePlayer(id))

    socket.on("changeName", ({id, name}) =>
      player = _.find(@get("otherPlayers"), (p) -> p.get("id") is id)
      player.set("name", name)
      return
    )

    socket.on("changeState", (changes) =>
      allPlayers = @get("allPlayers")
      currentId = @get("currentPlayer.id")
      opponentId = @get("currentPlayer.opponent.id")
      changes = _.filter(changes, (c) -> c.id isnt currentId and c.id isnt opponentId)

      for change in changes
        player = _.find(allPlayers, (p) -> p.get("id") is change.id)
        player.transitionTo(change.state)
      return
    )

    socket.on("getChallenge", ({opponentId}) =>
      window.challenger = _.find(@get("allPlayers"), (p) -> p.get("id") is opponentId)
      window.currentPlayer = @get("currentPlayer")

      if challenger?
        currentPlayer.transitionTo("challenged")
        currentPlayer.set("opponent", challenger)
        challenger.transitionTo("wait")
        challenger.set("opponent", currentPlayer)

      return
    )

    socket.on("declineChallenge", =>
      opponent = @get("currentPlayer.opponent")
      opponent.send("declineChallenge")
      @get("currentPlayer").send("challengeDeclined")
      @set("currentPlayer.opponent", null)
      console.log "#{opponent.get("name")} declined your challenge"
    )

    socket.on("challengeCancelled", =>
      console.log "challenge canceled"
      opponent = @get("currentPlayer.opponent")
      @get("currentPlayer").send("challengeCanceled")
      opponent.send("cancelChallenge")
    )


  # add a player if not already in the list
  addPlayer: (player) ->
    console.log "add player: ", player
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
    @set("currentPlayer.name", newName)
    socket.emit("setName", {name: newName})

  challenges: (opponent) ->
    @get("currentPlayer").challengePlayer(opponent)
    return

  declineChallenge: ->
    currentPlayer = @get("currentPlayer")
    opponent = currentPlayer.get("opponent")
    currentPlayer.send("declineChallenge")
    opponent.send("challengeDeclined")
    socket.emit("declineChallenge", {opponentId: opponent.get("id")})
    return

  cancelChallenge: ->
    socket.emit("cancelChallenge", {opponentId: @get("currentPlayer.opponent.id")})
    @get("currentPlayer.opponent").send("challengeCanceled")
    @get("currentPlayer").send("cancelChallenge")
})

App.PlayerNameView = Ember.TextField.extend({
  focusOut: ->
    @get("controller").send("changeName", @get("value"))
})
