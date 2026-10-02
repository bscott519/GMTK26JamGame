extends Label

@onready var reloading_label: Label = $ReloadingLabel

func _ready() -> void:
	reloading_label.visible = false
	call_deferred("_connect_player")  # same pattern as HealthBar, avoids a race with the player's _ready()
 
func _connect_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	player.ammo_changed.connect(_on_ammo_changed)
	player.reloading_changed.connect(_on_reloading_changed)
	_on_ammo_changed(player.current_gun_ammo, player.mag_size)  # show starting ammo immediately
 
func _on_ammo_changed(current: int, mag_size: int) -> void:
	text = "%d/%d" % [current, mag_size]
 
func _on_reloading_changed(reloading: bool) -> void:
	reloading_label.visible = reloading
 
