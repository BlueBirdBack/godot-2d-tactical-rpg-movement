## Draws the unit's movement path using an autotile.
class_name UnitPath
extends TileMap

@export var grid: Resource

var _pathfinder: PathFinder
var current_path := PackedVector2Array()


## Creates a new PathFinder that uses the AStar algorithm to find a path between two cells among
## the `walkable_cells`.
func initialize(walkable_cells: Array[Vector2i]) -> void:
	_pathfinder = PathFinder.new(grid, walkable_cells)


## Finds and draws the path between `cell_start` and `cell_end`
func draw(cell_start: Vector2i, cell_end: Vector2i) -> void:
	clear()
	current_path = _pathfinder.calculate_point_path(cell_start, cell_end)
	
	# Convert Vector2i to Vector2 for TileMap functions if needed
	var cells_for_tilemap := []
	for cell in current_path:
		cells_for_tilemap.append(Vector2i(cell.x, cell.y))
	
	set_cells_terrain_connect(0, cells_for_tilemap, 0, 0)


## Stops drawing, clearing the drawn path and the `_pathfinder`.
func stop() -> void:
	_pathfinder = null
	clear()
