class_name SprintRun
extends RefCounted
## Session-only street trial rules in world meters. Segment crossings keep
## results independent of render FPS; no score is kept for an invalid run.

enum Phase { READY, RUNNING, FINISHED, INVALID }
const START := Vector3(420.0, 0.0, -220.0)
const DIRECTION: Vector3 = Vector3(0.484794006312, 0.0, -0.874628361903)
const LENGTH := 100.0
const HALF_WIDTH := 6.0
const MAX_SECONDS := 60.0

var phase := Phase.READY
var elapsed := 0.0
var best := INF
var reason := ""
var _previous := Vector3.ZERO
var _has_previous := false
var _staged := false


func reset() -> void:
	phase = Phase.READY
	elapsed = 0.0
	reason = ""
	_has_previous = false
	_staged = false


func along(point: Vector3) -> float:
	return (point - START).dot(DIRECTION)


func across(point: Vector3) -> float:
	return absf((point - START).dot(Vector3(DIRECTION.z, 0.0, -DIRECTION.x)))


func invalidate(why: String) -> void:
	if phase == Phase.READY or phase == Phase.RUNNING:
		phase = Phase.INVALID
		reason = why


## Called after the actual hero has moved. The caller supplies world positions
## so a floating-origin shift cannot look like a teleport or a finish.
func sample(point: Vector3, delta: float, legal: bool, why := "Stay on foot") -> void:
	if phase == Phase.FINISHED or phase == Phase.INVALID:
		return
	if not legal:
		invalidate(why)
		return
	if across(point) > HALF_WIDTH or along(point) < -10.0:
		invalidate("Left the marked street corridor")
		return
	if not _has_previous:
		_previous = point
		_has_previous = true
		return
	var movement := point.distance_to(_previous)
	if movement > 65.0 * delta + 0.35:
		invalidate("Travel or unexpected movement")
		return
	var before := along(_previous)
	var now := along(point)
	if phase == Phase.READY:
		if now >= -6.0 and now <= -1.0 and movement < delta:
			_staged = true
		if before < 0.0 and now >= 0.0:
			if not _staged:
				invalidate("Stop behind START before running")
				return
			phase = Phase.RUNNING
			elapsed = delta * now / (now - before)
	elif phase == Phase.RUNNING:
		elapsed += delta
		if before < LENGTH and now >= LENGTH:
			elapsed -= delta * (now - LENGTH) / (now - before)
			phase = Phase.FINISHED
			best = minf(best, elapsed)
		elif elapsed > MAX_SECONDS:
			invalidate("Time limit: 60 seconds")
	_previous = point
