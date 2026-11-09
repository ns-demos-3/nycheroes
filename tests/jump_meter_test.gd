extends Node3D
## Drives real hero physics on synthetic ground; no city downloads required.
## Run: godot --headless --path . res://tests/jump_meter_test.tscn

var _failures := 0


func _ready() -> void:
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(200.0, 2.0, 200.0)
	collision.shape = shape
	floor_body.position.y = 9.0
	floor_body.add_child(collision)
	add_child(floor_body)
	var hero := preload("res://scenes/hero/hero.tscn").instantiate() as Hero
	hero.position = Vector3(0.0, 10.05, 0.0)
	add_child(hero)
	hero.frozen = false
	var hud := GameHud.new()
	hud.hero = hero
	# Only query visibility here; drawing needs the full game's directors.
	hud.visible = false
	add_child(hud)
	await _ticks(20)
	_check(hero.is_on_floor(), "hero stands on actual collision")
	_check(hud.jump_charge() < 0.0, "idle meter hidden")
	hero.input.jump_held = true
	await _ticks(5)
	_check(hud.jump_charge() < 0.0, "tap window does not flash the meter")
	await _ticks(30)
	_check(hud.jump_charge() > 0.2 and hud.jump_charge() < 0.8, "partial charge follows hero physics")
	await _ticks(60)
	_check(hud.jump_charge() == 1.0, "full charge caps at one")
	hero.frozen = true
	_check(hud.jump_charge() < 0.0, "frozen hero hides charge")
	hero.frozen = false
	get_tree().paused = true
	_check(hud.jump_charge() < 0.0, "paused menu hides charge")
	get_tree().paused = false
	hero.input.jump_held = false
	await _ticks(2)
	_check(hero.velocity.y > 60.0, "release launches the real charged jump")
	_check(hud.jump_charge() < 0.0, "released airborne meter hidden")
	hero.set_mode(&"Flight")
	_check(hud.jump_charge() < 0.0, "flight meter hidden")
	print("[jump_meter] %s" % ("PASS" if _failures == 0 else "FAIL"))
	get_tree().quit(0 if _failures == 0 else 1)


func _ticks(count: int) -> void:
	for tick in count:
		await get_tree().physics_frame


func _check(ok: bool, message: String) -> void:
	print("[jump_meter] %s: %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
