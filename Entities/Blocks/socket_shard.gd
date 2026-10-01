@tool
class_name SocketShard
extends Panel

## 数字块与 operand 的凹槽。轮廓直接复用 NumberShard.build_outline —— 洞和放进去的
## 碎片必须是同一个形状，共用一个来源才不会各改各的然后对不上。
##
## 它是"洞"不是"块"：填色比战场底色更暗、描边压得很弱。洞壁远侧背光压暗、近侧迎光提亮，
## 靠这点明暗差读出"凹进去"。主角始终是里面的碎片，凹槽只负责把位置画出来。

## 相对 NumberShard.SHARD 的缩放。洞口要比碎片大一圈，
## 碎片落进去才是"嵌进槽里"而不是"压在槽上"。
@export var shape_scale := 1.08 : set = _set_shape_scale
## 轮廓抖动幅度。凹槽是重复的容器，抖得比碎片轻，一排槽位才不会毛毛躁躁
@export var wobble := 1.2 : set = _set_wobble
## 每条边分成几段，越大越平滑
@export var segments := 6 : set = _set_segments
## 换个种子换一套抖法
@export var variant := 0 : set = _set_variant

## 洞底：比 IsoFloor.BG 略暗就够。压成纯黑会变成一块比碎片还响的剪影，
## 空槽位会抢走该给数字的注意力。
const PIT := Color(0.098, 0.090, 0.125)
## 远侧洞壁（上/左）：背光，只留一点点，用来闭合形状
const EDGE_FAR := Color(0.784, 0.784, 0.831, 0.12)
## 近侧洞壁（下/右）：迎光。凹槽的"凹陷"主要靠这道唇口的亮度读出来
const EDGE_NEAR := Color(0.784, 0.784, 0.831, 0.42)
## 迎光的是 SHARD 的下标为 2、3 的两条边（右下、下）
const NEAR_EDGES := [2, 3]


func _ready() -> void:
	# 容器尺寸由 HBoxContainer / 偏移决定，排完版才知道中心在哪
	resized.connect(queue_redraw)


func _set_shape_scale(v : float) -> void:
	shape_scale = v
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
	# 凹槽画在自己的矩形中心，碎片也是以这里为原点落进来的
	var center := size * 0.5
	var outline := PackedVector2Array()
	for p in NumberShard.build_outline(wobble, segments, variant):
		outline.append(center + p * shape_scale)

	draw_colored_polygon(outline, PIT)
	draw_polyline(_closed(outline), EDGE_FAR, 1.0, true)
	for e in NEAR_EDGES:
		draw_polyline(_edge(outline, e), EDGE_NEAR, 1.0, true)


func _closed(pts : PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out


## 取下标为 e 的那条边上的采样点（首尾都含，边与边才接得上）
func _edge(pts : PackedVector2Array, e : int) -> PackedVector2Array:
	var step := segments + 1
	var out := PackedVector2Array()
	for s in range(e * step, (e + 1) * step + 1):
		out.append(pts[s])
	return out
