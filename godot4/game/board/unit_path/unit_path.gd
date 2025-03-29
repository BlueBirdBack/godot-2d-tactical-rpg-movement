## Visualizes a unit's movement path on the game board using autotile terrain.
## 
## This class handles calculating and displaying the path a unit will take when moving
## from one cell to another. It uses AStarGrid2D for pathfinding and renders paths
## using TileMap's terrain system.
class_name UnitPath
extends TileMapLayer

## Reference to the shared Grid resource for coordinate conversion and grid parameters.
@export var grid: Grid

## The A* pathfinding algorithm implementation
var _astar: AStarGrid2D = null

## The current calculated path as a sequence of grid coordinates.
## This is used by the GameBoard to execute unit movement.
var current_path: Array[Vector2i] = []


## Initializes the pathfinding system with cells the unit can move to.
## 
## Parameters:
## - walkable_cells: Array of grid coordinates where the unit can move.
func initialize(walkable_cells: Array[Vector2i]) -> void:
	# Create and configure the A* grid
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(0, 0, grid.dimensions.x, grid.dimensions.y)
	_astar.cell_size = grid.cell_size
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER # Units can only move in 4 directions
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()
	
	# Mark all cells that aren't walkable as solid (obstacles)
	for y in range(grid.dimensions.y):
		for x in range(grid.dimensions.x):
			if not walkable_cells.has(Vector2i(x, y)):
				_astar.set_point_solid(Vector2i(x, y))


## Calculates and visualizes a path between two grid positions.
## 
## Parameters:
## - cell_start: The starting grid cell (usually the unit's current position)
## - cell_end: The target grid cell where the unit would move to
func draw(cell_start: Vector2i, cell_end: Vector2i) -> void:
	# Clear any existing path visualization
	clear()
	
	# Calculate the optimal path
	current_path = _astar.get_id_path(cell_start, cell_end)
	
	# Draw the path using terrain autotiling
	set_cells_terrain_connect(current_path, 0, 0)


## Cleans up the path visualization and pathfinding resources.
## Called when a unit is deselected or has completed its movement.
func stop() -> void:
	_astar = null
	clear()
