extends SceneTree
## Reproducible native gameplay capture. Loads the unchanged main scene and
## drives ordinary Input actions through PlayerInput; never changes hero physics.
## See docs/STREET_SPRINT.md for the Movie Maker command and timing.
var game
var sprint
var clock := -1.0
var settled := 0.0
var started := false
var retried := false
var flight := false
var old_stats: Variant

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	old_stats = root.get_node("Settings").get_value("show_stats", true)
	root.get_node("Settings").set_value("show_stats", false)
	var scene := load("res://scenes/world.tscn") as PackedScene
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	sprint = game.get_node("StreetSprint")
	# Submit the real first-launch name form, as pressing its Play button does.
	if game._name_prompt.visible:
		game._name_prompt._play.pressed.emit()

func _physics_process(delta: float) -> bool:
	if not is_instance_valid(sprint):
		return false
	if clock < 0.0:
		if game.hero.frozen or sprint._waiting or game.city.pending_count() > 0:
			return false
		settled += delta
		if settled < 1.0:
			return false
		clock = 0.0
		print("[sprint capture] gameplay begins frame=", Engine.get_frames_drawn())
	clock += delta
	if clock > 1.5 and not started:
		started = true
		Input.action_press("move_forward")
	if sprint.run.phase == 2 and not retried:
		Input.action_release("move_forward")
		if clock > 15.0:
			print("[sprint capture] FINISHED time=", sprint.run.elapsed, " best=", sprint.run.best)
			sprint._retry.pressed.emit()
			retried = true
	if retried and clock > 17.0 and not flight and not game.hero.frozen:
		flight = true
		Input.action_press("fly_toggle")
	if flight and clock > 17.1:
		Input.action_release("fly_toggle")
	if clock > 21.0:
		print("[sprint capture] final phase=", sprint.run.phase, " reason=", sprint.run.reason)
		root.get_node("Settings").set_value("show_stats", old_stats)
		quit(0 if retried and sprint.run.phase == 3 else 1)
	return false
