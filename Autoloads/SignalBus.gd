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
	var enemy_hp : int
	var enemy_max_hp : int
signal battle_field_inited(payload : BattleFieldInitedPayload)

#endregion

#region PlayerSystem
class PlayerHPChangedPayload extends RefCounted:
	var player_hp : int
	var player_max_hp : int
signal player_hp_changed(payload : PlayerHPChangedPayload)

#endregion

#region EnemySystem
class EnemyHPChangedPayload extends RefCounted:
	var enemy_hp : int
	var enemy_max_hp : int
signal enemy_hp_changed(payload : EnemyHPChangedPayload)
#endregion

#region BlockSystem
class PileDrawStartedPayload extends RefCounted:
	var block_class_name : String
signal pile_draw_started(payload : PileDrawStartedPayload)
#endregion

#region BufferSystem
class NumberBlockRemovalRequestedPayload extends RefCounted:
	var removal_requested_number_block : NumberBlock
signal number_block_removal_requested(payload : NumberBlockRemovalRequestedPayload)

class BufferOverflowedPayload extends RefCounted:
	var removal_requested_number_block : NumberBlock
signal buffer_overflowed(payload : BufferOverflowedPayload)
#endregion

#region DeckSystem
class OperandFilledPayload extends RefCounted:
	var operator_block : OperatorBlock
	var operand_index : int
	var number_block_value : int
signal operand_filled(payload : OperandFilledPayload)

class OperatorBlockDroppedPayload extends RefCounted:
	var calculate_result : int
	var operator_block : OperatorBlock
signal operator_block_dropped(payload : OperatorBlockDroppedPayload)

class OperatorBlockRemovalRequestedPayload extends RefCounted:
	var calculate_result : int
	var operator_block : OperatorBlock
signal operator_block_removal_requested(payload : OperatorBlockRemovalRequestedPayload)
#endregion
