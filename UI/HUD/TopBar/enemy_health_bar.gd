extends ProgressBar

func _ready() -> void:
	SignalBus.battle_field_inited.connect(update_health_bar_progress)
	SignalBus.enemy_hp_changed.connect(update_health_bar_progress)
	
func update_health_bar_progress(payload : Variant):
	assert("enemy_hp" in payload and "enemy_max_hp" in payload)
	if payload.enemy_max_hp <= 0:
		return
	self.value = float(payload.enemy_hp) / float(payload.enemy_max_hp)
