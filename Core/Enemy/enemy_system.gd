extends Node
class_name EnemySystem

var enemies_state : Array[EnemyState]
var buffer_system : BufferSystem

func init(battle_system : BattleSystem):
	self.buffer_system = battle_system.buffer_system
	for i in range(enemies_state.size()):
		var state := enemies_state[i]
		state.enemy_node = state.enemy_data.enemy_packed_scene.instantiate()
		battle_system.root.get_node("Entities").get_node("EnemiesContainer").add_child(state.enemy_node)
		state.enemy_node.position = IsoFloor.mirror(IsoFloor.ANCHOR)
		SignalBus.enemy_turn_started.connect(
			func(payload : SignalBus.EnemyTurnStartedPayload):
				payload._enemy_state.float_amplitude = 10
				handle_action(state)
		)
		SignalBus.enemy_turn_exited.connect(
			func(payload : SignalBus.EnemyTurnExitedPayload):
				payload._enemy_state.float_amplitude = 10
		)
		SignalBus.operator_block_dropped.connect(_on_block_dropped)

		# battle_field_inited 由 BattleSystem 在所有子系统初始化完之后统一发射
		state.spawn_block_value = state.enemy_data.random_value_spawn_block()
		self.buffer_system.spawn_number_block_in_buffer(state.spawn_block_value)

func handle_action(state : EnemyState):
	#var label : Label = state.enemy_node.get_node("Label")
	match state.enemy_data.current_behavior:
		state.enemy_data.Behavior.SPAWN_BLOCK:
			state.spawn_block_value = state.enemy_data.random_value_spawn_block()
			self.buffer_system.spawn_number_block_in_buffer(state.spawn_block_value)
			#state.enemy_data.current_behavior = state.enemy_data.Behavior.DEFENCE
		state.enemy_data.Behavior.DEFENCE:
			state.enemy_data.current_behavior = state.enemy_data.Behavior.SPAWN_BLOCK

func decease_hp(num : int, index : int = 0):
	self.enemies_state[index].enemy_data.hp -= num

func _on_block_dropped(payload : SignalBus.OperatorBlockDroppedPayload):
	decease_hp(payload.calculate_result)
	var changed_payload := SignalBus.EnemyHPChangedPayload.new()
	changed_payload.enemy_hp = self.enemies_state[0].enemy_data.hp
	changed_payload.enemy_max_hp = self.enemies_state[0].enemy_data.max_hp
	SignalBus.enemy_hp_changed.emit(changed_payload)
