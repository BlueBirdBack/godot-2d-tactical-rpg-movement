## Global constants for the game
extends Node

## Cardinal directions for grid movement
const DIRECTIONS = [
	Vector2i(-1, 0), # Left
	Vector2i(1, 0), # Right
	Vector2i(0, -1), # Up
	Vector2i(0, 1) # Down
]

## Shortened direction enum
enum D {LEFT = 0, RIGHT = 1, UP = 2, DOWN = 3}

## Shortened direction getter
static func d(dir: D) -> Vector2i:
	return DIRECTIONS[dir]
