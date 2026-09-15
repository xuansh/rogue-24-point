extends Node

class_name BlockSystem

var block_state := BlockState.new()
var battle_system : BattleSystem

func init(_battle_system : BattleSystem):
	self.battle_system = _battle_system
	SignalBus.pile_draw_started.connect(_on_pile_draw_started)

## 不知道怎么描述这个函数 就是当摸牌信号(pile_draw_started)发出时 会调用这个函数 前面的信号每摸一次牌都会发出信号
func _on_pile_draw_started(payload : SignalBus.PileDrawStartedPayload) -> void:
	var node : Control
	match payload.block_class_name:
		"OperatorBlock":
			node = self.block_state.operator_block_packed_scene.instantiate()
		_:
			pass
	self.battle_system.card_container.add_child(node)
	
