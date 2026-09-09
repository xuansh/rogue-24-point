extends Node

class_name TurnSystem

enum TurnPhase{
	IDLE,
	PLAYER_TURN,
	ENEMY_TURN,
	TRANSITION,
	END
}


# 战斗循环的逻辑
func start_player_turn():
	pass

func end_player_turn():
	pass

func start_enemies_turn():
	pass

func start_enemy_turn():
	pass

func end_enemies_turn():
	start_player_turn()
