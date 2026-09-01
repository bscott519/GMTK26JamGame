extends CanvasLayer

@export var main_menu_scene_path: String = "res://Scenes/main_menu.tscn"
@onready var win_label: Label = $WinLabel
@onready var loss_label: Label = $LossLabel
 
var _win_active: bool = false
 
func _ready() -> void:
	win_label.visible = false
	loss_label.visible = false
	GlobalTimer.time_out.connect(_on_time_out)
	call_deferred("_connect_player_health")

func _connect_player_health() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.died.connect(_on_player_died)
 
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
	loss_label.text = "FAILED TO STOP BOMB\n(Press R to Retry)"
	loss_label.visible = true
 
func _on_player_died() -> void:
	_lose("YOU DIED\n[Press R to Retry]")

func _lose(message: String) -> void:
	if get_tree().paused:
		return  # already showing a fail/win screen, don't double-trigger
	get_tree().paused = true
	loss_label.text = message
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
 
