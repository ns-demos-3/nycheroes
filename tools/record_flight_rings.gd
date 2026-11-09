extends Node
## Reproducible actual-world flight rehearsal / native Movie Maker input.
## godot --path . res://tools/record_flight_rings.tscn -- --rings=1 --solo=1
## Add --write-movie PATH.avi --fixed-fps 30 --resolution 1280x720 before --.
## Drives only ordinary HeroInput after loading; never changes flight physics.

var world: Game
var driver: RingPilot


func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	world = load("res://scenes/world.tscn").instantiate() as Game
	add_child(world)
	# This is a recording driver, not a second gameplay scene.
	world.player_input.set_physics_process(false)
	world._name_prompt.close()
	# Equivalent to turning off Show FPS and stats in the options menu.
	world.hud.get_node("DebugLabel").hide()
	driver = RingPilot.new()
	driver.world = world
	world.add_child(driver)


class RingPilot extends Node:
	var world: Game
	var time := 0.0
	var started := false
	var course: FlightRings
	var result_logged := false
	var restarted := false
	var previous_checkpoint := -1

	func _ready() -> void:
		process_physics_priority = -5
		course = world.get_node("FlightRings") as FlightRings

	func _physics_process(delta: float) -> void:
		world.hero.input.clear()
		if not started:
			if world.hero.frozen or is_instance_valid(world._loading) or world.city.pending_count() > 0:
				return
			started = true
			print("[rings recording] first_frame=", Engine.get_process_frames())
		if course.checkpoint != previous_checkpoint:
			previous_checkpoint = course.checkpoint
			print("[rings recording] checkpoint=", course.checkpoint, " position=", world.hero.world_position())
			_capture.call_deferred(course.checkpoint)
		time += delta
		if time < 1.0:
			return
		if course.checkpoint < FlightRings.COURSE.size():
			var target := FlightRings.COURSE[course.checkpoint]
			var direction := (target - world.hero.world_position()).normalized()
			# Same bounded stick/aim values as a player holding forward and looking.
			world.hero.input.stick = Vector2(0, -1)
			world.hero.input.aim = direction
			world.hero_camera.yaw = lerp_angle(world.hero_camera.yaw, atan2(-direction.x, -direction.z), delta * 3.0)
			world.hero_camera.pitch = 0.0
		elif not result_logged:
			result_logged = true
			print("[rings recording] FINISH checkpoints=", course.checkpoint, " time=", course.elapsed)
		if time > 24.0 and not restarted:
			restarted = true
			course.restart()
			print("[rings recording] RESTART checkpoints=", course.checkpoint, " time=", course.elapsed, " best=", course.best)
		if time > 25.0:
			print("[rings recording] final_frame=", Engine.get_process_frames())
			get_tree().quit()

	func _capture(index: int) -> void:
		await RenderingServer.frame_post_draw
		var folder := LaunchOptions.get_string("evidence", "/data/flight-rings")
		get_viewport().get_texture().get_image().save_png(folder.path_join("native-%d.png" % index))
