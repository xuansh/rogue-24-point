@tool
class_name EnemyIntent
extends Node2D

## 敌人头上的"下回合动向"图标。骨架只有一条：
## 上面的图形说明"会生成什么"，下面的大数字说明"几个"。
##
## 刻意不加外框、不加箭头、不加手绘线：图标在头顶只有五十几像素，
## 多一个元素就多糊一层，之前几版都是这么堆死的。字形用 Frick，
## 跟方块上那个数字是同一支字体；图形用 Assets 里那张 spawn_block。
## 原点在图形正中，内容约 32 宽 x 56 高（y 从 -28 到 28）。

const GLYPH_SIZE := 32.0
const GLYPH_CENTER_Y := -12.0
const NUMBER_CENTER_Y := 18.0
const NUMBER_SIZE := 20
const NUMBER_WIDTH := 120.0
const NUMBER_COLOR := Color(0.941, 0.925, 0.988)
const NUMBER_OUTLINE := Color(0.129, 0.122, 0.173)

## 生成物的图形；换成别的动向图标就换这里
@export var glyph: Texture2D = preload("res://Assets/Textures/spawn_block.png")
@export var number_font: Font = preload("res://Assets/Fonts/Frick0.3-Regular-3.otf")
## 会生成几个；<= 0 就只画图形不画数字
@export var count := 1 : set = _set_count

func _set_count(value: int) -> void:
	count = value
	queue_redraw()

func _draw() -> void:
	if glyph != null:
		draw_texture_rect(
			glyph,
			Rect2(Vector2(-GLYPH_SIZE * 0.5, GLYPH_CENTER_Y - GLYPH_SIZE * 0.5), Vector2(GLYPH_SIZE, GLYPH_SIZE)),
			false
		)
	if count <= 0 or number_font == null:
		return
	var text := "+%d" % count
	# 基线放在数字框的正中：文字框从基线上方 ascent 到下方 descent
	var baseline := NUMBER_CENTER_Y + (number_font.get_ascent(NUMBER_SIZE) - number_font.get_descent(NUMBER_SIZE)) * 0.5
	var pos := Vector2(-NUMBER_WIDTH * 0.5, baseline)
	draw_string_outline(number_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, NUMBER_WIDTH, NUMBER_SIZE, 3, NUMBER_OUTLINE)
	draw_string(number_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, NUMBER_WIDTH, NUMBER_SIZE, NUMBER_COLOR)
