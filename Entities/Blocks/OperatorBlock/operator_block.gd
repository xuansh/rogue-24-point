extends Block

class_name OperatorBlock 

@onready var area_2d: Area2D = $Area2D

## 聚焦时的放大倍率
const FOCUS_SCALE := 1.12
## 缩放围绕卡面内部的这个点生效（y 向下为正），比中心低一点，放大时视觉上像"抬起来"
## 这点必须在卡面内部，否则碰撞区会从鼠标下面移开，导致 enter/exit 反复抖动
const PIVOT_OFFSET := Vector2(0, 28)
## 过渡时长
const DURATION := 0.12

var _tween : Tween

func _ready() -> void:
	area_2d.mouse_entered.connect(block_focus)
	area_2d.mouse_exited.connect(block_unfocus)
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func block_focus():
	_animate(FOCUS_SCALE)

func block_unfocus():
	_animate(1.0)

## 只动 Area2D，不动 self：self 由 HBoxContainer 排版，手改 position 会被重排覆盖
func _animate(target_scale: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(area_2d, "scale", Vector2.ONE * target_scale, DURATION)
	# 围绕 PIVOT_OFFSET 缩放的位移补偿：不动点是 P 时，原点需偏移 P * (1 - s)
	_tween.parallel().tween_property(area_2d, "position", PIVOT_OFFSET * (1.0 - target_scale), DURATION)
