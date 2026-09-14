extends Node
@warning_ignore_start("unused_signal")

#region TurnSystem
#signal turn_phase_changed(new_phase : TurnSystem.TurnPhase)
class PlayerTurnStartedPayload extends RefCounted:
	pass
signal player_turn_started(payload : PlayerTurnStartedPayload)

class PlayerTurnExitedPayload extends RefCounted:
	pass
signal player_turn_exited(payload : PlayerTurnExitedPayload) 

class EnemyTurnStartedPayload extends RefCounted:
	var _enemy_state : EnemyState
signal enemy_turn_started(payload : EnemyTurnStartedPayload)

class EnemyTurnExitedPayload extends RefCounted:
	var _enemy_state : EnemyState
signal enemy_turn_exited(payload : EnemyTurnExitedPayload)
#endregion

#region BattleSystem
class BattleFieldInitedPayload extends RefCounted:
	var player_hp : int
	var player_max_hp : int
signal battle_field_inited(payload : BattleFieldInitedPayload)

#endregion

#region PlayerSystem
class PlayerHPChangedPayload extends RefCounted:
	var player_hp : int
	var player_max_hp : int
signal player_hp_changed(payload : PlayerHPChangedPayload)

#endregion
