extends ProgressBar

func _ready() -> void:
	SignalBus.battle_field_inited.connect(update_health_bar_progress)
	SignalBus.player_hp_changed.connect(update_health_bar_progress)
	
func update_health_bar_progress(payload : Variant):
	assert("player_hp" in payload and "player_max_hp" in payload)
	if payload.player_max_hp <= 0:
		return
	self.value = float(payload.player_hp) / float(payload.player_max_hp)
