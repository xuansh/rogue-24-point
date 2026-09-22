extends Resource

class_name EnemyData

enum Behavior{
	SPAWN_BLOCK,
	DEFENCE,
}

@export var hp : int
@export var max_hp : int
@export var enemy_packed_scene : PackedScene

## 每个敌人回合往玩家 buffer 里塞几个数字块
## 这是战斗节奏的主要调节钮: 玩家每回合有 4 个 operand 槽的消耗能力,
## 这个数远小于它的时候 玩家每回合就只能做一个"把唯一的方块拖进空槽"的动作
@export var spawn_block_count : int = 3

## 行为循环: 每个敌人回合按顺序取一项, 走完一轮回到开头
## 里面存的是 Behavior 的枚举值(0 = SPAWN_BLOCK, 1 = DEFENCE)
## 例: [SPAWN_BLOCK] 每回合都产牌  [SPAWN_BLOCK, DEFENCE] 产一回合停一回合
@export var behavior_cycle : Array[int] = [Behavior.SPAWN_BLOCK]

func random_value_spawn_block() -> int:
	var rand = randi_range(1, 9)
	return rand
