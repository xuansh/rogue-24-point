@tool
class_name PathGuide
extends Node2D

## map 场景的「路径指引」绘制节点：把指定格子整块砖面点亮。
##
## 方向是「整块砖面亮起」而不是「一片圆形光洒下来」，所以主体是菱形硬边：
##   外溢菱形光（可选） → 整块砖面 → 中心热区 → 砖缝描边
## 挂在 Entities 下、IsoFloor 之后：z_index 相同，靠树序压在地砖之上、方块之下。
##
## 这里只负责画，不含寻路逻辑。高亮哪些格子由外部喂进来：
##   现在 = 调试字段 debug_cells（直接在编辑器里看效果）
##   之后 = SelectableNodeSystem 算完路径后调 set_cells
##
## 几何全部走 IsoFloor.cell_to_world / CELL_HW / CELL_QH，和地砖共用唯一一套换算，
## 光斑才会正好垫在方块底下，不多不少一格。

## 砖面主色：暖金，压在 Map 的绿色地面上对比最强，一眼就是「可走的路」
@export var glow_color := Color(1.00, 0.86, 0.50)
## 砖缝描边色：接近白，才能盖过 IsoFloor 的近黑砖缝
@export var rim_color := Color(1.00, 0.97, 0.84)

@export_group("砖面")
## 整块砖面的基础亮度。加法混合，调太高会把格子里长出来的装饰物糊掉
@export_range(0.0, 1.0, 0.01) var core_alpha := 0.30
## 中心热区亮度系数：在砖面上再叠两层更小的同心菱形，中间自然更烫
@export_range(0.0, 1.0, 0.01) var core_hotspot := 0.55
## 砖缝描边亮度 / 线宽
@export_range(0.0, 2.0, 0.01) var rim_alpha := 0.75
@export_range(0.0, 6.0, 0.1) var rim_width := 1.6

@export_group("外溢光")
## 砖面外侧再套几层同心菱形，0 = 光完全不越出本格（最"整块砖面"）
@export_range(0, 4, 1) var spill_rings := 2
## 每层放大的比例
@export_range(0.02, 0.5, 0.01) var spill_step := 0.13
## 最外层的亮度，往里递增
@export_range(0.0, 1.0, 0.01) var spill_alpha := 0.15

@export_group("呼吸")
@export var animated := true:
	set(value):
		animated = value
		set_process(value)
@export var pulse_speed := 2.4
@export_range(0.0, 1.0, 0.01) var pulse_amplitude := 0.18

@export_group("调试")
## 还没接寻路系统时，直接在编辑器里写死要高亮的格子看效果。
## 默认是一串「边相邻」的格子 —— (12,-13) 和 (13,-13) 共边，光斑连得起来；
## 而 (k,-k) 那种是尖角相碰，看着是断开的 —— 再加上两个可选节点格。
## 接上 SelectableNodeSystem 之后把这个数组清空即可
var debug_cells : Array[Vector2i] = []:
	set(value):
		debug_cells = value
		if is_node_ready():
			_sync_debug_cells()

## cell -> Vector2(intensity, phase)。phase 预留给以后「从玩家向外扩散的波」，
## 让公共主干上的格子呼吸同步，单格阶段恒为 0
var _cells : Dictionary = {}
var _time := 0.0


func _ready() -> void:
	set_process(animated)
	_sync_debug_cells()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## 外部入口：整批替换高亮格子。
## cells 的值可以是 intensity(float)，也可以是 Vector2(intensity, phase)，两种都收
func set_cells(cells: Dictionary) -> void:
	_cells.clear()
	for cell in cells:
		var v = cells[cell]
		_cells[cell] = v if v is Vector2 else Vector2(float(v), 0.0)
	queue_redraw()


func clear_cells() -> void:
	_cells.clear()
	queue_redraw()


func glow_cell(cell: Vector2i, intensity := 1.0, phase := 0.0) -> void:
	_cells[cell] = Vector2(intensity, phase)
	queue_redraw()


func _sync_debug_cells() -> void:
	_cells.clear()
	for cell in debug_cells:
		_cells[cell] = Vector2(1.0, 0.0)
	queue_redraw()


func _draw() -> void:
	if _cells.is_empty():
		return
	# 先远后近：和 IsoFloor 画装饰物的顺序一致，光斑互相压叠时前后关系才对
	var ordered := _cells.keys()
	ordered.sort_custom(
		func(a, b): return IsoFloor.cell_to_world(a).y < IsoFloor.cell_to_world(b).y
	)
	for cell in ordered:
		var v : Vector2 = _cells[cell]
		_draw_cell(cell, v.x, v.y)


func _draw_cell(cell: Vector2i, intensity: float, phase: float) -> void:
	if intensity <= 0.0:
		return
	var p := IsoFloor.cell_to_world(cell)
	var hw := IsoFloor.CELL_HW
	var qh := IsoFloor.CELL_QH
	var breathe := 1.0
	if animated:
		# 只让光晕和描边呼吸，砖面本身不闪 —— 砖面闪会像"选中/取消选中"在抖
		breathe = 1.0 - pulse_amplitude * (0.5 + 0.5 * sin(_time * pulse_speed - phase))

	# 1) 外溢：同心菱形，越外越淡。spill_rings = 0 时完全不出本格
	for k in range(spill_rings, 0, -1):
		var s := 1.0 + spill_step * k
		var a := spill_alpha * (1.0 - float(k) / (spill_rings + 1.0)) * intensity * breathe
		draw_colored_polygon(_diamond(p, hw * s, qh * s), _tint(glow_color, a))

	# 2) 砖面：整块点亮。不参与呼吸，砖面亮度保持稳定
	var base := core_alpha * intensity
	draw_colored_polygon(_diamond(p, hw, qh), _tint(glow_color, base))

	# 3) 中心热区：两层更小的同心菱形叠上去，加法混合下自然"中间更烫"
	var hot := base * core_hotspot
	draw_colored_polygon(_diamond(p, hw * 0.66, qh * 0.66), _tint(glow_color, hot))
	draw_colored_polygon(_diamond(p, hw * 0.34, qh * 0.34), _tint(glow_color, hot))

	# 4) 砖缝描边：盖掉 IsoFloor 的近黑网格线，一格边界瞬间"点亮"
	var rim := _diamond(p, hw, qh)
	rim.append(rim[0])
	draw_polyline(rim, _tint(rim_color, rim_alpha * intensity * breathe), rim_width, true)


## 以 p 为中心的菱形，顺序 北 → 东 → 南 → 西（与 IsoFloor 的砖面顶点一致）
static func _diamond(p: Vector2, hw: float, qh: float) -> PackedVector2Array:
	return PackedVector2Array([
		p + Vector2(0.0, -qh), p + Vector2(hw, 0.0), p + Vector2(0.0, qh), p + Vector2(-hw, 0.0),
	])


## 只换 alpha，保留 HDR 色值（以后想开 WorldEnvironment 的 2D bloom，把颜色乘到 >1 即可）
static func _tint(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)
