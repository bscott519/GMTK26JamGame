extends Control

@export var game_scene_path: String = "res://Scenes/main.tscn"
 
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(game_scene_path)
 
func _on_quit_button_pressed() -> void:
	get_tree().quit()
