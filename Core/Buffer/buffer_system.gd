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

func spawn_number_block_in_buffer():
	var slots = self.battle_system.buffer_slots
	var children = slots.get_children()
	for i in children.size():
		if children[i].get_child(0) == null:
			var node = self.block_system.block_state.number_block_packed_scene.instantiate()
			children[i].add_child(node)
			self.buffer_state.number_block_nodes.append(node)
			return

func add_number(num):
	if slots.size() >= MAX_SIZE:
		var pop_num = slots.pop_front()
	slots.push_back(num)
