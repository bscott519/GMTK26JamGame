extends Marker3D

@export var enemy_pool: Array[PackedScene] = []
@export_range(1, 8) var min_enemies: int = 4
@export_range(1, 8) var max_enemies: int = 8
@export var spawn_radius: float = 6.0

@export_range(0.0, 1.0) var ranged_chance: float = 0.5
@export var melee_scene: PackedScene   
@export var ranged_scene: PackedScene  
@export var use_weighted_mix: bool = false
 
func _ready() -> void:
	var count := randi_range(min_enemies, max_enemies)
	for i in count:
		var scene := _pick_enemy_scene()
		if not scene:
			continue
 
		var enemy := scene.instantiate()
		var angle := randf_range(0, TAU)
		var dist := randf_range(spawn_radius * 0.3, spawn_radius)
		var offset := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		enemy.position = global_position + offset
		get_tree().current_scene.add_child.call_deferred(enemy)
 
func _pick_enemy_scene() -> PackedScene:
	if use_weighted_mix and melee_scene and ranged_scene:
		return ranged_scene if randf() < ranged_chance else melee_scene
	if enemy_pool.is_empty():
		return null
	return enemy_pool[randi() % enemy_pool.size()]
 
