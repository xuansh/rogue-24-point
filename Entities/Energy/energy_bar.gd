@tool
class_name EnergyBar
extends Node2D

## 玩家能量槽外观：一排等轴测菱形晶格。
## 亮的 = 当前剩余能量（对应 BattleState.cost_point），暗的 = 已经花掉/空着的槽。
## 只负责画，不接任何逻辑；上层改 current_energy / max_energy 就会重绘。
##
## 每个槽位是一枚压扁的菱形，比例跟地面格子一致（高 = 半宽），
## 整排默认以节点原点为中心，方便直接挂在玩家头上或脚下。

## 能量上限 = 槽位数量，默认对齐 PlayerState.max_cost_point
@export var max_energy := 4 : set = _set_max_energy
## 当前剩余能量；超过上限会被夹住
@export var current_energy := 4 : set = _set_current_energy
## 单个槽位的半宽（菱形的横向半径）
@export var pip_radius := 11.0 : set = _refresh
## 相邻槽位的中心间距
@export var pip_gap := 30.0 : set = _refresh
## 整排是否以原点为中心；关掉就从原点向右排
@export var centered := true : set = _refresh
## 有能量时的填充色（暖金，和绿色血条拉开区分）
@export var filled_color := Color(1.0, 0.78, 0.34) : set = _refresh
## 空槽的底色
@export var empty_color := Color(0.192, 0.188, 0.243, 1.0) : set = _refresh
## 空槽描边
@export var border_color := Color(0.475, 0.451, 0.573, 0.9) : set = _refresh

func _set_max_energy(value: int) -> void:
	max_energy = maxi(value, 0)
	current_energy = clampi(current_energy, 0, max_energy)
	queue_redraw()

func _set_current_energy(value: int) -> void:
	current_energy = clampi(value, 0, max_energy)
	queue_redraw()

func _refresh(_value = null) -> void:
	queue_redraw()

## 上层刷新入口：比如每回合回填、打牌扣费时调用
func set_energy(current: int, max_value: int = -1) -> void:
	if max_value >= 0:
		max_energy = maxi(max_value, 0)
	current_energy = clampi(current, 0, max_energy)
	queue_redraw()

func _draw() -> void:
	if max_energy <= 0:
		return
	var span := pip_gap * (max_energy - 1)
	var start_x := -span * 0.5 if centered else 0.0
	for i in range(max_energy):
		_draw_pip(Vector2(start_x + pip_gap * i, 0.0), i < current_energy)

func _draw_pip(center: Vector2, lit: bool) -> void:
	# 等轴测菱形：竖向半径取半，跟地面上格子的 2:1 比例一致
	var half_w := pip_radius
	var half_h := pip_radius * 0.5
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -half_h),
		center + Vector2(half_w, 0.0),
		center + Vector2(0.0, half_h),
		center + Vector2(-half_w, 0.0),
	])

	if lit:
		# 几圈由内向外衰减的辉光，跟 CubeEntity 的发光一个路子
		for ring in range(3, 0, -1):
			var glow_pts := PackedVector2Array()
			for p in diamond:
				glow_pts.append(center + (p - center) * (1.0 + 0.18 * ring))
			draw_colored_polygon(glow_pts, Color(filled_color.r, filled_color.g, filled_color.b, 0.20 * ring / 3.0))
		draw_colored_polygon(diamond, filled_color)
		var edge := filled_color.lightened(0.5)
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), edge, 1.5, true)
	else:
		draw_colored_polygon(diamond, empty_color)
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), border_color, 1.5, true)
