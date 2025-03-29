# Tactical RPG Movement System for Godot 4.4

🌐 **Available in:** [English](README.md) | [中文](README.zh.md) 

Welcome to the Tactical RPG Movement System! This beginner-friendly project provides a complete grid-based movement system for tactical games, similar to classics like Fire Emblem and Advance Wars.

![Tactical RPG Movement Demo](images/trpg-screenshot.png)

## What You'll Learn

By exploring this project, you'll learn how to:

- Create a grid-based game board
- Move a cursor using keyboard or mouse
- Select and move units
- Implement pathfinding for unit movement
- Visualize movement ranges and paths
- Use signals for communication between game elements

## Project Overview

This project implements a turn-based tactical movement system with these key features:

- Grid-based game board
- Unit selection and movement
- Cursor navigation (keyboard and mouse)
- Path visualization
- Movement range display

## Getting Started

### Prerequisites

- [Godot 4.4](https://godotengine.org/download) or newer

### Running the Project

1. Download or clone this repository
2. Open Godot Engine
3. Click "Import" and select the project folder
4. Click "Open"
5. Press F5 or click the "Play" button to run the project

## How It Works

The project is built using several interconnected components, each with a specific responsibility. Let's explore each one:

### 1. The Grid System

The `Grid` resource defines our game board's dimensions and handles converting between grid coordinates (like (3,4)) and pixel positions (like (240,320)).

```gdscript
# Grid.gd
class_name Grid
extends Resource

@export var dimensions := Vector2i(10, 10)  # Grid size in cells
@export var cell_size := Vector2i(64, 64)   # Size of each cell in pixels

## Converts grid coordinates to pixel position (center of cell)
func grid_to_pixel(grid_position: Vector2i) -> Vector2:
    return Vector2(grid_position) * Vector2(cell_size) + Vector2(cell_size) / 2

## Converts pixel position to grid coordinates
func pixel_to_grid(pixel_position: Vector2) -> Vector2i:
    return Vector2i(pixel_position / Vector2(cell_size))

## Ensures coordinates stay within grid boundaries
func clamp_to_grid(grid_position: Vector2i) -> Vector2i:
    var x = clamp(grid_position.x, 0, dimensions.x - 1)
    var y = clamp(grid_position.y, 0, dimensions.y - 1)
    return Vector2i(x, y)
```

The Grid handles two main tasks:

- Converting between grid coordinates and screen positions
- Making sure positions stay within the grid's boundaries

### 2. The Cursor (GridSelector)

The `GridSelector` allows the player to navigate and select cells on the grid using keyboard, gamepad, or mouse.

```gdscript
# Key parts of GridSelector
class_name GridSelector
extends Node2D

@export var grid: Grid  # Reference to the Grid resource
var cell := Vector2i.ZERO  # Current grid position

func _unhandled_input(event: InputEvent) -> void:
    # Handle mouse movement
    if event is InputEventMouseMotion:
        cell = grid.pixel_to_grid(event.position)

    # Handle selection (click or Enter key)
    elif event.is_action_pressed("click") or event.is_action_pressed("ui_accept"):
        EventBus.cell_selected.emit(cell)
```

The cursor:

- Moves across the grid
- Converts mouse position to grid coordinates
- Emits signals when cells are selected

### 3. Units

The `Unit` class represents characters that can move on the grid.

```gdscript
# Key parts of Unit
class_name Unit
extends Path2D

@export var grid: Grid
@export var movement_range: int = 6  # How far the unit can move
var cell: Vector2i = Vector2i.ZERO   # Current grid position
var is_selected := false             # Whether unit is currently selected

# Moves the unit along a path
func walk_along(path: Array[Vector2i]) -> void:
    if path.size() <= 1:
        return

    # Create a curve for the movement path
    curve.clear_points()
    curve.add_point(Vector2.ZERO)

    for i in range(1, path.size()):
        var point = grid.grid_to_pixel(path[i]) - position
        curve.add_point(point)

    # Update the unit's final position
    cell = path[path.size() - 1]

    # Start moving
    _is_moving = true
```

Units handle:

- Storing their position on the grid
- Visual representation (sprite)
- Smooth movement animation
- Selection state

### 4. The Game Board

The `GameBoard` ties everything together, managing units and handling selection/movement.

```gdscript
# Key parts of GameBoard
class_name GameBoard
extends Node2D

@export var grid: Grid

var _unit_by_cell := {}         # Dictionary mapping grid positions to units
var _selected_unit: Unit        # Currently selected unit
var _walkable_cells := []       # Cells the selected unit can move to

# Handle cell selection
func _on_cell_selected(cell: Vector2i) -> void:
    if _selected_unit == null:
        _select_unit_at(cell)
    elif _selected_unit.is_selected:
        _move_selected_unit(cell)

# Find all cells a unit can move to
func _calculate_walkable_cells(unit: Unit) -> Array[Vector2i]:
    # Flood fill algorithm to find all cells within movement range
    var cells: Array[Vector2i] = []
    var stack := [unit.cell]
    var visited := {}

    while not stack.is_empty():
        var current = stack.pop_back()

        if visited.has(current):
            continue

        visited[current] = true
        var distance = abs(current.x - unit.cell.x) + abs(current.y - unit.cell.y)

        if distance <= unit.movement_range:
            cells.append(current)

            # Check adjacent cells (4 directions)
            for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
                var next_cell = current + direction

                if grid.is_within_bounds(next_cell) and not _unit_by_cell.has(next_cell):
                    stack.append(next_cell)

    return cells
```

The GameBoard:

- Tracks which units are on which cells
- Handles unit selection
- Calculates where units can move
- Manages the movement process

### 5. Movement Visualization

Two classes help visualize movement options:

#### MovementHighlighter

Highlights all cells a selected unit can move to.

```gdscript
# MovementHighlighter.gd
class_name MovementHighlighter
extends TileMapLayer

func draw(cells: Array[Vector2i]) -> void:
    clear()
    for cell in cells:
        set_cell(cell, 0, Vector2i(0, 0))
```

#### MovementPreview

Shows the path a unit will take to reach the cursor's position.

```gdscript
# Key parts of MovementPreview
class_name MovementPreview
extends TileMapLayer

@export var grid: Grid
var _astar: AStarGrid2D = null
var current_path: Array[Vector2i] = []

# Calculate and show the path between two points
func draw(start_cell: Vector2i, end_cell: Vector2i) -> void:
    clear()

    if not _astar:
        return

    # Find path using A* algorithm
    current_path = _astar.get_id_path(start_cell, end_cell)

    if current_path.size() <= 1:
        return

    # Draw path on tilemap
    for i in range(current_path.size()):
        var cell = current_path[i]
        set_cell(cell, 0, _get_tile_based_on_neighbors(cell, i, current_path))
```

### 6. Communication System (EventBus)

The `EventBus` allows components to communicate without direct references.

```gdscript
# EventBus.gd
extends Node

# Emitted when player selects a cell
signal cell_selected(cell_coordinates: Vector2i)

# Emitted when cursor moves to a different cell
signal grid_position_changed(new_cell_coordinates: Vector2i)

# Emitted when a unit completes movement
signal unit_moved(unit: Unit)
```

Using signals helps keep the code modular and easier to understand.

## Step-by-Step Tutorial: Creating a New Level

Let's create a simple tactical game level:

### 1. Create a new scene

1. Click "Scene" → "New Scene"
2. Add a Node2D as the root and name it "Level"
3. Save the scene as "level.tscn"

### 2. Set up the grid

1. Create a new resource file: Right-click in FileSystem → "New Resource"
2. Search for "Resource" and create a blank resource
3. Save it as "grid.tres"
4. Add script to this resource: Right-click → "Attach Script"
5. Name it "grid.gd" with content from the Grid section above (using snake_case as per Godot naming conventions)
6. In the Inspector panel, set:
   - Dimensions: 10, 10 (or your preferred grid size)
   - Cell Size: 64, 64 (or your preferred cell size)

### 3. Add a background

1. Add a TileMapLayer node to your Level (Note: TileMap is deprecated in Godot 4.3; use TileMapLayer instead)
2. Configure it with your tileset (walls, floors, etc.)
3. Draw your map layout

### 4. Add the GameBoard

1. Add a Node2D and name it "GameBoard"
2. Attach the GameBoard script to it
3. In the Inspector, set the Grid property to your grid.tres resource

### 5. Add movement visualization

1. Add a TileMapLayer node as a child of GameBoard and name it "MovementHighlighter"
2. Attach the MovementHighlighter script
3. Configure its tileset with a blue/highlighted tile
4. Add another TileMapLayer node as a child and name it "MovementPreview"
5. Attach the MovementPreview script
6. Configure its tileset with path arrow tiles
7. Set its Grid property to your grid.tres resource

### 6. Add the cursor

1. Add a Node2D as a child of Level (not GameBoard) and name it "GridSelector"
2. Attach the GridSelector script
3. Set its Grid property to your grid.tres resource
4. Add a Sprite2D as a child and set its texture to your cursor image
5. Add a Timer node as a child and name it "Timer"

### 7. Add some units

1. Create a new scene for your unit
2. Add a Path2D as the root and name it "Unit"
3. Attach the Unit script
4. Add a PathFollow2D as a child named "PathFollow2D"
5. Add a Sprite2D as a child of PathFollow2D and name it "Sprite"
6. Set your character texture
7. Add an AnimationPlayer as a child of Unit
8. Create "idle" and "selected" animations
9. Save the scene as "unit.tscn"
10. Instance this unit in your Level scene
11. Set its Grid property to your grid.tres resource
12. Position it where you want it to start

### 8. Add the EventBus

1. Create a new script called "event_bus.gd" with the EventBus code
2. Create an Autoload: Project → Project Settings → Autoload
3. Add your event_bus.gd script and name it "EventBus"

### 9. Run the game!

Press F5 to run your game. You should be able to:

- Move the cursor with arrow keys or mouse
- Select a unit by clicking on it
- See highlighted cells showing where it can move
- Move the cursor to a valid destination and click to move the unit

## Core Concepts for Beginners

### What is a Grid?

In our game, the grid is like a chess board - a collection of squares (or cells) arranged in rows and columns. Each cell has coordinates (x, y) that tell us its position on the board.

### What are Signals?

Signals are like messengers that notify different parts of the game when something happens. For example, when a unit finishes moving, it sends a signal so the game board knows it's done.

### What is Pathfinding?

Pathfinding is a way for the computer to figure out how to get from point A to point B while avoiding obstacles. Our game uses the A\* (A-star) algorithm, which is like a more intelligent version of following a map.

## Extending the Project

Here are some ideas to enhance the project:

1. **Add Combat System**: Implement unit battles when they encounter enemies
2. **Turn System**: Add a system to alternate between player and enemy turns
3. **Different Unit Types**: Create units with varying movement ranges and abilities
4. **Obstacles**: Add terrain that affects movement cost
5. **Fog of War**: Implement limited visibility for units

## Troubleshooting

### Common Issues

1. **Units not showing up**: Make sure the Unit's Grid property is set correctly
2. **Cursor not moving**: Check that input actions ("ui_up", "ui_down", etc.) are configured in Project Settings
3. **Path not appearing**: Verify that the MovementPreview's tileset is configured correctly

## Resources for Learning More

1. [Official Godot Documentation](https://docs.godotengine.org)
2. [GDQuest Tactical RPG Movement Tutorial](https://www.gdquest.com/tutorial/godot/2d/tactical-rpg-movement/)
3. [Godot's Signal System](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)

## Conclusion

You now have a complete foundation for a tactical RPG movement system! This project demonstrates important game development concepts like grid-based movement, pathfinding, and signal-based communication between game elements.

Feel free to experiment, modify, and build upon this system to create your own unique tactical game!
