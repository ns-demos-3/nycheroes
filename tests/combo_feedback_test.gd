extends Node3D
## Synthetic combat fixture: actual melee strikes, with no city downloads.
## Run: godot --headless --path . res://tests/combo_feedback_test.tscn

var _failed := false


func _ready() -> void:
	var hero: Hero = load("res://scenes/hero/hero.tscn").instantiate()
	add_child(hero)
	hero.frozen = true
	var melee := hero.get_mode(&"Melee") as MeleeMode
	var victims: Array[Thug] = []
	for k in 2:
		var thug: Thug = load("res://scenes/npc/thug.tscn").instantiate()
		add_child(thug)
		thug.position = Vector3(k * 0.2, 0.0, -1.3)
		thug.health = 1000.0
		thug.process_mode = Node.PROCESS_MODE_DISABLED
		victims.append(thug)
	await get_tree().physics_frame
	hero.input.aim = Vector3.FORWARD
	melee.enter(&"OnFoot")
	melee.physics_update(0.17)
	_check(melee.connected_punches == 1, "two victims count as one connected punch")
	hero.attack_pressed = true
	melee.physics_update(0.20)
	hero.attack_pressed = false
	melee.physics_update(0.19)
	_check(melee.connected_punches == 2 and melee.feedback.contains("FINISHER NEXT"), "second hit cues finisher")
	hero.attack_pressed = true
	melee.physics_update(0.22)
	hero.attack_pressed = false
	melee.physics_update(0.27)
	_check(melee.connected_punches == 3 and melee.feedback.contains("FINISHER!"), "third connected punch confirms finisher")
	melee.exit()
	_check(melee.feedback.contains("FINISHER!"), "completed cue survives mode exit")
	melee._process(1.3)
	_check(melee.feedback.is_empty(), "feedback expires")
	for thug in victims:
		thug.position.x += 100.0
	var civilian: Pedestrian = load("res://scenes/npc/pedestrian.tscn").instantiate()
	add_child(civilian)
	civilian.process_mode = Node.PROCESS_MODE_DISABLED
	civilian.position = hero.position + Vector3.FORWARD
	melee.enter(&"OnFoot")
	melee.physics_update(0.17)
	_check(melee.connected_punches == 0 and melee.feedback.is_empty(), "a strike near a civilian awards no progress")
	victims[0].state = Thug.State.IDLE
	victims[0].position = hero.position + Vector3.FORWARD * 1.3
	melee.enter(&"OnFoot")
	melee.physics_update(0.17)
	melee.exit()
	_check(melee.connected_punches == 0 and melee.feedback == "COMBO ENDED", "interrupted chain resets clearly")
	melee.enter(&"OnFoot")
	melee.physics_update(0.17)
	for thug in victims:
		thug.position.x += 100.0
	hero.attack_pressed = true
	melee.physics_update(0.20)
	hero.attack_pressed = false
	melee.physics_update(0.19)
	_check(melee.connected_punches == 0 and melee.feedback.contains("COMBO RESET"), "a missed follow-up clears earned progress")
	victims[0].state = Thug.State.DOWN
	victims[0].position = hero.position + Vector3.FORWARD
	melee.enter(&"OnFoot")
	melee.physics_update(0.17)
	_check(melee.connected_punches == 0, "downed thugs earn no progress")
	Engine.time_scale = 1.0
	get_tree().quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	print("%s: %s" % ["PASS" if condition else "FAIL", message])
	_failed = _failed or not condition
