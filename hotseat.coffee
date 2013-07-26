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
  reset: ->
    @set("board", Game.Board.createBoard())

  board: Game.Board.createBoard()

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

  currentPlayerBinding: "board.currentPlayer"

  nextTurn: ->
    console.log "end of #{@get("board.currentPlayer")} turn"
    if @get("board.currentPlayer") is 'x'
      @set("board.currentPlayer", 'o')
    else
      @set("board.currentPlayer", 'x')

  markSquare: (square, domBlock) ->
    return unless domBlock.get("isPlayable")
    square.set("markedBy", @get("currentPlayer"))
    @nextTurn()

})
