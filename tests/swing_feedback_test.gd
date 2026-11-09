extends Node3D
## Synthetic collision check: no anchor, attachment, constraint feedback and
## floating-origin invariance. No city downloads required.
## godot --headless --path . res://tests/swing_feedback_test.tscn

var failures := 0


func _ready() -> void:
	var hero: Hero = load("res://scenes/hero/hero.tscn").instantiate()
	add_child(hero)
	hero.position = Vector3(0.0, 20.0, 0.0)
	hero.input.aim = Vector3.FORWARD
	await get_tree().physics_frame
	var swing := hero.get_mode(&"Swing") as SwingMode
	check(not swing.try_attach(), "empty space rejects attachment")
	check(swing.unavailable_time > 0.0, "failed attempt makes one unavailable cue")
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 160.0, 5.0)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0.0, 80.0, -35.0)
	add_child(wall)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(swing.try_attach(), "real wall accepts attachment")
	check(swing.unavailable_time == 0.0, "success immediately clears unavailable cue")
	hero.input.web_held = true
	hero.set_mode(&"Swing")
	swing.physics_update(1.0 / 60.0)
	check(swing.rope_taut, "initial reel activates existing constraint")
	var before := swing.anchor - hero.global_position
	var shift := Vector3(1000.0, 0.0, -1000.0)
	hero.position -= shift
	WorldOrigin.shifted.emit(shift)
	check((swing.anchor - hero.global_position).is_equal_approx(before), "origin shift preserves pivot distance")
	hero.global_position = swing.anchor + Vector3.DOWN * (swing.rope_length * 0.5 + SwingMode.HAND_HEIGHT)
	hero.velocity = Vector3.ZERO
	swing.physics_update(1.0 / 60.0)
	check(not swing.rope_taut, "inside rope length reports slack")
	print("Swing feedback: %d failures" % failures)
	get_tree().quit(1 if failures else 0)


func check(ok: bool, message: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures += 1
