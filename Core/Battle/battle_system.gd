extends Node

class_name BattleSystem
 
@export var root : Node
var card_container : Control
var buffer_slots : HBoxContainer
var end_button : Button

var battle_state := BattleState.new()
var enemy_system := EnemySystem.new()
var deck_system := DeckSystem.new()
var turn_system := TurnSystem.new()
var player_system := PlayerSystem.new()
var block_system := BlockSystem.new()
var buffer_system := BufferSystem.new()

func init_battle():
	init()
	player_system.init(self)
	enemy_system.init(self)
	deck_system.init(self)
	turn_system.init(self)
	block_system.init(self)
	buffer_system.init(self)

func init():
	card_container = root.get_node("BattleUI").get_node("Hand").get_node("CardContainer")
	buffer_slots = root.get_node("BattleUI").get_node("Buffer").get_node("Slots")
	end_button = root.get_node("BattleUI").get_node("EndTurnButton")
