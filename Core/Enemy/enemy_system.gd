extends Node
class_name EnemySystem

var enemies_state : Array[EnemyState]

func init(battle_system : BattleSystem):
	for i in range(enemies_state.size()):
		var state := enemies_state[i]
		var enemy_node : Node2D = state.enemy_data.enemy_packed_scene.instantiate()
		battle_system.root.get_node("Entities").get_node("EnemiesContainer").add_child(enemy_node)
		enemy_node.position = IsoFloor.mirror(IsoFloor.ANCHOR)
		state.enemy_node = enemy_node
		
	SignalBus.enemy_turn_started.connect(
		func(payload : SignalBus.EnemyTurnStartedPayload):
			payload._enemy_state.float_amplitude = 10
	)
	
	SignalBus.enemy_turn_exited.connect(
		func(payload : SignalBus.EnemyTurnExitedPayload):
			payload._enemy_state.float_amplitude = 10
	)
func handle_action():
	pass
