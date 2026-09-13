@tool
class_name CubeEntity
extends Node2D

## 等轴测低多边形方块。玩家 / 敌人 / 目标标记共用，靠 color 区分。
@export var color := Color(1.0, 0.51, 0.44)
## 立方体边长，默认等于 IsoFloor.CELL_W；改小就跟格子不成比例
@export var size := IsoFloor.CELL_W
## 柔和辉光强度，0 关闭
@export var glow := 0.35 : set = _refresh
## 落点吸附到菱形格中心；关掉就用系统给的原始坐标
@export var snap_to_grid := true
## > 0 时只向上浮动（不会沉到基准线以下），单位像素
@export var float_amplitude := 0.0
@export var float_speed := 1.5

var _snapped := false
var _t := 0.0
var _base_y := 0.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _snapped:
		# player_system / enemy_system 是 add_child 之后才赋 position，所以延后到第一帧吸附
		_snapped = true
		if snap_to_grid:
			position = IsoFloor.snap_to_cell(position)
		_base_y = position.y
	_t += delta * float_speed
	# absf 把 sin 压到 0~1，只在基准线以上起落；y 轴向下，所以是减
	# 振幅为 0 时结果恒等于 _base_y，自动从半空落回格心
	position.y = _base_y - absf(sin(_t)) * float_amplitude

func _refresh(_value = null) -> void:
	queue_redraw()

func _draw() -> void:
	var hw := size * 0.5
	var qh := size * 0.25
	var depth := size * 0.5
	var t_n := Vector2(0, -depth - qh)
	var t_e := Vector2(hw, -depth)
	var t_s := Vector2(0, -depth + qh)
	var t_w := Vector2(-hw, -depth)
	# 底面菱形以节点原点为中心，正好落在一个地面格子上
	var b_e := Vector2(hw, 0)
	var b_s := Vector2(0, qh)
	var b_w := Vector2(-hw, 0)
	var hull := PackedVector2Array([t_n, t_e, b_e, b_s, b_w, t_w])

	if glow > 0.0:
		var center := Vector2(0, -depth * 0.5)
		for ring in range(3, 0, -1):
			var ring_pts := PackedVector2Array()
			for p in hull:
				ring_pts.append(center + (p - center) * (1.0 + 0.09 * ring))
			draw_colored_polygon(ring_pts, Color(color.r, color.g, color.b, glow * 0.16))

	draw_colored_polygon(PackedVector2Array([t_n, t_e, t_s, t_w]), color.lightened(0.30))
	draw_colored_polygon(PackedVector2Array([t_w, t_s, b_s, b_w]), color.darkened(0.45))
	draw_colored_polygon(PackedVector2Array([t_s, t_e, b_e, b_s]), color.darkened(0.15))

	var edge := color.lightened(0.55)
	edge.a = 0.55
	draw_polyline(PackedVector2Array([t_n, t_e, b_e, b_s, b_w, t_w, t_n]), edge, 1.0, true)
