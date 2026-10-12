extends Node3D

@export var capture_size := Vector2i(3840, 2160)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_U:
		capture()

func capture() -> void:
	var main_cam := get_viewport().get_camera_3d()

	var vp := SubViewport.new()
	vp.size = capture_size
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var cam := Camera3D.new()
	cam.fov = main_cam.fov
	cam.keep_aspect = main_cam.keep_aspect
	cam.near = main_cam.near
	cam.far = main_cam.far
	vp.add_child(cam)
	cam.global_transform = main_cam.global_transform
	cam.current = true

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	var path := "user://capsule_%d.png" % Time.get_unix_time_from_system()
	vp.get_texture().get_image().save_png(path)
	print("Saved: ", ProjectSettings.globalize_path(path))
	vp.queue_free()
