extends Control
@onready var rich_text_label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	await get_tree().create_timer(0.3).timeout
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(rich_text_label, "position:x", position.x + 50, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(rich_text_label, "position:y", position.y - 144, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
