extends Node3D

const ARENA_LENGTH := 18.0
const MAX_HITS := 5

var neutral_gravity := Vector3.ZERO
var calibrated := false
var tilt := Vector2.ZERO
var hits_taken := 0
var round_number := 1
var opponent_attack := "high"
var match_active := false
var message_label: Label
var status_label: Label
var calibration_button: Button
var player: Node3D
var opponent: Node3D
var player_lance: MeshInstance3D
var opponent_lance: MeshInstance3D

func _ready() -> void:
	_build_world()
	_build_hud()
	_update_status()
	set_process(true)

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.75)
	env.ambient_light_energy = 0.7
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -25, 0)
	sun.light_energy = 1.4
	add_child(sun)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 3.4, 9.5)
	camera.rotation_degrees = Vector3(-9, 0, 0)
	camera.current = true
	add_child(camera)

	_add_box("Arena floor", Vector3(0, -0.35, -1), Vector3(12, 0.7, 20), Color(0.38, 0.25, 0.16))
	_add_box("Left rail", Vector3(-6, 0.8, -1), Vector3(0.35, 1.6, 20), Color(0.25, 0.19, 0.15))
	_add_box("Right rail", Vector3(6, 0.8, -1), Vector3(0.35, 1.6, 20), Color(0.25, 0.19, 0.15))
	for z in [-7.5, -5.0, -2.5, 0.0, 2.5, 5.0]:
		_add_box("Arena lane stripe", Vector3(0, 0.015, z), Vector3(0.12, 0.025, 0.12), Color(0.83, 0.67, 0.42))

	player = _make_knight("You", Vector3(0, 1.45, 3.0), Color(0.62, 0.72, 0.84), true)
	opponent = _make_knight("Opponent", Vector3(0, 1.45, -5.0), Color(0.68, 0.19, 0.16), false)

	_add_box("Far grandstand", Vector3(0, 2.0, -10.5), Vector3(15, 4, 0.8), Color(0.22, 0.24, 0.3))
	for x in range(-7, 8, 2):
		_add_box("Stadium post", Vector3(float(x), 3.0, -10.0), Vector3(0.18, 6, 0.18), Color(0.55, 0.43, 0.29))

func _add_box(label: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _material(color)
	add_child(mesh_instance)
	return mesh_instance

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat

func _make_knight(label: String, pos: Vector3, armor: Color, is_player: bool) -> Node3D:
	var root := Node3D.new()
	root.name = label
	root.position = pos
	add_child(root)
	_add_knight_part(root, "Torso", Vector3(0, 0, 0), Vector3(0.75, 1.0, 0.48), armor)
	_add_knight_part(root, "Helmet", Vector3(0, 0.72, 0), Vector3(0.52, 0.52, 0.52), Color(0.72, 0.75, 0.79))
	_add_knight_part(root, "Visor", Vector3(0, 0.72, -0.25 if is_player else 0.25), Vector3(0.42, 0.13, 0.08), Color(0.12, 0.16, 0.2))
	_add_knight_part(root, "Jetpack", Vector3(-0.48, 0.05, 0), Vector3(0.25, 0.8, 0.34), Color(0.28, 0.31, 0.35))
	_add_knight_part(root, "Left boot", Vector3(-0.2, -0.72, 0), Vector3(0.22, 0.42, 0.28), Color(0.16, 0.18, 0.22))
	_add_knight_part(root, "Right boot", Vector3(0.2, -0.72, 0), Vector3(0.22, 0.42, 0.28), Color(0.16, 0.18, 0.22))
	var lance := MeshInstance3D.new()
	var lance_mesh := CylinderMesh.new()
	lance_mesh.top_radius = 0.035
	lance_mesh.bottom_radius = 0.035
	lance_mesh.height = 3.2
	lance.mesh = lance_mesh
	lance.rotation_degrees.z = 90
	lance.position = Vector3(1.6, 0.05, 0)
	lance.material_override = _material(Color(0.68, 0.48, 0.27))
	root.add_child(lance)
	if is_player:
		player_lance = lance
	else:
		opponent_lance = lance
	return root

func _add_knight_part(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = pos
	part.material_override = _material(color)
	parent.add_child(part)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.035, 0.055, 0.09, 0.84)
	panel.anchor_right = 1.0
	panel.offset_bottom = 142
	layer.add_child(panel)

	var title := Label.new()
	title.text = "JETPACK JOUSTING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.anchor_right = 1.0
	title.offset_top = 12
	title.offset_bottom = 52
	panel.add_child(title)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.anchor_right = 1.0
	status_label.offset_top = 57
	status_label.offset_bottom = 82
	panel.add_child(status_label)

	calibration_button = Button.new()
	calibration_button.text = "CALIBRATE PHONE"
	calibration_button.anchor_left = 0.5
	calibration_button.anchor_right = 0.5
	calibration_button.offset_left = -105
	calibration_button.offset_right = 105
	calibration_button.offset_top = 91
	calibration_button.offset_bottom = 132
	calibration_button.pressed.connect(_calibrate)
	panel.add_child(calibration_button)

	message_label = Label.new()
	message_label.text = "Calibrate, then defend and thrust!"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.anchor_left = 0.05
	message_label.anchor_right = 0.95
	message_label.anchor_top = 0.78
	message_label.anchor_bottom = 0.84
	message_label.add_theme_font_size_override("font_size", 19)
	layer.add_child(message_label)

	_add_touch_zone(layer, "HIGH BLOCK", Vector2(0, 0.57), Vector2(0.5, 0.78), "high_block")
	_add_touch_zone(layer, "HIGH THRUST", Vector2(0.5, 0.57), Vector2(1, 0.78), "high_attack")
	_add_touch_zone(layer, "LOW BLOCK", Vector2(0, 0.78), Vector2(0.5, 1), "low_block")
	_add_touch_zone(layer, "LOW THRUST", Vector2(0.5, 0.78), Vector2(1, 1), "low_attack")

func _add_touch_zone(layer: CanvasLayer, label_text: String, top_left: Vector2, bottom_right: Vector2, action: String) -> void:
	var zone := Button.new()
	zone.text = label_text
	zone.modulate = Color(1, 1, 1, 0.025)
	zone.focus_mode = Control.FOCUS_NONE
	zone.anchor_left = top_left.x
	zone.anchor_top = top_left.y
	zone.anchor_right = bottom_right.x
	zone.anchor_bottom = bottom_right.y
	zone.pressed.connect(func(): _player_action(action))
	layer.add_child(zone)

func _calibrate() -> void:
	neutral_gravity = Input.get_gravity()
	calibrated = true
	match_active = true
	hits_taken = 0
	round_number = 1
	message_label.text = "Calibration set! Opponent incoming."
	_update_status()

func _process(_delta: float) -> void:
	if calibrated:
		var gravity_now := Input.get_gravity()
		if gravity_now.length() > 1.0 and neutral_gravity.length() > 1.0:
			var difference := gravity_now - neutral_gravity
			tilt.x = clampf(difference.x / 5.0, -1.0, 1.0)
			tilt.y = clampf(difference.y / 5.0, -1.0, 1.0)
			player.rotation.z = lerpf(player.rotation.z, -tilt.x * 0.22, 0.12)
			player.position.y = lerpf(player.position.y, 1.45 - tilt.y * 0.3, 0.12)
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		player.position.x = lerpf(player.position.x, -1.0, 0.12)
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		player.position.x = lerpf(player.position.x, 1.0, 0.12)
	else:
		player.position.x = lerpf(player.position.x, 0.0, 0.08)

func _player_action(action: String) -> void:
	if not match_active:
		message_label.text = "Tap CALIBRATE PHONE to begin."
		return
	var action_high := action.begins_with("high")
	var action_blocks := action.ends_with("block")
	var opponent_high := opponent_attack == "high"
	var matched := action_high == opponent_high
	if action_blocks and matched:
		hits_taken = maxi(0, hits_taken - 1)
		message_label.text = "PERFECT BLOCK!"
	elif not action_blocks and matched:
		hits_taken = maxi(0, hits_taken - 1)
		message_label.text = "CLEAN THRUST!"
	else:
		hits_taken += 1
		message_label.text = "Counter-hit! Read the opponent."
	round_number += 1
	opponent_attack = "high" if randf() > 0.5 else "low"
	opponent.rotation.z = 0.16 if opponent_attack == "high" else -0.16
	if hits_taken >= MAX_HITS:
		match_active = false
		message_label.text = "KNOCKED OUT — recalibrate to try again."
	_update_status()

func _update_status() -> void:
	if status_label == null:
		return
	status_label.text = "ROUND %d   •   HITS %d/%d" % [round_number, hits_taken, MAX_HITS]
