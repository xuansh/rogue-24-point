extends Block

class_name OperatorBlock 

@onready var operand_a : Area2D = $Area2D/Operand_A
@onready var operand_b : Area2D = $Area2D/Operand_B
@onready var output_label : RichTextLabel = $Area2D/OutputRichTextLabel
@onready var body : CardShard = $Area2D/Body
@onready var collision_shape : CollisionShape2D = $Area2D/CollisionShape2D

var origin_position : Vector2
var calculate_result : int

## 聚焦时的放大倍率
const FOCUS_SCALE := 1.12
## 缩放围绕卡面内部的这个点生效（y 向下为正），比中心低一点，放大时视觉上像"抬起来"
## 这点必须在卡面内部，否则碰撞区会从鼠标下面移开，导致 enter/exit 反复抖动
const PIVOT_OFFSET := Vector2(0, 28)
## 过渡时长
const DURATION := 0.12
## 空槽位的标记 数字块的值是 1~9 不会撞上
const EMPTY_OPERAND := -1

var _tween : Tween
## 两个操作数当前的值 下标 0 = Operand_A, 1 = Operand_B
var _operand_values : Array[int] = [EMPTY_OPERAND, EMPTY_OPERAND]

func _ready() -> void:
	area_2d = self.get_node("Area2D")
	# 每张卡的刀身抖法错开一点，手牌才像一张张手打的而不是复制粘贴
	body.variant = randi()
	# 判定区跟刀身同形状，右上那块空三角不该算在卡上
	var shape := ConvexPolygonShape2D.new()
	shape.points = PackedVector2Array(CardShard.SHARD)
	collision_shape.shape = shape
	area_2d.mouse_entered.connect(
		func():
			is_mouse_in_area = true
			block_focus()
	)
	area_2d.mouse_exited.connect(
		func():
			is_mouse_in_area = false
			block_unfocus()
	)
	# origin_position 不能在这里取：CardContainer(HBoxContainer) 是延迟排版的
	# _ready() 里读到的还是场景默认值 (0,0)
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	SignalBus.operand_filled.connect(_on_operand_filled)

func _input(event: InputEvent) -> void:
	# 按下时如果鼠标在方块内 就锁定拖拽状态 之后不再依赖 hover 判定
	if event.is_action_pressed("Mouse-Left") and is_mouse_in_area:
		# 这时容器已经排好版 记下来的才是真正的原位
		origin_position = self.position
		is_dragging = true
		_is_committed = false
		body.armed = true
	elif event.is_action_released("Mouse-Left"):
		# 只有正在拖的那张才回位，否则场上所有 OP 都会被重置到 origin_position
		if is_dragging:
			if self.position.distance_to(origin_position) > 200 and _operand_values[0] != EMPTY_OPERAND and _operand_values[1] != EMPTY_OPERAND:
				var payload := SignalBus.OperatorBlockRemovalRequestedPayload.new()
				payload.calculate_result = self.calculate_result
				payload.operator_block = self
				SignalBus.operator_block_dropped.emit(payload)
			self.position = origin_position
			is_dragging = false
			body.armed = false

func block_focus():
	_animate(FOCUS_SCALE)

func block_unfocus():
	_animate(1.0)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if is_dragging:
		self.global_position = get_global_mouse_position()

## 只动 Area2D，不动 self：self 由 HBoxContainer 排版，手改 position 会被重排覆盖
func _animate(target_scale: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(area_2d, "scale", Vector2.ONE * target_scale, DURATION)
	# 围绕 PIVOT_OFFSET 缩放的位移补偿：不动点是 P 时，原点需偏移 P * (1 - s)
	_tween.parallel().tween_property(area_2d, "position", PIVOT_OFFSET * (1.0 - target_scale), DURATION)

## operand 槽位在运算块里的下标 Operand_A = 0, Operand_B = 1
func operand_index(operand : Area2D) -> int:
	if operand == operand_a:
		return 0
	if operand == operand_b:
		return 1
	return -1

## 数字块被放进某个 operand 时触发
func _on_operand_filled(payload : SignalBus.OperandFilledPayload):
	if payload.operator_block != self:
		return
	var index := payload.operand_index
	if index < 0 or index >= _operand_values.size():
		return
	if _operand_values[index] != EMPTY_OPERAND:
		return
	_operand_values[index] = payload.number_block_value
	_update_output()

## 两个操作数都填了才算一次运算(现在是加法 之后按运算块的类型来)
func _update_output():
	if _operand_values[0] == EMPTY_OPERAND or _operand_values[1] == EMPTY_OPERAND:
		return
	calculate_result = _operand_values[0] + _operand_values[1]
	output_label.text = str(calculate_result)
