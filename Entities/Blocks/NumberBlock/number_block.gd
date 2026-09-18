extends Block

class_name NumberBlock

## 一个数字块的值
var value : int


@onready var num_rich_text_label: RichTextLabel = $Area2D/NumRichTextLabel
@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	num_rich_text_label.text = str(self.value)
	area_2d.mouse_entered.connect(
		func():
			is_mouse_in_area = true
	)
	area_2d.mouse_exited.connect(
		func():
			is_mouse_in_area = false
	)
	area_2d.area_entered.connect(_on_area_2d_area_entered)

func _input(event: InputEvent) -> void:
	# 按下时如果鼠标在方块内 就锁定拖拽状态 之后不再依赖 hover 判定
	if event.is_action_pressed("Mouse-Left") and is_mouse_in_area:
		is_dragging = true
	elif event.is_action_released("Mouse-Left"):
		is_dragging = false
		self.position = Vector2(32, 32) # worth tweening

func _process(delta: float) -> void:
	if is_dragging:
		self.global_position = get_global_mouse_position()

func _on_area_2d_area_entered(area: Area2D):
	if area.is_in_group("HandOperatorBlockOperandArea"):
		var payload := SignalBus.NumberBlockInBufferPopedPayload.new()
		payload.poped_number_block = self
		SignalBus.number_block_in_buffer_poped.emit(payload)
