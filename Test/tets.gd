extends Node
@onready var battle_system: BattleSystem = $BattleControl/BattleSystem

func _ready() -> void:
	var ed1 = EnemyData.new()
	ed1.hp = 100
	ed1.max_hp = 100
	ed1.current_behavior = EnemyData.Behavior.SPAWN_BLOCK
	
	var ed2 = EnemyData.new()
	ed2.hp = 20
	ed2.max_hp = 20
	
	Run.init_run()
	Run.opertor_deck_inventory.append(1)
	battle_system.enemy_system.enemy_state.enemies = [ed1]
	battle_system.init_battle()
