extends Node

class_name BattleSystem

var battle_state := BattleState.new()
var enemy_system := EnemySystem.new()
var deck_system := DeckSystem.new()
var turn_system := TurnSystem.new()

func init_battle():
	init_player()
	enemy_system.init()
	deck_system.init(battle_state)
	turn_system.init(battle_state, enemy_system.enemy_state)

func init_player():
	battle_state.player_hp = Run.player_hp
	battle_state.player_max_hp = Run.player_max_hp
	battle_state.deck_inventory = Run.opertor_deck_inventory
	
	#TEST
	print(
		"Init Player: ",
		"Player HP: ",
		battle_state.player_hp,
		", Player Max HP: ",
		battle_state.player_max_hp,
		", Deck Inventory: ",
		battle_state.deck_inventory,
	)
