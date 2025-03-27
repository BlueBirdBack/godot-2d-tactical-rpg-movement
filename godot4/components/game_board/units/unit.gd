## A game unit that can move on the grid-based game board.
## This class handles both unit state (position, selection) and visual representation.
## The GameBoard manages unit positioning while this class handles smooth movement animations.
@tool
class_name Unit
extends Path2D

## Emitted when the unit completes its movement along a path.
signal movement_completed

## Reference to the Grid resource for coordinate conversions between grid and pixel space.
@export var grid: Grid
## Maximum number of cells this unit can move in a single turn.
@export var movement_range: int = 6
## Movement animation speed in pixels per second.
@export var movement_speed: float = 600.0
## Visual appearance of the unit.
@export var character_texture: Texture:
	set(value):
		character_texture = value
		# REMOVED: if not _character_sprite: await ready
		# REMOVED: _character_sprite.texture = value
		# ADDED: If the node is ready, update immediately. Otherwise _ready() will handle it.
		if is_node_ready() and _character_sprite:
			_character_sprite.texture = value
## Fine-tuning of sprite position in pixels.
@export var texture_offset := Vector2.ZERO:
	set(value):
		texture_offset = value
		# REMOVED: if not _character_sprite: await ready
		# REMOVED: _character_sprite.position = value
		# ADDED: If the node is ready, update immediately. Otherwise _ready() will handle it.
		if is_node_ready() and _character_sprite:
			_character_sprite.position = value

## Current position on the game grid.
var cell: Vector2i = Vector2i.ZERO:
	set(value):
		# Ensure the unit stays within the valid grid boundaries
		cell = grid.clamp_to_grid(value)
## Whether this unit is currently selected by the player.
var is_selected := false:
	set(value):
		is_selected = value
		if is_selected:
			_animation_player.play("selected")
		else:
			_animation_player.play("idle")

## Controls whether the unit is currently moving along a path.
var _is_moving := false:
	set(value):
		_is_moving = value
		set_process(_is_moving)

@onready var _character_sprite: Sprite2D = $PathFollow2D/Sprite
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _path_follower: PathFollow2D = $PathFollow2D


func _ready() -> void:
	set_process(false)
	_path_follower.rotates = false

	# ADDED: Apply initial texture and offset after _character_sprite is ready
	if _character_sprite: # Check if sprite exists (good practice)
		if character_texture: # Check if texture is assigned
			_character_sprite.texture = character_texture
		_character_sprite.position = texture_offset

	cell = grid.pixel_to_grid(position)
	position = grid.grid_to_pixel(cell)

	# Create Curve2D at runtime to avoid editor movement issues
	# (Creating it in the editor would prevent repositioning the unit)
	if not Engine.is_editor_hint():
		curve = Curve2D.new()


func _process(delta: float) -> void:
	_path_follower.progress += movement_speed * delta

	if _path_follower.progress_ratio >= 1.0:
		_is_moving = false
		# Use non-zero value to prevent "Zero Length Interval" error
		_path_follower.progress = 0.00001
		position = grid.grid_to_pixel(cell)
		curve.clear_points()
		emit_signal("movement_completed")


## Moves the unit along a path of grid coordinates.
## Automatically converts grid coordinates to pixel positions for smooth movement.
## If path has only one point, teleports to that position instead of animating.
func move_along_path(path: Array[Vector2i]) -> void:
	if path.size() < 2: # Minimum of 2 points needed for a path
		if path.size() == 1:
			# Single point - just teleport
			cell = path[0]
			position = grid.grid_to_pixel(cell)
			emit_signal("movement_completed")
		return

	curve.clear_points() # Reset curve before creating new path
	curve.add_point(Vector2.ZERO)
	
	# Avoid adding duplicate points which can cause path issues
	var previous_point: Vector2 = Vector2.ZERO
	for point in path:
		var new_point: Vector2 = grid.grid_to_pixel(point) - position
		# Only add points that differ enough from the previous one
		if new_point.distance_squared_to(previous_point) > 0.01:
			curve.add_point(new_point)
			previous_point = new_point
	
	# Ensure we have a valid path with at least 2 distinct points
	if curve.get_point_count() < 2:
		# Path is invalid - signal completion without moving
		emit_signal("movement_completed")
		return
		
	cell = path[-1]
	_is_moving = true
