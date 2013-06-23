class Cell
  constructor: (@xCell, @yCell) ->
    @markedBy = null # 1: marked by X

  mark: (game) ->
    @markedBy = game.currentPlayer
    game.lastMove = this
    updateDomBlock(@getEnclosingBlock(game))
    game.markPlayableBlocks()

  getEnclosingBlock: (game) ->
    xBlock = Math.floor((@xCell-1)/3)
    yBlock = Math.floor((@yCell-1)/3)
    return game.blocks[xBlock][yBlock]


# the cell with coordinate (x, y) is in blocks.cell(y,x)
class Block
  constructor: (@x, @y) ->
    @isPlayable = -> true
    @isWon = null
    @cells = [3,2,1].map( (yCell) =>
      return [1,2,3].map( (xCell) =>
        return new Cell( (@x-1)*3+xCell, (@y-1)*3+yCell)
      )
    )

  isFull: ->
    @cells.every( (row) ->
      row.every( (cell) -> cell.markedBy isnt null)
    )

  # 1 if X has won the block, 0 if O has won, null otherwise
  wonBy: ->
    if @isWon isnt null
      return @isWon

    winner = arrayWonBy(@cells, (cell) -> cell.markedBy)
    if winner isnt null
      @isWon = winner
    return winner

  print: ->
    res = "\n"
    for row in @cells
      for cell in row
        res += cell.markedBy+" "
      res += "\n"

    console.log res



class Game
  constructor: ->
    @currentPlayer = 1 #1 = 'X', 0 = 'O'
    @isFinished = false
    @blocks = [1,2,3].map( (x) ->
      return [1,2,3].map( (y) ->
        return new Block(x,y)
      )
    )

  nextTurn: ->
    winner = arrayWonBy(@blocks, (block) -> block.wonBy())
    if winner isnt null
      @isFinished = true
      @winner = winner
    else
      @currentPlayer = 1-@currentPlayer
    return

  markPlayableBlocks: ->
    target = {
      x: @lastMove.xCell%3
      y: @lastMove.yCell%3
    }
    target.x = 3 if target.x is 0
    target.y = 3 if target.y is 0

    for rowBlocks in @blocks
      for block in rowBlocks
        status = block.isPlayable()
        isTargetBlock = (block.x is target.x) and (block.y is target.y)

        if isTargetBlock
          if not block.isFull()
            block.isPlayable = -> true
            updateDomBlock(block)
          else
            # mark all non full blocks as playable and update dom
            for r in @blocks
              for b in r
                if b.isFull()
                  b.isPlayable = -> false
                else
                  b.isPlayable = -> true
                updateDomBlock(b)
            return
        else
          block.isPlayable = -> false
          updateDomBlock(block)

# takes an array of array (3x3) and, using the accessor function
# on each elements: accessor(el), check if the array of array
# has been won by a player. This is used to check if a block or
# the board has been won.
arrayWonBy = (array, accessor) ->
  # 3 in a row ?
  for row in array
    player = accessor(row[0])
    continue if player is null

    for cell in row
      if accessor(cell) isnt player
        player = null

    if player isnt null
      return player

  # 3 in a column ?
  for col in [0..2]
    player = accessor(array[0][col])
    continue if player is null
    for y in [1..2]
      if player isnt accessor(array[y][col])
        player = null
    if player isnt null
      return player

  # diagonal ?
  potential = accessor(array[1][1])
  diag = potential isnt null
  diag = diag and (potential is accessor(array[0][0])) and (potential is accessor(array[2][2]))
  diag = diag or (potential is accessor(array[0][2])) and (potential is accessor(array[2][0]))
  if diag
    return potential

  return null




window.game = new Game()
# game.blocks[1][1].cells[0][0].markedBy = 1
# game.blocks[1][1].cells[0][1].markedBy = 1
# game.blocks[1][1].cells[0][2].markedBy = 1
# game.blocks[1][1].cells[1][0].markedBy = 1
# game.blocks[1][1].cells[1][1].markedBy = 1
# game.blocks[1][1].cells[1][2].markedBy = 1
# game.blocks[1][1].cells[2][0].markedBy = 1
# game.blocks[1][1].cells[2][1].markedBy = 1
# game.blocks[1][1].cells[2][2].markedBy = 1

init = (game) ->
  target = $(".board:last")

  # Generate a board. x axis is from left to right, y axis is from bottom to top.
  # So the bottom left cell is at (1,1)
  for y in [3..1]
    row = $("<div>").addClass("row").attr("id", "row-#{y}")

    for x in [1..3]
      block = $("<div>").addClass("block").attr("id", "block-#{x}-#{y}")
      if game.blocks[x-1][y-1].isPlayable() and not game.blocks[x-1][y-1].isFull()
        block.addClass("playable")
      row.append block

      for yBlock in [3..1]
        blockRow = $("<div>").addClass("block-row")
        for xBlock in [1..3]
          idX = (x-1)*3+xBlock
          idY = (y-1)*3+yBlock
          cell = $("<div>").addClass("cell").attr("id", "cell-#{idX}-#{idY}")
          cell.data("cell", game.blocks[x-1][y-1].cells[3-yBlock][xBlock-1])
          blockRow.append cell
        block.append blockRow

    target.append row

# update the dom element gameStatus
updateGameStatus = (game) ->
  if game.isFinished
    $(".cell").unbind("click")
    if game.winner is 0
      icon = "icon-circle-blank"
    else
      icon = "icon-remove"
    $("#gameStatus").html("<h1>Game won by <i class='#{icon}'></i> !</h1>")
    $(".block.playable").each -> $(this).removeClass "playable"
  else
    if game.currentPlayer is 0
      icon = "icon-circle-blank"
    else
      icon = "icon-remove"
    $("#gameStatus").html("<h1><i class='#{icon}'></i>'s turn</h1>")

markDomCell = (domCell, game) ->
  if game.currentPlayer is 0
    icon = "icon-circle-blank"
  else
    icon = "icon-remove"

  domCell.html("<i class='#{icon}'></i>")
  domCell.addClass("marked")

updateDomBlock = (gameBlock) ->
  # console.log "game block is: full? #{gameBlock.isFull()} | wonBy? #{gameBlock.wonBy()}"
  domBlock = $("#block-#{gameBlock.x}-#{gameBlock.y}")

  if gameBlock.wonBy() isnt null
    winner = if gameBlock.wonBy() is 0 then 'o' else 'x'
    domBlock.addClass("won-#{winner}")

  if gameBlock.isFull()
    domBlock.removeClass("playable")
  else if gameBlock.isPlayable()
    domBlock.addClass("playable")
  else
    domBlock.removeClass("playable")



$(document).ready ->
  init(game)
  updateGameStatus(game)
  
  # attach listener to cells
  $(".cell").each ->
    $(this).bind("click", (ev, foo, bar, baz) ->
      coordinates = ev.target.id.split('-')
      x = coordinates[1]
      y = coordinates[2]
      # console.log "cell(#{x}-#{y}) clicked: ", ev.target
      # console.log "cell from data: ", $(ev.target).data("cell")
      domCell = $(ev.delegateTarget)
      gameCell = domCell.data("cell")
      if domCell.closest(".block").hasClass("playable") and not domCell.html()
        markDomCell(domCell, game)
        gameCell.mark(game)
        game.nextTurn()
        updateGameStatus(game)
    )


