extends RefCounted
class_name EnemyState

var enemy_data := EnemyData.new()
var float_amplitude : float = 0.0:
	set(value):
		enemy_node.float_amplitude = value

## 由 EnemySystem.init 生成并回填；不能在声明处 instantiate，那时 enemy_data 还是空的
var enemy_node : Node2D = null
var spawn_block_value : int
