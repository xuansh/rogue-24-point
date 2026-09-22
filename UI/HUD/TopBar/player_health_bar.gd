extends ProgressBar
@onready var label: Label = $Label

func _ready() -> void:
	SignalBus.battle_field_inited.connect(update_health_bar_progress)
	SignalBus.player_hp_changed.connect(update_health_bar_progress)
	
func update_health_bar_progress(payload : Variant):
	assert("player_hp" in payload and "player_max_hp" in payload)
	self.max_value = payload.player_max_hp
	if payload.player_max_hp <= 0:
		return
	self.value = payload.player_hp
	var label_text = str(int(self.value)) + '/' + str(int(self.max_value))
	label.text = label_text
