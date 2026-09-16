extends RefCounted

class_name PlayerState

@warning_ignore("unused_private_class_variable")

var _floor: int = 0
var gold: int = 0
var player_max_hp = 100
var player_hp: int = 100:
	set(value):
		player_hp = clampi(value, 0, player_max_hp)
var draw_cards_per_turn : int = 2
var relics: Array = []
var opertor_deck_inventory: Array[Block] = []
var float_amplitude : float = 0.0:
	set(value):
		player_node.float_amplitude = value

const player_packed_scene : PackedScene = preload("res://Entities/Player/player.tscn")
var player_node : Node2D = self.player_packed_scene.instantiate()
