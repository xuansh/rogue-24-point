extends RefCounted
class_name EnemyState

var enemy_data := EnemyData.new()
var float_amplitude : float = 0.0:
	set(value):
		enemy_node.float_amplitude = value

## 由 EnemySystem.init 生成并回填；不能在声明处 instantiate，那时 enemy_data 还是空的
var enemy_node : Node2D = null
var spawn_block_value : int

## 当前行为放在 state 上 不能写在 enemy_data 上:
## enemy_data 是 .tres 的共享实例, 改它会污染同一场战斗的其它敌人和下一场战斗
var current_behavior : EnemyData.Behavior = EnemyData.Behavior.SPAWN_BLOCK
var _behavior_index : int = 0

## 进入战斗时调用 从行为循环的第一项开始
func reset_behavior() -> void:
	_behavior_index = 0
	_apply_behavior()

## 走到行为循环的下一项 走完一轮回到开头
func advance_behavior() -> void:
	var cycle_size := enemy_data.behavior_cycle.size()
	if cycle_size > 0:
		_behavior_index = (_behavior_index + 1) % cycle_size
	_apply_behavior()

func _apply_behavior() -> void:
	var cycle := enemy_data.behavior_cycle
	if cycle.is_empty():
		# 没配行为循环就退化成每回合都产牌 免得敌人站着不动
		current_behavior = EnemyData.Behavior.SPAWN_BLOCK
		return
	current_behavior = cycle[clampi(_behavior_index, 0, cycle.size() - 1)]
