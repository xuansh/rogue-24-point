extends Node

class_name MapSystem


var player_system := PlayerSystem.new()

var map_state : MapState
@export var root : Node

func init_map():
	player_system.map_init(self)

func _ready() -> void:
	init_map()
