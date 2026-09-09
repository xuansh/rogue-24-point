extends RefCounted

class_name EnemyData

enum Behavior{
	SPAWN_BLOCK,
	DEFENCE,
}

var hp : int
var max_hp : int
var current_behavior : Behavior
