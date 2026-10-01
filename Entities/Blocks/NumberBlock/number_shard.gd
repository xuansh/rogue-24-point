@tool
class_name NumberShard
extends Node2D

## 数字块的碎片外壳。和运算块刀身( CardShard )共用同一套语言：暗紫体 + 高亮描边 + 歪曲线轮廓。
## 差别在轮廓更胖更短 —— 刀身两头收尖是为了指向敌人，数字块得把中间让给数字。
##
## 值驱动体色、描边与辉光强度。数字越大越烫，
## "这块被挤出去要扣我多少血" 不用读字就能先感觉到。
## 尺寸不参与分档：一排数字块必须一样大，槽位才不会看着参差不齐。

## 碎片轮廓（以中心为原点）。钝头朝右，和刀身一个方向。
const SHARD := [
	Vector2(-31, -30), Vector2(9, -30), Vector2(31, 0), Vector2(9, 30), Vector2(-31, 30),
]
## 数字画在轮廓的面积重心而不是包围盒中心：这个形状左重右尖，按包围盒居中会看着偏右。
## 数值为 SHARD 的面积重心 x（约 -5.1）取整；改 SHARD 时要跟着重算。
const NUMBER_CENTER := Vector2(-5.1, 0.0)

const VALUE_MIN := 1
const VALUE_MAX := 9

## 低值：安静、贴近槽位底色，不跟别的块抢注意力
const BODY_COOL := Color(0.216, 0.208, 0.271)
## 高值：偏暖发亮，一眼从一排里跳出来
const BODY_HOT := Color(0.361, 0.306, 0.322)
const RIM_COOL := Color(1.0, 0.72, 0.42, 0.50)
const RIM_HOT := Color(1.0, 0.84, 0.48, 1.0)
## 高值才有的辉光强度；0 = 关
const GLOW_HOT := 0.42

const FONT : Font = preload("res://Assets/Fonts/Frick0.3-Regular-3.otf")
## 数字字号。定值 —— 分档只走颜色和辉光，不动尺寸
const DIGIT_SIZE := 38
## 数字是主要读取通道，透明度有个下限，不跟着低档一起暗到读不清。
## 分档靠的是体色、描边和辉光，不是靠把数字藏起来。
const DIGIT_ALPHA_COOL := 0.75
const DIGIT_ALPHA_HOT := 1.0
## 居中用的文本框宽度，取槽位边长
const DIGIT_BOX := 64.0
const DIGIT_OUTLINE := Color(0.129, 0.122, 0.173)

## 这个数字块的值，驱动全部外观分档
@export var value := 1 : set = _set_value
## 轮廓抖动幅度
@export var wobble := 2.2 : set = _set_wobble
## 每条边分成几段，越大越平滑
@export var segments := 6 : set = _set_segments
## 换个数字换一套抖法，一排数字块不会长得一模一样
@export var variant := 0 : set = _set_variant


## 0 = 最小(1)，1 = 最大(9)
func tier() -> float:
	return clampf(float(value - VALUE_MIN) / float(VALUE_MAX - VALUE_MIN), 0.0, 1.0)


func _set_value(v : int) -> void:
	value = v
	queue_redraw()


func _set_wobble(v : float) -> void:
	wobble = v
	queue_redraw()


func _set_segments(v : int) -> void:
	segments = maxi(v, 1)
	queue_redraw()


func _set_variant(v : int) -> void:
	variant = v
	queue_redraw()


func _draw() -> void:
	var t := tier()
	var rim := RIM_COOL.lerp(RIM_HOT, t)
	var outline := _wobbled_outline()

	# 辉光：一圈圈向外扩张的同形多边形，和 CubeEntity / EnergyBar 同一个路子
	for ring in range(3, 0, -1):
		var alpha := GLOW_HOT * t * 0.16 * float(ring) / 3.0
		if alpha <= 0.0:
			continue
		draw_colored_polygon(_grow(outline, 1.0 + 0.10 * ring), Color(rim.r, rim.g, rim.b, alpha))

	draw_colored_polygon(outline, BODY_COOL.lerp(BODY_HOT, t))
	draw_polyline(_closed(outline), rim, lerpf(1.0, 2.4, t), true)
	_draw_digit(t)


## 和 EnemyIntent 一样：先描边再填字，深色背景下数字才不会糊在碎片上
func _draw_digit(t : float) -> void:
	var color := RIM_COOL.lerp(RIM_HOT, t)
	color.a = lerpf(DIGIT_ALPHA_COOL, DIGIT_ALPHA_HOT, t)
	var text := str(value)
	# 基线放在文本框正中：文字从基线上方 ascent 到下方 descent
	var baseline := NUMBER_CENTER.y + (FONT.get_ascent(DIGIT_SIZE) - FONT.get_descent(DIGIT_SIZE)) * 0.5
	var pos := Vector2(NUMBER_CENTER.x - DIGIT_BOX * 0.5, baseline)
	draw_string_outline(
		FONT, pos, text, HORIZONTAL_ALIGNMENT_CENTER, DIGIT_BOX, DIGIT_SIZE,
		roundi(lerpf(2.0, 4.0, t)), DIGIT_OUTLINE
	)
	draw_string(FONT, pos, text, HORIZONTAL_ALIGNMENT_CENTER, DIGIT_BOX, DIGIT_SIZE, color)


## 沿每条边采样、法线方向按哈希鼓一点；sin 在两端归零 → 角点纹丝不动，形状始终闭合。
## 做成静态是为了让凹槽( socket_shard.gd )复用同一份轮廓，洞和碎片不会各自漂移。
static func build_outline(wobble_amount : float, seg : int, wobble_seed : int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := SHARD.size()
	for e in n:
		var a : Vector2 = SHARD[e]
		var b : Vector2 = SHARD[(e + 1) % n]
		var perp := (b - a).orthogonal().normalized()
		var bend := IsoFloor._hash(e, wobble_seed, 40) * 2.0 - 1.0
		for s in seg + 1:
			var u := float(s) / seg
			pts.append(a.lerp(b, u) + perp * sin(u * PI) * bend * wobble_amount)
	return pts


func _wobbled_outline() -> PackedVector2Array:
	return build_outline(wobble, segments, variant)


func _closed(pts : PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out


func _grow(pts : PackedVector2Array, k : float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p * k)
	return out
