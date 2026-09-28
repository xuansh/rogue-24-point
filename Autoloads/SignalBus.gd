extends Node
@warning_ignore_start("unused_signal")

#region TurnSystem
#signal turn_phase_changed(new_phase : TurnSystem.TurnPhase)
class PlayerTurnStartedPayload extends RefCounted:
	var draw_cards_per_turn : int
signal player_turn_started(payload : PlayerTurnStartedPayload)

## 玩家回合结束发出的信号
## 目前有: [member operator_block]
class PlayerTurnExitedPayload extends RefCounted:
	var operator_block : OperatorBlock
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
	var changed_hp : int
	var enemy_hp : int
	var enemy_max_hp : int
signal enemy_hp_changed(payload : EnemyHPChangedPayload)

## 目前什么也没有
class EnemyDiedPayload extends RefCounted:
	pass
## 敌人死亡时发出的信号
signal enemy_died(payload : EnemyDiedPayload)
#endregion

#region BlockSystem
class PileDrawStartedPayload extends RefCounted:
	var deck_block : DeckBlock
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

class OperatorBlockUsageRequestPayload extends RefCounted:
	var calculate_result : int
	var operator_block : OperatorBlock
## 请求使用某一个[member OperatorBlock]时发出的信号，与[signal operator_block_removal_requested]有顺连关系
signal operator_block_usage_request_payload(payload : OperatorBlockUsageRequestPayload)

## 该类有: [member calculate_result] [member operator_block]
class OperatorBlockRemovalRequestedPayload extends RefCounted:
	var calculate_result : int
	var operator_block : OperatorBlock
## 请求移除某一个[member OperatorBlock]时发出的信号
signal operator_block_removal_requested(payload : OperatorBlockRemovalRequestedPayload)
#endregion
