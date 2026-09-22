extends CanvasLayer

@export var main_menu_scene_path: String = "res://Scenes/main_menu.tscn"
@onready var win_label: Label = $WinLabel
@onready var loss_label: Label = $LossLabel
@onready var pause_label: Label = $PauseLabel
@onready var pause_menu: Control = $PauseMenu
@onready var pause_main_menu_button: Button = $PauseMenu/PauseMainMenuButton
@onready var controls_button: Button = $PauseMenu/ControlsButton
@onready var controls_panel: Control = $ControlsPanel
@onready var close_controls_button: Button = $ControlsPanel/CloseControlsButton
 
var game_over_active: bool = false
var reloading: bool = false
var is_paused: bool = false
 
func _ready() -> void:
	win_label.visible = false
	loss_label.visible = false
	pause_menu.visible = false
	controls_panel.visible = false
	pause_main_menu_button.pressed.connect(_on_pause_main_menu_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	close_controls_button.pressed.connect(_on_close_controls_pressed)
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
	win_label.text = "MADE IT TO CITY HALL (MORE COMING SOON)!\nRemaining Time: %s\n\nPress E for Main Menu" % GlobalTimer.format_time()
	win_label.visible = true
	game_over_active = true
 
func _on_time_out() -> void:
	get_tree().paused = true
	_lose("FAILED TO STOP BOMB\n(Press E for Main Menu)")
	loss_label.visible = true
 
func _on_player_died() -> void:
	_lose("YOU DIED\n[Press E for Main Menu]")

func _lose(message: String) -> void:
	if get_tree().paused:
		return  # already showing a fail/win screen, don't double-trigger
	get_tree().paused = true
	loss_label.text = message
	loss_label.visible = true
	game_over_active = true

func _toggle_pause() -> void:
	if game_over_active:
		return
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if not is_paused:
		controls_panel.visible = false

func _on_pause_main_menu_pressed() -> void:
	GlobalTimer.reset()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(main_menu_scene_path)

func _on_controls_pressed() -> void:
	controls_panel.visible = true
	pause_menu.visible = false

func _on_close_controls_pressed() -> void:
	controls_panel.visible = false
	pause_menu.visible = true
 
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_P:
		if not controls_panel.visible:
			_toggle_pause()

	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_E:
		if game_over_active and not reloading:
			reloading = true
			GlobalTimer.reset()
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().change_scene_to_file(main_menu_scene_path)
 
