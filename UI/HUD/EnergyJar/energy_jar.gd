@tool
class_name EnergyJar
extends Control

## 战斗界面左下角的能量罐：把原来战场上那排菱形槽换成"罐子 + 数字"，
## 数值直接对应 BattleState.cost_point / max_cost_point（杀戮尖塔那味儿）。
## 只负责画，接不接逻辑看上层：也可以直接改 current / max_value。
##
## 罐子按 DESIGN 里的设计坐标画，实际绘制时按控件尺寸等比缩放并居中，
## 所以换分辨率 / 拉伸都不会变形。

## 当前剩余费用
@export var current : int = 4 : set = _set_current
## 费用上限
@export var max_value : int = 4 : set = _set_max
## 液体填充色，沿用旧 energy_bar 的暖金，和绿色血条拉开
@export var fill_color := Color(1.0, 0.78, 0.34) : set = _refresh
## 罐身玻璃底色
@export var glass_color := Color(0.13, 0.12, 0.17, 0.9) : set = _refresh
## 罐口 / 罐身描边
@export var border_color := Color(0.475, 0.451, 0.573, 0.95) : set = _refresh
## 数字颜色
@export var number_color := Color(1.0, 0.96, 0.88) : set = _refresh

## 设计坐标系：罐子就是按这个尺寸画的
const DESIGN := Vector2(120.0, 150.0)
## 轮廓自己的中心（设计坐标，x 已经对称在 0）。
## y 不是 0：轮廓从罐口 y=8 画到罐底 y=147，不减掉这个中心罐子就会掉到控件外面去
const ART_CENTER := Vector2(0.0, 77.5)
## 液面最高能到哪儿（脖子根）/ 最低（罐底尖，0 费时正好一滴不剩）
const LIQUID_TOP := 30.0
const LIQUID_BOTTOM := 147.0
## 罐身轮廓：以 x=0 为轴左右对称，从罐口正中出发，右半边往下、左半边由镜像往上。
## 注意是从上往下的顺时针，_clip_below 依赖这个绕序。
## 用 static var 而不是 const：PackedVector2Array 的构造不是常量表达式
static var JAR := PackedVector2Array([
	Vector2(0, 8), Vector2(17, 8), Vector2(27, 13), Vector2(27, 20), Vector2(21, 23),
	Vector2(22, 34), Vector2(30, 44), Vector2(41, 54), Vector2(48, 68), Vector2(51, 88),
	Vector2(51, 108), Vector2(47, 123), Vector2(38, 134), Vector2(24, 142), Vector2(10, 146),
	Vector2(0, 147), Vector2(-10, 146), Vector2(-24, 142), Vector2(-38, 134), Vector2(-47, 123),
	Vector2(-51, 108), Vector2(-51, 88), Vector2(-48, 68), Vector2(-41, 54), Vector2(-30, 44),
	Vector2(-22, 34), Vector2(-21, 23), Vector2(-27, 20), Vector2(-27, 13), Vector2(-17, 8),
])

func _set_current(value: int) -> void:
	current = maxi(value, 0)
	queue_redraw()

func _set_max(value: int) -> void:
	max_value = maxi(value, 0)
	current = mini(current, max_value)
	queue_redraw()

func _refresh(_value = null) -> void:
	queue_redraw()

## 上层刷新入口：max_v < 0 表示沿用当前上限
func set_energy(value: int, max_v: int = -1) -> void:
	if max_v >= 0:
		max_value = maxi(max_v, 0)
	current = maxi(value, 0)
	queue_redraw()

func _ready() -> void:
	# 场景里只是摆样子，编辑器里别去碰 autoload
	if Engine.is_editor_hint():
		return
	SignalBus.cost_point_changed.connect(_on_cost_point_changed)

func _on_cost_point_changed(payload : SignalBus.CostPointChangedPayload) -> void:
	set_energy(payload.cost_point, payload.max_cost_point)

#region 绘制

func _draw() -> void:
	draw_colored_polygon(_screen(JAR), glass_color)

	# 液面以上的罐子是空的，只画到当前费用对应的水位
	var level := _liquid_level()
	var liquid := _clip_below(JAR, level)
	if liquid.size() >= 3:
		draw_colored_polygon(_screen(liquid), fill_color)
		var span := _surface_span(liquid, level)
		if span.x < span.y:
			draw_line(_to_screen(Vector2(span.x, level)), _to_screen(Vector2(span.y, level)),
					fill_color.lightened(0.45), maxf(2.0 * _scale(), 1.0), true)

	# 玻璃高光：左边一道长的加一道短的，罐子才有体积
	var s := _scale()
	draw_line(_to_screen(Vector2(24, 52)), _to_screen(Vector2(18, 118)), Color(1, 1, 1, 0.10), 7.0 * s, true)
	draw_line(_to_screen(Vector2(22, 56)), _to_screen(Vector2(19, 90)), Color(1, 1, 1, 0.16), 3.0 * s, true)

	draw_polyline(_closed(_screen(JAR)), border_color, maxf(2.0 * s, 1.0), true)

	# 罐口单独盖一层，描出"罐子"的唇边
	var rim := _screen(_ellipse(Vector2(0, 13.5), 27.5, 7.0))
	draw_colored_polygon(rim, Color(0.20, 0.19, 0.26, 0.97))
	draw_polyline(_closed(rim), border_color, maxf(1.5 * s, 1.0), true)

	_draw_numbers()

func _draw_numbers() -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var s := _scale()
	var width := size.x

	var big_size := int(54.0 * s)
	var baseline := _to_screen(Vector2(0, 112)).y
	draw_string_outline(font, Vector2(0, baseline), str(current), HORIZONTAL_ALIGNMENT_CENTER,
			width, big_size, int(6.0 * s), Color(0.05, 0.04, 0.08, 0.85))
	draw_string(font, Vector2(0, baseline), str(current), HORIZONTAL_ALIGNMENT_CENTER,
			width, big_size, number_color)

	var small_size := int(15.0 * s)
	var small_base := _to_screen(Vector2(0, 136)).y
	# 满费时数字压在橙色液体上，没描边就糊成一片
	draw_string_outline(font, Vector2(0, small_base), "MAX %d" % max_value, HORIZONTAL_ALIGNMENT_CENTER,
			width, small_size, int(3.0 * s), Color(0.05, 0.04, 0.08, 0.8))
	draw_string(font, Vector2(0, small_base), "MAX %d" % max_value, HORIZONTAL_ALIGNMENT_CENTER,
			width, small_size, Color(number_color.r, number_color.g, number_color.b, 0.75))

## 当前费用在 [0, 上限] 里的比例 → 设计坐标下的液面高度
func _liquid_level() -> float:
	var ratio := 1.0 if max_value <= 0 else clampf(float(current) / float(max_value), 0.0, 1.0)
	return lerpf(LIQUID_BOTTOM, LIQUID_TOP, ratio)

## 半平面 y >= level 裁剪多边形（Sutherland–Hodgman）。
## 罐子下半段是凸的，裁一条水平线只会得到一块连通的多边形
func _clip_below(poly: PackedVector2Array, level: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var a_in := a.y >= level
		var b_in := b.y >= level
		if a_in:
			out.append(a)
		if a_in != b_in:
			out.append(a.lerp(b, (level - a.y) / (b.y - a.y)))
	return out

## 液面那条线左右两个端点（就是裁剪时新插进去的两个交点）
func _surface_span(poly: PackedVector2Array, level: float) -> Vector2:
	var left := INF
	var right := -INF
	for p in poly:
		if absf(p.y - level) < 0.01:
			left = minf(left, p.x)
			right = maxf(right, p.x)
	return Vector2(left, right)

## 设计坐标 → 控件坐标：等比缩放 + 居中。
## 减掉轮廓中心而不是设计框中心，罐子才正好落在控件里
func _to_screen(p: Vector2) -> Vector2:
	return (p - ART_CENTER) * _scale() + size * 0.5

func _screen(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(_to_screen(p))
	return out

func _scale() -> float:
	return minf(size.x / DESIGN.x, size.y / DESIGN.y)

func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out

func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(center + Vector2(cos(t) * rx, sin(t) * ry))
	return pts

#endregion
