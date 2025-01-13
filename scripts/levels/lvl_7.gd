extends Control

var cell_cords: Vector2i = Vector2i.ZERO
# cell array from which we loop over
var cell_direction_array: Array[TileSet.CellNeighbor] = [
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,]
# specify the cell direction (picked in the array)
var cell_direction_idx: int = 0

func _ready() -> void:
	%DeleteCellTimer.connect("timeout", func():
		# erase cells
		%Background.set_cell(cell_cords, -1)
		%Rocks.set_cell(cell_cords, -1)
		# setup next cell
		var cell_direction: TileSet.CellNeighbor = cell_direction_array[cell_direction_idx]
		var next_cell: Vector2i = %Background.get_neighbor_cell(cell_cords, cell_direction)
		# check if there is a cell for the next loop
		if %Background.get_cell_source_id(next_cell) == -1:
			# switch direction
			cell_direction_idx = (1 + cell_direction_idx) % cell_direction_array.size()
			cell_direction = cell_direction_array[cell_direction_idx]
		
		cell_cords = %Background.get_neighbor_cell(cell_cords, cell_direction)
		# we don't want to erase all the cells
		if cell_cords == Vector2i(5, 5):
			%DeleteCellTimer.stop()
			return
		%Background.set_cell(cell_cords, 1, Vector2i(2, 0))
	)
