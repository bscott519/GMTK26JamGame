extends Control

@export var game_scene_path: String = "res://Scenes/main.tscn"
@onready var controls_panel: Control = $ControlsPanel
@onready var close_controls_button: Button = $ControlsPanel/CloseControlsButton
@onready var main_controls_button: Button = $MainControlsButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("Main menu ready, mouse mode set to visible")
	controls_panel.visible = false
	main_controls_button.pressed.connect(_on_controls_pressed)
	close_controls_button.pressed.connect(_on_close_controls_pressed)

func _on_play_button_pressed() -> void:
	GlobalTimer.reset()
	get_tree().change_scene_to_file(game_scene_path)
 
func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_controls_pressed() -> void:
	controls_panel.visible = true

func _on_close_controls_pressed() -> void:
	controls_panel.visible = false
