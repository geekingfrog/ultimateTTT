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
  constructor: (@socket, @name, @status="IDLE") ->

  # get a hash to be send to a client
  serialize: ->
    return {
      id: @socket.id
      name: @name
      status: @status
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

  socket.on("gameRequest", ({opponentId}, cb) ->
    opponent = players[opponentId]
    if opponent?
      players[opponentId].socket.emit("gameRequest", {opponentId: socket.id})
      cb()
    else
      cb("Opponent not found.")
    return
  )
)


server.use(server.router)

server.use(express.directory __dirname)
server.use(express.static __dirname)


httpServer.listen(4445)
console.log "Server up and running on port 4445"

