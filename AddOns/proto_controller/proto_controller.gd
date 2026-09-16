extends CharacterBody3D

@export var speed: float = 9.0
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.002

signal health_changed(current: int, max: int)
signal died

@export_group("Health")
@export var max_health: int = 200
var current_health: int

@export_group("Gravity Feel")
@export var gravity_multiplier: float = 2.5      # overall gravity strength while ascending
@export var fall_gravity_multiplier: float = 4.0
 
@export_group("Grapple Dash")
@export var grapple_range: float = 30.0
@export var grapple_pull_strength: float = 28.0
@export var grapple_release_distance: float = 2.5
@export var grapple_line_radius: float = 0.1
@export_flags_3d_physics var grapple_collision_mask: int = 1

@export_group("Melee")
@export var punch_cooldown: float = 0.4
@export var punch_knockback_force: float = 20.0
@export var punch_knockback_upward: float = 4.0
@export var punch_squash_scale: Vector3 = Vector3(1.3, 0.8, 1.3)
@export var punch_reach: float = 3.0
@export var punch_visual_duration: float = 0.15
@export var punch_damage: float = 34.0
@export var swing_angle: float = 90.0
@export var swing_duration: float = 0.15
@export var swing_position_offset: Vector3 = Vector3(-0.6, 0, 0)
@export var swing_reach: float = 0.6
@export var hip_height: float = -0.4
@export var shoulder_height: float = 0.5
@export var combo_reset_time: float = 0.8

var combo_index: int = 0
var _combo_reset_timer: float = 0.0
var _weapon_rest_position: Vector3
var _current_swing_tween: Tween

@export_group("Firearm Settings")
var current_gun_ammo : int = 10
var is_holding_gun : bool = false
@onready var pistol: MeshInstance3D = $Head/RightHand/Pistol
@onready var pistol_2: MeshInstance3D = $Head/LeftHand/Pistol2
var next_shot_is_left: bool = false

@export_group("Roll")
@export var roll_speed: float = 18.0
@export var roll_duration: float = 0.25
@export var roll_cooldown: float = 0.6
@export var roll_invincible: bool = true

## IMPORTANT REFERENCES
@onready var collider: CollisionShape3D = $Collider
@onready var mesh: MeshInstance3D = $Mesh
@onready var left_hand: Marker3D = $Head/LeftHand
@onready var right_hand: Marker3D = $Head/RightHand
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var grapple_line: MeshInstance3D = $StretchedArm
@onready var punch_area: Area3D = $PunchArea
@onready var jump_sfx: AudioStreamPlayer = $JumpSFX
@export var impact_effect_scene: PackedScene
@onready var baton_axe: MeshInstance3D = $Head/RightHand/BatonAxe

var mouse_captured: bool = true
var look_rotation: Vector2
 
var base_scale: Vector3
var target_scale: Vector3
 
var is_grappling: bool = false
var grapple_target: Vector3
 
var can_punch: bool = true
var _punch_arm_active: bool = false
 
var _jump_requested: bool = false
var _grapple_requested: bool = false

var is_rolling: bool = false
var can_roll: bool = true
var is_invincible: bool = false
 
func _ready() -> void:
	current_health = max_health
	_equip_weapon()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	base_scale = mesh.scale
	target_scale = base_scale
	_setup_grapple_line()
	_weapon_rest_position = baton_axe.position
 
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		rotate_look(event.relative)
 
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE:
			_jump_requested = true
		if event.physical_keycode == KEY_TAB:
			_grapple_requested = true
		if event.physical_keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
		if event.physical_keycode == KEY_1:
			_equip_weapon()
		if event.physical_keycode == KEY_2:
			_equip_gun()
		if event.physical_keycode == KEY_SHIFT:
			_try_roll()
	if event is InputEventMouseButton and event.pressed:
		if not mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if is_holding_gun and current_gun_ammo > 0:
				shoot_gun()
			elif not is_holding_gun:
				_try_punch()
				
 
func _physics_process(delta: float) -> void:
	if _grapple_requested and not is_grappling:
		_try_start_grapple()
	_grapple_requested = false
 
	if is_grappling:
		_update_grapple()
	elif is_rolling:
		pass
	else:
		if not is_on_floor():
			if velocity.y < 0:
				velocity += get_gravity() * fall_gravity_multiplier * delta
			else:
				velocity += get_gravity() * gravity_multiplier * delta
 
		if _jump_requested and is_on_floor():
			velocity.y = jump_velocity
			jump_sfx.play()
 
		var move := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_W): move.y -= 1
		if Input.is_physical_key_pressed(KEY_S): move.y += 1
		if Input.is_physical_key_pressed(KEY_A): move.x -= 1
		if Input.is_physical_key_pressed(KEY_D): move.x += 1
		move = move.normalized()
 
		var move_dir := (transform.basis * Vector3(move.x, 0, move.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * speed
			velocity.z = move_dir.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
 
	_jump_requested = false
 
	var was_on_floor := is_on_floor()
	move_and_slide()
 
	_update_grapple_line()
 
	if target_scale != base_scale and mesh.scale.distance_to(target_scale) < 0.02:
		target_scale = base_scale
	
	if combo_index > 0:
		_combo_reset_timer -= delta
		if _combo_reset_timer <= 0.0:
			combo_index = 0
			if baton_axe and (not _current_swing_tween or not _current_swing_tween.is_valid()):
				baton_axe.position = _weapon_rest_position
				baton_axe.rotation = Vector3.ZERO
 
func _try_roll() -> void:
	if not can_roll or is_rolling or is_grappling:
		return

	var move := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): move.y -= 1
	if Input.is_physical_key_pressed(KEY_S): move.y += 1
	if Input.is_physical_key_pressed(KEY_A): move.x -= 1
	if Input.is_physical_key_pressed(KEY_D): move.x += 1
	move = move.normalized()

	# no input held -> roll forward (facing direction) instead of standing still
	var roll_dir: Vector3
	if move:
		roll_dir = (transform.basis * Vector3(move.x, 0, move.y)).normalized()
	else:
		roll_dir = -transform.basis.z

	is_rolling = true
	can_roll = false
	if roll_invincible:
		is_invincible = true

	velocity.x = roll_dir.x * roll_speed
	velocity.z = roll_dir.z * roll_speed

	await get_tree().create_timer(roll_duration).timeout
	is_rolling = false
	is_invincible = false

	await get_tree().create_timer(roll_cooldown - roll_duration).timeout
	can_roll = true

func rotate_look(rot_input: Vector2) -> void:
	look_rotation.x -= rot_input.y * mouse_sensitivity
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-45), deg_to_rad(60))
	look_rotation.y -= rot_input.x * mouse_sensitivity
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func shoot_gun():
	current_gun_ammo -= 1

	var flash_path := "Head/LeftHand/Pistol2/MuzzleFlash" if next_shot_is_left else "Head/RightHand/Pistol/MuzzleFlash"
	var flash = get_node_or_null(flash_path)
	print("Looking for: ", flash_path, " | found: ", flash)
	if flash:
		flash.restart()
		flash.emitting = true

	next_shot_is_left = not next_shot_is_left  # alternate for next shot

	print("Gun Fired! Ammo left: ", current_gun_ammo)

	# raycast stays camera-based regardless of which hand visually fired,
	# so aim accuracy doesn't depend on which pistol's turn it is
	var cam = get_viewport().get_camera_3d()
	var space_state = get_world_3d().direct_space_state
	var ray_origin = cam.global_position
	var ray_end = ray_origin + -cam.global_transform.basis.z * 50.0

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)

	if result:
		spawn_impact_effect(result.position, result.normal)
		if result.collider.has_method("take_dmg"):
			result.collider.take_dmg(40, Vector3.ZERO)
		if result.collider.has_method("take_hit"):
			result.collider.take_hit(0.3)

	apply_screen_shake(0.05)
	if current_gun_ammo == 0:
		print("OUT OF AMMO")
		
func spawn_impact_effect(hit_position: Vector3, hit_normal: Vector3):
	var impact = impact_effect_scene.instantiate()
	get_tree().root.add_child(impact)
	
	# Position it slightly off the wall surface
	impact.global_position = hit_position + (hit_normal * 0.05)
	
	# Orient the particles to point away from the wall
	if hit_normal.length() > 0:
		impact.look_at(hit_position + hit_normal, Vector3.UP)
	print("DEBUG: Spawned impact at: ", hit_position) # Check your console for this!
	
	# Make the debug mesh HUGE just to find it
	if impact.has_node("MeshInstance3D"):
		impact.get_node("MeshInstance3D").scale = Vector3(5, 5, 5)

func apply_screen_shake(intensity: float):
	# Assuming your Camera3D is under 'head'
	var tween = create_tween()
	for i in 4:
		var offset = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * intensity
		tween.tween_property($Head/Camera3D, "h_offset", offset.x, 0.05)
		tween.tween_property($Head/Camera3D, "v_offset", offset.y, 0.05)
	tween.tween_property($Head/Camera3D, "h_offset", 0, 0.05)
	tween.tween_property($Head/Camera3D, "v_offset", 0, 0.05)
 
func _try_start_grapple() -> void:
	var cam := get_viewport().get_camera_3d()
	var space_state := get_world_3d().direct_space_state
	var from := cam.global_position
	var aim_dir := -cam.global_transform.basis.z
	var to := from + aim_dir * grapple_range
 
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self.get_rid()]
	query.collision_mask = grapple_collision_mask
	var result := space_state.intersect_ray(query)

	if result:
		grapple_target = result.position
		is_grappling = true
 
func _update_grapple() -> void:
	var to_target := grapple_target - global_position
	if to_target.length() < grapple_release_distance:
		is_grappling = false
		return
	velocity = to_target.normalized() * grapple_pull_strength
 
func _setup_grapple_line() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = grapple_line_radius
	cylinder.bottom_radius = grapple_line_radius
	cylinder.height = 1.0
	grapple_line.mesh = cylinder
 
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0, 0, 0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0, 0, 0)
	mat.emission_energy_multiplier = 1.5
	grapple_line.material_override = mat
	grapple_line.visible = false
 
func _update_grapple_line() -> void:
	if _punch_arm_active:
		return
	
	if not is_grappling or left_hand == null:
		grapple_line.visible = false
		return
 
	grapple_line.visible = true
	var start := left_hand.global_position
	var end := grapple_target
	var mid := (start + end) / 2.0
	var dist := start.distance_to(end)
 
	grapple_line.global_position = mid
	grapple_line.look_at_from_position(mid, end, Vector3.UP)
	grapple_line.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	grapple_line.scale = Vector3(1.0, dist, 1.0)
 
## Left-click melee: checks whatever's currently overlapping PunchArea and
## knocks each of them outward from the player
## Has a short cooldown so holding the mouse button doesn't spam-hit.
func _try_punch() -> void:
	if not is_holding_gun:
		if not can_punch:
			return
		can_punch = false
		
		_swing_melee_weapon()
	 
		for body in punch_area.get_overlapping_bodies():
			if body == self:
				continue
			_apply_knockback(body)
	 
		await get_tree().create_timer(punch_cooldown).timeout
		can_punch = true

func _apply_knockback(body: Node3D) -> void:
	var dir := body.global_position - global_position
	dir.y = 0.0
	dir = dir.normalized()
	var impulse := dir * punch_knockback_force + Vector3.UP * punch_knockback_upward
 
	if body.has_method("take_dmg"):
		body.take_dmg(punch_damage, impulse)
	elif body.has_method("apply_knockback"):
		body.apply_knockback(impulse)
	elif body is RigidBody3D:
		body.apply_central_impulse(impulse)
	elif body is CharacterBody3D:
		body.velocity += impulse
		
func _swing_melee_weapon() -> void:
	if not baton_axe:
		return

	if _current_swing_tween and _current_swing_tween.is_valid():
		_current_swing_tween.kill()

	var rest_position := _weapon_rest_position
	var right_hip := rest_position + Vector3(swing_reach, hip_height, 0)
	var left_shoulder := rest_position + Vector3(-swing_reach, shoulder_height, 0)
	var left_hip := rest_position + Vector3(-swing_reach, hip_height, 0)

	var start_pos: Vector3
	var end_pos: Vector3
	var start_rot_z: float
	var end_rot_z: float

	match combo_index:
		0:  # right hip -> left shoulder (upward diagonal)
			start_pos = right_hip
			end_pos = left_shoulder
			start_rot_z = deg_to_rad(-45)
			end_rot_z = deg_to_rad(45)
		1:  # left shoulder -> right hip (downward diagonal)
			start_pos = left_shoulder
			end_pos = right_hip
			start_rot_z = deg_to_rad(45)
			end_rot_z = deg_to_rad(-45)
		2:  # right hip -> left hip (horizontal sweep)
			start_pos = right_hip
			end_pos = left_hip
			start_rot_z = deg_to_rad(-20)
			end_rot_z = deg_to_rad(20)

	var start_rotation := baton_axe.rotation
	start_rotation.z = start_rot_z
	var end_rotation := baton_axe.rotation
	end_rotation.z = end_rot_z

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(baton_axe, "position", start_pos, swing_duration * 0.15)
	tween.tween_property(baton_axe, "rotation", start_rotation, swing_duration * 0.15)

	tween.chain().set_parallel(true)
	tween.tween_property(baton_axe, "position", end_pos, swing_duration * 0.5)
	tween.tween_property(baton_axe, "rotation", end_rotation, swing_duration * 0.5)

	tween.chain().set_parallel(true)
	tween.tween_property(baton_axe, "position", rest_position, swing_duration * 0.35)
	tween.tween_property(baton_axe, "rotation", baton_axe.rotation, swing_duration * 0.35)

	_current_swing_tween = tween
	combo_index = (combo_index + 1) % 3
	_combo_reset_timer = combo_reset_time

func _equip_weapon() -> void:
	is_holding_gun = false
	if baton_axe:
		baton_axe.visible = true
	if pistol:
		pistol.visible = false
	if pistol_2:
		pistol_2.visible = false

func _equip_gun() -> void:
	is_holding_gun = true
	if pistol:
		pistol.visible = true
	if pistol_2:
		pistol_2.visible = true
	if baton_axe:
		baton_axe.visible = false

func take_damage(amount: int) -> void:
	if is_invincible:
		return
	if current_health <= 0:
		return
	current_health -= amount
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		current_health = 0
		died.emit()

func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
