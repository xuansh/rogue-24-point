extends Node

class_name BattleSystem
 
@export var root : Node
var card_container : Control
var buffer_slots : HBoxContainer
var end_button : Button

var battle_state := BattleState.new()
var enemy_system := EnemySystem.new()
var deck_system := DeckSystem.new()
var turn_system := TurnSystem.new()
var player_system := PlayerSystem.new()
var block_system := BlockSystem.new()
var buffer_system := BufferSystem.new()

func init_battle():
	init()
	player_system.init(self)
	deck_system.init(self)
	turn_system.init(self)
	block_system.init(self)
	buffer_system.init(self)
	enemy_system.init(self)

	emit_battle_field_inited()
	turn_system.start_battle()

## 玩家/敌人子系统都初始化完之后 再一次性广播双方的数据
## 之前 player_system 和 enemy_system 各自 emit 一次, 且各自只填自己那一半字段,
## 血条收到对方那次信号时读到默认值 0, 0/0 得到 NaN 就画坏了
func emit_battle_field_inited():
	var payload := SignalBus.BattleFieldInitedPayload.new()
	payload.player_hp = battle_state.player_hp
	payload.player_max_hp = battle_state.player_max_hp
	if enemy_system.enemies_state.size() > 0:
		var enemy_data := enemy_system.enemies_state[0].enemy_data
		payload.enemy_hp = enemy_data.hp
		payload.enemy_max_hp = enemy_data.max_hp
	SignalBus.battle_field_inited.emit(payload)

func init():
	card_container = root.get_node("BattleUI").get_node("Hand").get_node("CardContainer")
	buffer_slots = root.get_node("BattleUI").get_node("Buffer").get_node("Slots")
	end_button = root.get_node("BattleUI").get_node("EndTurnButton")
