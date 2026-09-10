extends Node
var _floor: int = 0
var gold: int = 0

var player_hp = 100
var player_max_hp = 100

var relics: Array = []

var opertor_deck_inventory: Array = []

func init_run():
	reset()

func reset() -> void:
	_floor = 0
	player_max_hp = 100
	player_hp = player_max_hp
	
	gold = 0
	relics.clear()
	opertor_deck_inventory.clear()
	
	print(
		"Reset Successfully: ",
		"player_hp: ",
		player_hp,
		", player_max_hp: ",
		player_max_hp,
		", gold: ",
		gold,
		", relics: ",
		relics,
		", Operator Deck Inventory: ",
		opertor_deck_inventory
	)
