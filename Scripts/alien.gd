extends CharacterBody3D

@export var speed: float = 3.0
@export var detect_range: float = 15.0
@export var damage_seconds: float = 10.0
@export var knockback_stun_duration: float = 0.5
@export var death_delay: float = 1.0
 
var player: Node3D
var stun_timer: float = 0.0
var is_dying: bool = false
 
@onready var hit_area: Area3D = $HitArea
 
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	hit_area.body_entered.connect(_on_hit_area_body_entered)
 
func apply_knockback(impulse: Vector3) -> void:
	if is_dying:
		return
	velocity += impulse
	is_dying = true
	hit_area.set_deferred("monitoring", false)
	await get_tree().create_timer(death_delay).timeout
	queue_free()
 
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
 
	if is_dying:
		pass
	elif stun_timer > 0.0:
		stun_timer -= delta
	elif player and global_position.distance_to(player.global_position) < detect_range:
		var dir := (player.global_position - global_position)
		dir.y = 0
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
 
	move_and_slide()
 
func _on_hit_area_body_entered(body: Node3D) -> void:
	if not is_dying and body.is_in_group("player"):
		GlobalTimer.subtract_time(damage_seconds)
