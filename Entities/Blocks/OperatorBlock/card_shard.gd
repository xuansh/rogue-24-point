@tool
class_name CardShard
extends Node2D

## 运算块的刀身：左边竖排两个装弹口，右边收成刀尖指向敌人那一侧，
## 算出来的伤害数字落在刀身上。轮廓沿用战场网格那套"歪曲线"——
## 每笔带点抖，但角点不动，所以形状始终闭合、也始终贴着判定区。

## 刀身形状（以卡片中心为原点）。必须是凸多边形：它也直接拿去当鼠标判定区
const SHARD := [
	Vector2(-58, -56), Vector2(2, -56), Vector2(60, 0), Vector2(2, 56), Vector2(-58, 56),
]
## 等号那两横，放在装弹口和伤害数字中间的缝里
const EQUALS := [
	Vector2(-11, -4), Vector2(-1, -4), Vector2(-11, 4), Vector2(-1, 4),
]
## 刀尖外侧的两道箭头，位置比刀尖再靠右一点
const TIP := Vector2(60, 0)
const MARK_STEP := 8.0

## 拖动中 = 这张牌正要甩出去，轮廓和箭头一起提亮
@export var armed := false : set = _set_armed
## 轮廓抖动幅度
@export var wobble := 2.2 : set = _set_wobble
## 每条边分成几段，越大越平滑
@export var segments := 6 : set = _set_segments
## 换个数字换一套抖法，多张手牌不会长得一模一样
@export var variant := 0 : set = _set_variant

const BODY_COLOR := Color(0.235, 0.227, 0.306)
const EDGE_COLOR := Color(0.784, 0.784, 0.831, 0.72)
const EDGE_ARMED_COLOR := Color(0.949, 0.949, 0.961, 0.95)
## 箭头用数字方块的橙：提示这两个数最后会变成伤害
const MARK_COLOR := Color(1.000, 0.720, 0.420, 0.85)
const EQUALS_COLOR := Color(0.550, 0.480, 0.700, 0.70)

func _set_armed(value: bool) -> void:
	armed = value
	queue_redraw()

func _set_wobble(value: float) -> void:
	wobble = value
	queue_redraw()

func _set_segments(value: int) -> void:
	segments = maxi(value, 1)
	queue_redraw()

func _set_variant(value: int) -> void:
	variant = value
	queue_redraw()

func _draw() -> void:
	var body := _wobbled_outline()
	draw_colored_polygon(body, BODY_COLOR)
	draw_polyline(_closed(body), EDGE_ARMED_COLOR if armed else EDGE_COLOR, 1.0, true)

	for i in 2:
		var a: Vector2 = EQUALS[i * 2]
		var b: Vector2 = EQUALS[i * 2 + 1]
		draw_line(a, b, EQUALS_COLOR, 1.0, true)

	# 刀尖外侧的箭头：拖起来的时候更亮更长，一眼知道要甩出去了
	var reach := 6.0 if armed else 0.0
	for k in 2:
		var x := TIP.x + 4.0 + k * MARK_STEP + reach
		draw_polyline(
			PackedVector2Array([Vector2(x, -9), Vector2(x + 7, 0), Vector2(x, 9)]),
			MARK_COLOR,
			2.0 if armed else 1.0,
			true
		)

## 沿每条边采样，法线方向按哈希鼓一点；sin 在两端归零 → 角点纹丝不动
func _wobbled_outline() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := SHARD.size()
	for e in n:
		var a: Vector2 = SHARD[e]
		var b: Vector2 = SHARD[(e + 1) % n]
		var perp := (b - a).orthogonal().normalized()
		var bend := IsoFloor._hash(e, variant, 40) * 2.0 - 1.0
		for s in segments + 1:
			var t := float(s) / segments
			pts.append(a.lerp(b, t) + perp * sin(t * PI) * bend * wobble)
	return pts

func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out
