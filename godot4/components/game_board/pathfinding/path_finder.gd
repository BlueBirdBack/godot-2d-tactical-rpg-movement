## Finds the path between two points among walkable cells using the AStar pathfinding algorithm.
class_name PathFinder
extends Resource

# Define Vector2i directions since Vector2i doesn't have these constants
const DIRECTIONS = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)] # LEFT, RIGHT, UP, DOWN

var _grid: Resource
var _astar := AStarGrid2D.new()


## Initializes the AstarGrid2D object upon creation.
func _init(grid: Grid, walkable_cells: Array[Vector2i]) -> void:
	_grid = grid
	_astar.size = _grid.dimensions
	_astar.cell_size = _grid.cell_size
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.update()
	# Iterate over all points on the grid and disable any which are
	#	not in the given array of walkable cells
	for y in _grid.dimensions.y:
		for x in _grid.dimensions.x:
			if not walkable_cells.has(Vector2i(x, y)):
				_astar.set_point_solid(Vector2i(x, y))

## Returns the path found between `start` and `end` as an array of Vector2i coordinates.
func calculate_point_path(start: Vector2i, end: Vector2i) -> PackedVector2Array:
	# With an AStarGrid2D, we only need to call get_id_path to return
	#	the expected array - note it's returning Vector2 that we need to work with
	return _astar.get_id_path(start, end)
