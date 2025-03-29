# 适用于 Godot 4.4 的战术 RPG 移动系统

🌐 **可用语言：** [英文](README.md) | [中文](README.zh.md)

欢迎来到战术 RPG 移动系统！这个对初学者友好的项目提供了一个完整的基于网格的移动系统，适用于战术游戏，类似于《火焰纹章》和《高级战争》等经典游戏。

![战术 RPG 移动演示](images/trpg-screenshot.png)

## 你将学到什么

通过探索这个项目，你将学习如何：

- 创建一个基于网格的游戏棋盘
- 使用键盘或鼠标移动光标
- 选择和移动单位
- 实现单位移动的寻路功能
- 可视化移动范围和路径
- 使用信号进行游戏元素之间的通信

## 项目概述

该项目实现了一个回合制战术移动系统，具有以下关键特性：

- 基于网格的游戏棋盘
- 单位选择和移动
- 光标导航（键盘和鼠标）
- 路径可视化
- 移动范围显示

## 开始使用

### 先决条件

- [Godot 4.4](https://godotengine.org/download) 或更新版本

### 运行项目

1.  下载或克隆此仓库
2.  打开 Godot 引擎
3.  点击“导入”并选择项目文件夹
4.  点击“打开”
5.  按 F5 或点击“运行”按钮来运行项目

## 工作原理

该项目由几个相互连接的组件构建而成，每个组件都有特定的职责。让我们来探索每一个组件：

### 1. 网格系统 (Grid System)

`Grid` 资源定义了我们游戏棋盘的尺寸，并处理网格坐标（如 (3,4)）和像素位置（如 (240,320)）之间的转换。

```gdscript
# Grid.gd
class_name Grid
extends Resource

@export var dimensions := Vector2i(10, 10)  # 网格大小（单元格数量）
@export var cell_size := Vector2i(64, 64)   # 每个单元格的大小（像素）

## 将网格坐标转换为像素位置（单元格中心）
func grid_to_pixel(grid_position: Vector2i) -> Vector2:
    return Vector2(grid_position) * Vector2(cell_size) + Vector2(cell_size) / 2

## 将像素位置转换为网格坐标
func pixel_to_grid(pixel_position: Vector2) -> Vector2i:
    return Vector2i(pixel_position / Vector2(cell_size))

## 确保坐标保持在网格边界内
func clamp_to_grid(grid_position: Vector2i) -> Vector2i:
    var x = clamp(grid_position.x, 0, dimensions.x - 1)
    var y = clamp(grid_position.y, 0, dimensions.y - 1)
    return Vector2i(x, y)
```

Grid 处理两个主要任务：

- 在网格坐标和屏幕位置之间进行转换
- 确保位置保持在网格边界内

### 2. 光标 (GridSelector)

`GridSelector` 允许玩家使用键盘、手柄或鼠标在网格上导航和选择单元格。

```gdscript
# GridSelector 的关键部分
class_name GridSelector
extends Node2D

@export var grid: Grid  # 对 Grid 资源的引用
var cell := Vector2i.ZERO  # 当前网格位置

func _unhandled_input(event: InputEvent) -> void:
    # 处理鼠标移动
    if event is InputEventMouseMotion:
        cell = grid.pixel_to_grid(event.position)

    # 处理选择（点击或 Enter 键）
    elif event.is_action_pressed("click") or event.is_action_pressed("ui_accept"):
        EventBus.cell_selected.emit(cell)
```

光标：

- 在网格上移动
- 将鼠标位置转换为网格坐标
- 在选择单元格时发出信号

### 3. 单位 (Units)

`Unit` 类代表可以在网格上移动的角色。

```gdscript
# Unit 的关键部分
class_name Unit
extends Path2D

@export var grid: Grid
@export var movement_range: int = 6  # 单位可以移动多远
var cell: Vector2i = Vector2i.ZERO   # 当前网格位置
var is_selected := false             # 单位当前是否被选中

# 让单位沿着路径移动
func walk_along(path: Array[Vector2i]) -> void:
    if path.size() <= 1:
        return

    # 为移动路径创建曲线
    curve.clear_points()
    curve.add_point(Vector2.ZERO)

    for i in range(1, path.size()):
        var point = grid.grid_to_pixel(path[i]) - position
        curve.add_point(point)

    # 更新单位的最终位置
    cell = path[path.size() - 1]

    # 开始移动
    _is_moving = true
```

单位处理：

- 存储它们在网格上的位置
- 视觉表示（精灵图）
- 平滑的移动动画
- 选择状态

### 4. 游戏棋盘 (GameBoard)

`GameBoard` 将所有东西联系在一起，管理单位并处理选择/移动。

```gdscript
# GameBoard 的关键部分
class_name GameBoard
extends Node2D

@export var grid: Grid

var _unit_by_cell := {}         # 映射网格位置到单位的字典
var _selected_unit: Unit        # 当前选中的单位
var _walkable_cells := []       # 选中单位可以移动到的单元格

# 处理单元格选择
func _on_cell_selected(cell: Vector2i) -> void:
    if _selected_unit == null:
        _select_unit_at(cell)
    elif _selected_unit.is_selected:
        _move_selected_unit(cell)

# 查找单位可以移动到的所有单元格
func _calculate_walkable_cells(unit: Unit) -> Array[Vector2i]:
    # 使用洪水填充算法查找移动范围内的所有单元格
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

            # 检查相邻单元格（4个方向）
            for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
                var next_cell = current + direction

                if grid.is_within_bounds(next_cell) and not _unit_by_cell.has(next_cell):
                    stack.append(next_cell)

    return cells
```

GameBoard：

- 跟踪哪些单位在哪些单元格上
- 处理单位选择
- 计算单位可以移动到的位置
- 管理移动过程

### 5. 移动可视化 (Movement Visualization)

有两个类帮助可视化移动选项：

#### MovementHighlighter

高亮显示选中单位可以移动到的所有单元格。

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

显示单位将要移动到光标位置所采取的路径。

```gdscript
# MovementPreview 的关键部分
class_name MovementPreview
extends TileMapLayer

@export var grid: Grid
var _astar: AStarGrid2D = null
var current_path: Array[Vector2i] = []

# 计算并显示两点之间的路径
func draw(start_cell: Vector2i, end_cell: Vector2i) -> void:
    clear()

    if not _astar:
        return

    # 使用 A* 算法查找路径
    current_path = _astar.get_id_path(start_cell, end_cell)

    if current_path.size() <= 1:
        return

    # 在瓦片地图上绘制路径
    for i in range(current_path.size()):
        var cell = current_path[i]
        set_cell(cell, 0, _get_tile_based_on_neighbors(cell, i, current_path))
```

### 6. 通信系统 (EventBus)

`EventBus` 允许组件之间在没有直接引用的情况下进行通信。

```gdscript
# EventBus.gd
extends Node

# 当玩家选择一个单元格时发出
signal cell_selected(cell_coordinates: Vector2i)

# 当光标移动到不同的单元格时发出
signal grid_position_changed(new_cell_coordinates: Vector2i)

# 当单位完成移动时发出
signal unit_moved(unit: Unit)
```

使用信号有助于保持代码模块化且更易于理解。

## 分步教程：创建一个新关卡

让我们创建一个简单的战术游戏关卡：

### 1. 创建一个新场景

1.  点击“场景” → “新建场景”
2.  添加一个 Node2D 作为根节点并命名为 "Level"
3.  将场景保存为 "level.tscn"

### 2. 设置网格

1.  创建一个新的资源文件：在文件系统（FileSystem）中右键点击 → “新建资源...”
2.  搜索 "Resource" 并创建一个空白资源
3.  将其保存为 "grid.tres"
4.  为此资源添加脚本：右键点击 → “附加脚本”
5.  将其命名为 "grid.gd"，内容来自上面的 Grid 部分（遵循 Godot 命名约定使用 snake_case）
6.  在检查器（Inspector）面板中设置：
    *   Dimensions: 10, 10 (或你喜欢的网格大小)
    *   Cell Size: 64, 64 (或你喜欢的单元格大小)

### 3. 添加背景

1.  向你的 Level 添加一个 TileMapLayer 节点（注意：TileMap 在 Godot 4.3 中已弃用；请改用 TileMapLayer）
2.  使用你的瓦片集（墙壁、地板等）配置它
3.  绘制你的地图布局

### 4. 添加 GameBoard

1.  添加一个 Node2D 并命名为 "GameBoard"
2.  将 GameBoard 脚本附加到它上面
3.  在检查器中，将 Grid 属性设置为你的 grid.tres 资源

### 5. 添加移动可视化

1.  添加一个 TileMapLayer 节点作为 GameBoard 的子节点，并命名为 "MovementHighlighter"
2.  附加 MovementHighlighter 脚本
3.  使用蓝色/高亮瓦片配置其瓦片集
4.  添加另一个 TileMapLayer 节点作为子节点，并命名为 "MovementPreview"
5.  附加 MovementPreview 脚本
6.  使用路径箭头瓦片配置其瓦片集
7.  将其 Grid 属性设置为你的 grid.tres 资源

### 6. 添加光标

1.  添加一个 Node2D 作为 Level 的子节点（不是 GameBoard 的子节点）并命名为 "GridSelector"
2.  附加 GridSelector 脚本
3.  将其 Grid 属性设置为你的 grid.tres 资源
4.  添加一个 Sprite2D 作为子节点，并将其纹理设置为你的光标图像
5.  添加一个 Timer 节点作为子节点，并命名为 "Timer"

### 7. 添加一些单位

1.  为你的单位创建一个新场景
2.  添加一个 Path2D 作为根节点并命名为 "Unit"
3.  附加 Unit 脚本
4.  添加一个 PathFollow2D 作为子节点，命名为 "PathFollow2D"
5.  添加一个 Sprite2D 作为 PathFollow2D 的子节点，并命名为 "Sprite"
6.  设置你的角色纹理
7.  添加一个 AnimationPlayer 作为 Unit 的子节点
8.  创建 "idle" 和 "selected" 动画
9.  将场景保存为 "unit.tscn"
10. 在你的 Level 场景中实例化此单位
11. 将其 Grid 属性设置为你的 grid.tres 资源
12. 将其放置在你希望它开始的位置

### 8. 添加 EventBus

1.  创建一个名为 "event_bus.gd" 的新脚本，包含 EventBus 的代码
2.  创建一个自动加载（Autoload）：项目 → 项目设置 → Autoload 选项卡
3.  添加你的 event_bus.gd 脚本，并将其命名为 "EventBus"

### 9. 运行游戏！

按 F5 运行你的游戏。你应该能够：

- 使用方向键或鼠标移动光标
- 通过点击单位来选择它
- 看到高亮的单元格显示它可以移动到的位置
- 将光标移动到有效目的地并点击以移动单位

## 面向初学者的核心概念

### 什么是网格 (Grid)？

在我们的游戏中，网格就像一个棋盘——由排列成行和列的正方形（或单元格）集合组成。每个单元格都有坐标 (x, y)，告诉我们它在棋盘上的位置。

### 什么是信号 (Signals)？

信号就像信使，当某事发生时，它们会通知游戏的不同部分。例如，当一个单位完成移动时，它会发送一个信号，这样游戏棋盘就知道它已经完成了。

### 什么是寻路 (Pathfinding)？

寻路是计算机找出如何从 A 点到达 B 点同时避开障碍物的一种方法。我们的游戏使用了 A\* (A-star) 算法，这就像一个更智能的地图导航版本。

## 扩展项目

以下是一些增强该项目的想法：

1.  **添加战斗系统**：实现单位遇到敌人时的战斗
2.  **回合系统**：添加一个系统来交替玩家和敌人的回合
3.  **不同单位类型**：创建具有不同移动范围和能力的单位
4.  **障碍物**：添加影响移动成本的地形
5.  **战争迷雾**：为单位实现有限的视野

## 故障排除

### 常见问题

1.  **单位不显示**：确保 Unit 的 Grid 属性设置正确
2.  **光标不移动**：检查输入操作（"ui_up", "ui_down" 等）是否在项目设置中配置
3.  **路径不出现**：验证 MovementPreview 的瓦片集是否配置正确

## 学习更多资源的链接

1.  [Godot 官方文档](https://docs.godotengine.org)
2.  [GDQuest 战术 RPG 移动教程](https://www.gdquest.com/tutorial/godot/2d/tactical-rpg-movement/)
3.  [Godot 的信号系统](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)

## 结论

你现在拥有了一个战术 RPG 移动系统的完整基础！该项目演示了重要的游戏开发概念，如基于网格的移动、寻路以及游戏元素之间基于信号的通信。

随意试验、修改并在此系统基础上构建，创造属于你自己的独特战术游戏吧！