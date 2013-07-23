"use strict"

window.App = Em.Application.create({
  rootElement: "#application"
})

################################################################################ 
# A block is composed of 9 squares, and there are 9 blocks in a board.
# A block has (x,y) as coordinate to indicate its position inside the board.
# The x axis is from left to right and starts at 0.
# The y axis is from top to bottom and starts at 0.
# ------------------------
# | (0,0) | (1,0) | (2,0) |
# ------------------------
# | (0,1) | (1,1) | (2,1) |
# ------------------------
# | (0,2) | (1,2) | (2,2) |
# ------------------------
#
# To acces a given square from a block, one calls b.getSquare(xSquare, ySquare)
# where xSquare and ySquare are the coordinate of the square in the block's frame
################################################################################ 
App.Block = Em.Object.extend({
  x: null
  y: null
  board: null

  getSquare: (x, y) ->
    return @get("squares").objectAt(x+y*3)

  isFull: ( ->
    @get("squares").every( (square) -> square.get("markedBy") != null)
  ).property("squares.@each.markedBy")

  hasBeenWon: null
  wonBy: ( ->
    if @get("hasBeenWon")
      return @get("hasBeenWon")

    squares = @get("squares")
    accessor = (square) -> square.get("markedBy")
    winner = arrayWonBy(squares, accessor)
    if winner
      @set("hasBeenWon", winner)
      return winner
  ).property("squares.@each.markedBy")

  # returns the array representation of the block's squares
  serialize: ->
    @get("squares").map( (square) -> square.get("markedBy"))

  print: ->
    map = @serialize().map( (s) ->
      if s then return s else return "-"
    )
    console.log map
    return

})

App.Block.reopenClass({
  createBlock: (opts) ->
    block = @create(opts)
    squares = [0..8].map( (i) ->
      return App.Square.create({
        block: block
        x: i%3
        y: Math.floor(i/3)
      })
    )
    block.set("squares", squares)
    return block

  materialize: (opts, marks) ->
    block = @createBlock(opts)
    marks.forEach( (mark, index) ->
      return unless mark
      xBlock = index%3
      yBlock = Math.floor(index/3)
      block.getSquare(xBlock,yBlock).set("markedBy", mark)
    )
    return block

})

################################################################################ 
# A square is the basic element of the board. There are 81 squares.
# A square has two coordinate system. The global one (x,y), which represent
# its position inside the board, and a block-relative one (xBlock, yBlock)
# which represents its position inside its block.
# The x-axis and y-axis are the same for squares and blocks (hopefully)
#
# So the center square in the block with coordinate (3,2) has:
# x = 8 ; y = 5
# xBlock = 1 ; yBlock = 1
#
# A square is created inside a block, using the block's frame. The absolute
# position of the square in the board's frame is computed from the block's
# and square's position
################################################################################ 
App.Square = Em.Object.extend({
  xBlock: null
  yBlock: null
  block: null

  markedBy: null # which player marked this square, 'x' or 'o'
  x: ( ->
    @get("block.x")*3+@get("xBlock")
  ).property("block.x", "xBlock")
  y: ( ->
    @get("block.y")*3+@get("yBlock")
  ).property("block.y", "yBlock")

  set: ->
    @_super.apply(this, arguments)
    @get("block.board").set("lastMove", this)
})

################################################################################ 
# A board is composed of an array of blocks
# To acces a given block, one calls board.getBlock(x,y) with x and y
# the coordinates of the block.
# To access a square, one calls board.getSquare(x,y) with x and y the
# position of the square in the board's frame.
################################################################################ 
App.Board = Em.Object.extend({
  getBlock: (x, y) ->
    return @get("blocks").objectAt(x+y*3)

  getSquare: (x, y) ->
    block = @get("blocks").objectAt(Math.floor(x/3)+Math.floor(y/3)*3)
    xBlock = (x - block.get("x")*3)
    yBlock = (y - block.get("y")*3)
    return block.getSquare(xBlock, yBlock)

  isFull: ( ->
    @get("blocks").every( (block) -> block.get("isFull"))
  ).property("blocks.@each.isFull")

  lastMove: null

  hasBeenWon: null
  wonBy: ( ->
    if @get("hasBeenWon")
      return @get("hasBeenWon")

    blocks = @get("blocks")
    accessor = (block) -> block.get("wonBy")
    winner = arrayWonBy(blocks, accessor)
    if winner
      console.log "board won by: #{winner}"
      @set("hasBeenWon", winner)
      return winner
  ).property("blocks.@each.wonBy")

  serialize: ->
    {
      marks: [].concat.apply([], @get("blocks").map( (block) -> block.serialize()))
      lastMove: {x: @get("lastMove.x"), y: @get("lastMove.y")}
    }
})

App.Board.reopenClass({
  createBoard: ->
    board = @create()
    blocks = [0..8].map( (i) ->
      return App.Block.createBlock({
        board: board
        x: Math.floor(i/3)
        y: i%3
      })
    )
    board.set("blocks", blocks)
    return board

  ################################################################################ 
  # returns an array where squares are null, "x" or "o". A block is read from
  # left to right, from top to bottom to build the array.
  ################################################################################ 
  materialize: ({marks, lastMove}) ->
    board = @create()
    blocks = [0..8].map( (i) ->
      xBlock = i%3
      yBlock = Math.floor(i/3)
      return App.Block.materialize({board: board, x: xBlock, y: yBlock},
        marks.slice(i*9, (i+1)*9)
      )
    )
    board.set("blocks", blocks)
    board.set("lastMove", board.getSquare(lastMove.x, lastMove.y))
    if board.get("lastMove.markedBy") is "x"
      board.set("currentPlayer", "o")
    else
      board.set("currentPlayer", "x")
    return board
})

window.stored = {
  marks: [
    "x", "x", "x", null, null, null, null, null, "o",
    "x", "x", "x", null, null, null, null, null, null,
    "x", "x", null, null, null, null, null, null, null,
    null, null, null, null, "o", null, null, null, null,
    null, null, "o", null, "x", null, null, null, null,
    null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null,
    null, null, null, null, null, null, null, null, null,
    null, "x", null, null, null, null, null, null, null]
  lastMove: {x: 5, y: 3}
}

# window.stored = JSON.parse('{"marks":[null,null,null,null,"x",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,"x",null,null,null,null,"o","o","o",null,"x",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],"lastMove":{"x":5,"y":3}}')

################################################################################ 
# Utility function to check if an array has been won by a player
# The array has a square-length (n*n) and it's assume that the first n elements
# represent the first line.
# An array has been won by a player if all element on a row, a column or a
# diagonal are marked by the same player.
# @param array
# @param accessor: how to check if the given element has been marked by
# a player (accessor(element) should return null or the player who has marked
# the element)
################################################################################ 
window.arrayWonBy = (array, accessor) ->
  n = Math.sqrt(array.length)

  # check for rows
  for i in [0...n]
    player = accessor(array.objectAt(i*n))
    if player is null
      continue
    isWon = array.slice(i*n+1, i*n+1 + n-1).every( (el) ->
      r = accessor(el) is player
      return r
    )
    if isWon
      return player

  # check for columns
  for i in [0..n-1]
    player = accessor(array.objectAt(i))
    continue if player is null
    isWon = true
    for j in [1..n-1]
      if accessor(array.objectAt(i+j*n)) isnt player
        isWon = false
        break
    if isWon
      return player

  # diagonals
  player = accessor(array.objectAt(0))
  if player isnt null
    isWon = true
    for i in [1..n-1]
      if accessor(array.objectAt(i+i*n)) isnt player
        isWon = false
        break
    if isWon
      return player

  player = accessor(array.objectAt(n-1))
  if player isnt null
    isWon = true
    for i in [1..n-1]
      if accessor(array.objectAt(n-1-i + i*n)) isnt player
        isWon = false
        break
    if isWon
      return player

  return null

window.a = [
  'x', 'o', 'x'
  'o', 'x', 'o'
  'x', 'x', 'o'
]

# window.board = App.Board.createBoard()
window.board = App.Board.materialize(stored)
App.ApplicationController = Em.Controller.extend({
  board: board

  isWonByX: ( -> @get("board.wonBy") is 'x').property("board.wonBy")
  isWonByO: ( -> @get("board.wonBy") is 'o').property("board.wonBy")

  currentX: ( -> @get("board.currentPlayer") is 'x').property("board.currentPlayer")
  currentO: ( -> @get("board.currentPlayer") is 'o').property("board.currentPlayer")

  # create the nested structure needed to generate the board in html
  domBoard: ( ->
    board = @get("board")

    DomBlock = Em.Object.extend({
      block: null
      blockRow: null
      isWonByO: ( -> @get("block.wonBy") is 'o').property("block.wonBy")
      isWonByX: ( -> @get("block.wonBy") is 'x').property("block.wonBy")
      isPlayable: ( ->
        if @get("block.isFull") or @get("block.board.wonBy")?
          return false

        lastMove = @get("block.board.lastMove")
        if lastMove is null
          return true
        targetBlock = @get("block.board").getBlock(
          lastMove.get("x"), lastMove.get("y")
        )
        if targetBlock.get("wonBy")
          # can play anywhere if the targetted block has already been won
          return true
        else
          return targetBlock is @get("block")

      ).property("block", "block.board.lastMove", "block.board.blocks.@each")
    })


    rows = [0..2].map( (i) ->
      [
        board.getBlock(0,i)
        board.getBlock(1,i)
        board.getBlock(2,i)
      ]
    ).map( (rowBlock) =>
      rowBlock.map( (block) =>
        return DomBlock.create({block: block, blockRow: @makeBlockRow(block)})
      )
    )
    return rows
  ).property("board")

  makeBlockRow: (block) ->
    return [0..2].map( (i) ->
      [
        block.getSquare(0,i)
        block.getSquare(1,i)
        block.getSquare(2,i)
      ]
    ).map( (blockRow) =>
      blockRow.map( (square) =>
        Em.Object.extend({
          square: square
          isMarked: ( -> @get("square.markedBy") isnt null).property("square.markedBy")
          isMarkedByX: ( -> @get("square.markedBy") is 'x').property("square.markedBy")
          isMarkedByO: ( -> @get("square.markedBy") is 'o').property("square.markedBy")
        }).create()
      )
    )

  currentPlayer: 'x'
  nextTurn: ->
    if @get("board.currentPlayer") is 'x'
      @set("board.currentPlayer", 'o')
    else
      @set("board.currentPlayer", 'x')

  markSquare: (square, domBlock) ->
    return unless domBlock.get("isPlayable")
    square.set("markedBy", @get("currentPlayer"))
    @nextTurn()

})
