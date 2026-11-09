extends Node
## Synthetic open-air physics checks; no tile downloads required.
## Run: godot --headless --path . res://tests/flight_cruise_test.tscn

var _hero: Hero
var _failed := false


func _ready() -> void:
	_hero = load("res://scenes/hero/hero.tscn").instantiate()
	add_child(_hero)
	_hero.position.y = 300.0
	_hero.frozen = false
	_hero.set_mode(&"Flight")
	await _ticks(2)
	_check(not _hero.flight_cruise, "flight starts with cruise off")
	_hero.input.cruise_toggle_pressed = true
	await _ticks(120)
	_check(_hero.flight_cruise and _hero.velocity.z < -32.0, "cruise holds forward without stick")
	_hero.input.aim = Vector3.RIGHT
	await _ticks(120)
	_check(_hero.velocity.x > 32.0, "cruise follows steering")
	var sync := PlayerSync.new()
	var encoded := sync._encode(_hero)
	_check(int(encoded[5]) & PlayerSync.FLIGHT_CRUISE != 0, "peer snapshot carries cruise flag")
	var copy: Hero = load("res://scenes/hero/hero.tscn").instantiate()
	copy.remote_id = 2
	add_child(copy)
	var snapshots := SnapshotBuffer.new()
	snapshots.push(float(encoded[0]), encoded)
	sync._follow(copy, snapshots)
	_check(copy.flight_cruise and copy.mode.name == &"Flight", "remote hero receives cruise state")
	encoded[5] = int(encoded[5]) & ~PlayerSync.FLIGHT_CRUISE
	sync._follow(copy, snapshots)
	_check(not copy.flight_cruise, "remote hero receives cruise cancellation")
	copy.queue_free()
	sync.free()
	_hero.input.stick.y = 1.0
	await _ticks(2)
	_check(not _hero.flight_cruise, "pull back cancels")
	_hero.input.clear()
	await _ticks(180)
	_check(_hero.velocity.length() < 0.1, "ordinary no-input flight hovers")
	_hero.input.cruise_toggle_pressed = true
	await _ticks(2)
	_hero.input.cruise_toggle_pressed = true
	await _ticks(2)
	_check(not _hero.flight_cruise, "second toggle cancels")
	_hero.flight_cruise = true
	_hero.set_mode(&"OnFoot")
	_check(not _hero.flight_cruise, "leaving flight clears cruise")
	_hero.set_mode(&"Flight")
	_hero.flight_cruise = true
	_hero.take_hit(1.0, Vector3.ZERO)
	_check(not _hero.flight_cruise, "damage clears cruise")
	var controls := PlayerInput.new()
	controls.hero = _hero
	_hero.flight_cruise = true
	controls.enabled = false
	_check(not _hero.flight_cruise, "opening menus clears cruise immediately")
	_hero.flight_cruise = true
	controls._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not _hero.flight_cruise, "focus loss clears cruise")
	controls.free()
	_hero.input.clear()
	_hero.velocity = Vector3.ZERO
	_hero.input.aim = Vector3.FORWARD
	_hero.flight_cruise = true
	var before := _hero.world_position()
	WorldOrigin.shift(Vector3(1000.0, 0.0, 0.0))
	_check(_hero.flight_cruise and _hero.input.aim == Vector3.FORWARD, "origin shift preserves direction and cruise")
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 20.0, 1.0)
	shape.shape = box
	wall.add_child(shape)
	add_child(wall)
	wall.global_position = _hero.global_position + Vector3.FORWARD * 4.0
	await _ticks(100)
	_check(not _hero.flight_cruise, "collision cancels cruise")
	_check(_hero.world_position().distance_to(before) < 5.0, "hero stops at obstacle")
	print("flight_cruise_test: FAIL" if _failed else "flight_cruise_test: PASS")
	get_tree().quit(1 if _failed else 0)


func _ticks(count: int) -> void:
	for tick in count:
		await get_tree().physics_frame


func _check(ok: bool, description: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_failed = true
