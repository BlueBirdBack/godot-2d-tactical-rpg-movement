## Visualizes a unit's movement path on the game board using autotile terrain.
## 
## This class handles calculating and displaying the path a unit will take when moving
## from one cell to another. It uses PathFinder for calculating optimal routes and
## renders them using TileMap's terrain system.
class_name UnitPath
extends TileMap

## Reference to the shared Grid resource for coordinate conversion and grid parameters.
@export var grid: Grid

## The pathfinding algorithm that calculates the optimal path between cells.
var _pathfinder: PathFinder = null

## The current calculated path as a sequence of grid coordinates.
## This is used by the GameBoard to execute unit movement.
var current_path: PackedVector2Array = PackedVector2Array()


## Initializes the pathfinding system with cells the unit can move to.
## 
## Parameters:
## - walkable_cells: Array of grid coordinates where the unit can move.
func initialize(walkable_cells: Array[Vector2i]) -> void:
	_pathfinder = PathFinder.new(grid, walkable_cells)


## Calculates and visualizes a path between two grid positions.
## 
## Parameters:
## - cell_start: The starting grid cell (usually the unit's current position)
## - cell_end: The target grid cell where the unit would move to
func draw(cell_start: Vector2i, cell_end: Vector2i) -> void:
	# Clear any existing path visualization
	clear()
	
	# Calculate the optimal path
	current_path = _pathfinder.calculate_point_path(cell_start, cell_end)
	
	# Prepare cells for tilemap drawing
	var cells_to_draw: Array[Vector2i] = []
	for cell in current_path:
		# Explicitly create Vector2i to avoid conversion warning
		cells_to_draw.append(Vector2i(int(cell.x), int(cell.y)))
	
	# Draw the path using terrain autotiling for a smooth connected path
	set_cells_terrain_connect(0, cells_to_draw, 0, 0)


## Cleans up the path visualization and pathfinding resources.
## Called when a unit is deselected or has completed its movement.
func stop() -> void:
	_pathfinder = null
	clear()
