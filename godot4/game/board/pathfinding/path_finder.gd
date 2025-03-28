## A pathfinding utility that finds optimal paths between grid cells using Godot's AStarGrid2D.
## 
## This class encapsulates the A* pathfinding algorithm to calculate the shortest path
## between two points on a grid. It's used by UnitPath to preview movement paths and
## by Unit to execute movement. Only walkable cells are considered valid for pathfinding.
class_name PathFinder
extends Resource

## Reference to the shared Grid resource for dimensions and coordinate conversion
var _grid: Grid
## The A* pathfinding algorithm implementation
var _astar := AStarGrid2D.new()


## Creates and configures the A* pathfinding grid based on available walkable cells.
## 
## Parameters:
## - grid: The Grid resource containing dimensions and cell size information
## - walkable_cells: Array of Vector2i coordinates representing cells units can move to
func _init(grid: Grid, walkable_cells: Array[Vector2i]) -> void:
	_grid = grid
	
	# Configure the A* grid
	_astar.region = Rect2i(0, 0, _grid.dimensions.x, _grid.dimensions.y)
	_astar.cell_size = _grid.cell_size
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER # Units can only move in 4 directions
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()
	
	# Mark all cells that aren't walkable as solid (obstacles)
	for y in range(_grid.dimensions.y):
		for x in range(_grid.dimensions.x):
			if not walkable_cells.has(Vector2i(x, y)):
				_astar.set_point_solid(Vector2i(x, y))


## Calculates the shortest path between two grid cells.
## 
## Parameters:
## - start: Starting grid cell coordinates
## - end: Target grid cell coordinates
## 
## Returns:
## - An Array[Vector2i] containing the sequence of grid cells forming the path
func calculate_cell_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	return _astar.get_id_path(start, end)
