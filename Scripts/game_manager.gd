extends CanvasLayer

@onready var win_label: Label = $WinLabel
@onready var loss_label: Label = $LossLabel
 
func _ready() -> void:
	win_label.visible = false
	loss_label.visible = false
	GlobalTimer.time_out.connect(_on_time_out)
 
func _on_finish_line_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_win()
 
func _win() -> void:
	get_tree().paused = true
	win_label.text = "MADE IT ON TIME!\nRemaining Time: %s" % GlobalTimer.format_time()
	win_label.visible = true
 
func _on_time_out() -> void:
	get_tree().paused = true
	loss_label.text = "YOU'RE FIRED!\n(Press R to Retry)"
	loss_label.visible = true
 
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().paused = false
		get_tree().reload_current_scene()
