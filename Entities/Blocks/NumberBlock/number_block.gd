extends Block

class_name NumberBlock

## 一个数字块的值
var value : int

@onready var num_rich_text_label: RichTextLabel = $Area2D/NumRichTextLabel

## 运算块 operand 槽位的组名(见 OperatorBlock.tscn)
const OPERAND_GROUP := "HandOperatorBlockOperandArea"
## operand 被占用时 它下面会挂一个这个名字的小数字块
const OPERAND_NUMBER_BLOCK_NAME := "OperandNumberBlock"
const OPERAND_NUMBER_BLOCK_SCENE = preload("uid://me7p8dhhguec")

func _ready() -> void:
	num_rich_text_label.text = str(self.value)
	area_2d = self.get_node("Area2D")
	area_2d.mouse_entered.connect(
		func():
			is_mouse_in_area = true
	)
	area_2d.mouse_exited.connect(
		func():
			is_mouse_in_area = false
	)

func _input(event: InputEvent) -> void:
	# 按下时如果鼠标在方块内 就锁定拖拽状态 之后不再依赖 hover 判定
	if event.is_action_pressed("Mouse-Left") and is_mouse_in_area:
		is_dragging = true
		_is_committed = false
	elif event.is_action_released("Mouse-Left"):
		# 落点只在松手时判定一次 避免同时压住两个 operand 时两个都被赋值
		if is_dragging:
			_release()
		is_dragging = false

func _process(delta: float) -> void:
	if is_dragging:
		self.global_position = get_global_mouse_position()

## 松手时选出唯一的 operand 没选中就回原位
func _release():
	if _is_committed:
		return
	var operand := _pick_operand()
	if operand == null:
		_snap_back()
		return
	var target_operator := _find_operator(operand)
	if target_operator == null:
		_snap_back()
		return
	_commit(operand, target_operator)

## 候选槽位里取离鼠标最近的一个 已占用的跳过 同时压住两个也只会选一个
func _pick_operand() -> Area2D:
	var mouse := get_global_mouse_position()
	var candidates : Array[Area2D] = []
	for area in area_2d.get_overlapping_areas():
		if area.is_in_group(OPERAND_GROUP):
			candidates.append(area)
	# 物理重叠可能比输入慢一帧 再用"鼠标点是否落在槽位矩形内"兜底
	for node in get_tree().get_nodes_in_group(OPERAND_GROUP):
		var area := node as Area2D
		if area != null and not candidates.has(area) and _contains_point(area, mouse):
			candidates.append(area)

	var best : Area2D = null
	var best_distance := INF
	for area in candidates:
		if _is_operand_filled(area):
			continue
		var distance := mouse.distance_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			best = area
	return best

func _commit(operand : Area2D, target_operator : OperatorBlock):
	_is_committed = true

	# 小数字块放进槽位里
	var number_visual := OPERAND_NUMBER_BLOCK_SCENE.instantiate()
	number_visual.get_node("Area2D/NumRichTextLabel").text = str(self.value)
	operand.add_child(number_visual)

	# 通知运算块这个槽位被填了
	var filled_payload := SignalBus.OperandFilledPayload.new()
	filled_payload.operator_block = target_operator
	filled_payload.operand_index = target_operator.operand_index(operand)
	filled_payload.number_block_value = self.value
	SignalBus.operand_filled.emit(filled_payload)

	# 再让 buffer 把自己移走(它会顺带压缩剩下的方块)
	var requested_payload := SignalBus.NumberBlockRemovalRequestedPayload.new()
	requested_payload.removal_requested_number_block = self
	SignalBus.number_block_removal_requested.emit(requested_payload)

## 没放到任何槽位上 回原位(方块和槽位都是中心锚点 32,32 就是槽位中心)
func _snap_back():
	self.position = Vector2(32, 32)

func _contains_point(operand : Area2D, point : Vector2) -> bool:
	var panel := operand.get_node_or_null("Panel") as Control
	return panel != null and panel.get_global_rect().has_point(point)

func _is_operand_filled(operand : Area2D) -> bool:
	return operand.get_node_or_null(OPERAND_NUMBER_BLOCK_NAME) != null

## operand 在运算块内部 沿父链向上找它属于哪个运算块
func _find_operator(node : Node) -> OperatorBlock:
	var current := node
	while current != null:
		if current is OperatorBlock:
			return current as OperatorBlock
		current = current.get_parent()
	return null
