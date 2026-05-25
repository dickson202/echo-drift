extends Node2D

@onready var player: CharacterBody2D = $World/Player
@onready var player_shadow: Polygon2D = $World/PlayerShadow
@onready var glow_a: ColorRect = $GlowA
@onready var glow_b: ColorRect = $GlowB
@onready var fog_a: ColorRect = $FogBandA
@onready var fog_b: ColorRect = $FogBandB
@onready var beacon_a: Polygon2D = $World/BeaconA
@onready var beacon_b: Polygon2D = $World/BeaconB
@onready var title_card: PanelContainer = %TitleCard
@onready var objective_label: Label = %ObjectiveLabel
@onready var hint_label: Label = %HintLabel
@onready var status_label: RichTextLabel = %StatusLabel
@onready var progress_label: Label = %ProgressLabel
@onready var finish_panel: PanelContainer = %FinishPanel

var total_scans := 0
var scans_found := 0
var time_passed := 0.0
var scan_origins: Dictionary = {}

func _ready() -> void:
	_configure_input()
	var scans := get_tree().get_nodes_in_group("scan_pickups")
	total_scans = scans.size()
	for scan in scans:
		scan_origins[scan] = scan.position
		scan.body_entered.connect(_on_scan_body_entered.bind(scan))
	_update_ui()
	_play_intro()

func _process(delta: float) -> void:
	time_passed += delta
	player_shadow.position = player.position + Vector2(0, 82)
	_animate_scans()
	_animate_environment()

func _configure_input() -> void:
	if not InputMap.has_action("move_left"):
		InputMap.add_action("move_left")
		var left_event := InputEventKey.new()
		left_event.physical_keycode = KEY_A
		InputMap.action_add_event("move_left", left_event)
		var left_arrow := InputEventKey.new()
		left_arrow.physical_keycode = KEY_LEFT
		InputMap.action_add_event("move_left", left_arrow)

	if not InputMap.has_action("move_right"):
		InputMap.add_action("move_right")
		var right_event := InputEventKey.new()
		right_event.physical_keycode = KEY_D
		InputMap.action_add_event("move_right", right_event)
		var right_arrow := InputEventKey.new()
		right_arrow.physical_keycode = KEY_RIGHT
		InputMap.action_add_event("move_right", right_arrow)

	if not InputMap.has_action("move_up"):
		InputMap.add_action("move_up")
		var up_event := InputEventKey.new()
		up_event.physical_keycode = KEY_W
		InputMap.action_add_event("move_up", up_event)
		var up_arrow := InputEventKey.new()
		up_arrow.physical_keycode = KEY_UP
		InputMap.action_add_event("move_up", up_arrow)

	if not InputMap.has_action("move_down"):
		InputMap.add_action("move_down")
		var down_event := InputEventKey.new()
		down_event.physical_keycode = KEY_S
		InputMap.action_add_event("move_down", down_event)
		var down_arrow := InputEventKey.new()
		down_arrow.physical_keycode = KEY_DOWN
		InputMap.action_add_event("move_down", down_arrow)

func _play_intro() -> void:
	title_card.modulate.a = 1.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(1.4)
	tween.tween_property(title_card, "modulate:a", 0.0, 0.7)
	tween.finished.connect(func() -> void:
		title_card.visible = false
	)

func _animate_scans() -> void:
	for scan in scan_origins.keys():
		if not is_instance_valid(scan) or scan.get_meta("collected", false):
			continue
		var origin: Vector2 = scan_origins[scan]
		var bob := sin(time_passed * 2.2 + origin.x * 0.01) * 8.0
		scan.position = origin + Vector2(0, bob)
		scan.scale = Vector2.ONE * (1.0 + 0.08 * sin(time_passed * 3.1 + origin.y * 0.02))
		var ring := scan.get_node_or_null("Ring") as Polygon2D
		if ring:
			ring.rotation = time_passed * 0.8
			ring.scale = Vector2.ONE * (1.0 + 0.14 * sin(time_passed * 2.7 + origin.x * 0.015))

func _animate_environment() -> void:
	glow_a.modulate.a = 0.14 + 0.06 * sin(time_passed * 0.7)
	glow_b.modulate.a = 0.1 + 0.05 * sin(time_passed * 0.9 + 1.2)
	fog_a.position.x = sin(time_passed * 0.18) * 24.0
	fog_b.position.x = cos(time_passed * 0.14) * -18.0
	beacon_a.modulate.a = 0.08 + 0.1 * (0.5 + 0.5 * sin(time_passed * 1.8))
	beacon_b.modulate.a = 0.08 + 0.1 * (0.5 + 0.5 * sin(time_passed * 1.5 + 1.1))

func _on_scan_body_entered(body: Node2D, scan: Area2D) -> void:
	if body != player or scan.get_meta("collected", false):
		return

	scan.set_meta("collected", true)
	scan.visible = false
	scan.monitoring = false
	scans_found += 1

	var scan_name := str(scan.get_meta("scan_name", "Unknown Relic"))
	status_label.text = "Recovered [color=#7de4ff]%s[/color]. Environmental telemetry archived." % scan_name
	hint_label.text = "Recovered signal fragment. Continue through the ruin."
	_update_ui()

	if scans_found == total_scans:
		finish_panel.visible = true
		objective_label.text = "All relics recovered. Vertical slice complete."
		hint_label.text = "Traversal route complete."
		status_label.text = "Traversal, collection loop, and environmental storytelling are all demonstrated in one compact scene."

func _update_ui() -> void:
	progress_label.text = "%d / %d relic scans recovered" % [scans_found, total_scans]
	if scans_found < total_scans:
		objective_label.text = "Traverse the ruin and recover the three scattered relic scans."
		hint_label.text = "Move with WASD or arrow keys."
