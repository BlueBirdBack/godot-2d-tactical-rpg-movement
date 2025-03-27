## Represents a unit on the game board.
## The board manages its position inside the game grid.
## The unit itself holds stats and a visual representation that moves smoothly in the game world.
@tool
class_name Unit
extends Path2D

## Emitted when the unit reached the end of a path along which it was walking.
signal movement_completed

## Shared resource of type Grid, used to calculate map coordinates.
@export var grid: Grid
## Distance to which the unit can walk in cells.
@export var movement_range: int = 6
## The unit's move speed when it's moving along a path.
@export var movement_speed: float = 600.0
## Texture representing the unit.
@export var character_texture: Texture:
	set(value):
		character_texture = value
		if not _character_sprite:
			# This will resume execution after this node's _ready()
			await ready
		_character_sprite.texture = value
## Offset to apply to the `character_texture` sprite in pixels.
@export var texture_offset := Vector2.ZERO:
	set(value):
		texture_offset = value
		if not _character_sprite:
			await ready
		_character_sprite.position = value

## Coordinates of the current cell the cursor moved to.
var cell: Vector2i = Vector2i.ZERO:
	set(value):
		# When changing the cell's value, we don't want to allow coordinates outside
		#	the grid, so we clamp them
		cell = grid.clamp_to_grid(value)
## Toggles the "selected" animation on the unit.
var is_selected := false:
	set(value):
		is_selected = value
		if is_selected:
			_animation_player.play("selected")
		else:
			_animation_player.play("idle")

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

	cell = grid.pixel_to_grid(position)
	position = grid.grid_to_pixel(cell)

	# We create the curve resource here because creating it in the editor prevents us from
	# moving the unit.
	if not Engine.is_editor_hint():
		curve = Curve2D.new()


func _process(delta: float) -> void:
	_path_follower.progress += movement_speed * delta

	if _path_follower.progress_ratio >= 1.0:
		_is_moving = false
		# Setting this value to 0.0 causes a Zero Length Interval error
		_path_follower.progress = 0.00001
		position = grid.grid_to_pixel(cell)
		curve.clear_points()
		emit_signal("movement_completed")


## Starts walking along the `path`.
## `path` is an array of grid coordinates that the function converts to map coordinates.
func move_along_path(path: Array[Vector2i]) -> void:
	if path.size() < 2: # Need at least 2 points for a valid path
		if path.size() == 1:
			# Just teleport to the destination if only one point
			cell = path[0]
			position = grid.grid_to_pixel(cell)
			emit_signal("movement_completed")
		return

	curve.clear_points() # Always clear existing points first
	curve.add_point(Vector2.ZERO)
	
	# Track previous point to avoid duplicates
	var previous_point: Vector2 = Vector2.ZERO
	for point in path:
		var new_point: Vector2 = grid.grid_to_pixel(point) - position
		# Only add if point is sufficiently different from previous
		if new_point.distance_squared_to(previous_point) > 0.01:
			curve.add_point(new_point)
			previous_point = new_point
	
	# Final validation to ensure we have a valid path
	if curve.get_point_count() < 2:
		# Still not enough distinct points
		emit_signal("movement_completed")
		return
		
	cell = path[-1]
	_is_moving = true
