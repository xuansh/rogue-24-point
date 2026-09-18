extends Node

class_name BufferSystem

var buffer_state := BufferState.new()
var battle_system : BattleSystem
var block_system : BlockSystem

func init(_battle_system : BattleSystem):
	self.battle_system = _battle_system
	self.block_system = _battle_system.block_system
	SignalBus.number_block_in_buffer_poped.connect(resort_number_blocks_in_slots)
	SignalBus.number_block_in_buffer_poped.connect(_on_block_poped_from_buffer)

func spawn_number_block_in_buffer(value : int):
	var slots_root = self.battle_system.buffer_slots

	# 满了 就弹出最前面的方块
	# 弹出走 number_block_in_buffer_poped 信号 由 resort_number_blocks_in_slots 统一处理
	# 该处理是同步的 所以下面立刻就能拿到空出来的槽位
	if _get_first_free_slot(slots_root) == null:
		_pop_front_number_block()

	# 新方块放进最后一个空槽
	var free_slot = _get_first_free_slot(slots_root)
	if free_slot == null:
		return
	var node := self.block_system.block_state.number_block_packed_scene.instantiate() as NumberBlock
	node.value = value
	free_slot.add_child(node)
	_snap_block_to_slot(node)
	self.buffer_state.number_block_nodes.append(node)

func resort_number_blocks_in_slots(payload : SignalBus.NumberBlockInBufferPopedPayload):
	var block := payload.poped_number_block
	if block.get_parent() != null:
		block.get_parent().remove_child(block)
	_forget_block(block)
	block.queue_free()
	_compact_slots()

func _pop_front_number_block():
	var block := _get_block_in_slot(self.battle_system.buffer_slots.get_child(0))
	if block == null:
		return
	
	var payload1 := SignalBus.NumberBlockInBufferPopedPayload.new()
	payload1.poped_number_block = block
	SignalBus.number_block_in_buffer_poped.emit(payload1)
	
	var payload2 := SignalBus.FrontNumberBlockInBufferPopedPayload.new()
	payload2.poped_number_block = block
	SignalBus.front_number_block_in_buffer_poped.emit(payload2)

## 把所有方块按顺序压到最前面的槽位 空槽留在最后
func _compact_slots():
	var slots_root = self.battle_system.buffer_slots
	var alive_number_blocks : Array[NumberBlock] = []
	for i in range(slots_root.get_child_count()):
		var block := _get_block_in_slot(slots_root.get_child(i))
		if block != null:
			alive_number_blocks.append(block)
	for j in range(alive_number_blocks.size()):
		var target_slot = slots_root.get_child(j)
		if alive_number_blocks[j].get_parent() != target_slot:
			# 第二个参数为 false 否则 reparent 会保留全局坐标 方块在屏幕上不会移动
			alive_number_blocks[j].reparent(target_slot, false)
		_snap_block_to_slot(alive_number_blocks[j])

func _get_block_in_slot(slot : Node) -> NumberBlock:
	for child in slot.get_children():
		if child is NumberBlock:
			return child as NumberBlock
	return null

func _get_first_free_slot(slots_root : Node):
	for slot in slots_root.get_children():
		if _get_block_in_slot(slot) == null:
			return slot
	return null

## 槽位和方块都用中心锚点 位置归零即居中
func _snap_block_to_slot(block : NumberBlock):
	block.position = Vector2(32, 32)

## 方块离开 buffer 后 从 buffer_state 里移除 避免留下失效引用
func _forget_block(block : NumberBlock):
	self.buffer_state.number_block_nodes.erase(block)

func _on_block_poped_from_buffer(payload : SignalBus.NumberBlockInBufferPopedPayload):
	print(payload.poped_number_block.value)
