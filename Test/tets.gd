extends Node
@onready var battle_system: BattleSystem = $BattleControl/BattleSystem
@onready var player_health_bar: ProgressBar = $BattleUI/HUD/TopBar/PlayerHealthBar

var slime_tres : Resource = load("res://Data/Enemies/slime.tres")

func _ready() -> void:
	var e_state1 := EnemyState.new()
	e_state1.enemy_data = slime_tres
	
	battle_system.player_system.reset()
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.player_system.player_state.opertor_deck_inventory.append(1)
	battle_system.enemy_system.enemies_state.append(e_state1)
	battle_system.init_battle()
