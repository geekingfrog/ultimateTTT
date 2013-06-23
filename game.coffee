$(document).ready ->
  target = $(".board:last")

  for y in [3..1]
    row = $("<div>").addClass("row").attr("id", "row-#{y}")

    for x in [1..3]
      block = $("<div>").addClass("block").attr("id", "block-#{x}-#{y}")
      row.append block

      for yBlock in [3..1]
        blockRow = $("<div>").addClass("block-row")
        for xBlock in [1..3]
          idX = (x-1)*3+xBlock
          idY = (y-1)*3+yBlock
          cell = $("<div>").addClass("cell").attr("id", "cell-#{idX}-#{idY}")
          blockRow.append cell
        block.append blockRow

    target.append row

