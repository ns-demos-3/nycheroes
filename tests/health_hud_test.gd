extends Node
## Health notices follow actual damage, regeneration and knockout timers.
## Run: godot --headless --path . res://tests/health_hud_test.tscn

var _failures := 0


func _ready() -> void:
	var hero: Hero = preload("res://scenes/hero/hero.tscn").instantiate()
	add_child(hero)
	hero.frozen = false
	var hud := GameHud.new()
	hud.hero = hero
	_check(hud.health_notice() == "", "full health stays quiet")
	hero.take_hit(60.0, Vector3.ZERO)
	_check(hud.health_notice() == "", "moderate damage stays quiet during delay")
	hero.take_hit(10.0, Vector3.ZERO)
	_check(hud.health_notice() == "LOW HEALTH · Avoid hits", "30 percent warns")
	hero.take_hit(6.0, Vector3.ZERO)
	_check(hud.health_notice().begins_with("LOW HEALTH"), "repeated hits keep warning")
	# Advance actual physics without a city; disable automatic ticks to control time.
	hero.set_physics_process(false)
	hero._physics_process(Hero.REGEN_DELAY + 0.01)
	_check(hud.health_notice().begins_with("RECOVERING"), "actual regeneration supersedes warning")
	hero.take_hit(100.0, Vector3.ZERO)
	_check(hud.health_notice() == "KNOCKED OUT · Up in 4s", "knockout explains automatic get-up")
	hero._physics_process(1.0)
	_check(hud.health_notice() == "KNOCKED OUT · Up in 3s", "countdown follows mode timer")
	hero._physics_process(2.6)
	_check(hud.health_notice() == "", "full-health get-up clears notice")
	hud.free()
	print("health_hud_test: %d failures" % _failures)
	get_tree().quit(_failures)


func _check(ok: bool, label: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_failures += 1
