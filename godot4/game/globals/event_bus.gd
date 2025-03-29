## Global event bus for game-wide communication
extends Node

## Emitted when the player confirms selection of a cell (via click or ui_accept)
signal accept_pressed(cell_coordinates: Vector2i)
## Emitted when the cursor moves to a different cell
signal cursor_moved(new_cell_coordinates: Vector2i)
## Emitted when a unit completes movement along its path
signal unit_movement_completed(unit: Unit)
