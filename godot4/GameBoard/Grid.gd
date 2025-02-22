## Represents a grid with its size, the size of each cell in pixels, and some helper functions to
## calculate and convert coordinates.
## It's meant to be shared between game objects that need access to those values.
class_name Grid
extends Resource

## The grid's number of columns and rows.
@export var size := Vector2i(20, 20)
## The size of a cell in pixels.
@export var cell_size := Vector2(80, 80)

## Half of `cell_size`, used to optimize calculations.
var _half_cell_size = cell_size / 2

## Returns the world position (in pixels) of the center of a grid cell.
func grid_to_world_position(grid_position: Vector2i) -> Vector2:
	return Vector2(grid_position) * cell_size + _half_cell_size

## Returns the corresponding grid coordinates given world coordinates (in pixels).
func calculate_grid_coordinates(world_position: Vector2) -> Vector2i:
	return (world_position / cell_size).floor()

## Checks if the given grid coordinates are within the grid boundaries.
## Returns true if within bounds, false otherwise.
func is_within_bounds(cell_coordinates: Vector2i) -> bool:
	return cell_coordinates >= Vector2i.ZERO and cell_coordinates < size

## Clamps the grid coordinates to the grid boundaries.
## Returns the adjusted grid coordinates.
func grid_clamp(grid_position: Vector2i) -> Vector2i:
	return grid_position.clamp(Vector2i.ZERO, size - Vector2i.ONE)
