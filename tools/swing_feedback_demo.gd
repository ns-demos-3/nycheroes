extends Node
## Reproducible real-world swing rehearsal/Movie Maker input driver.
## No physics overrides: only HeroInput movement, web presses and camera aim.
## Run with res://tools/swing_feedback_demo.tscn -- --tiles_url=http://localhost:8060/tiles
## --quality=low --solo=1 --name=SwingReview

const AVENUE := Vector3(0.485, 0.0, -0.875)
var game: Game
var elapsed := 0.0
var started := false
var frame := 0
var last_state := ""
var captured := -1


func _ready() -> void:
	process_physics_priority = -20
	# Wait until autoloads exist before loading the real game.
	call_deferred("_start")


func _start() -> void:
	game = load("res://scenes/world.tscn").instantiate() as Game
	add_child(game)
	game.player_input.process_mode = Node.PROCESS_MODE_DISABLED
	game.place_hero(Vector3(420.0, 30.0, -220.0), deg_to_rad(-29.0), true)


func _physics_process(_delta: float) -> void:
	if game == null:
		return
	frame += 1
	if game.hero.frozen or game.city.pending_count() > 0 and not started:
		return
	if not started:
		started = true
		print("DEMO_START physics_frame=", frame)
	elapsed += 1.0 / Engine.physics_ticks_per_second
	var input := game.hero.input
	input.clear()
	input.aim = AVENUE
	game.hero_camera.pitch = 0.1
	# Start with a stationary attachment.
	# Then swing along the avenue, releasing between ordinary web holds.
	if elapsed < 2.5:
		input.aim = AVENUE
		input.web_held = elapsed > 0.5
	elif elapsed < 17.0:
		input.move = AVENUE
		input.stick = Vector2(0.0, -1.0)
		input.web_held = fmod(elapsed - 2.5, 2.5) < 1.9
	var swing := game.hero.get_mode(&"Swing") as SwingMode
	var state := "%s/%s/%s" % [game.hero.mode.name, swing.rope_taut, swing.unavailable_time > 0.0]
	if state != last_state:
		print("DEMO %.2f %s position=%s" % [elapsed, state, game.hero.world_position()])
		last_state = state
	var second := int(elapsed)
	if second != captured and second in [1, 3, 6, 10, 15, 18]:
		captured = second
		_capture(second)
	if elapsed >= 19.0:
		get_tree().quit()


func _capture(second: int) -> void:
	var directory := LaunchOptions.get_string("evidence_dir")
	if directory.is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("native-%02d.png" % second))
