class_name ExplorationDiscoveries
extends RefCounted
## Optional local session activity. Positions are documented street viewpoints
## from docs/REFERENCE.md, not building centroids or scene coordinates.
const NAMES: Array[String] = ["Times Square", "Flatiron Building", "Brooklyn Bridge", "DUMBO"]
const SPOTS: Array[Vector3] = [Vector3(13, 16.1, -67), Vector3(-291, 13.8, 1711), Vector3(-761, 43.5, 5975), Vector3(-346, 6.2, 6100)]
## A sphere prevents high flyovers counting as street visits; a short dwell
## lets passing players read feedback without rewarding a single stray tick.
const RADIUS := 70.0
const DWELL := 1.0

var enabled := false
var visited: Array[int] = []
var _dwell: Array[float] = [0.0, 0.0, 0.0, 0.0]


## Takes an absolute world position (Hero.world_position survives origin shifts).
## Returns the newly discovered index, or -1. Pausing retains session progress.
func sample(world_position: Vector3, delta: float) -> int:
	if not enabled:
		_dwell.fill(0.0)
		return -1
	for i in SPOTS.size():
		if visited.has(i):
			continue
		if world_position.distance_to(SPOTS[i]) <= RADIUS:
			_dwell[i] += delta
			if _dwell[i] >= DWELL:
				visited.append(i)
				return i
		else:
			_dwell[i] = 0.0
	return -1


func nearest(world_position: Vector3) -> int:
	var best := -1
	var distance := INF
	for i in SPOTS.size():
		if not visited.has(i):
			var candidate := world_position.distance_squared_to(SPOTS[i])
			if candidate < distance:
				distance = candidate
				best = i
	return best
