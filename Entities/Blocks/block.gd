extends Control

class_name Block

var area_2d : Area2D

var is_mouse_in_area : bool = false
## 按下鼠标时锁定 整个拖拽过程不再依赖 hover 判定 避免快速移动时脱离鼠标
var is_dragging : bool = false
## 本次拖拽是否已经提交过 保证一次拖放只会填一个槽位
var _is_committed : bool = false
