extends Node

class_name PlayerSystem

var player_state : PlayerState:
	get:
		return Run.player_state

func _ready() -> void:
	print("qq")


func reset() -> void:
	player_state._floor = 0
	player_state.player_max_hp = 100
	player_state.player_hp = player_state.player_max_hp
	
	player_state.gold = 0
	player_state.relics.clear()
	player_state.opertor_deck_inventory.clear()

func decrease_hp(num : int):
	player_state.player_hp -= num
	var payload = SignalBus.PlayerHPChangedPayload.new()
	payload.player_hp = player_state.player_hp
	payload.player_max_hp = player_state.player_max_hp
	SignalBus.battle_field_inited.emit(payload)
	
	#region TEST
	print("HP is decreased, now hp is ", player_state.player_hp)
	#endregion

func init(battle_system : BattleSystem):
	var battle_state = battle_system.battle_state
	battle_state.player_hp = self.player_state.player_hp
	battle_state.player_max_hp = self.player_state.player_max_hp
	battle_state.deck_inventory = self.player_state.opertor_deck_inventory
	
	var payload := SignalBus.BattleFieldInitedPayload.new()
	payload.player_hp = battle_state.player_hp
	payload.player_max_hp = battle_state.player_max_hp
	SignalBus.battle_field_inited.emit(payload)
	
	battle_system.root.get_node("Entities").add_child(player_state.player_node)
	player_state.player_node.position = IsoFloor.ANCHOR
	
	SignalBus.player_turn_started.connect(
		func(payload : SignalBus.PlayerTurnStartedPayload):
			player_state.float_amplitude = 10
	)
	
	SignalBus.player_turn_exited.connect(
		func(payload : SignalBus.PlayerTurnExitedPayload):
			player_state.float_amplitude = 0
	)
