@tool
class_name IsoFloor
extends Node2D

## 深紫菱形网格战场地面 + 深色背景。放在 Entities 的第一个子节点，绘制在实体之下。
## 这里的格子尺寸与原点是全场景对齐的唯一来源，CubeEntity 用同一套公式吸附格心。

## 设计分辨率 = project.godot 的窗口尺寸。以前这里是写死的 1152，改了窗口尺寸后
## 网格中点和左右镜像就都跟着错，所以现在从工程设置读，改窗口尺寸不用再动这里
static var DESIGN_SIZE := Vector2(
	float(ProjectSettings.get_setting("display/window/size/viewport_width", 1152)),
	float(ProjectSettings.get_setting("display/window/size/viewport_height", 648)))
## 菱形格子宽度，等于实体方块底面宽度
const CELL_W := 60
## 战场基准行 = 竖直中线，战场上下居中
static var BASE_Y := DESIGN_SIZE.y * 0.5
## 玩家所在格 = 战场原点 = 格子 (0,0)。到中线的距离原本是 0.315 * 宽（原来的
## (宽 / 2) * 0.37），这里再量化到半格，玩家格镜像后才会正好落在对称的格心上
static var ANCHOR := Vector2(
	DESIGN_SIZE.x * 0.5 - roundf(DESIGN_SIZE.x * 0.315 / (CELL_W * 0.5)) * CELL_W * 0.5,
	BASE_Y)

const BG := Color(0.055, 0.043, 0.086)
const TILE_A := Color(0.121, 0.086, 0.180)
const TILE_B := Color(0.150, 0.106, 0.216)
const TILE_PIT := Color(0.082, 0.059, 0.124)
const TILE_BRIGHT := Color(0.180, 0.130, 0.252)
const LINE := Color(0.545, 0.400, 0.850, 0.42)
const MARK := Color(0.040, 0.030, 0.062, 0.55)

## 整体透明度
@export var intensity := 1.0
## 网格线风格：STRAIGHT = 之前的笔直网格；DUNGEON = 断续微弯的怪诞网格
enum GridStyle { STRAIGHT, DUNGEON }
@export var grid_style := GridStyle.DUNGEON

## 世界坐标吸附到最近的菱形格中心，让方块底面正好压住一个格子
static func snap_to_cell(p: Vector2) -> Vector2:
	var u := (p.x - ANCHOR.x) / (CELL_W * 0.5)  # i - j
	var v := (p.y - BASE_Y) / (CELL_W * 0.25)   # i + j
	var i := roundf((u + v) * 0.5)
	var j := roundf((v - u) * 0.5)
	return ANCHOR + Vector2((i - j) * CELL_W * 0.5, (i + j) * CELL_W * 0.25)

## 把左侧的格子镜像到右侧（敌人站玩家对面）
static func mirror(p: Vector2) -> Vector2:
	return snap_to_cell(Vector2(DESIGN_SIZE.x - p.x, p.y))

## 每格确定性伪随机：同一格无论重绘多少次（窗口缩放）结果都一样，不会闪
static func _hash(i: int, j: int, salt: int) -> float:
	var n := (i * 92837111 + j * 689287499 + salt * 283923481) & 0x7FFFFFFF
	n = (n ^ (n >> 13)) & 0x7FFFFFFF
	n = (n * 1274126177) & 0x7FFFFFFF
	n = (n ^ (n >> 16)) & 0x7FFFFFFF
	return float(n) / float(0x7FFFFFFF)

## 菱形内的随机点，单位坐标（|x| <= 1，|y| <= 1，且 |x| + |y| <= 1）
static func _cell_point(i: int, j: int, salt: int) -> Vector2:
	var a := _hash(i, j, salt) * 2.0 - 1.0
	var b := _hash(i, j, salt + 1) * 2.0 - 1.0
	return Vector2(a * (1.0 - absf(b)), b)

## 菱形四个角点的格坐标（uv = (i - j, i + j)），顺序 北 → 东 → 南 → 西
static func _corners(uv: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(uv.x, uv.y - 1), Vector2i(uv.x + 1, uv.y),
		Vector2i(uv.x, uv.y + 1), Vector2i(uv.x - 1, uv.y),
	]

## 边 e（角点 e → 角点 e + 1）的 key = 两端格坐标之和。一块砖的四条边会被
## 相邻砖各画一次，但共用同一条边的两块砖算出同一个 key，所以画出来是同一条
## 曲线，不会变成两条错开的线
static func _edge_key(uv: Vector2i, e: int) -> Vector2i:
	var corners := _corners(uv)
	return corners[e] + corners[(e + 1) % 4]

## 怪诞网格：每条边单独画，微微弯曲，并且随机断成半截
func _draw_wonky_grid(diamond: PackedVector2Array, uv: Vector2i, a: float) -> void:
	const STEPS := 4
	for e in 4:
		var key := _edge_key(uv, e)
		var roll := _hash(key.x, key.y, 30)
		if roll < 0.20:
			continue  # 整条边断开，网格就有缺口
		var t0 := 0.0
		var t1 := 1.0
		if roll < 0.48:  # 剩下的边再抽掉一部分，只留半截，看着断断续续
			t0 = _hash(key.x, key.y, 31) * 0.45
			t1 = minf(t0 + 0.35 + _hash(key.x, key.y, 32) * 0.4, 1.0)
		var pa := diamond[e]
		var pb := diamond[(e + 1) % 4]
		# 垂直于这条边的方向，弧度只往一侧鼓
		var perp := (pb - pa).orthogonal().normalized()
		var amp := 0.9 + _hash(key.x, key.y, 33) * 1.7  # 1~2.6px，够"微微弯曲"
		var bend := _hash(key.x, key.y, 35) * 2.0 - 1.0
		var pts := PackedVector2Array()
		for s in STEPS + 1:
			var t := lerpf(t0, t1, float(s) / STEPS)
			# sin 在两端归零：整条边两头的角点不动，断成半截时断点也落回线上。
			# 相邻两块砖算的是同一条边（同一个 key），所以角点永远接得上
			var wob := sin((t - t0) / (t1 - t0) * PI) * bend
			pts.append(pa.lerp(pb, t) + perp * wob * amp)
		draw_polyline(
			pts,
			Color(LINE.r, LINE.g, LINE.b, LINE.a * a * (0.45 + _hash(key.x, key.y, 36) * 0.4)),
			1.0,
			true
		)

func _ready() -> void:
	if position != Vector2.ZERO:
		push_warning("IsoFloor 带了位移，会和实体吸附用的世界网格错位，请在场景里把它归零")
	get_viewport().size_changed.connect(_refresh)

func _refresh(_value = null) -> void:
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(-vp, vp * 3.0), BG)

	var hw := CELL_W * 0.5
	var qh := CELL_W * 0.25
	var origin := ANCHOR
	var focus := Vector2(DESIGN_SIZE.x * 0.5, BASE_Y)
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
			# 地牢风格：深浅不再交替，由每格哈希决定，偶发深坑与亮石
			var roll := _hash(i, j, 0)
			var tile: Color
			if roll < 0.10:
				tile = TILE_PIT
			elif roll > 0.90:
				tile = TILE_BRIGHT
			else:
				# 取两次哈希平均，让多数砖面颜色接近、少数明显偏深或偏浅
				var t := (_hash(i, j, 1) + _hash(i, j, 4)) * 0.5
				tile = TILE_A.lerp(TILE_B, t)
			var jitter := (_hash(i, j, 2) - 0.5) * 0.03
			tile += Color(jitter, jitter, jitter)
			var diamond := PackedVector2Array([
				p + Vector2(0, -qh), p + Vector2(hw, 0), p + Vector2(0, qh), p + Vector2(-hw, 0)
			])
			draw_colored_polygon(diamond, Color(tile.r, tile.g, tile.b, a))
			var mark := Color(MARK.r, MARK.g, MARK.b, MARK.a * a)
			if _hash(i, j, 6) < 0.22:
				var crack := PackedVector2Array([
					p + _cell_point(i, j, 10) * Vector2(hw, qh),
					p + _cell_point(i, j, 12) * Vector2(hw, qh),
					p + _cell_point(i, j, 14) * Vector2(hw, qh),
				])
				draw_polyline(crack, mark, 1.0, true)
			for k in int(_hash(i, j, 20) * 3.0):
				var spot := p + _cell_point(i, j, 22 + k * 2) * Vector2(hw, qh)
				draw_circle(spot, 0.8 + _hash(i, j, 23 + k * 2) * 1.4, mark)
			if grid_style == GridStyle.STRAIGHT:
				draw_polyline(
					PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
					Color(LINE.r, LINE.g, LINE.b, LINE.a * a),
					1.0,
					true
				)
			else:
				_draw_wonky_grid(diamond, Vector2i(i - j, i + j), a)
