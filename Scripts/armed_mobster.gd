extends CharacterBody3D

@export var min_distance: float = 6.0    # too close -> flee
@export var max_distance: float = 14.0   # too far -> approach
@export var move_speed: float = 4.0
@export var detect_range: float = 20.0
@export var max_health: int = 80
@export var knockback_stun_duration: float = 0.5
@export var death_delay: float = 1.0
 
@onready var hit_reaction_model: Node3D = $"Node3D/Hit Reaction"
@onready var pistol_idle_model: Node3D = $"Node3D/Pistol Idle"
@onready var pistol_walk_model: Node3D = $"Node3D/Pistol Walk"
@onready var death_gunner_model: Node3D = $"Node3D/Standing Death Backward 01 (Gunner)"
@onready var hit_reaction_anim_player: AnimationPlayer = $"Node3D/Hit Reaction/AnimationPlayer"
@onready var pistol_idle_anim_player: AnimationPlayer = $"Node3D/Pistol Idle/AnimationPlayer"
@onready var pistol_walk_anim_player: AnimationPlayer = $"Node3D/Pistol Walk/AnimationPlayer"
@onready var death_anim_player: AnimationPlayer = $"Node3D/Standing Death Backward 01 (Gunner)/AnimationPlayer"
var current_anim_state: String = ""

@export_group("Shooting")
@export var bullet_scene: PackedScene
@export var shoot_cooldown: float = 2.5
@onready var gun_sfx: AudioStreamPlayer = $GunSFX

@export_group("Drops")
@export var ammo_pickup_scene: PackedScene
@export var health_pickup_scene: PackedScene
@export_range(0.0, 1.0) var health_drop_chance: float = 0.15
 
@onready var gun_muzzle: Marker3D = $Gun/GunMuzzle
 
var cur_health: int
var player: Node3D
var stun_timer: float = 0.0
var is_dying: bool = false
var shoot_timer: float = 0.0
 
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")
	cur_health = max_health
 
func take_dmg(amount: int, knockback: Vector3) -> void:
	if is_dying:
		return
	cur_health -= amount
	apply_knockback(knockback)
	if cur_health <= 0:
		die()
 
func die() -> void:
	is_dying = true
	if ammo_pickup_scene:
		spawn_drop(ammo_pickup_scene, Vector3.ZERO)
	if health_pickup_scene and randf() < health_drop_chance:
		spawn_drop(health_pickup_scene, Vector3(0.8, 0, 0))
	await get_tree().create_timer(death_delay).timeout
	queue_free()
 
func spawn_drop(scene: PackedScene, offset: Vector3) -> void:
	var drop := scene.instantiate()
	drop.position = global_position + offset + Vector3(0, 0.5, 0)
	get_tree().current_scene.add_child.call_deferred(drop)

func apply_knockback(impulse: Vector3) -> void:
	if is_dying:
		return
	velocity.x = impulse.x
	velocity.z = impulse.z
	velocity.y += impulse.y
	stun_timer = knockback_stun_duration
 
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
 
	if is_dying:
		pass
	elif stun_timer > 0.0:
		stun_timer -= delta
	else:
		_process_kite_and_shoot(delta)
 
	move_and_slide()
 
func _process_kite_and_shoot(delta: float) -> void:
	if not player:
		velocity.x = 0.0
		velocity.z = 0.0
		return
 
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player
	dir.y = 0
	dir = dir.normalized()
 
	if dist < min_distance:
		# too close -> flee directly away from the player
		velocity.x = -dir.x * move_speed
		velocity.z = -dir.z * move_speed
	elif dist > max_distance and dist < detect_range:
		# too far -> close the gap
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		# in the sweet spot -> hold position and shoot
		velocity.x = 0.0
		velocity.z = 0.0
 
	if dist < detect_range:
		_face_direction(dir)
 
	if dist >= min_distance and dist <= detect_range:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			_shoot()
			shoot_timer = shoot_cooldown
 
func _face_direction(dir: Vector3) -> void:
	if dir.length() < 0.01:
		return
	# NOTE: this offset (+PI/2) matched the base alien mesh's orientation.
	# If this enemy uses a different mesh, re-test which offset is correct
	# the same way we did for alien.gd (try 0, +PI/2, -PI/2, PI).
	var target_rotation := atan2(-dir.x, -dir.z) + PI / 2.0
	rotation.y = lerp_angle(rotation.y, target_rotation, 0.15)
 
func _shoot() -> void:
	if not bullet_scene or not player or is_dying or not gun_muzzle:
		return
 
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child.call_deferred(bullet)
 
	var spawn_pos := gun_muzzle.global_position
	var target_dir := (player.global_position - spawn_pos)
	target_dir.y = 0
	target_dir = target_dir.normalized()
 
	bullet.position = spawn_pos
	if bullet.has_method("launch"):
		bullet.call_deferred("launch", target_dir, self)
	
	gun_sfx.play()

func _update_animation() -> void:
	var new_state := "idle"
	if Vector2(velocity.x, velocity.z).length() > 0.5:
		new_state = "walk"
	elif player and global_position.distance_to(player.global_position) < detect_range:
		new_state = "attack"

	if new_state == current_anim_state:
		return
	current_anim_state = new_state

	pistol_idle_model.visible = new_state == "idle"
	pistol_walk_model.visible = new_state == "walk"
	attack_model.visible = new_state == "attack"

	match new_state:
		"idle": idle_anim.play("Take 001")
		"walk": walk_anim.play("Take 001")
		"attack": attack_anim.play("Take 001")
