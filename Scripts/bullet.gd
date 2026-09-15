extends Area3D

@export var speed: float = 20.0
@export var damage: int = 15
@export var lifetime: float = 3.0
 
var direction: Vector3 = Vector3.FORWARD
var shooter: Node3D = null
 
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()
 
## Called by whatever fired this bullet, right after spawning it.
func launch(dir: Vector3, from: Node3D = null) -> void:
	direction = dir.normalized()
	shooter = from
	look_at(global_position + direction, Vector3.UP)
 
func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
 
func _on_body_entered(body: Node3D) -> void:
	if body == shooter:
		return  # never let a bullet destroy itself on its own shooter
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("enemy"):
		# hit a wall/environment piece — stop here rather than passing through
		queue_free()
 
