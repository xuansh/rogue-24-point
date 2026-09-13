extends Node

class_name BattleSystem

@export var root : Node

var battle_state := BattleState.new()
var enemy_system := EnemySystem.new()
var deck_system := DeckSystem.new()
var turn_system := TurnSystem.new()
var player_system := PlayerSystem.new()

func init_battle():
	player_system.init(self)
	enemy_system.init(self)
	deck_system.init(self)
	turn_system.init(self, enemy_system, deck_system, player_system)
