extends ProgressBar

func _ready() -> void:
	call_deferred("_connect_player_health")
 
func _connect_player_health() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		push_error("HealthBar: no node in 'player' group found.")
		return
 
	max_value = player.max_health
	value = player.current_health
	player.health_changed.connect(_on_health_changed)
 
func _on_health_changed(current: int, max: int) -> void:
	max_value = max
	value = current
 
