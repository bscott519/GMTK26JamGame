extends Marker3D

@export var mob_assoc_scene: PackedScene  # your enemy scene, drag it in the Inspector
@export_range(1, 8) var min_enemies: int = 3
@export_range(1, 8) var max_enemies: int = 8
@export var spawn_radius: float = 8.0

func _ready() -> void:
	var count := randi_range(min_enemies, max_enemies)
	for i in count:
		var enemy := mob_assoc_scene.instantiate()
		var angle := randf_range(0, TAU)
		var dist := randf_range(spawn_radius * 0.3, spawn_radius)  # min distance too, avoids dead-center overlap
		var offset := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		enemy.position = global_position + offset
		get_tree().current_scene.add_child.call_deferred(enemy)
