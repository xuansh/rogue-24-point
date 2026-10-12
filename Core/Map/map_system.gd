extends Node

class_name MapSystem


var player_system := PlayerSystem.new()
var selectable_node_system := SelectableNodeSystem.new()

var map_state := MapState.new()
@export var root : Node
var selectable_node_container : Node2D
var path_guide : PathGuide

func init_map():
	init()
	player_system.map_init(self)
	selectable_node_system.map_init(self)

func init():
	selectable_node_container = root.get_node("Entities").get_node("SelectableNodeContainer")
	path_guide = root.get_node("Entities").get_node("PathGuide")
