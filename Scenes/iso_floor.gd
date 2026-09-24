@tool
class_name IsoFloor
extends Node2D

## 鼠尾草绿菱形网格战场地面 + 同色系背景（绗缝质感）。放在 Entities 的第一个子节点，
## 绘制在实体之下。
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

## 配色走"鼠尾草绿绗缝"：背景比砖面略深，砖面在同一色相里上下浮动，
## 网格缝线比砖面深一档，远看就是一整片拼布
const BG := Color(0.427, 0.541, 0.416)
const TILE_A := Color(0.494, 0.620, 0.482)
const TILE_B := Color(0.561, 0.686, 0.545)
const TILE_PIT := Color(0.412, 0.529, 0.400)
const TILE_BRIGHT := Color(0.616, 0.741, 0.596)
const LINE := Color(0.278, 0.376, 0.267, 0.72)
const MARK := Color(0.290, 0.392, 0.282, 0.45)

## 地牢装饰物配色，都压在同一套灰绿里，免得装饰比实体方块还抢眼
const DECOR_STONE := Color(0.438, 0.463, 0.412)
const DECOR_STONE_LIT := Color(0.596, 0.624, 0.565)
const DECOR_STEM := Color(0.769, 0.749, 0.678)
const DECOR_MOSS := Color(0.361, 0.478, 0.333)
const DECOR_PUDDLE := Color(0.302, 0.427, 0.424)
const DECOR_CAP := Color(0.718, 0.447, 0.376)

## 整体透明度
@export var intensity := 1.0
## 网格线风格：STRAIGHT = 之前的笔直网格；DUNGEON = 断续微弯的怪诞网格
enum GridStyle { STRAIGHT, DUNGEON }
@export var grid_style := GridStyle.DUNGEON
## 地牢装饰物密度：每格出现装饰的机率，设 0 就整片关掉
@export_range(0.0, 0.3, 0.01) var decor_density := 0.07

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

## 按格子哈希挑一种装饰画出来。unit = 半格宽高，用它把单位坐标换算成菱形内的像素位置
func _draw_decor(p: Vector2, i: int, j: int, unit: Vector2, a: float) -> void:
	match int(_hash(i, j, 51) * 5.0):
		0:
			_decor_rubble(p, i, j, unit, a)
		1:
			_decor_mushrooms(p, i, j, unit, a)
		2:
			_decor_weeds(p, i, j, unit, a)
		3:
			_decor_puddle(p, i, j, unit, a)
		_:
			_decor_stalagmite(p, i, j, unit, a)

## 碎石：几块散落的小三角，朝上一面提亮一点
func _decor_rubble(p: Vector2, i: int, j: int, unit: Vector2, a: float) -> void:
	for k in 2 + int(_hash(i, j, 60) * 3.0):
		var c := p + _cell_point(i, j, 61 + k * 3) * unit * 0.62
		var s := 1.6 + _hash(i, j, 62 + k * 3) * 2.2
		var col := DECOR_STONE_LIT if _hash(i, j, 63 + k * 3) > 0.5 else DECOR_STONE
		draw_colored_polygon(
			PackedVector2Array([
				c + Vector2(-s, s * 0.45), c + Vector2(s, s * 0.45), c + Vector2(-s * 0.15, -s * 0.8),
			]),
			Color(col.r, col.g, col.b, 0.85 * a)
		)

## 蘑菇：细杆加圆帽，一丛最多三朵
func _decor_mushrooms(p: Vector2, i: int, j: int, unit: Vector2, a: float) -> void:
	var stem := Color(DECOR_STEM.r, DECOR_STEM.g, DECOR_STEM.b, 0.7 * a)
	var cap := Color(DECOR_CAP.r, DECOR_CAP.g, DECOR_CAP.b, 0.8 * a)
	for k in 1 + int(_hash(i, j, 80) * 3.0):
		var base := p + _cell_point(i, j, 81 + k * 2) * unit * 0.55
		var top := base - Vector2(0, 4.0 + _hash(i, j, 82 + k * 2) * 3.5)
		draw_line(base, top, stem, 1.6, true)
		draw_circle(top, 1.8 + _hash(i, j, 83 + k * 2) * 1.4, cap)

## 杂草：几根往外散开的短曲线，顶端带点弯
func _decor_weeds(p: Vector2, i: int, j: int, unit: Vector2, a: float) -> void:
	var col := Color(DECOR_MOSS.r, DECOR_MOSS.g, DECOR_MOSS.b, 0.75 * a)
	for k in 3 + int(_hash(i, j, 90) * 3.0):
		var base := p + _cell_point(i, j, 91 + k * 2) * unit * 0.7
		var h := 4.0 + _hash(i, j, 92 + k * 2) * 6.0
		var sway := (_hash(i, j, 93 + k * 2) - 0.5) * 6.0
		draw_polyline(
			PackedVector2Array([
				base, base + Vector2(sway * 0.35, -h * 0.6), base + Vector2(sway, -h),
			]),
			col,
			1.0,
			true
		)

## 积水：压扁的暗色多边形，加一道短反光
func _decor_puddle(p: Vector2, i: int, j: int, unit: Vector2, a: float) -> void:
	var c := p + _cell_point(i, j, 100) * unit * 0.4
	var r := 5.0 + _hash(i, j, 101) * 5.0
	const RIM := 8
	# 半径只抖 0.85~1.0，多边形保持接近凸形，draw_colored_polygon 才不会三角化出错
	var pts := PackedVector2Array()
	for k in RIM:
		var ang := TAU * float(k) / RIM
		var rad := r * (0.85 + _hash(i, j, 102 + k) * 0.15)
		pts.append(c + Vector2(cos(ang) * rad, sin(ang) * rad * 0.5))
	draw_colored_polygon(pts, Color(DECOR_PUDDLE.r, DECOR_PUDDLE.g, DECOR_PUDDLE.b, 0.85 * a))
	draw_polyline(
		PackedVector2Array([pts[0].lerp(pts[RIM / 2], 0.3), pts[0].lerp(pts[RIM / 2], 0.55)]),
		Color(LINE.r, LINE.g, LINE.b, 0.3 * a),
		1.0,
		true
	)

## 石笋：左右两半深浅不同，假装有一面朝着光
func _decor_stalagmite(p: Vector2, i: int, j: int, unit: Vector2, a: float) -> void:
	var c := p + _cell_point(i, j, 110) * unit * 0.5
	var h := 6.0 + _hash(i, j, 111) * 6.0
	var w := 2.5 + _hash(i, j, 112) * 2.0
	var lit := Color(DECOR_STONE_LIT.r, DECOR_STONE_LIT.g, DECOR_STONE_LIT.b, 0.9 * a)
	var dark := Color(DECOR_STONE.r, DECOR_STONE.g, DECOR_STONE.b, 0.9 * a)
	draw_colored_polygon(
		PackedVector2Array([c + Vector2(-w, 0), c + Vector2(0, -h), c + Vector2(0, 0)]), lit
	)
	draw_colored_polygon(
		PackedVector2Array([c + Vector2(0, 0), c + Vector2(0, -h), c + Vector2(w, 0)]), dark
	)

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
	# 装饰物先收集、后绘制：它们会长出格子外，得压在所有地砖之上
	var decor_cells : Array = []

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
			if decor_density > 0.0 and _hash(i, j, 50) < decor_density:
				decor_cells.append([p, i, j, a])

	# 按屏幕 y 排序再画：先远后近，近处的装饰盖住远处的，前后关系才对
	decor_cells.sort_custom(func(x, y): return x[0].y < y[0].y)
	for d in decor_cells:
		_draw_decor(d[0], d[1], d[2], Vector2(hw, qh), d[3])
