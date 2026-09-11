extends Marker3D

@export var mob_assoc_scene: PackedScene  # your enemy scene, drag it in the Inspector
@export_range(1, 8) var min_enemies_per_zone: int = 3
@export_range(1, 8) var max_enemies_per_zone: int = 8
@export var spawn_radius: float = 3.0  

func _ready() -> void:
	for zone in get_children():
		if zone is Marker3D:
			_spawn_zone(zone)

func _spawn_zone(zone: Marker3D) -> void:
	var count := randi_range(min_enemies_per_zone, max_enemies_per_zone)
	for i in count:
		var enemy := mob_assoc_scene.instantiate()
		get_tree().current_scene.add_child(enemy)
		var offset := Vector3(randf_range(-spawn_radius, spawn_radius), 0, randf_range(-spawn_radius, spawn_radius))
		enemy.global_position = zone.global_position + offset
