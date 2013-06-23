sys = require 'sys'
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
    if pattern.test(filename)
      fun(filename)
 
watch('./', filter(/\.js$|\.css$|\.html$/i, _.debounce(->
  console.log "fire reload event"
  io.sockets.emit('reload')
), 200))

server.use(server.router)

server.use(express.directory __dirname)
server.use(express.static __dirname)


httpServer.listen(4445)
console.log "Server up and running on port 4445"

