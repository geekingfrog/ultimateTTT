"use strict"

App.MultiplayerRoute = Ember.Route.extend({
  beforeModel: ->
    username = App.get("username")
    if not username
      console.log "no username !"
      @transitionTo("index")

  setupController: (controller) ->
    controller.set("username", App.get("username"))
})

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
    play: (player) -> player.transitionTo "waitOpponentMove"
  })

  waitOpponentMove: Ember.State.create({
    finishGame: (player) -> player.transitionTo "idle"
    opponentPlays: (player) -> player.transitionTo "inGame"
  })

  # define other properties for a player
  opponent: null
  symbol: null # can be 'x' or 'o'

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
    state = @get("currentState.name")
    return state is "inGame" or state is "waitOpponentMove"
  ).property("currentState.name")

  isWaitingOpponentMove: (->
    return @get("currentState.name") is "waitOpponentMove"
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

App.MultiplayerController = Ember.Controller.extend({
  needs: "game"

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
    res = _.find(@get("allPlayers"), (p) -> p.get("id") is socket.socket.sessionid)
    return res
  ).property("allPlayers.@each")

  setCurrentPlayer: (->
    @get("allPlayers").forEach((p) => p.set("currentPlayer", @get("currentPlayer")))
    App.set("currentPlayer", @get("currentPlayer"))
    return
  ).observes("allPlayers.@each", "currentPlayer")

  init: ->
    @_super()

    socket.emit("getPlayersList")

    # manage new/leaving player from the lobby
    socket.on("addPlayer", ({player}) => @addPlayer(App.Player.create(player)))
    socket.on("bye", ({id}) => @removePlayer(id))

    socket.emit("join", {name: App.get("username")}, ({playersList}) =>
      @set("allPlayers", _.map(playersList, (raw) ->
        App.Player.createPlayer(raw)
      ))
      window.list = @get("allPlayers")
      return
    )

    socket.on("changeState", (changes) =>
      console.log "change state with changes: ", changes
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

    socket.on("challengeAccepted", =>
      console.log "challenge accepted"
      opponent = @get("currentPlayer.opponent")
      @get("currentPlayer").send("challengeAccepted")
      opponent.send("acceptChallenge")
      opponent.transitionTo("waitOpponentMove")
      @set("controllers.game.player", @get("currentPlayer"))
      @set("currentPlayer.symbol", "x")
    )

    socket.on("surrender", =>
      player = @get("currentPlayer")
      opponent = player.get("opponent")
      player.transitionTo("idle")
      opponent.transitionTo("idle")
      toastr.info "Opponent surrendered ! Victory !"
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

  acceptChallenge: ->
    console.log "start game against: ", @get("currentPlayer.opponent.name")
    @get("currentPlayer").send("acceptChallenge")
    @get("currentPlayer").transitionTo("waitOpponentMove")
    @get("currentPlayer.opponent").send("challengeAccepted")
    socket.emit("acceptChallenge", {opponentId: @get("currentPlayer.opponent.id")})
    @set("controllers.game.player", @get("currentPlayer"))
    @set("currentPlayer.symbol", "o")

  confirmSurrender: ->
    socket.emit("surrender", {opponentId: @get("currentPlayer.opponent.id")})
    @finishGame()

  # executed when the game has been won by someone
  gameFinished: (->
    wonBy = @get("controllers.game.board.wonBy")
    return unless wonBy
    console.log "game finished and won by: ", @get("controllers.game.board.wonBy")
    if @get("currentPlayer.symbol") is wonBy
      toastr.info("You won !")
    else
      toastr.info("Maybe next time...")
    @finishGame()
    return
  ).observes("controllers.game.board.wonBy")

  finishGame: ->
    @get("currentPlayer").transitionTo("idle")
    @get("currentPlayer.opponent").transitionTo("idle")

})

App.PlayerNameView = Ember.TextField.extend({
  focusOut: ->
    @get("controller").send("changeName", @get("value"))
})

App.IconSymbolView = Ember.View.extend({
  # template: Ember.Handlebars.compile("<i {{bindAttr class=view.iconSymbol}}></i>bla")
  template: Ember.Handlebars.compile(" ")
  classNameBindings: [':icon-2x', 'iconSymbol']
  tagName: 'i'
  iconSymbol: (->
    symbol = @get("symbol")
    if symbol is 'x'
      return "icon-remove"
    else if symbol is 'o'
      return "icon-circle-blank"
    else
      return ""
  ).property("symbol")
})

App.SurrenderController = Ember.Controller.extend({
  clicked: false
  
  surrender: -> @set("clicked", true)
  cancelSurrender: -> @set("clicked", false)
})
