extends CharacterBody3D

enum State { CHASE, LUNGE, RETREAT }
 
@export var speed: float = 3.0
@export var detect_range: float = 15.0
@export var contact_damage: float = 20.0
@export var knockback_stun_duration: float = 0.5
@export var death_delay: float = 1.0
@export var max_health: int = 100
 
@export_group("Attack Pattern")
@export var attack_range: float = 2.0       # distance at which the enemy lunges
@export var lunge_speed: float = 9.0
@export var lunge_duration: float = 0.3     # how long the lunge (and hurtbox) lasts
@export var retreat_speed: float = 4.0
@export var retreat_duration: float = 1.5   # how long it backs off before chasing again
 
var cur_health: int
var player: Node3D
var stun_timer: float = 0.0
var is_dying: bool = false
 
var state: State = State.CHASE
var state_timer: float = 0.0
 
@onready var hit_area: Area3D = $HitArea
 
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	hit_area.body_entered.connect(_on_hit_area_body_entered)
	hit_area.monitoring = false  # only active during the lunge window now
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
	hit_area.set_deferred("monitoring", false)
	await get_tree().create_timer(death_delay).timeout
	queue_free()
 
func apply_knockback(impulse: Vector3) -> void:
	if is_dying:
		return
	velocity.x = impulse.x
	velocity.z = impulse.z
	velocity.y += impulse.y
	stun_timer = knockback_stun_duration
	# a knockback interrupts whatever attack state it was in
	state = State.CHASE
 
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
 
	if is_dying:
		pass
	elif stun_timer > 0.0:
		stun_timer -= delta
	else:
		match state:
			State.CHASE:
				_process_chase()
			State.LUNGE:
				_process_lunge(delta)
			State.RETREAT:
				_process_retreat(delta)
 
	move_and_slide()
 
func _process_chase() -> void:
	if not player:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var dist := global_position.distance_to(player.global_position)

	if dist <= attack_range:
		_start_lunge()
	elif dist < detect_range:
		var dir := (player.global_position - global_position)
		dir.y = 0
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_face_direction(dir)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func _face_direction(dir: Vector3) -> void:
	if dir.length() < 0.01:
		return
	var target_rotation := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, 0.15)
 
func _start_lunge() -> void:
	if not player:
		return
	state = State.LUNGE
	state_timer = lunge_duration
 
	var dir := (player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	velocity.x = dir.x * lunge_speed
	velocity.z = dir.z * lunge_speed
 
	_face_direction(dir)
	
	hit_area.monitoring = true
 
func _process_lunge(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		hit_area.monitoring = false
		_start_retreat()
 
func _start_retreat() -> void:
	state = State.RETREAT
	state_timer = retreat_duration
 
func _process_retreat(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		state = State.CHASE
		velocity.x = 0.0
		velocity.z = 0.0
		return
 
	if player:
		var dir := (global_position - player.global_position)
		dir.y = 0
		dir = dir.normalized()
		velocity.x = dir.x * retreat_speed
		velocity.z = dir.z * retreat_speed
 
func _on_hit_area_body_entered(body: Node3D) -> void:
	if not is_dying and body.is_in_group("player"):
		player.take_damage(int(contact_damage))
