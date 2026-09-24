extends RefCounted
class_name BattleState

enum BattleResult{
	NONE,
	PLAYER_WIN,
	PLAYER_LOSE
}

var player_hp : int
var player_max_hp : int
## 本场战斗当前的费用点。上限在 PlayerState.max_cost_point，
## 这里存的是这一场打到现在还剩多少，每回合开始回填
var cost_point : int = 0
var deck_inventory : Array[DeckBlock] = []
var extra_cards_per_turn : int = 0

var current_turn : int = 0
var battle_result : BattleResult = BattleResult.NONE

## 费用唯一的扣款入口: 够就扣掉并回 true，不够原样不动回 false。
## 判断和扣款必须待在同一支里，拆成两支迟早会扣两次或扣成负数
func try_spend_cost(amount : int) -> bool:
	if amount > cost_point:
		return false
	cost_point -= amount
	return true
