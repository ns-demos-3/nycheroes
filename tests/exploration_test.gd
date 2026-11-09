extends Node
## Run: godot --headless --path . res://tests/exploration_test.tscn
func _ready() -> void:
	var activity := ExplorationDiscoveries.new()
	var spot := activity.SPOTS[0]
	assert(activity.sample(spot, 2.0) == -1)
	activity.enabled = true
	assert(activity.sample(spot + Vector3.UP * 100, 2.0) == -1)
	assert(activity.sample(spot, 0.6) == -1)
	assert(activity.sample(spot + Vector3.RIGHT * 100, 1.0) == -1)
	assert(activity.sample(spot, 0.6) == -1)
	# The caller supplies world position, including after the origin moves.
	WorldOrigin.offset = Vector3(2000, 0, -1000)
	var local := WorldOrigin.to_local(spot)
	assert(activity.sample(local + WorldOrigin.offset, 0.5) == 0)
	assert(activity.sample(spot, 2.0) == -1)
	activity.enabled = false
	assert(activity.visited.size() == 1)
	activity.enabled = true
	for i in range(1, 4):
		assert(activity.sample(activity.SPOTS[i], 1.1) == i)
	assert(activity.nearest(spot) == -1)
	print("Exploration: opt-in, altitude, dwell reset, origin shift, deduplication, pause and completion passed")
	get_tree().quit()
