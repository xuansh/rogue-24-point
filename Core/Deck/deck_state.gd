extends RefCounted
class_name DeckState

const MAX_DRAW_PILE_SIZE = 20
const MAX_HAND_PILE = 5

## 摸牌堆
var draw_pile : Array[DeckBlock] = []
## 弃牌堆
var discard_pile : Array[DeckBlock] = []
## 手牌堆
var hand_pile : Array[DeckBlock] = []

var total_draw_cards_per_turn : int
