extends Control
@export var BattleField : Node
@onready var decrease_player_hp_button: Button = $GridContainer/DecreasePlayerHPButton
@onready var enter_player_turn_button: Button = $GridContainer/EnterPlayerTurnButton
@onready var exit_player_turn_button: Button = $GridContainer/ExitPlayerTurnButton
@onready var enter_enemies_turn_button: Button = $GridContainer/EnterEnemiesTurnButton

func _ready() -> void:
	decrease_player_hp_button.pressed.connect(_on_decrease_player_hp_button_pressed)
	enter_player_turn_button.pressed.connect(_on_enter_player_turn_button_pressed)
	exit_player_turn_button.pressed.connect(_on_exit_player_turn_button_pressed)
	enter_enemies_turn_button.pressed.connect(_on_enter_enemies_turn_button_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("KeyBoard-W"):
		self.visible = !self.visible

func _on_decrease_player_hp_button_pressed():
	BattleField.battle_system.player_system.decrease_hp(10)

func _on_enter_player_turn_button_pressed():
	var sys : BattleSystem = BattleField.battle_system
	sys.turn_system.start_player_turn()

func _on_exit_player_turn_button_pressed():
	var sys : BattleSystem = BattleField.battle_system
	sys.turn_system.end_player_turn()

func _on_enter_enemies_turn_button_pressed():
	var sys : BattleSystem = BattleField.battle_system
	sys.turn_system.start_enemies_turn()
