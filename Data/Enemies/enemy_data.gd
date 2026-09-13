extends Resource

class_name EnemyData

enum Behavior{
	SPAWN_BLOCK,
	DEFENCE,
}

@export var hp : int
@export var max_hp : int
@export var current_behavior : Behavior
@export var enemy_packed_scene : PackedScene
