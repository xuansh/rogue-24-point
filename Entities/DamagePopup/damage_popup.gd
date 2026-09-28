extends Control
@onready var rich_text_label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	if not is_inside_tree():
		return
	
	var start := rich_text_label.position
	var offset := Vector2(50, -144)
	var duration := 0.5
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(
		func(t: float):
			var ex := _ease_out_sine(t)
			var ey := _ease_out_back(t)
			rich_text_label.position = start + Vector2(offset.x * ex, offset.y * ey),
		0.0, 1.0, duration
	)
	tween.tween_property(rich_text_label, "scale", Vector2(0.12, 0.12), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_interval(0.3)
	
	await tween.finished
	self.queue_free()
	

func _ease_out_sine(t: float) -> float:
	return sin(t * PI / 2.0)

func _ease_out_back(t: float) -> float:
	var c1 := 3
	var c3 := c1 + 1.0
	# print("t = ", t, " y = ", 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0))
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)
