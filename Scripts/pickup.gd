extends Area3D

enum PickupType { HEALTH, AMMO }
 
@export var pickup_type: PickupType = PickupType.HEALTH
@export var amount: int = 50
@export var spin_speed: float = 2.0
@export var bob_height: float = 0.15
@export var bob_speed: float = 3.0
 
var _base_y: float
var _time: float = 0.0
 
func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)
 
func _process(delta: float) -> void:
	_time += delta
	rotation.y += spin_speed * delta
	position.y = _base_y + sin(_time * bob_speed) * bob_height
 
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
 
	match pickup_type:
		PickupType.HEALTH:
			if body.get("current_health") >= body.get("max_health"):
				return  # full health: leave it on the ground for later
			body.heal(amount)
		PickupType.AMMO:
			if body.get("current_gun_ammo") >= body.get("max_gun_ammo"):
				return  # full ammo: leave it on the ground for later
			body.add_ammo(amount)
 
	queue_free()
