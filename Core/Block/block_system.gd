extends Node

class_name BlockSystem

var block_state := BlockState.new()
var battle_system : BattleSystem

func init(_battle_system : BattleSystem):
	self.battle_system = _battle_system
	SignalBus.pile_draw_started.connect(_on_pile_draw_started)

## 不知道怎么描述这个函数 就是当摸牌信号(pile_draw_started)发出时 会调用这个函数 前面的信号每摸一次牌都会发出信号
func _on_pile_draw_started(payload : SignalBus.PileDrawStartedPayload) -> void:
	var node := payload.deck_block.block_packed_scene.instantiate() as Block
	# 牌面数据必须赶在 add_child 之前灌: add_child 会触发 _ready(),
	# 那时 cost / operator 才有效, 否则 label 只会显示默认的 "+"
	node.apply_reso(payload.deck_block)
	# 费用池是战斗上下文不是牌面数据, 单独注入
	node.battle_state = self.battle_system.battle_state
	self.battle_system.card_container.add_child(node)
	
