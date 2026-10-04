extends CharacterBody3D

enum State { CHASE, LUNGE, RETREAT, WINDUP }
 
@export var speed: float = 3.0
@export var detect_range: float = 15.0
@export var contact_damage: float = 20.0
@export var knockback_stun_duration: float = 0.5
@export var death_delay: float = 1.0
@export var max_health: int = 100
@export var attack_windup_time: float = 0.4
@onready var mesh: Node3D = $Model

@onready var mobster_idle: Node3D = $"Model/Mobster Idle (1)"
@onready var standing_walk_forward: Node3D = $"Model/Standing Walk Forward"
@onready var punching: Node3D = $Model/Punching
@onready var mobster_idle_anim: AnimationPlayer = $"Model/Mobster Idle (1)/AnimationPlayer"
@onready var mobster_punch_anim: AnimationPlayer = $Model/Punching/AnimationPlayer
@onready var walk_forward_anim: AnimationPlayer = $"Model/Standing Walk Forward/AnimationPlayer"
var current_anim_state: String = ""

@export_group("Attack Pattern")
@export var attack_range: float = 2.0       # distance at which the enemy lunges
@export var lunge_speed: float = 9.0
@export var lunge_duration: float = 0.3     # how long the lunge (and hurtbox) lasts
@export var retreat_speed: float = 4.0
@export var retreat_duration: float = 1.5   # how long it backs off before chasing again

@export_group("Drops")
@export var health_pickup_scene: PackedScene
@export_range(0.0, 1.0) var health_drop_chance: float = 0.15

var cur_health: int
var player: Node3D
var stun_timer: float = 0.0
var is_dying: bool = false
var has_attack_slot: bool = false
 
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
	if health_pickup_scene and randf() < health_drop_chance:
		spawn_drop(health_pickup_scene, Vector3.ZERO)
	_release_attack_slot()
	hit_area.set_deferred("monitoring", false)
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
	# a knockback interrupts whatever attack state it was in
	state = State.CHASE
	hit_area.monitoring = false
	_release_attack_slot()
	if mesh:
		mesh.scale = Vector3.ONE 
 
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
			State.WINDUP:
				_process_windup(delta)
 
	move_and_slide()
	_update_animation()
 
func _process_chase() -> void:
	if not player:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var dist := global_position.distance_to(player.global_position)

	if dist <= attack_range:
		if AttackSlots.request_slot():
			has_attack_slot = true
			_start_windup()
		else:
			velocity.x = 0.0
			velocity.z = 0.0
		return
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
	var target_rotation := atan2(-dir.x, -dir.z) + PI / 2.0
	rotation.y = lerp_angle(rotation.y, target_rotation, 0.15)
 
func _release_attack_slot() -> void:
	if has_attack_slot:
		AttackSlots.release_slot()
		has_attack_slot = false

func _start_windup() -> void:
	state = State.WINDUP
	state_timer = attack_windup_time
	velocity.x = 0.0
	velocity.z = 0.0
	if mesh:
		var tween := create_tween()
		tween.tween_property(mesh, "scale", Vector3(1.15, 0.8, 1.15), attack_windup_time)

func _process_windup(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_start_lunge()

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
	if mesh:
		mesh.scale = Vector3.ONE
 
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
		_release_attack_slot()
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

func _update_animation() -> void:
	var new_state := "idle"
	if state == State.WINDUP or state == State.LUNGE:
		new_state = "attack"
	elif Vector2(velocity.x, velocity.z).length() > 0.5:
		new_state = "walk"

	if new_state == current_anim_state:
		return
	current_anim_state = new_state

	mobster_idle.visible = new_state == "idle"
	standing_walk_forward.visible = new_state == "walk"
	punching.visible = new_state == "attack"

	match new_state:
		"idle": mobster_idle_anim.play("mixamo_com")
		"walk": walk_forward_anim.play("mixamo_com")
		"attack":
			mobster_punch_anim.stop()
			mobster_punch_anim.play("mixamo_com")
