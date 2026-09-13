extends Node
class_name EnemySystem

var enemy_state := EnemyState.new()

func init(battle_system : BattleSystem):
	for i in range(enemy_state.enemies.size()):
		var enemy_node : Node2D = enemy_state.enemies[i].enemy_packed_scene.instantiate()
		battle_system.root.get_node("Entities").get_node("EnemiesContainer").add_child(enemy_node)
		enemy_node.position = IsoFloor.mirror(IsoFloor.ANCHOR)
	

func handle_action():
	pass
