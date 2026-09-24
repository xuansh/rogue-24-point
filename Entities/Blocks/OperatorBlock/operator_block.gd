extends Block

class_name OperatorBlock 

@onready var operand_a : Area2D = $Area2D/Operand_A
@onready var operand_b : Area2D = $Area2D/Operand_B
@onready var output_label : RichTextLabel = $Area2D/OutputRichTextLabel
@onready var body : CardShard = $Area2D/Body
@onready var collision_shape : CollisionShape2D = $Area2D/CollisionShape2D
@onready var cost_label : RichTextLabel = $Area2D/CostBadge/CostLabel
@onready var cost_badge : Panel = $Area2D/CostBadge

var origin_position : Vector2
var calculate_result : int
## 这张牌的打出费用 由牌库资料(DeckBlock)在生成时写入
## 必须在 add_child() 之前赋值: add_child 会触发 _ready() 拿它填 label
var cost : int = 0
## 本场战斗的费用池 同样由 BlockSystem 在 add_child 之前注入
var battle_state : BattleState

## 聚焦时的放大倍率
const FOCUS_SCALE := 1.12
## 缩放围绕卡面内部的这个点生效（y 向下为正），比中心低一点，放大时视觉上像"抬起来"
## 这点必须在卡面内部，否则碰撞区会从鼠标下面移开，导致 enter/exit 反复抖动
const PIVOT_OFFSET := Vector2(0, 28)
## 过渡时长
const DURATION := 0.12
## 空槽位的标记 数字块的值是 1~9 不会撞上
const EMPTY_OPERAND := -1
## 费用不足时徽章闪的红
const NO_COST_TINT := Color(1.0, 0.35, 0.35)

var _tween : Tween
## 徽章闪红的补间 跟 _tween 分开: 焦点缩放随时可能打断它, 共用会被 kill 掉
var _badge_tween : Tween
## 两个操作数当前的值 下标 0 = Operand_A, 1 = Operand_B
var _operand_values : Array[int] = [EMPTY_OPERAND, EMPTY_OPERAND]

func _ready() -> void:
	area_2d = self.get_node("Area2D")
	cost_label.text = str(cost)
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
			_resolve_drop()
			self.position = origin_position
			is_dragging = false
			body.armed = false

## 松手时结算这次拖放。
## 判定顺序有意义: 距离和操作数先判、费用最后判。反过来的话，
## 一张没填满、也没真的拖出去的牌会先被扣费
func _resolve_drop() -> void:
	if self.position.distance_to(origin_position) <= 200:
		return
	if _operand_values[0] == EMPTY_OPERAND or _operand_values[1] == EMPTY_OPERAND:
		return
	if not battle_state.try_spend_cost(cost):
		_flash_no_cost()
		return
	var payload := SignalBus.OperatorBlockRemovalRequestedPayload.new()
	payload.calculate_result = self.calculate_result
	payload.operator_block = self
	# 发 removal_requested 而不是 dropped: 前者给 DeckSystem 移牌，
	# 后者由 DeckSystem 移完之后再发，给 EnemySystem 结算伤害
	SignalBus.operator_block_removal_requested.emit(payload)

## 费用不足的反馈: 徽章闪一下红再淡回原色。
## 用 modulate 而不是改 StyleBoxFlat: 那个 stylebox 是场景内的 SubResource，
## 所有卡共用同一份，直接改会让整手牌一起变红
func _flash_no_cost() -> void:
	if _badge_tween and _badge_tween.is_valid():
		_badge_tween.kill()
	cost_badge.modulate = NO_COST_TINT
	_badge_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_badge_tween.tween_property(cost_badge, "modulate", Color.WHITE, 0.45)

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
