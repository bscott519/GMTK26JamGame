extends CanvasLayer

@export var main_menu_scene_path: String = "res://Scenes/main_menu.tscn"
@onready var win_label: Label = $WinLabel
@onready var loss_label: Label = $LossLabel
 
var _win_active: bool = false
 
func _ready() -> void:
	win_label.visible = false
	loss_label.visible = false
	GlobalTimer.time_out.connect(_on_time_out)
 
func _on_finish_line_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_win()
 
func _win() -> void:
	get_tree().paused = true
	win_label.text = "MADE IT ON TIME!\nRemaining Time: %s\n\nPress E for Main Menu" % GlobalTimer.format_time()
	win_label.visible = true
	_win_active = true
 
func _on_time_out() -> void:
	get_tree().paused = true
	loss_label.text = "YOU'RE FIRED!\n(Press R to Retry)"
	loss_label.visible = true
 
var _reloading: bool = false
 
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		if _reloading:
			return
		_reloading = true
		GlobalTimer.reset()
		get_tree().paused = false
		get_tree().reload_current_scene()
 
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_E:
		if _win_active and not _reloading:
			_reloading = true
			GlobalTimer.reset()
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().change_scene_to_file(main_menu_scene_path)
 
