extends Node

@onready var map_system: MapSystem = $MapControl/MapSystem

var tres : TestSelectableNode = load("res://Test/MapFieldTest/test_node.tres")

func _ready() -> void:
	map_system.selectable_node_system.selectable_node_state.selectable_node_datas = tres.nodes
	map_system.init_map()
