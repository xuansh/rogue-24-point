extends Control

class_name Block

var area_2d : Area2D

var is_mouse_in_area : bool = false
## 按下鼠标时锁定 整个拖拽过程不再依赖 hover 判定 避免快速移动时脱离鼠标
var is_dragging : bool = false
## 本次拖拽是否已经提交过 保证一次拖放只会填一个槽位
var _is_committed : bool = false

## 由 BlockSystem 在 add_child() 之前调用，把牌库数据灌进实体。
## 每种方块在这里读自己需要的字段；BlockSystem 永远不认识具体类型。
var reso : DeckBlock
var battle_state : BattleState

func apply_reso(_reso : DeckBlock) -> void:
	pass
