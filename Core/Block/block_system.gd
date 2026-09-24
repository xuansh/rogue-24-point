extends Node

class_name BlockSystem

var block_state := BlockState.new()
var battle_system : BattleSystem

func init(_battle_system : BattleSystem):
	self.battle_system = _battle_system
	SignalBus.pile_draw_started.connect(_on_pile_draw_started)

## 不知道怎么描述这个函数 就是当摸牌信号(pile_draw_started)发出时 会调用这个函数 前面的信号每摸一次牌都会发出信号
func _on_pile_draw_started(payload : SignalBus.PileDrawStartedPayload) -> void:
	var node := payload.deck_block.block_packed_scene.instantiate() as OperatorBlock
	# cost 得在 add_child 之前写: add_child 会触发 _ready(), 那时才有值可以填 label
	node.cost = payload.deck_block.cost
	# 费用池也一并注入: 卡片不自己去捞全局或沿父链找 BattleSystem
	node.battle_state = self.battle_system.battle_state
	self.battle_system.card_container.add_child(node)
	
