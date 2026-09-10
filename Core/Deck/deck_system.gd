extends Node

class_name DeckSystem

var deck_state := DeckState.new()

## 绝大多数是被init_battle() 里调用
func init():
	deck_state.draw_pile = []
	deck_state.hand_pile = []
	deck_state.discard_pile = []
	
	## 将抽牌堆设置成玩家的所有卡牌
	deck_state.draw_pile = Run.opertor_deck_inventory
	
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

func reset_draw_pile():
	pass
