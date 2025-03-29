## Player-controlled cursor for navigating and interacting with the game grid.
## Supports both keyboard/gamepad navigation and mouse/touch positioning.
@tool
class_name GridSelector
extends Node2D

## Grid resource providing conversion methods between grid and pixel coordinates.
@export var grid: Grid
## Cooldown time in seconds between consecutive cursor movements when a direction key is held.
## Lower values allow faster movement while holding a direction.
@export var movement_cooldown := 0.1

## Current grid coordinates of the cell the cursor is hovering.
var cell := Vector2i.ZERO:
	set(value):
		# Skip processing in the editor
		if Engine.is_editor_hint() or not is_instance_valid(grid):
			cell = value
			return
			
		# Ensure cursor stays within grid boundaries
		var new_cell: Vector2i = grid.clamp_to_grid(value)
		if new_cell == cell:
			return

		cell = new_cell
		position = grid.grid_to_pixel(cell)
		EventBus.cursor_moved.emit(cell)
		_movement_timer.start()

## Timer that controls the movement rate when holding direction keys.
@onready var _movement_timer: Timer = $Timer


func _ready() -> void:
	_movement_timer.wait_time = movement_cooldown
	if Engine.is_editor_hint() or not is_instance_valid(grid):
		return
	position = grid.grid_to_pixel(cell)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	# Handle mouse/touch positioning
	if event is InputEventMouseMotion:
		cell = grid.pixel_to_grid(event.position)
		
	# Handle cell selection via click or ui_accept button
	elif event.is_action_pressed("click") or event.is_action_pressed("ui_accept"):
		EventBus.accept_pressed.emit(cell)
		get_viewport().set_input_as_handled()

	# Handle keyboard/gamepad directional movement
	_handle_directional_input(event)


## Processes directional input for keyboard/gamepad cursor movement.
## Includes handling for continuous movement when a direction is held down.
func _handle_directional_input(event: InputEvent) -> void:
	# Determine if we should move the cursor based on input state and cooldown
	var should_move := event.is_pressed()
	if event.is_echo():
		# For held keys, only move if the cooldown timer has expired
		should_move = should_move and _movement_timer.is_stopped()

	if not should_move:
		return

	# Move cursor by one cell in the appropriate direction
	if event.is_action("ui_right"):
		cell += Vector2i(1, 0) # Move right
	elif event.is_action("ui_up"):
		cell += Vector2i(0, -1) # Move up
	elif event.is_action("ui_left"):
		cell += Vector2i(-1, 0) # Move left
	elif event.is_action("ui_down"):
		cell += Vector2i(0, 1) # Move down


## Draws the visual cursor as a rectangular outline around the current cell.
func _draw() -> void:
	# Draw a rectangular outline centered on the cursor position
	draw_rect(Rect2(-grid.cell_size / 2, grid.cell_size), Color.ALICE_BLUE, false, 2.0)
