extends RefCounted
class_name BattleState

enum BattleResult{
	NONE,
	PLAYER_WIN,
	PLAYER_LOSE
}

var player_hp : int
var player_max_hp : int
var deck_inventory : Array = []

var current_turn : int = 0
var battle_result : BattleResult = BattleResult.NONE
