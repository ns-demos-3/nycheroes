extends Node
## Reproducible Movie Maker driver for the actual world and ordinary inputs.

var game: Game
var tick := -1
var loaded_ticks := 0

func _ready() -> void:
	call_deferred("start")

func start() -> void:
	Settings.use_file("user://waypoint_movie.cfg")
	Settings.set_value("player_name", "Waypoint pilot")
	Settings.set_value("show_stats", false)
	game = load("res://scenes/world.tscn").instantiate()
	add_child(game)
	get_tree().physics_frame.connect(step)

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/data/waypoint/" + label + ".png")


func step() -> void:
	if tick < 0 and (game.hero.frozen or game.city.pending_count() > 0):
		return
	if tick < 0:
		loaded_ticks += 1
		if loaded_ticks < 60:
			return
		tick = 0
		print("[waypoint] gameplay begins at render frame ", Engine.get_process_frames())
		game._options.open()
		game._options._address.text = "40.76061, -73.98006"
	if tick in [120, 220, 680, 900, 1060]:
		capture("beat-%d" % tick)
	if tick == 180:
		game._options._address_mark.pressed.emit()
		print("[waypoint] marked through real Go to UI at ", game.hero.world_position(), " destination ", game._waypoint.destination)
	if tick == 240:
		Input.action_press("move_forward")
	if tick == 720:
		Input.action_release("move_forward")
		print("[waypoint] moved to ", game.hero.world_position(), " guidance ", game._waypoint.guidance())
	if tick > 740 and tick < 860:
		game.hero_camera.yaw += 0.008
	if tick == 930:
		game._options.open()
	if tick == 990:
		for button: Button in game._options.find_children("*", "Button", true, false):
			if button.text == "Clear personal waypoint":
				button.pressed.emit()
		game._options.close()
		print("[waypoint] clear active=", game._waypoint.active)
	if tick == 1080:
		print("[waypoint] finished at render frame ", Engine.get_process_frames())
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://waypoint_movie.cfg"))
		get_tree().quit()
	tick += 1
