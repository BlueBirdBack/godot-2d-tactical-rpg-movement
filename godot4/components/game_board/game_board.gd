## Represents and manages the game board for a tactical RPG-style game.
## 
## The GameBoard is responsible for:
## - Tracking unit positions on the grid
## - Handling unit selection and movement
## - Calculating walkable cells using flood fill algorithm
## - Coordinating between cursor input and unit actions
## Units can only move one at a time, and only to unoccupied cells within their movement range.
class_name GameBoard
extends Node2D

## Cardinal movement directions (LEFT, RIGHT, UP, DOWN)
const DIRECTIONS = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

## Resource of type Grid that defines the game grid properties.
@export var grid: Resource

## Dictionary mapping grid coordinates to unit references.
## Key: Vector2i grid cell, Value: Unit reference
var _unit_by_cell := {}

## Currently selected unit that the player can move.
var _active_unit: Unit

## Cache of walkable cells for the active unit.
var _walkable_cells: Array[Vector2i] = []

## Reference to the overlay that highlights walkable cells.
@onready var _unit_overlay: UnitOverlay = $UnitOverlay

## Reference to the path visualization for unit movement.
@onready var _unit_path: UnitPath = $UnitPath


func _ready() -> void:
	_initialize_unit_positions()


## Handles cancellation of unit selection with the ESC key.
func _unhandled_input(event: InputEvent) -> void:
	if _active_unit and event.is_action_pressed("ui_cancel"):
		_deselect_active_unit()
		_clear_active_unit()


## Warns about missing Grid resource in the editor.
func _get_configuration_warning() -> String:
	var warning := ""
	if not grid:
		warning = "You need a Grid resource for this node to work."
	return warning


## Returns whether a cell is occupied by any unit.
## 
## Parameters:
## - cell: The grid coordinates to check
##
## Returns: true if occupied, false otherwise
func is_occupied(cell: Vector2i) -> bool:
	return _unit_by_cell.has(cell)


## Calculates all cells a unit can move to based on its position and movement range.
## 
## Parameters:
## - unit: The unit to calculate movement for
##
## Returns: Array of grid coordinates the unit can move to
func get_walkable_cells(unit: Unit) -> Array[Vector2i]:
	return _flood_fill(unit.cell, unit.movement_range)


## Rebuilds the unit position mapping from the current state of child nodes.
func _initialize_unit_positions() -> void:
	_unit_by_cell.clear()

	for child in get_children():
		var unit := child as Unit
		if not unit:
			continue
		_unit_by_cell[unit.cell] = unit


## Calculates walkable cells using a flood fill algorithm.
## 
## Starting from origin cell, this expands outward until it reaches max_distance
## or encounters obstacles (units, grid boundaries).
##
## Parameters:
## - cell: Starting position for the flood fill
## - max_distance: Maximum Manhattan distance to travel from start
##
## Returns: Array of walkable cell coordinates
func _flood_fill(cell: Vector2i, max_distance: int) -> Array[Vector2i]:
	var walkable_cells: Array[Vector2i] = []
	var pending_cells: Array[Vector2i] = [cell]
	
	while pending_cells.size() > 0:
		var current = pending_cells.pop_back()
		
		# Skip invalid cells
		if not grid.is_within_grid(current):
			continue
		if current in walkable_cells:
			continue
			
		# Check if we've exceeded movement range
		var difference: Vector2i = (current - cell).abs()
		var distance := int(difference.x + difference.y)
		if distance > max_distance:
			continue

		# Add valid cell to results
		walkable_cells.append(current)
		
		# Explore neighbors
		for direction in DIRECTIONS:
			var next_cell: Vector2i = current + direction
			if is_occupied(next_cell):
				continue
			if next_cell in walkable_cells or next_cell in pending_cells:
				continue

			pending_cells.append(next_cell)
			
	return walkable_cells


## Moves the active unit to a new cell and updates the game state.
## 
## Parameters:
## - target_cell: The destination cell for the unit
func _move_active_unit(target_cell: Vector2i) -> void:
	# Validate the move is legal
	if is_occupied(target_cell) or not target_cell in _walkable_cells:
		return
		
	# Update unit position in tracking dictionary
	_unit_by_cell.erase(_active_unit.cell)
	_unit_by_cell[target_cell] = _active_unit
	
	# Clear selection visuals
	_deselect_active_unit()
	
	# Animate unit movement
	_active_unit.move_along_path(_unit_path.current_path)
	await _active_unit.movement_completed
	
	# Reset selection state
	_clear_active_unit()


## Selects a unit at the given cell and displays its movement options.
## 
## Parameters:
## - cell: The cell containing the unit to select
func _select_unit(cell: Vector2i) -> void:
	if not _unit_by_cell.has(cell):
		return

	_active_unit = _unit_by_cell[cell]
	_active_unit.is_selected = true
	
	# Calculate and display movement options
	_walkable_cells = get_walkable_cells(_active_unit)
	_unit_overlay.draw(_walkable_cells)
	_unit_path.initialize(_walkable_cells)


## Visually deselects the active unit and clears movement visualizations.
func _deselect_active_unit() -> void:
	if not _active_unit:
		return
		
	_active_unit.is_selected = false
	_unit_overlay.clear()
	_unit_path.stop()


## Resets the active unit state.
func _clear_active_unit() -> void:
	_active_unit = null
	_walkable_cells.clear()


## Handles cursor selection input to either select a unit or move the active unit.
## 
## Parameters:
## - cell: The cell where the cursor selection occurred
func _on_Cursor_accept_pressed(cell: Vector2i) -> void:
	if not _active_unit:
		# No unit selected - try to select one
		_select_unit(cell)
	elif _active_unit.is_selected:
		# Unit already selected - try to move it
		_move_active_unit(cell)


## Updates the movement path preview as the cursor moves.
## 
## Parameters:
## - new_cell: The cell the cursor moved to
func _on_Cursor_moved(new_cell: Vector2i) -> void:
	if _active_unit and _active_unit.is_selected:
		_unit_path.draw(_active_unit.cell, new_cell)
