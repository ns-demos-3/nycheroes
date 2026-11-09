class_name PersonalWaypoint
extends PanelContainer
## Session-only navigation for our hero. Store a world position, never a scene
## position, so rebasing the city cannot move the destination. No network state.

const NEAR_DISTANCE := 30.0
const DIRECTIONS: Array[String] = ["Ahead", "Ahead left", "Left", "Behind left", "Behind", "Behind right", "Right", "Ahead right"]

var hero: Hero
var camera: ThirdPersonCamera
var options: OptionsPanel
var destination := Vector3.ZERO
var active := false
var _title: Label
var _guidance: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # hide the card while solo options pause the world
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(12.0, 82.0)
	custom_minimum_size = Vector2(280.0, 0.0)
	size.x = 330.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.075, 0.9)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	add_child(column)
	_title = Label.new()
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(_title)
	_guidance = Label.new()
	_guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_guidance.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	column.add_child(_guidance)
	var clear := Button.new()
	clear.text = "Clear waypoint · Backspace"
	clear.custom_minimum_size.y = 44.0
	clear.pressed.connect(dismiss)
	column.add_child(clear)
	visible = active
	if options:
		options.toggled.connect(func(open: bool) -> void: visible = active and not open)


func mark(world_position: Vector3, label: String) -> void:
	destination = world_position
	active = true
	_title.text = label
	_title.tooltip_text = label
	visible = true


func dismiss() -> void:
	active = false
	visible = false


## Horizontal straight-line guidance: an address often lies inside a building,
## so "Around here" means nearby, not that we found its entrance or a route.
func guidance() -> String:
	var delta := destination - hero.world_position()
	var distance := Vector2(delta.x, delta.z).length()
	if distance <= NEAR_DISTANCE:
		return "Around here · %d m · ground distance" % roundi(distance)
	var bearing := atan2(-delta.x, -delta.z)
	var relative := wrapf(bearing - camera.yaw, -PI, PI)
	var sector := posmod(roundi(relative / (PI / 4.0)), 8)
	var meters := "%d m" % roundi(distance) if distance < 1000.0 else "%.1f km" % (distance / 1000.0)
	return "%s · %s · straight line" % [DIRECTIONS[sector], meters]


func _process(_delta: float) -> void:
	size.x = minf(330.0, maxf(280.0, get_viewport_rect().size.x - 24.0))
	position.x = maxf(12.0, (get_viewport_rect().size.x - size.x) * 0.5)
	visible = active and (not options or not options.visible)
	if active and hero and camera:
		_guidance.text = guidance()


func _unhandled_key_input(event: InputEvent) -> void:
	if active and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_BACKSPACE:
		dismiss()
		get_viewport().set_input_as_handled()
