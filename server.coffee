sys = require("sys")
express = require('express')
_ = require 'lodash'
server = express()


httpServer = require('http').createServer(server)
io = require('socket.io').listen(httpServer,{
  'log level': 1
})

# for dev purpose, auto reload when changes
watch = require('node-watch')
filter = (pattern, fun) ->
  return (filename) ->
    if /server\./i.test(filename) # changes on the server don't require client's reload
      return false
    if pattern.test(filename)
      fun(filename)
 
watch('./', filter(/\.js$|\.css$|\.html$/i, _.debounce(->
  io.sockets.emit('reload')
), 200))



players = {}
getPlayersList = ->
  _.values(players).map((player) ->
    p = _.pick(player, "name")
    p.id = player.socket.id
    return p
  )

class Player
  constructor: (@socket, @name, @state="idle") ->
    @id = @socket.id

  # get a hash to be send to a client
  serialize: ->
    return {
      id: @socket.id
      name: @name
      state: @state
    }

guestId = 0
io.sockets.on("connection", (socket) ->
  socket.on("disconnect", ->
    delete players[socket.id]
    socket.broadcast.emit("bye", {id: socket.id})
    return
  )

  guestId++
  name = "Guest#{guestId}"
  players[socket.id] = new Player(socket, name)

  socket.broadcast.emit("addPlayer", {player: players[socket.id].serialize()})

  socket.on("getPlayersList", ->
    socket.emit("playersList", {playersList: _.values(players).map((player) ->
      return player.serialize()
    )})
  )

  socket.on("getDefaultName", do (id=guestId) ->
    return ->
      socket.emit("defaultName", {defaultName: "Guest#{id}"})
      return
  )

  socket.on("setName", ({name}) ->
    name = name or "-,..,-"
    players[socket.id].name = name
    socket.broadcast.emit("changeName", {id: socket.id, name: name})
    return
  )

  socket.on("challenges", ({opponentId}, cb) ->
    challenger = players[socket.id]
    challengee = players[opponentId]
    if challengee?
      challenger.state = "inGame"
      challenger.opponentId = opponentId

      challengee.state = "inGame"
      challengee.opponentId = challenger.id
      
      socket.broadcast.emit("changeState", [
        {id: challenger.id, state: challenger.state}
        {id: challengee.id, state: challengee.state}
      ])
      challengee.socket.emit("getChallenge", {opponentId: challenger.id})
      cb()
    else
      cb("Opponent not found.")
    return
  )

  socket.on("declineChallenge", ({opponentId}) ->
    player = players[socket.id]
    opponent = players[opponentId]
    player.state = "idle"
    opponent.state = "idle"
    opponent.socket.emit("declineChallenge")
    socket.broadcast.emit("changeState", [
      {id: player.id, state: player.state}
      {id: opponent.id, state: opponent.state}
    ])
  )

  socket.on("cancelChallenge", ({opponentId}) ->
    player = players[socket.id]
    opponent = players[opponentId]
    player.state = "idle"
    opponent.state = "idle"
    opponent.socket.emit("challengeCancelled")
    socket.broadcast.emit("changeState", [
      {id: player.id, state: player.state}
      {id: opponent.id, state: opponent.state}
    ])
  )
)

server.get("/clients", (req, res) ->
  res.send io.sockets.clients().map( (c) ->
    player = players[c.id]
    return {
      id: c.id
      state: player.state
      opponentId: player.opponentId
    }
  )
)

server.use(server.router)

server.use(express.directory __dirname)
server.use(express.static __dirname)


httpServer.listen(4445)
console.log "Server up and running on port 4445"
