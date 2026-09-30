extends Camera2D

@export var trauma : float = 0.0
@export var trauma_decay : float = 1.2
@export var max_offset : float = 8.0

func _ready() -> void:
	SignalBus.enemy_hp_decreased.connect(add_trauma)

func add_trauma(payload : SignalBus.EnemyHPDeceasedPayload):
	@warning_ignore("integer_division")
	var ratio = float(payload.changed_hp) / float(payload.enemy_max_hp)
	var num = clampf(ratio * 3.0, 0.3, 1.5)
	self.trauma = min(self.trauma + num, 1.5)
	self.trauma += num

func _process(delta: float) -> void:
	if trauma > 0:
		trauma -= delta * trauma_decay
		trauma = max(trauma, 0)
		var shake_amount = trauma * trauma
		var x_offset = randf_range(-1.0, 1.0) * max_offset * shake_amount
		var y_offset = randf_range(-1.0, 1.0) * max_offset * shake_amount
		self.offset = Vector2(x_offset, y_offset)
	else:
		self.offset = Vector2.ZERO
