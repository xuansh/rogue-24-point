extends Node

class_name BattleSystem
 
@export var root : Node
var card_container : Control

var battle_state := BattleState.new()
var enemy_system := EnemySystem.new()
var deck_system := DeckSystem.new()
var turn_system := TurnSystem.new()
var player_system := PlayerSystem.new()
var block_system := BlockSystem.new()

func init_battle():
	init()
	player_system.init(self)
	enemy_system.init(self)
	deck_system.init(self)
	turn_system.init(self, enemy_system, deck_system, player_system)
	block_system.init(self)
	
func init():
	card_container = root.get_node("BattleUI").get_node("Hand").get_node("CardContainer")
