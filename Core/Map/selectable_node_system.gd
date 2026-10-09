extends Node

class_name SelectableNodeSystem

var selectable_node_state : SelectableNodeState

func init():
	var count = selectable_node_state.selectable_node_datas.size()
	for i in count:
		var datas = selectable_node_state.selectable_node_datas
		var node = datas[i].node_packed_scene.instantiate()
