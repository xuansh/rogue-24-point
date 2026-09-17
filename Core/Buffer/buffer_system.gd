extends Node

class_name BufferSystem

const MAX_SIZE := 4

var buffer_state := BufferState.new()
var battle_system : BattleSystem
var block_system : BlockSystem
var slots: Array = []

func init(_battle_system : BattleSystem):
	slots.clear()
	self.battle_system = _battle_system
	self.block_system = _battle_system.block_system
	SignalBus.number_block_in_slots_poped.connect(resort_number_blocks_in_slots)

func spawn_number_block_in_buffer(value : int):
	var HBoxslots = self.battle_system.buffer_slots
	var children = HBoxslots.get_children()
	for i in children.size():
		if children[i].get_child(1) == null:
			var node = self.block_system.block_state.number_block_packed_scene.instantiate() as NumberBlock
			node.value = value
			children[i].add_child(node)
			self.buffer_state.number_block_nodes.append(node)
			slots.push_back(value)
			return
	if slots.size() >= MAX_SIZE:
		pop_front_number_blocks_in_slots()

func resort_number_blocks_in_slots(payload : SignalBus.NumberBlockInSlotsPopedPayload):
	await self.battle_system.root.get_tree().process_frame
	var alive_number_blocks : Array[NumberBlock] = []
	for i in range(MAX_SIZE):
		var slot = self.battle_system.buffer_slots.get_child(i)
		if slot.get_child(1) != null:	alive_number_blocks.append(slot.get_child(1))
	for j in range(alive_number_blocks.size()):
		alive_number_blocks[j].reparent(self.battle_system.buffer_slots.get_child(j))

func pop_front_number_blocks_in_slots():
	var slot = self.battle_system.buffer_slots.get_child(0)
	if slot.get_child(1) != null:
		var payload := SignalBus.NumberBlockInSlotsPopedPayload.new()
		SignalBus.number_block_in_slots_poped.emit(payload)
		slot.get_child(1).queue_free()
	

#func add_number(num):
			#if slots.size() >= MAX_SIZE:
				#var pop_num = slots.pop_front()
