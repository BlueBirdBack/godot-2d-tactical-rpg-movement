## Grid resource that handles coordinate conversions and grid bounds management.
## Stores grid dimensions and cell size, and provides helper methods for coordinate transformations.
## This resource is shared between game objects that need access to grid information.
class_name Grid
extends Resource

## Grid dimensions in columns (x) and rows (y)
@export var dimensions: Vector2i = Vector2i(20, 20)
## Size of each cell in pixels (width, height)
@export var cell_size: Vector2 = Vector2(80.0, 80.0)

## Half of cell_size - used for centering calculations
var _half_cell_size = cell_size / 2


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
