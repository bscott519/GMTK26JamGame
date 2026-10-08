extends ProgressBar

@onready var special_label: Label = $SpecialLabel

func _ready() -> void:
	value = 0
	call_deferred("_connect_player")
	special_label.visible = false
	
	var pulse := create_tween().set_loops()
	pulse.tween_property(special_label, "modulate:a", 0.3, 0.5)
	pulse.tween_property(special_label, "modulate:a", 1.0, 0.5)
 
func _connect_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	player.focus_changed.connect(_on_focus_changed)
	_on_focus_changed(player.current_focus, player.focus_max)
 
func _on_focus_changed(current: int, max_focus: int) -> void:
	max_value = max_focus
	value = current
	special_label.visible = current >= max_focus
