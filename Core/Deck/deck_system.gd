extends Node

class_name DeckSystem

var deck_state := DeckState.new()
var battle_state : BattleState

## 绝大多数是被init_battle() 里调用
func init(_battle_state: BattleState):
	self.battle_state = _battle_state

	deck_state.draw_pile = []
	deck_state.hand_pile = []
	deck_state.discard_pile = []
	
	init_draw_pile()
	
	#TEST
	print(
		"Init Deck: ",
		"Draw Pile: ",
		deck_state.draw_pile,
		", Discard Pile: ",
		deck_state.discard_pile,
		", Hand Pile: ",
		deck_state.hand_pile
	)

func init_draw_pile():
	## 将抽牌堆设置成玩家的所有卡牌
	deck_state.draw_pile = battle_state.deck_inventory

func reset_draw_pile():
	deck_state.draw_pile = deck_state.discard_pile
	deck_state.discard_pile.clear()

func draw_draw_pile(count : int):
	for i in range(count):
		var index = randi_range(0, deck_state.draw_pile.size() - 1)
		var card = deck_state.draw_pile.pop_at(index)
		deck_state.hand_pile.append(card)
		
		#region TEST
		print("Draw Card: ", card)
		#endregion
