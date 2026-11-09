extends Node
## Synthetic rule checks: crossings, rejected shortcuts, repeatability and
## world-space continuity across an origin shift. Run sprint_test.tscn.
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1

func point(distance: float) -> Vector3:
	return SprintRun.START + SprintRun.DIRECTION * distance

func staged() -> SprintRun:
	var run := SprintRun.new()
	run.sample(point(-4), 0.1, true)
	run.sample(point(-4), 0.1, true)
	return run

func _ready() -> void:
	var run := staged()
	for i in range(-3, 102):
		run.sample(point(float(i)), 0.1, true)
	check(run.phase == SprintRun.Phase.FINISHED, "Ground run finishes")
	check(absf(run.elapsed - 10.0) < 0.001, "Interpolated 100 m time")
	var best := run.best
	run.reset()
	check(run.phase == SprintRun.Phase.READY and run.elapsed == 0.0 and run.best == best, "Retry preserves session best only")
	run = staged()
	run.sample(point(100), 0.1, true)
	check(run.phase == SprintRun.Phase.INVALID and is_inf(run.best), "Teleport cannot finish")
	run = staged()
	run.sample(point(-3), 0.1, false, "Flight")
	check(run.phase == SprintRun.Phase.INVALID and run.reason == "Flight", "Powers void the run")
	run = staged()
	run.sample(point(-3) + Vector3(SprintRun.DIRECTION.z, 0, -SprintRun.DIRECTION.x) * 7.0, 0.1, true)
	check(run.phase == SprintRun.Phase.INVALID, "Leaving corridor voids the run")
	run = staged()
	WorldOrigin.shift(Vector3(2000, 0, 0))
	run.sample(WorldOrigin.to_world(WorldOrigin.to_local(point(-3))), 0.1, true)
	check(run.phase == SprintRun.Phase.READY, "Origin shift retains world-space progress")
	WorldOrigin.shift(Vector3(-2000, 0, 0))
	run = SprintRun.new()
	run.sample(point(-0.5), 0.1, true)
	run.sample(point(0.5), 0.1, true)
	check(run.phase == SprintRun.Phase.INVALID, "Must stop in staging area")
	run = staged()
	for i in 610:
		run.sample(point(1.0), 0.1, true)
	check(run.phase == SprintRun.Phase.INVALID, "Stopped run times out")
	print("sprint_test: ", "PASS" if failures == 0 else "FAIL", " (9 checks)")
	get_tree().quit(failures)
