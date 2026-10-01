extends Node
@onready var battle_system: BattleSystem = $BattleControl/BattleSystem
@onready var player_health_bar: ProgressBar = $BattleUI/HUD/TopBar/PlayerHealthBar/ProgressBar

var operator_block_tres : OperatorReso = load("res://Data/Blocks/Operator/ob.tres")
var slime_tres : Resource = load("res://Data/Enemies/slime.tres")
var test_inv : TestInventory = load("res://Test/test_inventory.tres")

func _ready() -> void:
	var e_state1 := EnemyState.new()
	e_state1.enemy_data = slime_tres
	battle_system.player_system.reset()
	battle_system.player_system.player_state.opertor_deck_inventory = test_inv.inv
	battle_system.enemy_system.enemy_state = e_state1
	battle_system.init_battle()
