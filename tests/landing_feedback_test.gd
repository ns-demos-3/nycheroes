extends Node3D
## Real hero falls onto a synthetic floor: quiet contacts, medium dust, slam
## ring and shake-off behavior. No city download required.
## godot --headless --path . res://tests/landing_feedback_test.tscn

var _failed := false


func _ready() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	floor_body.position.y = 1.5
	floor_body.add_child(shape)
	add_child(floor_body)
	var effects := CombatEffects.new()
	add_child(effects)
	for height: float in [0.8, 12.0, 70.0]:
		var hero: Hero = load("res://scenes/hero/hero.tscn").instantiate()
		hero.position = Vector3(0, 2.0 + height, 0)
		add_child(hero)
		hero.frozen = false
		var impact := [0.0]
		hero.landed.connect(func(speed: float) -> void: impact[0] = speed)
		for tick in 240:
			await get_tree().physics_frame
			if impact[0] > 0.0:
				break
		_check(impact[0] > 0.0, "hero actually landed")
		var rings := 0
		var dust := 0
		for child in effects.get_children():
			if child is MeshInstance3D:
				rings += 1
			if child is CPUParticles3D:
				dust += 1
		_check(dust == (0 if height < 1.0 else 1), "dust only for meaningful contact")
		_check(rings == (1 if height > 60.0 else 0), "ring reserved for combat slam")
		print("landing height=%.1f speed=%.1f dust=%d rings=%d" % [height, impact[0], dust, rings])
		hero.queue_free()
		for child in effects.get_children():
			child.queue_free()
		await get_tree().process_frame
	# Exercise the camera's real pulse handlers with the accessibility setting.
	var hero: Hero = load("res://scenes/hero/hero.tscn").instantiate()
	add_child(hero)
	var camera := ThirdPersonCamera.new()
	camera.target = hero
	var arm := SpringArm3D.new()
	arm.name = "SpringArm"
	var lens := Camera3D.new()
	lens.name = "Camera"
	arm.add_child(lens)
	camera.add_child(arm)
	add_child(camera)
	Settings.set_value("camera_shake", false)
	hero.landed.emit(90.0)
	Combat.impact.emit(hero.global_position, 1.0)
	camera._process(0.016)
	_check(is_zero_approx(lens.h_offset) and is_zero_approx(lens.v_offset), "shake off suppresses landing AND slam pulses")
	Settings.set_value("camera_shake", true)
	hero.landed.emit(90.0)
	camera._process(0.016)
	_check(absf(lens.v_offset) > 0.0 and absf(lens.v_offset) < 0.16, "shake on is visible and restrained")
	Settings.set_value("camera_shake", false)
	camera._process(0.016)
	_check(is_zero_approx(lens.h_offset) and is_zero_approx(lens.v_offset), "turning shake off clears an active pulse immediately")
	WorldOrigin.shift(Vector3(500, 0, 0))
	_check(effects.is_in_group("floating"), "effects follow floating origin")
	print("landing feedback: ", "FAILED" if _failed else "PASS")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failed = true
		push_error(message)
