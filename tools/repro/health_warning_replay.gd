extends Node
# Actual world, natural encounter director, ordinary HeroInput only.
var game: Game
var hero: Hero
var phase := 0
var elapsed := 0.0
var phase_time := 0.0
var last_notice := ""
var frame := 0
var first_low_frame := -1
var _flight_requested := false

func _ready() -> void:
	call_deferred("start")

func start() -> void:
	print("[replay] START")
	seed(29)
	game = load("res://scenes/world.tscn").instantiate() as Game
	add_child(game)
	hero = game.hero
	game.player_input.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.get_node("DebugLabel").visible = false
	game.hero_camera.yaw = -0.506
	game.hero_camera.pitch = -0.15

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hero):
		return
	frame = Engine.get_process_frames()
	if frame % 150 == 0:
		print("[replay] tick frame=%d frozen=%s pos=%s phase=%d hp=%.1f" % [frame, hero.frozen, hero.world_position(), phase, hero.health])
		call_deferred("save_frame")
	if hero.frozen:
		return
	elapsed += delta
	phase_time += delta
	hero.input.clear()
	var notice := (game.hud.get_node("GameHud") as GameHud).health_notice()
	if notice != last_notice:
		print("[replay] frame=%d time=%.2f health=%.2f mode=%s notice=%s" % [frame, elapsed, hero.health, hero.mode.name, notice])
		last_notice = notice
	if first_low_frame < 0 and notice.begins_with("LOW HEALTH"):
		first_low_frame = frame
		print("[replay] FIRST_LOW_FRAME=%d" % frame)
	if phase == 0 and LaunchOptions.has("replay_recovery") and hero.health <= 30.0 and hero.mode.name == &"OnFoot":
		phase = 3
		phase_time = 0.0
		print("[replay] RECOVERY_ESCAPE_FRAME=%d" % frame)
	var thug := game.encounters.nearest_thug(hero.world_position())
	if phase == 0 and thug:
		var offset := thug.global_position - hero.global_position
		offset.y = 0.0
		if offset.length() > 2.0:
			hero.input.move = offset.normalized()
			hero.input.stick = Vector2(0, -1)
			hero.input.aim = offset.normalized()
		if hero.mode.name == &"KnockedOut":
			phase = 1
			phase_time = 0.0
			print("[replay] KNOCKOUT_FRAME=%d" % frame)
	elif phase == 1 and hero.mode.name != &"KnockedOut":
		phase = 2
		phase_time = 0.0
		print("[replay] GETUP_FRAME=%d" % frame)
	elif phase == 2:
		# Let one normal punch land after get-up, then escape with normal flight.
		if hero.health < Hero.MAX_HEALTH or phase_time > 5.0:
			phase = 3
			phase_time = 0.0
	elif phase == 3:
		if not _flight_requested:
			_flight_requested = true
			hero.input.fly_toggle_pressed = true
		hero.input.vertical = 1.0 if phase_time < 1.0 else 0.0
		if phase_time > 10.0:
			print("[replay] FINISHED_FRAME=%d" % frame)
			get_tree().quit()
	if elapsed > 150.0:
		print("[replay] timeout")
		get_tree().quit(1)
	return

func save_frame() -> void:
	var directory := LaunchOptions.get_string("replay_frames")
	if not directory.is_empty():
		get_viewport().get_texture().get_image().save_png(directory.path_join("frame-%05d.png" % frame))
