extends Node3D

const MAX_HITS := 5
const INTRO_LENGTH := 5.5

var camera: Camera3D
var opponent: Node3D
var view_lance: Node3D
var neutral_gravity := Vector3.ZERO
var calibrated := false
var match_active := false
var intro_running := false
var intro_time := 0.0
var hits_taken := 0
var round_number := 1
var opponent_attack := "high"
var tilt := Vector2.ZERO
var status_label: Label
var message_label: Label
var title_panel: Control
var intro_button: Button
var calibrate_button: Button
var touch_layer: Control
var camera_home := Vector3(0, 2.05, 8.0)
var lance_home := Vector3(0.48, -0.42, -0.85)

func _ready() -> void:
	_build_world()
	_build_first_person_view()
	_build_hud()
	_show_title()

func _process(delta: float) -> void:
	if intro_running:
		intro_time += delta
		var t := clampf(intro_time / INTRO_LENGTH, 0.0, 1.0)
		camera.position = camera_home.lerp(Vector3(0, 1.85, 6.3), _ease_out(t))
		opponent.position.z = lerpf(-18.0, -7.8, _ease_out(clampf((intro_time - 0.7) / 3.5, 0.0, 1.0)))
		camera.rotation.x = lerpf(deg_to_rad(-5.0), deg_to_rad(-1.5), _ease_out(t))
		if intro_time >= INTRO_LENGTH:
			intro_running = false
			camera.position = Vector3(0, 1.85, 6.3)
			message_label.text = "HOLD YOUR PHONE NATURALLY, THEN CALIBRATE"
			calibrate_button.visible = true
			status_label.text = "THE CROWD IS WAITING"
	if calibrated:
		var gravity_now := Input.get_gravity()
		if gravity_now.length() > 1.0 and neutral_gravity.length() > 1.0:
			var difference := gravity_now - neutral_gravity
			tilt.x = clampf(difference.x / 4.5, -1.0, 1.0)
			tilt.y = clampf(difference.y / 4.5, -1.0, 1.0)
			camera.rotation.z = lerpf(camera.rotation.z, -tilt.x * 0.09, 0.09)
			camera.position.y = lerpf(camera.position.y, 1.85 - tilt.y * 0.22, 0.09)
			camera.position.x = lerpf(camera.position.x, tilt.x * 0.25, 0.09)
		if match_active:
			var bob := sin(Time.get_ticks_msec() * 0.004) * 0.012
			view_lance.position.y = bob
			view_lance.rotation.x = sin(Time.get_ticks_msec() * 0.003) * 0.012
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		camera.position.x = lerpf(camera.position.x, -0.35, 0.12)
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		camera.position.x = lerpf(camera.position.x, 0.35, 0.12)
	elif not calibrated:
		camera.position.x = lerpf(camera.position.x, 0.0, 0.1)

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.22, 0.48, 0.78)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.78, 0.58)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.55
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color(1.0, 0.78, 0.52)
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	add_child(sun)

	_add_box("Golden jousting lane", Vector3(0, -0.45, -4), Vector3(10, 0.8, 30), Color(0.55, 0.30, 0.13))
	_add_box("Left arena wall", Vector3(-5.2, 0.6, -4), Vector3(0.35, 1.8, 30), Color(0.42, 0.12, 0.12))
	_add_box("Right arena wall", Vector3(5.2, 0.6, -4), Vector3(0.35, 1.8, 30), Color(0.42, 0.12, 0.12))
	_add_box("Center gold lane", Vector3(0, -0.015, -4), Vector3(0.12, 0.035, 28), Color(1.0, 0.77, 0.28))
	for z in range(-16, 8, 2):
		_add_box("Lane dash", Vector3(0, 0.015, float(z)), Vector3(0.055, 0.025, 0.5), Color(1.0, 0.85, 0.53))

	_build_stands()
	_build_royal_box()
	_build_flags()
	opponent = _make_opponent(Vector3(0, 1.55, -18.0))

	camera = Camera3D.new()
	camera.name = "FirstPersonCamera"
	camera.position = camera_home
	camera.rotation_degrees = Vector3(-5, 0, 0)
	camera.fov = 82.0
	camera.current = true
	add_child(camera)

func _build_stands() -> void:
	var seat_colors := [Color(0.75, 0.13, 0.12), Color(0.12, 0.28, 0.62), Color(0.93, 0.62, 0.12), Color(0.16, 0.48, 0.28), Color(0.72, 0.72, 0.76)]
	for side in [-1, 1]:
		for row in range(4):
			var x := float(side) * (6.4 + row * 0.55)
			var y := 1.2 + row * 0.72
			_add_box("Terrace tier", Vector3(x, y, -5.0), Vector3(2.0, 0.55, 25.0), Color(0.30, 0.20, 0.16))
			for z_index in range(18):
				var z := -16.0 + float(z_index) * 1.35
				var color: Color = seat_colors[(z_index + row * 3 + side * 2 + 20) % seat_colors.size()]
				_add_box("Colorful crowd", Vector3(x, y + 0.42, z), Vector3(0.35, 0.38, 0.35), color)
		_add_box("Grandstand canopy", Vector3(float(side) * 7.8, 5.0, -5.0), Vector3(3.2, 0.35, 25.0), Color(0.62, 0.08, 0.12))
	for x in [-4.7, 4.7]:
		_add_box("Gold torch pillar", Vector3(x, 2.2, -7.0), Vector3(0.3, 4.4, 0.3), Color(0.75, 0.48, 0.12))
		_add_glow_orb(Vector3(x, 4.55, -7.0), 0.3, Color(1.0, 0.42, 0.08))

func _build_royal_box() -> void:
	_add_box("Royal balcony", Vector3(-4.5, 2.2, -2.5), Vector3(2.5, 0.45, 2.2), Color(0.52, 0.08, 0.12))
	_add_box("Royal canopy", Vector3(-4.5, 4.0, -2.5), Vector3(2.8, 0.25, 2.5), Color(0.78, 0.08, 0.12))
	_add_box("King torso", Vector3(-4.5, 3.0, -2.3), Vector3(0.65, 0.9, 0.45), Color(0.35, 0.12, 0.5))
	_add_sphere("King head", Vector3(-4.5, 3.7, -2.3), 0.32, Color(0.86, 0.57, 0.37))
	_add_box("King crown", Vector3(-4.5, 4.08, -2.3), Vector3(0.5, 0.18, 0.4), Color(1.0, 0.73, 0.08))
	_add_label_3d("THE KING", Vector3(-4.5, 4.45, -2.1), Color(1.0, 0.85, 0.4))

func _build_flags() -> void:
	for side in [-1, 1]:
		for z in [-12.0, -6.0, 0.0, 5.0]:
			var x := float(side) * 5.65
			_add_box("Banner pole", Vector3(x, 3.0, z), Vector3(0.09, 6.0, 0.09), Color(0.75, 0.58, 0.26))
			_add_box("Crimson banner", Vector3(x - 0.35 * side, 4.0, z), Vector3(0.75, 1.35, 0.08), Color(0.72, 0.06, 0.12))
			_add_box("Banner gold stripe", Vector3(x - 0.35 * side, 4.0, z - 0.05), Vector3(0.12, 1.1, 0.03), Color(1.0, 0.78, 0.16))

func _build_first_person_view() -> void:
	var rig := Node3D.new()
	rig.name = "FirstPersonViewModel"
	camera.add_child(rig)
	view_lance = rig

	var shaft := _make_cylinder("Your lance shaft", 0.045, 2.8, Color(0.48, 0.25, 0.10))
	shaft.rotation_degrees.x = 90
	shaft.position = Vector3(0.53, -0.39, -1.35)
	rig.add_child(shaft)
	var grip := _make_cylinder("Lance grip", 0.075, 0.42, Color(0.18, 0.12, 0.09))
	grip.rotation_degrees.x = 90
	grip.position = Vector3(0.53, -0.39, -0.42)
	rig.add_child(grip)
	var tip := _make_cone("Steel lance tip", 0.13, 0.42, Color(0.78, 0.88, 0.98))
	tip.rotation_degrees.x = -90
	tip.position = Vector3(0.53, -0.39, -2.92)
	rig.add_child(tip)

	var forearm := _make_box("Armored forearm", Vector3(0.38, 0.18, 0.62), Color(0.14, 0.28, 0.58))
	forearm.position = Vector3(0.68, -0.65, -0.42)
	rig.add_child(forearm)
	var gauntlet := _make_sphere_child(rig, "Steel gauntlet", Vector3(0.53, -0.48, -0.55), 0.2, Color(0.72, 0.78, 0.85))
	var left_arm := _make_box("Offhand vambrace", Vector3(0.25, 0.16, 0.5), Color(0.14, 0.28, 0.58))
	left_arm.position = Vector3(-0.65, -0.68, -0.3)
	rig.add_child(left_arm)
	var shield := _make_box("Small jousting shield", Vector3(0.38, 0.48, 0.12), Color(0.72, 0.08, 0.12))
	shield.position = Vector3(-0.67, -0.48, -0.58)
	rig.add_child(shield)
	var shield_badge := _make_sphere_child(rig, "Shield gold boss", Vector3(-0.67, -0.48, -0.67), 0.11, Color(1.0, 0.75, 0.12))

func _make_opponent(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "RivalJouster"
	root.position = pos
	add_child(root)
	_add_box_child(root, "Crimson armor", Vector3(0, 0, 0), Vector3(0.8, 1.0, 0.5), Color(0.65, 0.06, 0.1))
	_add_sphere_child(root, "Rival helmet", Vector3(0, 0.78, 0), 0.38, Color(0.78, 0.81, 0.87))
	_add_box_child(root, "Helmet visor", Vector3(0, 0.76, 0.34), Vector3(0.48, 0.13, 0.06), Color(0.07, 0.12, 0.2))
	_add_box_child(root, "Gold crest", Vector3(0, 1.18, 0), Vector3(0.13, 0.45, 0.13), Color(1.0, 0.68, 0.08))
	_add_box_child(root, "Jetpack", Vector3(-0.55, 0.0, 0), Vector3(0.3, 0.85, 0.4), Color(0.22, 0.25, 0.3))
	_add_glow_orb_child(root, Vector3(-0.55, -0.55, 0), 0.17, Color(0.1, 0.7, 1.0))
	_add_glow_orb_child(root, Vector3(-0.55, -0.85, 0), 0.11, Color(1.0, 0.35, 0.05))
	var lance := _make_cylinder("Rival lance", 0.045, 2.7, Color(0.58, 0.34, 0.13))
	lance.rotation_degrees.x = 90
	lance.position = Vector3(0.7, 0.0, 1.0)
	root.add_child(lance)
	return root

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := ColorRect.new()
	top.color = Color(0.025, 0.04, 0.09, 0.72)
	top.anchor_right = 1.0
	top.offset_bottom = 108
	layer.add_child(top)

	var title := Label.new()
	title.text = "⚔  JETPACK JOUSTING  ⚔"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_right = 1.0
	title.offset_top = 10
	title.offset_bottom = 49
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.38))
	top.add_child(title)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.anchor_right = 1.0
	status_label.offset_top = 57
	status_label.offset_bottom = 88
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	top.add_child(status_label)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.anchor_left = 0.06
	message_label.anchor_right = 0.94
	message_label.anchor_top = 0.69
	message_label.anchor_bottom = 0.76
	message_label.add_theme_font_size_override("font_size", 19)
	message_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58))
	layer.add_child(message_label)

	touch_layer = Control.new()
	touch_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(touch_layer)
	_add_touch_zone("high_block", Vector2(0, 0.52), Vector2(0.5, 0.75))
	_add_touch_zone("high_attack", Vector2(0.5, 0.52), Vector2(1, 0.75))
	_add_touch_zone("low_block", Vector2(0, 0.75), Vector2(0.5, 1))
	_add_touch_zone("low_attack", Vector2(0.5, 0.75), Vector2(1, 1))

	title_panel = Control.new()
	title_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(title_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.06, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_panel.add_child(shade)
	var title_big := Label.new()
	title_big.text = "JETPACK\nJOUSTING"
	title_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_big.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_big.offset_top = -120
	title_big.add_theme_font_size_override("font_size", 58)
	title_big.add_theme_color_override("font_color", Color(1.0, 0.78, 0.23))
	title_panel.add_child(title_big)
	var subtitle := Label.new()
	subtitle.text = "THE KINGDOM'S MOST DANGEROUS SPORT"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	subtitle.offset_left = -250
	subtitle.offset_top = 225
	subtitle.offset_right = 250
	subtitle.offset_bottom = 275
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	title_panel.add_child(subtitle)
	intro_button = Button.new()
	intro_button.text = "ENTER THE ARENA"
	intro_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	intro_button.offset_left = -140
	intro_button.offset_top = 100
	intro_button.offset_right = 140
	intro_button.offset_bottom = 160
	intro_button.add_theme_font_size_override("font_size", 22)
	intro_button.pressed.connect(_start_intro)
	title_panel.add_child(intro_button)

	calibrate_button = Button.new()
	calibrate_button.text = "CALIBRATE PHONE"
	calibrate_button.anchor_left = 0.5
	calibrate_button.anchor_right = 0.5
	calibrate_button.anchor_top = 0.84
	calibrate_button.anchor_bottom = 0.84
	calibrate_button.offset_left = -120
	calibrate_button.offset_right = 120
	calibrate_button.offset_top = -28
	calibrate_button.offset_bottom = 28
	calibrate_button.add_theme_font_size_override("font_size", 19)
	calibrate_button.pressed.connect(_calibrate)
	layer.add_child(calibrate_button)
	calibrate_button.visible = false

func _show_title() -> void:
	status_label.text = "A ROYAL TOURNAMENT AWAITS"
	message_label.text = "Jetpacks charged. Lances ready."
	calibrate_button.visible = false

func _start_intro() -> void:
	title_panel.visible = false
	intro_running = true
	intro_time = 0.0
	opponent.position = Vector3(0, 1.55, -18.0)
	message_label.text = "MAKE WAY FOR THE KING'S CHAMPIONS!"
	status_label.text = "THE GRAND TOURNAMENT"
	intro_button.release_focus()

func _calibrate() -> void:
	neutral_gravity = Input.get_gravity()
	calibrated = true
	match_active = true
	hits_taken = 0
	round_number = 1
	message_label.text = "CALIBRATED! READ THEIR LANCE!"
	_update_status()

func _add_touch_zone(action: String, top_left: Vector2, bottom_right: Vector2) -> void:
	var zone := Button.new()
	zone.text = ""
	zone.flat = true
	zone.focus_mode = Control.FOCUS_NONE
	zone.mouse_filter = Control.MOUSE_FILTER_STOP
	zone.modulate = Color(1, 1, 1, 0)
	zone.anchor_left = top_left.x
	zone.anchor_top = top_left.y
	zone.anchor_right = bottom_right.x
	zone.anchor_bottom = bottom_right.y
	zone.pressed.connect(func(): _player_action(action))
	touch_layer.add_child(zone)

func _player_action(action: String) -> void:
	if not match_active:
		message_label.text = "CALIBRATE FIRST!"
		return
	var action_high := action.begins_with("high")
	var action_blocks := action.ends_with("block")
	var matched := action_high == (opponent_attack == "high")
	if action_blocks and matched:
		hits_taken = maxi(0, hits_taken - 1)
		message_label.text = "PERFECT BLOCK!  CLANG!"
	elif not action_blocks and matched:
		hits_taken = maxi(0, hits_taken - 1)
		message_label.text = "DIRECT HIT!  WHAT A THRUST!"
	else:
		hits_taken += 1
		message_label.text = "YOU'VE BEEN CLIPPED! GUARD THE OTHER SIDE!"
	round_number += 1
	opponent_attack = "high" if randf() > 0.5 else "low"
	opponent.rotation.z = 0.16 if opponent_attack == "high" else -0.16
	if hits_taken >= MAX_HITS:
		match_active = false
		message_label.text = "KNOCKED OUT! RECALIBRATE TO RIDE AGAIN."
	_update_status()

func _update_status() -> void:
	status_label.text = "ROUND %d     •     HITS %d / %d" % [round_number, hits_taken, MAX_HITS]

func _add_box(label: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = pos
	item.material_override = _mat(color)
	add_child(item)
	return item

func _mat(color: Color, glow: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.48
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
	return mat

func _make_box(label: String, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = _mat(color)
	return item

func _make_cylinder(label: String, radius: float, height: float, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	item.mesh = mesh
	item.material_override = _mat(color)
	return item

func _make_cone(label: String, radius: float, height: float, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	item.mesh = mesh
	item.material_override = _mat(color)
	return item

func _make_sphere(label: String, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	item.mesh = mesh
	item.position = pos
	item.material_override = _mat(color)
	add_child(item)
	return item

func _make_sphere_child(parent: Node3D, label: String, pos: Vector3, radius: float, color: Color) -> void:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	item.mesh = mesh
	item.position = pos
	item.material_override = _mat(color)
	parent.add_child(item)

func _add_box_child(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var item := _make_box(label, size, color)
	item.position = pos
	parent.add_child(item)

func _add_glow_orb(pos: Vector3, radius: float, color: Color) -> void:
	var orb := _make_sphere("Torch flame", pos, radius, color)
	orb.material_override = _mat(color, true)

func _add_glow_orb_child(parent: Node3D, pos: Vector3, radius: float, color: Color) -> void:
	var orb := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	orb.mesh = mesh
	orb.position = pos
	orb.material_override = _mat(color, true)
	parent.add_child(orb)

func _ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)

func _add_sphere(label: String, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	return _make_sphere(label, pos, radius, color)

func _add_sphere_child(parent: Node3D, label: String, pos: Vector3, radius: float, color: Color) -> void:
	_make_sphere_child(parent, label, pos, radius, color)

func _add_label_3d(label_text: String, pos: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = label_text
	label.position = pos
	label.font_size = 48
	label.modulate = color
	add_child(label)
