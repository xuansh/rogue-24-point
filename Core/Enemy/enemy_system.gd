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
				handle_action(state.enemy_node)
		)
		
		SignalBus.enemy_turn_exited.connect(
			func(payload : SignalBus.EnemyTurnExitedPayload):
				payload._enemy_state.float_amplitude = 10
		)

func handle_action(node : Node2D):
	for i in range(enemies_state.size()):
		var state := enemies_state[i]
		#var label : Label = state.enemy_node.get_node("Label")
		match state.enemy_data.current_behavior:
			state.enemy_data.Behavior.SPAWN_BLOCK:
				self.buffer_system.spawn_number_block_in_buffer()
			state.enemy_data.Behavior.DEFENCE:
				print("Defence")
