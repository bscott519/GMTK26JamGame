extends Node

signal time_changed(time_left: float)
signal time_out
signal damage_taken
 
const START_TIME: float = 180.0
 
var time_left: float = START_TIME
var running: bool = true
 
func _process(delta: float) -> void:
	if running and time_left > 0.0:
		time_left = max(0.0, time_left - delta)
		time_changed.emit(time_left)
		if time_left <= 0.0:
			running = false
			time_out.emit()
 
func subtract_time(seconds: float) -> void:
	if not running:
		return
	time_left = max(0.0, time_left - seconds)
	time_changed.emit(time_left)
	damage_taken.emit()
	if time_left <= 0.0:
		running = false
		time_out.emit()
 
func add_time(seconds: float) -> void:
	if not running:
		return
	time_left += seconds
	time_changed.emit(time_left)
 
func format_time() -> String:
	var minutes := int(time_left) / 60
	var seconds := int(time_left) % 60
	return "%02d:%02d" % [minutes, seconds]
 
## Autoloads persist across scene reloads, so this MUST be called explicitly
## on retry/restart — reload_current_scene() alone won't touch this singleton.
func reset() -> void:
	time_left = START_TIME
	running = true
	time_changed.emit(time_left)
