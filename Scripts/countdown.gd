extends Label

func _ready() -> void:
	GlobalTimer.time_changed.connect(_on_time_changed)
	text = GlobalTimer.format_time()
 
func _on_time_changed(_time_left: float) -> void:
	text = GlobalTimer.format_time()
 
