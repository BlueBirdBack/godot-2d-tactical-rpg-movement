## Manages the tactical game board where units move on a grid.
## Handles: 
## - Unit selection and movement
## - Pathfinding (where units can move)
## - Visual feedback for movement options
class_name GameBoard
extends Node2D

# The grid that defines cell sizes and boundaries
@export var grid: Grid

# Tracks which units are on which cells {cell_position: unit_reference}
var _unit_by_cell := {}

# Currently selected unit (null if none selected)
var _selected_unit: Unit

# Cells the selected unit can move to (highlighted in blue)
var _walkable_cells: Array[Vector2i] = []

# Visual elements that show movement options and paths
@onready var _movement_highlights: MovementHighlighter = $MovementHighlighter
@onready var _movement_preview: UnitPath = $UnitPath


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Place all child units in their starting positions
	_setup_units()


# Initializes all unit positions by scanning child nodes
func _setup_units() -> void:
	_unit_by_cell.clear()
	
	for child in get_children():
		if child is Unit: # Only process Unit nodes
			_unit_by_cell[child.cell] = child


# Handles global input events not captured by other nodes.
func _unhandled_input(event: InputEvent) -> void:
	if _selected_unit and event.is_action_pressed("ui_cancel"):
		_deselect_selected_unit()
		_clear_selected_unit()


# Deselect unit and clear visuals
func _deselect_selected_unit() -> void:
	if not _selected_unit:
		return
		
	_selected_unit.is_selected = false
	_movement_highlights.clear() # Remove blue highlights
	_movement_preview.stop() # Remove path preview


# Clear selected unit reference
func _clear_selected_unit() -> void:
	_selected_unit = null
	_walkable_cells.clear()


# Check if a cell is occupied by any unit
func _is_occupied(cell: Vector2i) -> bool:
	return _unit_by_cell.has(cell)


# Get all cells a unit can move to within its movement range
func get_walkable_cells(unit: Unit) -> Array[Vector2i]:
	return _flood_fill(unit.cell, unit.movement_range)


# Find all reachable cells using flood fill algorithm
func _flood_fill(start_cell: Vector2i, max_distance: int) -> Array[Vector2i]:
	var walkable_cells: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start_cell]
	var visited := {start_cell: true}
	
	while not queue.is_empty():
		var current_cell = queue.pop_front()
		
		var distance = abs(current_cell.x - start_cell.x) + abs(current_cell.y - start_cell.y)
		if distance > max_distance:
			continue
			
		walkable_cells.append(current_cell)
		
		for direction in Constants.DIRECTIONS:
			var neighbor = current_cell + direction
			if grid.is_within_grid(neighbor) and not visited.get(neighbor, false) and not _is_occupied(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
				
	return walkable_cells


# Move selected unit to target cell if valid
func _move_selected_unit(target_cell: Vector2i) -> void:
	if _is_occupied(target_cell) or not target_cell in _walkable_cells:
		return # Can't move here
		
	# Update unit position tracking
	_unit_by_cell.erase(_selected_unit.cell)
	_unit_by_cell[target_cell] = _selected_unit
	
	# Clear selection visuals
	_deselect_selected_unit()
	
	# Animate movement along path
	_selected_unit.move_along_path(_movement_preview.current_path)
	await _selected_unit.movement_completed
	
	# Clear selection
	_clear_selected_unit()


# Select a unit and show its movement options
func _select_unit(cell: Vector2i) -> void:
	if not _unit_by_cell.has(cell):
		return # No unit here
		
	_selected_unit = _unit_by_cell[cell]
	_selected_unit.is_selected = true
	
	# Calculate and show movement options
	_walkable_cells = get_walkable_cells(_selected_unit)
	_movement_highlights.draw(_walkable_cells) # Blue highlight
	_movement_preview.initialize(_walkable_cells) # Path preview


# Handle cursor clicks - select or move units
func _on_Cursor_accept_pressed(cell: Vector2i) -> void:
	if not _selected_unit:
		_select_unit(cell) # Select unit at this cell
	elif _selected_unit.is_selected:
		_move_selected_unit(cell) # Move selected unit to this cell


# Update path preview when cursor moves
func _on_Cursor_moved(new_cell: Vector2i) -> void:
	if _selected_unit and _selected_unit.is_selected:
		_movement_preview.draw(_selected_unit.cell, new_cell) # Draw path line
