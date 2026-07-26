extends ColorRect

func _ready() -> void:
	color = Color(1, 0, 0, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GlobalTimer.damage_taken.connect(_on_damage_taken)
 
func _on_damage_taken() -> void:
	var tween := create_tween()
	tween.tween_property(self, "color:a", 0.4, 0.05)
	tween.tween_property(self, "color:a", 0.0, 0.25)
 
