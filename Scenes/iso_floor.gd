@tool
class_name IsoFloor
extends Node2D

## 深紫菱形网格战场地面 + 深色背景。放在 Entities 的第一个子节点，绘制在实体之下。
## 这里的格子尺寸与原点是全场景对齐的唯一来源，CubeEntity 用同一套公式吸附格心。

## 设计分辨率宽度（project.godot 没设窗口尺寸，用 Godot 默认 1152x648）
## 格子坐标一律用设计空间的固定值，不跟窗口尺寸走，拉伸窗口也不会错位
const DESIGN_WIDTH := 1152.0
## 菱形格子宽度，等于实体方块底面宽度
const CELL_W := 72.0
## 战场基准行
const BASE_Y := 326.0
## 玩家所在格 = 战场原点 = 格子 (0,0)；0.185 就是原先的 (宽 / 2) * 0.37
const ANCHOR := Vector2(DESIGN_WIDTH * 0.185, BASE_Y)

const BG := Color(0.055, 0.043, 0.086)
const TILE_A := Color(0.121, 0.086, 0.180)
const TILE_B := Color(0.150, 0.106, 0.216)
const LINE := Color(0.545, 0.400, 0.850, 0.42)

## 整体透明度
@export var intensity := 1.0 : set = _refresh

## 世界坐标吸附到最近的菱形格中心，让方块底面正好压住一个格子
static func snap_to_cell(p: Vector2) -> Vector2:
	var u := (p.x - ANCHOR.x) / (CELL_W * 0.5)  # i - j
	var v := (p.y - BASE_Y) / (CELL_W * 0.25)   # i + j
	var i := roundf((u + v) * 0.5)
	var j := roundf((v - u) * 0.5)
	return ANCHOR + Vector2((i - j) * CELL_W * 0.5, (i + j) * CELL_W * 0.25)

## 把左侧的格子镜像到右侧（敌人站玩家对面）
static func mirror(p: Vector2) -> Vector2:
	return snap_to_cell(Vector2(DESIGN_WIDTH - p.x, p.y))

func _ready() -> void:
	get_viewport().size_changed.connect(_refresh)

func _refresh(_value = null) -> void:
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(-vp, vp * 3.0), BG)

	var hw := CELL_W * 0.5
	var qh := CELL_W * 0.25
	var origin := ANCHOR
	var focus := Vector2(DESIGN_WIDTH * 0.5, BASE_Y)
	var span := int(maxf(vp.x, vp.y) / hw) + 4

	for i in range(-span, span + 1):
		for j in range(-span, span + 1):
			var p := origin + Vector2((i - j) * hw, (i + j) * qh)
			if p.x < -hw or p.x > vp.x + hw or p.y < -qh * 2.0 or p.y > vp.y + qh:
				continue
			# 离战场中心越远越淡，边缘自然溶进背景
			var a := clampf(1.0 - (p - focus).length() / (vp.x * 0.62), 0.0, 1.0) * intensity
			if a < 0.05:
				continue
			var tile := TILE_A if (i + j) % 2 == 0 else TILE_B
			var diamond := PackedVector2Array([
				p + Vector2(0, -qh), p + Vector2(hw, 0), p + Vector2(0, qh), p + Vector2(-hw, 0)
			])
			draw_colored_polygon(diamond, Color(tile.r, tile.g, tile.b, a))
			draw_polyline(
				PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
				Color(LINE.r, LINE.g, LINE.b, LINE.a * a),
				1.0,
				true
			)
