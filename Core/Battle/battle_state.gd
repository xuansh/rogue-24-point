extends RefCounted
class_name BattleState

enum BattleResult{
	NONE,
	PLAYER_WIN,
	PLAYER_LOSE
}

var player_hp : int
var player_max_hp : int
## 本场战斗的费用上限，开战时从 PlayerState.max_cost_point 复制过来，
## 之后本层自己说了算（扣费夹取、发信号都用它，不用再回头问 PlayerState）
var max_cost_point : int = 0
## 本场战斗当前的费用点。
## 这里存的是这一场打到现在还剩多少，每回合开始回填。
## 所有改动都必须走这个 setter：夹取和 cost_point_changed 只在这一处，
## 分散赋值迟早会有一条路漏发信号、能量罐就停在旧数字上
var cost_point : int = 0 : set = _set_cost_point

func _set_cost_point(value : int) -> void:
	cost_point = clampi(value, 0, max_cost_point)
	var payload := SignalBus.CostPointChangedPayload.new()
	payload.cost_point = cost_point
	payload.max_cost_point = max_cost_point
	SignalBus.cost_point_changed.emit(payload)

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
