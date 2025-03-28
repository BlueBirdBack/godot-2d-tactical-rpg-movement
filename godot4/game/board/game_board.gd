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
var _active_unit: Unit

# Cells the active unit can move to (highlighted in blue)
var _walkable_cells: Array[Vector2i] = []

# Visual elements that show movement options and paths
@onready var _unit_overlay: UnitOverlay = $UnitOverlay
@onready var _unit_path: UnitPath = $UnitPath


func _ready() -> void:
	# Place all child units in their starting positions
	_initialize_unit_positions()


# Handle ESC key to cancel unit selection
func _unhandled_input(event: InputEvent) -> void:
	if _active_unit and event.is_action_pressed("ui_cancel"):
		_deselect_active_unit()
		_clear_active_unit()


# Check if a cell is occupied by any unit
func is_occupied(cell: Vector2i) -> bool:
	return _unit_by_cell.has(cell)


# Get all cells a unit can move to within its movement range
func get_walkable_cells(unit: Unit) -> Array[Vector2i]:
	return _flood_fill(unit.cell, unit.movement_range)


# Set up initial unit positions from child nodes
func _initialize_unit_positions() -> void:
	_unit_by_cell.clear()
	
	for child in get_children():
		if child is Unit: # Only process Unit nodes
			_unit_by_cell[child.cell] = child


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
			if grid.is_within_grid(neighbor) and not visited.get(neighbor, false) and not is_occupied(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
				
	return walkable_cells


# Move selected unit to target cell if valid
func _move_active_unit(target_cell: Vector2i) -> void:
	if is_occupied(target_cell) or not target_cell in _walkable_cells:
		return # Can't move here
		
	# Update unit position tracking
	_unit_by_cell.erase(_active_unit.cell)
	_unit_by_cell[target_cell] = _active_unit
	
	# Clear selection visuals
	_deselect_active_unit()
	
	# Animate movement along path
	_active_unit.move_along_path(_unit_path.current_path)
	await _active_unit.movement_completed
	
	# Clear selection
	_clear_active_unit()


# Select a unit and show its movement options
func _select_unit(cell: Vector2i) -> void:
	if not _unit_by_cell.has(cell):
		return # No unit here
		
	_active_unit = _unit_by_cell[cell]
	_active_unit.is_selected = true
	
	# Calculate and show movement options
	_walkable_cells = get_walkable_cells(_active_unit)
	_unit_overlay.draw(_walkable_cells) # Blue highlight
	_unit_path.initialize(_walkable_cells) # Path preview


# Deselect unit and clear visuals
func _deselect_active_unit() -> void:
	if not _active_unit:
		return
		
	_active_unit.is_selected = false
	_unit_overlay.clear() # Remove blue highlights
	_unit_path.stop() # Remove path preview


# Clear active unit reference
func _clear_active_unit() -> void:
	_active_unit = null
	_walkable_cells.clear()


# Handle cursor clicks - select or move units
func _on_Cursor_accept_pressed(cell: Vector2i) -> void:
	if not _active_unit:
		_select_unit(cell) # Select unit at this cell
	elif _active_unit.is_selected:
		_move_active_unit(cell) # Move selected unit to this cell


# Update path preview when cursor moves
func _on_Cursor_moved(new_cell: Vector2i) -> void:
	if _active_unit and _active_unit.is_selected:
		_unit_path.draw(_active_unit.cell, new_cell) # Draw path line
