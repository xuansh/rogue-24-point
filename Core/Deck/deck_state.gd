extends RefCounted
class_name DeckState

const MAX_DRAW_PILE_SIZE = 20
const MAX_HAND_PILE = 5

var draw_pile : Array[Block] = []
var discard_pile : Array[Block] = []
var hand_pile : Array[Block] = []

var total_draw_cards_per_turn : int
