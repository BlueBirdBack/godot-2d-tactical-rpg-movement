## Grid resource that handles coordinate conversions and grid bounds management.
## Stores grid dimensions and cell size, and provides helper methods for coordinate transformations.
## This resource is shared between game objects that need access to grid information.
class_name Grid
extends Resource

## Grid dimensions in columns (x) and rows (y)
@export var dimensions: Vector2i = Vector2i(20, 20):
	set(value):
		assert(value.x > 0 and value.y > 0, "Grid dimensions must be positive")
		dimensions = value
## Size of each cell in pixels (width, height)
@export var cell_size: Vector2 = Vector2(80.0, 80.0):
	set(value):
		assert(value.x > 0 and value.y > 0, "Cell size must be positive")
		cell_size = value
		_update_half_cell_size()

## Half of cell_size - used for centering calculations
var _half_cell_size = cell_size / 2

func _init():
	# Ensure half_cell_size is calculated during initialization
	_update_half_cell_size()

# Add setter method for cell_size
func set_cell_size(new_size: Vector2) -> void:
	cell_size = new_size
	_update_half_cell_size()
	
func _update_half_cell_size() -> void:
	_half_cell_size = cell_size / 2

## Converts grid coordinates to pixel position (world space).
## Returns the center position of a cell in pixels.
func grid_to_pixel(grid_coordinates: Vector2i) -> Vector2:
	return Vector2(grid_coordinates) * cell_size + _half_cell_size


## Converts pixel position (world space) to grid coordinates.
## Returns the grid cell that contains the given pixel position.
func pixel_to_grid(pixel_position: Vector2) -> Vector2i:
	return (pixel_position / cell_size).floor()


## Checks if coordinates are within the grid boundaries.
## Returns true if the coordinates are valid grid positions.
func is_within_grid(grid_coordinates: Vector2i) -> bool:
	var out := grid_coordinates.x >= 0 and grid_coordinates.x < dimensions.x
	return out and grid_coordinates.y >= 0 and grid_coordinates.y < dimensions.y


## Restricts coordinates to stay within grid boundaries.
## Returns the closest valid grid position to the input coordinates.
func clamp_to_grid(grid_coordinates: Vector2i) -> Vector2i:
	var out := grid_coordinates
	out.x = clamp(out.x, 0, dimensions.x - 1)
	out.y = clamp(out.y, 0, dimensions.y - 1)
	return out

## Get adjacent cell coordinates
func get_adjacent_cells(cell: Vector2i) -> Array[Vector2i]:
	var adjacent_cells: Array[Vector2i] = []
	var potential_cells = [
		Vector2i(cell.x + 1, cell.y),
		Vector2i(cell.x - 1, cell.y),
		Vector2i(cell.x, cell.y + 1),
		Vector2i(cell.x, cell.y - 1)
	]
	
	for potential_cell in potential_cells:
		if is_within_grid(potential_cell):
			adjacent_cells.append(potential_cell)
	
	return adjacent_cells

## Calculate Manhattan distance between two cells
func get_manhattan_distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
	var difference = (to_cell - from_cell).abs()
	return difference.x + difference.y

## Method for visualizing grid in the editor
func draw_debug_grid(canvas_item: CanvasItem, color: Color = Color.WHITE) -> void:
	for x in range(dimensions.x + 1):
		var start = Vector2(x * cell_size.x, 0)
		var end = Vector2(x * cell_size.x, dimensions.y * cell_size.y)
		canvas_item.draw_line(start, end, color)
		
	for y in range(dimensions.y + 1):
		var start = Vector2(0, y * cell_size.y)
		var end = Vector2(dimensions.x * cell_size.x, y * cell_size.y)
		canvas_item.draw_line(start, end, color)

## Ensure resource is serialized correctly
func _get_property_list() -> Array:
	var properties = []
	properties.append({
		"name": "dimensions",
		"type": TYPE_VECTOR2I,
		"usage": PROPERTY_USAGE_DEFAULT,
	})
	properties.append({
		"name": "cell_size",
		"type": TYPE_VECTOR2,
		"usage": PROPERTY_USAGE_DEFAULT,
	})
	return properties
