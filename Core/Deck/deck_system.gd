extends Node

class_name DeckSystem

var deck_state := DeckState.new()
var battle_system : BattleSystem

## 绝大多数是被init_battle() 里调用
func init(_battle_system: BattleSystem):
	
	self.battle_system = _battle_system

	deck_state.draw_pile = []
	deck_state.hand_pile = []
	deck_state.discard_pile = []
	
	SignalBus.operator_block_dropped.connect(remove_pile)
	
	init_draw_pile()

func init_draw_pile():
	## 将抽牌堆设置成玩家的所有卡牌
	deck_state.draw_pile = battle_system.battle_state.deck_inventory

func reset_draw_pile():
	deck_state.draw_pile = deck_state.discard_pile
	deck_state.discard_pile.clear()

func draw_draw_pile(count : int):
	for i in range(count):
		var index = randi_range(0, deck_state.draw_pile.size() - 1)
		var card = deck_state.draw_pile.pop_at(index)
		var payload := SignalBus.PileDrawStartedPayload.new()
		payload.block_class_name = "OperatorBlock"
		SignalBus.pile_draw_started.emit(payload)
		deck_state.hand_pile.append(card)

func remove_pile(payload : SignalBus.OperatorBlockRemovalRequestedPayload):
	payload.operator_block.queue_free()
	var dropped_payload := SignalBus.OperatorBlockDroppedPayload.new()
	dropped_payload.calculate_result = payload.calculate_result
	dropped_payload.operator_block = payload.operator_block
	SignalBus.operator_block_dropped.emit(dropped_payload)
