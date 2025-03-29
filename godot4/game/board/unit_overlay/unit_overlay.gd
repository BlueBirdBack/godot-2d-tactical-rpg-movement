## Highlights walkable cells for a selected unit.
##
## Usage:
## 1. Call `draw()` with an array of walkable grid positions
## 2. Call `clear()` to remove the overlay when deselected
class_name MovementHighlighter
extends TileMapLayer


## Updates the overlay to show all walkable cells.
## 
## Note: Clears any existing overlay before drawing new cells.
func draw(cells: Array[Vector2i]) -> void:
	clear()
	for cell in cells:
		set_cell(cell, 0, Vector2i(0, 0))
