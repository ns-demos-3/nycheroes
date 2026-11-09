extends Node
## Reproducible REAL world flight cruise walkthrough. Drives ordinary Input
## actions through PlayerInput; no altered speeds, time scale or physics.
## godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie /data/flight-cruise/native.avi res://tools/demo/flight_cruise.tscn -- --solo=1 --name=Pilot --quality=low --peds=0 --traffic=0 --gangs=0 --trains=0 --spawn=420,20,-220,-29 --tiles_url=https://nycheroes.party/tiles

var _game: Game
var _elapsed := -1.0
var _stage := -1
var _settle := 0.0


func _ready() -> void:
	process_physics_priority = -20
	_game = load("res://scenes/world.tscn").instantiate()
	add_child(_game)
	_game.hero_camera.pitch = 0.02
	# Hide only the diagnostic overlay; the playable HUD stays visible.
	_game.hud.get_node("DebugLabel").hide()


func _physics_process(delta: float) -> void:
	if _elapsed < 0.0:
		if _game.hero.frozen or _game.city.pending_count() > 0 or not _game.hero.is_on_floor():
			return
		_settle += delta
		if _settle < 1.0:
			return
		_elapsed = 0.0
		print("[cruise movie] START frame=", Engine.get_process_frames())
	_elapsed += delta
	var stage := 0
	if _elapsed >= 2.0: stage = 1
	if _elapsed >= 5.0: stage = 2
	if _elapsed >= 9.0: stage = 3
	if _elapsed >= 12.0: stage = 4
	if _elapsed >= 15.0: stage = 5
	if _elapsed >= 18.0:
		print("[cruise movie] FINISH frame=", Engine.get_process_frames())
		get_tree().quit()
		return
	if stage != _stage:
		for action: String in ["fly_toggle", "flight_cruise", "move_back", "look_right", "jump"]:
			Input.action_release(action)
		print("[cruise movie] stage=", stage, " mode=", _game.hero.mode.name, " cruise=", _game.hero.flight_cruise, " speed=", snappedf(_game.hero.velocity.length(), 0.1))
		_stage = stage
		match stage:
			0:
				Input.action_press("fly_toggle")
				Input.action_press("jump")
				(_game.hud.get_node("GameHud") as GameHud).notify("F + Space: take off")
			1:
				Input.action_press("flight_cruise")
				(_game.hud.get_node("GameHud") as GameHud).notify("R: cruise · no forward key held")
			2:
				(_game.hud.get_node("GameHud") as GameHud).notify("Steer with the camera · cruise follows")
			3:
				Input.action_press("move_back")
				(_game.hud.get_node("GameHud") as GameHud).notify("S: cancel cruise · brake manually")
			4:
				(_game.hud.get_node("GameHud") as GameHud).notify("Controls released · ordinary hover")
			5:
				Input.action_press("flight_cruise")
				(_game.hud.get_node("GameHud") as GameHud).notify("R: cruise again · watch for obstacles")
	else:
		Input.action_release("fly_toggle")
		Input.action_release("flight_cruise")
	# A slow ordinary right-stick turn, rather than a camera teleport.
	if stage == 2:
		Input.action_press("look_right", 0.075)
	# A short back tap cancels cruise without sending the hero far backwards.
	if stage == 3 and _elapsed > 9.35:
		Input.action_release("move_back")
