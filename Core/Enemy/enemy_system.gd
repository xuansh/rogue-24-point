extends Node
class_name EnemySystem

var enemy_state := EnemyState.new()

func init_enemies():
	for i in range(enemy_state.enemies.size()):
		#TEST
		print(
			"Init Enemy[",
			i,
			"]: ",
			"Enemy HP: ",
			enemy_state.enemies[i].hp,
			", Enemy Max HP: ",
			enemy_state.enemies[i].max_hp,
			", Enemy Current Behavior: ",
			enemy_state.enemies[i].current_behavior
		)
