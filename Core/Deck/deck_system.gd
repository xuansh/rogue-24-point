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
	
	# 收 removal_requested: 卡片发出请求 -> 这里移牌并 free -> 再发 dropped 给 EnemySystem
	# 之前接的是 operator_block_dropped，而 remove_pile 结尾又发同一个讯号，会无限递归
	SignalBus.operator_block_usage_request_payload.connect(use_hand_pile)
	SignalBus.operator_block_removal_requested.connect(remove_card_to_discard_pile)
	SignalBus.player_turn_started.connect(
		func(payload : SignalBus.PlayerTurnStartedPayload):
			draw_draw_pile(payload.draw_cards_per_turn)
	)
	init_draw_pile()

func init_draw_pile():
	## 将抽牌堆设置成玩家的所有卡牌
	## 要拷贝一份而不是直接赋值: 直接赋值时两边是同一个 Array,
	## 抽牌时 pop_at 会把玩家卡组也一起吃掉, 下一场战斗就抽不出牌了
	deck_state.draw_pile.clear()
	deck_state.draw_pile.append_array(battle_system.battle_state.deck_inventory)

## 抽牌堆空的时候重洗: 先把弃牌堆洗回去
## 弃牌堆现在也是空的(还没有弃牌流程), 那就退化成用玩家卡组重洗, 避免牌堆空转
func reset_draw_pile():
	deck_state.draw_pile.clear()
	deck_state.draw_pile.append_array(deck_state.discard_pile)
	deck_state.discard_pile.clear()
	if deck_state.draw_pile.is_empty():
		deck_state.draw_pile.append_array(battle_system.battle_state.deck_inventory)

func draw_draw_pile(count : int):
	for i in range(count):
		if deck_state.draw_pile.is_empty():
			reset_draw_pile()
		## 牌堆真的抽干了就直接不抽, 不能拿 randi_range(0, -1) 去抽
		if deck_state.draw_pile.is_empty():
			push_warning("draw_pile 和 discard_pile 都是空的, 本回合少抽一张牌")
			return
		var index = randi_range(0, deck_state.draw_pile.size() - 1)
		var card = deck_state.draw_pile.pop_at(index)
		var payload := SignalBus.PileDrawStartedPayload.new()
		payload.deck_block = card
		SignalBus.pile_draw_started.emit(payload)
		deck_state.hand_pile.append(card)

### 回合结束后将所有手牌移入弃牌堆
#func discard_all_hand_pile():
	#for card in deck_state.hand_pile:
		#

## 通常在玩家使用手牌时调用
func use_hand_pile(payload : SignalBus.OperatorBlockRemovalRequestedPayload):
	var dropped_payload := SignalBus.OperatorBlockDroppedPayload.new()
	dropped_payload.calculate_result = payload.calculate_result
	dropped_payload.operator_block = payload.operator_block
	SignalBus.operator_block_dropped.emit(dropped_payload)
	#ALERT 如果卡牌带有顽固这类 不会随着玩家回合结束移出手牌 的效果 需要在此加个if
	SignalBus.operator_block_removal_requested.emit(payload)

func remove_card_to_discard_pile(payload : SignalBus.OperatorBlockRemovalRequestedPayload):
	deck_state.hand_pile.erase(payload.operator_block.reso)
	deck_state.discard_pile.append(payload.operator_block.reso)
	payload.operator_block.queue_free()
