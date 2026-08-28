extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not body.is_holding_gun:
		body.is_holding_gun = true
		body.current_gun_ammo = 12
		body.pistol.visible = true
		queue_free()
