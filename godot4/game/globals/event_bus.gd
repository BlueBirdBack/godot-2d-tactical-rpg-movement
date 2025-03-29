## Global event bus for game-wide communication
extends Node

## Emitted when the player confirms selection of a cell (via click or ui_accept)
signal cell_selected(cell_coordinates: Vector2i)
## Emitted when the cursor moves to a different cell
signal grid_position_changed(new_cell_coordinates: Vector2i)
## Emitted when a unit completes movement along its path
signal unit_moved(unit: Unit)
