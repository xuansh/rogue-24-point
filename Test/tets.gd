extends Node
@onready var battle_system: BattleSystem = $BattleControl/BattleSystem
@onready var player_health_bar: ProgressBar = $BattleUI/HUD/TopBar/PlayerHealthBar

var slime_tres : Resource = load("res://Data/Enemies/slime.tres")

func _ready() -> void:
	var ed1 = EnemyData.new()
	ed1 = slime_tres
	
	var ed2 = EnemyData.new()
	ed2.hp = 20
	ed2.max_hp = 20
	
	battle_system.player_system.reset()
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.enemy_system.enemy_state.enemies = [ed1]
	battle_system.init_battle()
