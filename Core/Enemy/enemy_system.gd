extends Node
class_name EnemySystem

var enemies_state : Array[EnemyState]
var buffer_system : BufferSystem

func init(battle_system : BattleSystem):
	self.buffer_system = battle_system.buffer_system
	# 这些信号只接一次。以前接在 for 循环里，多个敌人时每个敌人都会重复连接，
	# 一个敌人行动时所有敌人的 handle_action 都会被调用，产牌数量按敌人数量翻倍
	SignalBus.enemy_turn_started.connect(_on_enemy_turn_started)
	SignalBus.enemy_turn_exited.connect(_on_enemy_turn_exited)
	SignalBus.operator_block_dropped.connect(_on_block_dropped)

	for i in range(enemies_state.size()):
		var state := enemies_state[i]
		state.enemy_node = state.enemy_data.enemy_packed_scene.instantiate()
		battle_system.root.get_node("Entities").get_node("EnemiesContainer").add_child(state.enemy_node)
		state.enemy_node.position = IsoFloor.mirror(IsoFloor.ANCHOR)
		state.reset_behavior()

		# 开局先放一个数字块: 玩家先手, 第一回合 buffer 全空的话就没牌可打
		state.spawn_block_value = state.enemy_data.random_value_spawn_block()
		self.buffer_system.spawn_number_block_in_buffer(state.spawn_block_value)

func _on_enemy_turn_started(payload : SignalBus.EnemyTurnStartedPayload):
	payload._enemy_state.float_amplitude = 10
	handle_action(payload._enemy_state)

func _on_enemy_turn_exited(payload : SignalBus.EnemyTurnExitedPayload):
	payload._enemy_state.float_amplitude = 10

func handle_action(state : EnemyState):
	#var label : Label = state.enemy_node.get_node("Label")
	match state.current_behavior:
		EnemyData.Behavior.SPAWN_BLOCK:
			for i in range(maxi(state.enemy_data.spawn_block_count, 0)):
				state.spawn_block_value = state.enemy_data.random_value_spawn_block()
				self.buffer_system.spawn_number_block_in_buffer(state.spawn_block_value)
		EnemyData.Behavior.DEFENCE:
			# 这回合不产牌 (还没有防御数值, 先当作"停一回合")
			pass
	state.advance_behavior()

func decease_hp(num : int, index : int = 0):
	self.enemies_state[index].enemy_data.hp -= num

func _on_block_dropped(payload : SignalBus.OperatorBlockDroppedPayload):
	decease_hp(payload.calculate_result)
	var changed_payload := SignalBus.EnemyHPChangedPayload.new()
	changed_payload.enemy_hp = self.enemies_state[0].enemy_data.hp
	changed_payload.enemy_max_hp = self.enemies_state[0].enemy_data.max_hp
	SignalBus.enemy_hp_changed.emit(changed_payload)
