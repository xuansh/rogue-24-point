extends Node

class_name PlayerSystem
@warning_ignore_start("unused_parameter")
@warning_ignore_start("unused_variable")

var player_state : PlayerState:
	get:
		return Run.player_state

func _ready() -> void:
	print("qq")


func reset() -> void:
	player_state._floor = 0
	player_state.player_max_hp = 100
	player_state.player_hp = player_state.player_max_hp
	player_state.max_cost_point = 4
	
	player_state.gold = 0
	player_state.relics.clear()
	player_state.opertor_deck_inventory.clear()

func decrease_hp(num : int):
	player_state.player_hp -= num
	var payload = SignalBus.PlayerHPChangedPayload.new()
	payload.player_hp = player_state.player_hp
	payload.player_max_hp = player_state.player_max_hp
	SignalBus.player_hp_changed.emit(payload)
	
	#region TEST
	print("HP is decreased, now hp is ", player_state.player_hp)
	#endregion

func init(battle_system : BattleSystem):
	var battle_state = battle_system.battle_state
	battle_state.player_hp = self.player_state.player_hp
	battle_state.player_max_hp = self.player_state.player_max_hp
	# 费用上限复制进战斗层，之后扣的都是 battle_state.cost_point
	battle_state.cost_point = self.player_state.max_cost_point
	battle_state.deck_inventory = self.player_state.opertor_deck_inventory

	# battle_field_inited 由 BattleSystem 在所有子系统初始化完之后统一发射
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
	
	# 敌人把方块挤出 buffer(溢出)时触发 拖到手牌不算
	SignalBus.buffer_overflowed.connect(_on_front_number_block_poped)

## 被挤出去的方块 按其面值对玩家造成伤害 想改成固定伤害就改这一行
func _on_front_number_block_poped(payload : SignalBus.BufferOverflowedPayload):
	decrease_hp(payload.removal_requested_number_block.value)
