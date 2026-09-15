extends CharacterBody3D

@export var min_distance: float = 6.0    # too close -> flee
@export var max_distance: float = 14.0   # too far -> approach
@export var move_speed: float = 4.0
@export var detect_range: float = 20.0
@export var max_health: int = 80
@export var knockback_stun_duration: float = 0.5
@export var death_delay: float = 1.0
 
@export_group("Shooting")
@export var bullet_scene: PackedScene
@export var shoot_cooldown: float = 1.5
 
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
	await get_tree().create_timer(death_delay).timeout
	queue_free()
 
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
