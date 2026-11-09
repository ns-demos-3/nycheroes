class_name StreetSprint
extends Node3D
## Optional solo time trial (?sprint=1). Uses the real Hero and streamed city
## collision, with no custom movement, invisible track, or network state.

var game: Game
var run := SprintRun.new()
var _waiting := true
var _air_time := 0.0
var _markers: Array[Node3D] = []
var _status: Label
var _retry: Button


func _ready() -> void:
	process_physics_priority = 20  # sample after Hero and Game's ground placement
	_make_ui()
	restart()


func restart() -> void:
	if Net.state != Net.State.OFFLINE or Net.wants_public():
		_status.text = "Street sprint is solo. Leave co-op first."
		return
	run.reset()
	_waiting = true
	_air_time = 0.0
	for marker in _markers:
		marker.queue_free()
	_markers.clear()
	game.place_hero(SprintRun.START - SprintRun.DIRECTION * 4.0 + Vector3.UP * 30.0,
		atan2(-SprintRun.DIRECTION.x, -SprintRun.DIRECTION.z), true)


func _physics_process(delta: float) -> void:
	var hero := game.hero
	var end := SprintRun.START + SprintRun.DIRECTION * SprintRun.LENGTH
	var loaded := game.city.has_collision_at(SprintRun.START) and game.city.has_collision_at(end)
	if _waiting:
		_status.text = "SIXTH AVENUE · 100 m\nLoading the street…"
		if not loaded or hero.frozen or not hero.is_on_floor():
			return
		_make_gate(SprintRun.START, "START", Color(0.2, 0.95, 0.8))
		_make_gate(end, "FINISH", Color(1.0, 0.75, 0.15))
		_waiting = false
	_air_time = 0.0 if hero.is_on_floor() else _air_time + delta
	var legal := loaded and not hero.frozen and not game._free_camera_on \
		and Net.state == Net.State.OFFLINE and not Net.wants_public() \
		and hero.mode.name == &"OnFoot" and not hero.is_in_water() \
		and not hero.input.jump_held and not hero.input.web_held and _air_time < 0.18
	run.sample(hero.world_position(), delta, legal, "Run on the ground · no jumping, flight, webs, travel or co-op")
	for i in _markers.size():
		var point: Vector3 = SprintRun.START + SprintRun.DIRECTION * SprintRun.LENGTH * float(i)
		_markers[i].global_position = WorldOrigin.to_local(point)
	var best := "" if is_inf(run.best) else " · Best %.2f s" % run.best
	match run.phase:
		SprintRun.Phase.READY:
			_status.text = "SIXTH AVENUE · 100 m%s\nStop behind START, then run through FINISH\nW / stick to run · Shift / sprint allowed · stay between posts" % best
		SprintRun.Phase.RUNNING:
			_status.text = "STREET SPRINT   %.2f s%s\n%d / 100 m · keep running on the street" % [run.elapsed, best, clampi(int(run.along(hero.world_position())), 0, 100)]
		SprintRun.Phase.FINISHED:
			_status.text = "FINISHED   %.2f s%s\nSession best · Retry for another run" % [run.elapsed, best]
		SprintRun.Phase.INVALID:
			_status.text = "RUN VOID · no score%s\n%s\nRetry returns you to START" % [best, run.reason]


func _make_ui() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	var width := minf(500.0, get_viewport().get_visible_rect().size.x - 32.0)
	box.position = Vector2(-width * 0.5, 145.0)
	box.custom_minimum_size.x = width
	game.hud.add_child(box)
	game.hud.move_child(box, 0)  # loading and menus stay above the trial
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 18)
	_status.add_theme_color_override("font_outline_color", Color.BLACK)
	_status.add_theme_constant_override("outline_size", 6)
	box.add_child(_status)
	_retry = Button.new()
	_retry.text = "Retry street sprint"
	_retry.custom_minimum_size.y = 44.0
	_retry.focus_mode = Control.FOCUS_NONE
	_retry.pressed.connect(restart)
	box.add_child(_retry)


func _make_gate(point: Vector3, text: String, color: Color) -> void:
	var height := game.city.ground_height_at(point)
	if is_nan(height):
		run.invalidate("Street ground unavailable; retry once loaded")
		return
	var root := Node3D.new()
	add_child(root)
	_markers.append(root)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var across := Vector3(SprintRun.DIRECTION.z, 0.0, -SprintRun.DIRECTION.x)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.14
		mesh.bottom_radius = 0.25
		mesh.height = 3.0
		post.mesh = mesh
		post.material_override = material
		post.position = across * SprintRun.HALF_WIDTH * side + Vector3.UP * (height + 1.5)
		root.add_child(post)
	var line := MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(SprintRun.HALF_WIDTH * 2.0, 0.06, 0.45)
	line.mesh = bar
	line.material_override = material
	line.rotation.y = atan2(-SprintRun.DIRECTION.x, -SprintRun.DIRECTION.z)
	line.position.y = height + 0.08
	root.add_child(line)
	var label := Label3D.new()
	label.text = text + " · 100 m" if text == "FINISH" else text
	label.font_size = 60
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.position.y = height + 4.0
	root.add_child(label)
	root.global_position = WorldOrigin.to_local(point)
