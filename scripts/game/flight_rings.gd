class_name FlightRings
extends Node3D
## Optional personal time trial above midtown. World-space swept plane checks
## keep fast flight and floating-origin shifts from skipping checkpoints.
## Only the local hero is scored; its ordinary flight state still syncs in co-op.

const START := Vector3(0.0, 360.0, 160.0)
const RADIUS := 18.0
const COURSE: Array[Vector3] = [
	Vector3(0, 360, 100), Vector3(24, 360, -25),
	Vector3(-24, 360, -150), Vector3(0, 360, -275),
	Vector3(24, 360, -400), Vector3(0, 360, -525),
]

var game: Game
var active := false
var checkpoint := 0
var elapsed := 0.0
var best := INF
var _city_ready := false
var _previous := Vector3.ZERO
var _rings: Array[MeshInstance3D] = []
var _panel: VBoxContainer
var _status: Label
var _start: Button
var _leave: Button


func _ready() -> void:
	add_to_group("floating")
	position = WorldOrigin.to_local(Vector3.ZERO)
	process_physics_priority = 10  # sample after the hero has moved
	game.city.initial_load_finished.connect(func(_seconds: float) -> void:
		_city_ready = true
		if active:
			game.hero.frozen = false)
	_make_ui()
	for point in COURSE:
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = RADIUS
		mesh.outer_radius = RADIUS + 1.0
		mesh.rings = 48
		mesh.ring_segments = 8
		ring.mesh = mesh
		ring.rotation.x = PI * 0.5
		ring.position = point
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_rings.append(ring)
	_refresh_rings()
	if LaunchOptions.get_string("rings") == "1":
		restart()


## Restart is deliberate travel to a fixed start, using Game's normal loading
## placement. This aerial start waits for the city, rather than ground collision
## (low quality deliberately omits street detail at this height). The clock
## starts at ring one, so loading and hovering cost no time.
func restart() -> void:
	active = true
	checkpoint = 0
	elapsed = 0.0
	game.place_hero(START, 0.0)
	game.hero.set_mode(&"Flight")
	game.hero.frozen = not _city_ready
	game.hero_camera.pitch = 0.0
	_previous = START
	_refresh_rings()
	_update_ui()


func leave() -> void:
	active = false
	_refresh_rings()
	_update_ui()


## Cross only the next ring, toward north, inside its opening. Test the
## segment-plane intersection rather than proximity to avoid boost tunneling.
static func crosses_ring(from: Vector3, to: Vector3, center: Vector3) -> bool:
	if from.z <= center.z or to.z > center.z:
		return false
	var fraction := (from.z - center.z) / (from.z - to.z)
	var hit := from.lerp(to, fraction) - center
	return Vector2(hit.x, hit.y).length() <= RADIUS


func _physics_process(delta: float) -> void:
	if not active:
		return
	var current := game.hero.world_position()
	if game.hero.frozen:
		_previous = current
		return
	if checkpoint > 0 and checkpoint < COURSE.size():
		elapsed += delta
	if current.distance_to(_previous) > 100.0:
		# Address travel / co-op placement is not a flight through the course.
		_previous = current
		return
	if checkpoint < COURSE.size() and game.hero.mode.name == &"Flight" \
			and crosses_ring(_previous, current, COURSE[checkpoint]):
		checkpoint += 1
		if checkpoint == COURSE.size():
			best = minf(best, elapsed)
		_refresh_rings()
	_previous = current
	_update_ui()


func _refresh_rings() -> void:
	for i in _rings.size():
		_rings[i].visible = active and i >= checkpoint
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.72, 0.08) if i == checkpoint else Color(0.16, 0.75, 0.95)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_rings[i].material_override = material


func _make_ui() -> void:
	_panel = VBoxContainer.new()
	_panel.position = Vector2(20, 76)
	_panel.add_theme_constant_override("separation", 6)
	game.hud.add_child(_panel)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 18)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.x = 270.0
	_status.add_theme_color_override("font_outline_color", Color.BLACK)
	_status.add_theme_constant_override("outline_size", 6)
	_panel.add_child(_status)
	var buttons := HBoxContainer.new()
	_panel.add_child(buttons)
	_start = Button.new()
	_start.focus_mode = Control.FOCUS_NONE
	_start.pressed.connect(restart)
	buttons.add_child(_start)
	_leave = Button.new()
	_leave.text = "Leave course"
	_leave.focus_mode = Control.FOCUS_NONE
	_leave.pressed.connect(leave)
	buttons.add_child(_leave)
	_update_ui()


func _update_ui() -> void:
	# Hide under menus: clicking challenge controls must not move a hero while
	# the player is naming it or editing options. Loading already covers these.
	_panel.visible = game.player_input.enabled and not is_instance_valid(game._loading)
	_start.text = "Restart rings" if active else "Fly ring course"
	_leave.visible = active
	if not active:
		_status.text = "MIDTOWN FLIGHT RINGS"
	elif checkpoint == COURSE.size():
		_status.text = "FINISH  6/6  ·  %.2f s\nBest this session: %.2f s" % [elapsed, best]
	else:
		_status.text = "FLIGHT RINGS  %d/6  ·  %.2f s\n%s" % [checkpoint, elapsed,
			"Fly through gold to start · W to fly" if checkpoint == 0 else "Next: gold ring · Shift boosts · Missed? Turn back"]


func _process(_delta: float) -> void:
	var debug := game.hud.get_node_or_null("DebugLabel") as Control
	_panel.position.y = 126.0 if debug and debug.visible else 76.0
	_panel.size.x = minf(430.0, get_viewport().get_visible_rect().size.x - 40.0)
	_panel.visible = game.player_input.enabled and not is_instance_valid(game._loading)
