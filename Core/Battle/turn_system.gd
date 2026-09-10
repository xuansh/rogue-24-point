extends Node

class_name TurnSystem

var battle_state : BattleState
var enemy_state : EnemyState
var current_phase : TurnPhase

enum TurnPhase{
	IDLE,			# 战斗开始的准备阶段
	PLAYER_TURN,	# 玩家回合 一般来说 一场战斗的开始 都是玩家先手 不排除有道具让敌人先手的可能
	ENEMY_TURN,		# 敌人回合 有一定情况 有多个敌人 依次进行回合
	TRANSITION, 	# 一般是玩家回合 和 敌人回合都结束一次之后轮换的这个过程.
	END				# 战斗结束 只有两种情况：玩家死亡 或者 敌人全部死亡
}

signal turn_phase_changed(new_phase : TurnPhase)

func init(_battle_state : BattleState, _enemy_state: EnemyState) -> void:
	self.battle_state = _battle_state
	self.enemy_state = _enemy_state
	self.turn_phase_changed.connect(_on_turn_phase_changed)
	
	#region TEST
	print("Init Turn System: ")
	#endregion
	
	start_battle()
	
func start_battle():
	
	#region TEST
	print("Start a Battle -> ")
	#endregion
	
	change_turn_phase(TurnPhase.IDLE)
	
	start_player_turn()

# 战斗循环的逻辑
func start_player_turn():
	
	battle_state.current_turn += 1
	
	#region TEST
	print("Start Player Turn -> ")
	#endregion
	
	change_turn_phase(TurnPhase.PLAYER_TURN)
	
	end_player_turn()

func end_player_turn():
	
	#region TEST
	print("End Player Turn -> ")
	#endregion
	
	start_enemies_turn()

func start_enemies_turn():
	
	#region TEST
	print("Start Enemies Turns -> ")
	#endregion
	
	for i in range(enemy_state.enemies.size()):
		start_enemy_turn(i)
	
	end_enemies_turn()

func start_enemy_turn(index : int):
	
	#region TEST
	print(
		"Start Enemy",
		index,
		" Turn -> "
	)
	#endregion
	
	change_turn_phase(TurnPhase.ENEMY_TURN)
	
	end_enemy_turn(index)

func end_enemy_turn(index : int):
	
	#region TEST
	print(
		"End Enemy",
		index,
		" Turn -> "
	)
	#endregion
	
func end_enemies_turn():
	
	#region TEST
	print("End Enemies Turns ")
	#endregion
	
	
	start_transition_of_turn()

func start_transition_of_turn():
	
	#region TEST
	print("Start Transition: ", "Now Turn is ", battle_state.current_turn)
	#endregion
	
	change_turn_phase(TurnPhase.TRANSITION)
	if battle_state.current_turn == 2:
		end_battle()
	else:
		start_player_turn()

func change_turn_phase(new_phase : TurnPhase):
	current_phase = new_phase
	turn_phase_changed.emit(new_phase)

func end_battle():
	
	#region TEST
	print("Battle Ended")
	#endregion
	
	change_turn_phase(TurnPhase.END)

func _on_turn_phase_changed(new_phase : TurnPhase):
	print("Now Phase is ", new_phase)
