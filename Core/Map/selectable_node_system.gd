extends Node

class_name SelectableNodeSystem

var selectable_node_state := SelectableNodeState.new()

var _map_system : MapSystem
## 临时：喂给 PathGuide 的格子集合。两条路重叠的格子会重复出现，
## 但 PathGuide 内部是按格存的 Dictionary，会自动去重
var guide_cells : Array[Vector2i] = []

func map_init(map_system : MapSystem):
	_map_system = map_system
	var datas : Array[SelectableNodeData] = selectable_node_state.selectable_node_datas
	var count = datas.size()
	for i in count:
		if datas[i] == null or datas[i].node_packed_scene == null:
			push_error("SelectableNodeData at index %d has no node_packed_scene" % i)
			continue
		var _node : Node2D = datas[i].node_packed_scene.instantiate()
		_node.position = get_selectable_position(i, count)
		map_system.selectable_node_container.add_child(_node)
		# 路径要等节点落位之后再算，而且只算一次；它是拼进 guide_cells 的，
		# 必须用 append_array 展平，append 会把整个数组塞进去（类型不合法）
		guide_cells.append_array(
			get_path_cells(Vector2i.ZERO, IsoFloor.world_to_cell(_node.position))
		)
	_map_system.path_guide.debug_cells = guide_cells

func get_selectable_position(index : int, count : int) -> Vector2:
	var preset_position : Vector2 = selectable_node_state.preset_position
	if count == 2:
		var offset : float = 150
		var offset_y := offset if index == 0 else -offset
		return Vector2(preset_position.x, preset_position.y + offset_y)
	return preset_position

## from → to 的格子序列（含两端）。
## 菱形网格里只有 (±1,0) / (0,±1) 是共边的，(+1,-1) 只是尖角相碰。
## 所以每次只能推进一个轴：两个 if 各推一次的话会出现对角步，
## 光斑在那些地方会断成一颗一颗。
func get_path_cells(from : Vector2i, to : Vector2i) -> Array[Vector2i]:
	var cells : Array[Vector2i] = []

	var x := from.x
	var y := from.y
	var dx := absi(to.x - from.x)
	var dy := absi(to.y - from.y)
	var sx := 1 if from.x < to.x else -1
	var sy := 1 if from.y < to.y else -1
	var err := dx - dy

	while true:
		cells.append(Vector2i(x, y))
		if x == to.x and y == to.y:
			break
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		else:
			err += dx
			y += sy
	return cells
