extends Node

class_name TurnSystem

var battle_system : BattleSystem
var enemy_system : EnemySystem
var deck_system : DeckSystem
var player_system : PlayerSystem

var current_phase : TurnPhase

enum TurnPhase{
	IDLE,			# 战斗开始的准备阶段
	PLAYER_TURN,	# 玩家回合 一般来说 一场战斗的开始 都是玩家先手 不排除有道具让敌人先手的可能
	ENEMY_TURN,		# 敌人回合 有一定情况 有多个敌人 依次进行回合
	TRANSITION, 	# 一般是玩家回合 和 敌人回合都结束一次之后轮换的这个过程.
	END				# 战斗结束 只有两种情况：玩家死亡 或者 敌人全部死亡
}


func init(_battle_system : BattleSystem, _enemy_system: EnemySystem, _deck_system: DeckSystem, _player_system) -> void:
	self.battle_system = _battle_system
	self.enemy_system = _enemy_system
	self.deck_system = _deck_system
	self.player_system = _player_system

	start_battle()

## 改变回合 
func change_turn_phase(new_phase : TurnPhase):
	current_phase = new_phase
	#SignalBus.turn_phase_changed.emit(new_phase)
	match new_phase:
		TurnPhase.PLAYER_TURN:
			pass

func start_battle():
	#change_turn_phase(TurnPhase.IDLE)
	
	start_player_turn()

#region 战斗循环的逻辑

##
func start_player_turn():
	battle_system.battle_state.current_turn += 1
	#ALERT change_turn_phase(TurnPhase.PLAYER_TURN)
	
	deck_system.draw_draw_pile(player_system.player_state.draw_cards_per_turn)
	var payload := SignalBus.PlayerTurnStartedPayload.new()
	SignalBus.player_turn_started.emit(payload)

func end_player_turn():
	var payload := SignalBus.PlayerTurnExitedPayload.new()
	SignalBus.player_turn_exited.emit(payload)
	
	start_enemies_turn()

func start_enemies_turn():
	var enemies_state = enemy_system.enemies_state
	for i in range(enemies_state.size()):
		start_enemy_turn(i)
	
	end_enemies_turn()

func start_enemy_turn(index : int):
	var e_state : EnemyState = enemy_system.enemies_state[index]
	var payload := SignalBus.EnemyTurnStartedPayload.new()
	payload._enemy_state = e_state
	SignalBus.enemy_turn_started.emit(payload)
	change_turn_phase(TurnPhase.ENEMY_TURN)

func end_enemy_turn(index : int):
	var e_state : EnemyState = enemy_system.enemies_state[index]
	var payload := SignalBus.EnemyTurnExitedPayload.new()
	payload._enemy_state = e_state
	SignalBus.enemy_turn_exited.emit(payload)
	
func end_enemies_turn():
	start_transition_of_turn()

func start_transition_of_turn():
	var b_state = battle_system.battle_state
	
	change_turn_phase(TurnPhase.TRANSITION)
	if b_state.current_turn >= 1:
		end_battle()
	else:
		start_player_turn()



func end_battle():
	change_turn_phase(TurnPhase.END)

#endregion

func _on_turn_phase_changed(new_phase : TurnPhase):
	pass



#region ALERT
#func dra
#endregion
