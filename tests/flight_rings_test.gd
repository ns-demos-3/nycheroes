extends Node
## Swept checkpoint detection at cruise/boost speeds, misses, direction,
## course ordering, restart, finish and floating-origin behavior.
## Run: godot --headless --path . res://tests/flight_rings_test.tscn

func _ready() -> void:
	var center := FlightRings.COURSE[0]
	assert(FlightRings.crosses_ring(center + Vector3(0, 0, 90), center - Vector3(0, 0, 90), center))
	assert(not FlightRings.crosses_ring(center + Vector3(25, 0, 10), center + Vector3(25, 0, -10), center))
	assert(not FlightRings.crosses_ring(center - Vector3(0, 0, 10), center + Vector3(0, 0, 10), center))
	assert(not FlightRings.crosses_ring(center, center, center))
	var world := load("res://scenes/world.tscn").instantiate() as Game
	add_child(world)
	# A consumed HUD click must not become the raw mouse attack / flight dive.
	Input.action_press("attack")
	world.player_input.attack_blocked = true
	world.player_input._physics_process(0.016)
	assert(not world.hero.input.attack_held)
	Input.action_release("attack")
	world.player_input.attack_blocked = false
	var course := world.get_node("FlightRings") as FlightRings
	course.restart()
	world.city.initial_load_finished.emit(0.0)
	assert(not world.hero.frozen)  # aerial start needs no near street collision
	course.set_physics_process(false)
	world.hero.set_physics_process(false)
	world.set_physics_process(false)
	# Crossing a later ring must not skip the first.
	world.hero.global_position = FlightRings.COURSE[2] - Vector3(0, 0, 5)
	course._previous = FlightRings.COURSE[2] + Vector3(0, 0, 5)
	course._physics_process(0.1)
	assert(course.checkpoint == 0)
	WorldOrigin.shift(Vector3(2000, 0, -2000))
	assert(course._rings[0].global_position.is_equal_approx(WorldOrigin.to_local(center)))
	for point in FlightRings.COURSE:
		course._previous = point + Vector3(0, 0, 5)
		world.hero.global_position = WorldOrigin.to_local(point - Vector3(0, 0, 5))
		course._physics_process(0.1)
	assert(course.checkpoint == 6)
	assert(is_equal_approx(course.elapsed, 0.5))
	assert(is_equal_approx(course.best, 0.5))
	course.restart()
	assert(course.checkpoint == 0 and course.elapsed == 0.0)
	assert(is_equal_approx(course.best, 0.5))
	assert(world.hero.world_position().is_equal_approx(FlightRings.START))
	course.leave()
	assert(not course.active and not course._rings[0].visible)
	print("Flight rings: swept crossing, miss, direction, order, origin shift, finish, restart, leave PASS")
	get_tree().quit()
