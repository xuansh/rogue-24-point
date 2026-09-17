extends Control

class_name Block

var is_mouse_in_area : bool = false
## 按下鼠标时锁定 整个拖拽过程不再依赖 hover 判定 避免快速移动时脱离鼠标
var is_dragging : bool = false
