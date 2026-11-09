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
		opponent.position.z = lerpf(-18.0, -6.2, _ease_out(clampf((intro_time - 0.7) / 3.5, 0.0, 1.0)))
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
	env.background_color = Color(0.36, 0.64, 0.91)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.78, 0.58)
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	env.glow_intensity = 0.0
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color(1.0, 0.78, 0.52)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	_add_box("Golden jousting lane", Vector3(0, -0.45, -4), Vector3(10, 0.8, 30), Color(0.55, 0.30, 0.13))
	var floor_surface := MeshInstance3D.new()
	floor_surface.name = "Textured sandstone floor"
	var floor_plane := PlaneMesh.new()
	floor_plane.size = Vector2(10.0, 30.0)
	floor_surface.mesh = floor_plane
	floor_surface.position = Vector3(0, -0.035, -4)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_texture = load("res://assets/arena_floor.svg")
	floor_material.roughness = 0.96
	floor_material.uv1_scale = Vector3(5.0, 15.0, 1.0)
	floor_surface.material_override = floor_material
	add_child(floor_surface)
	_add_box("Left arena wall", Vector3(-5.2, 0.6, -4), Vector3(0.35, 1.8, 30), Color(0.42, 0.12, 0.12))
	_add_box("Right arena wall", Vector3(5.2, 0.6, -4), Vector3(0.35, 1.8, 30), Color(0.42, 0.12, 0.12))
	_add_box("Center gold lane", Vector3(0, -0.015, -4), Vector3(0.12, 0.035, 28), Color(1.0, 0.77, 0.28))
	for z in range(-16, 8, 2):
		_add_box("Lane dash", Vector3(0, 0.015, float(z)), Vector3(0.055, 0.025, 0.5), Color(1.0, 0.85, 0.53))

	_build_green_countryside()
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

func _build_green_countryside() -> void:
	# Broad grassy grounds sit below the raised dirt jousting lane.
	var grass := MeshInstance3D.new()
	grass.name = "Green tournament grounds"
	var grass_mesh := PlaneMesh.new()
	grass_mesh.size = Vector2(90.0, 90.0)
	grass.mesh = grass_mesh
	grass.position = Vector3(0, -0.88, -12)
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_texture = load("res://assets/grass_meadow.svg") as Texture2D
	grass_mat.roughness = 1.0
	grass_mat.uv1_scale = Vector3(12.0, 12.0, 1.0)
	grass.material_override = grass_mat
	add_child(grass)

	# Soft rolling hills frame the arena without obscuring the jousting lane.
	for side in [-1, 1]:
		for i in range(3):
			var hill := _make_sphere("Rolling green hillside", Vector3(float(side) * (15.0 + i * 5.0), -0.2 + i * 0.25, -13.0 - i * 8.0), 1.0, Color(0.25 + i * 0.025, 0.43 + i * 0.025, 0.18))
			hill.scale = Vector3(7.0, 2.0 + i * 0.35, 11.0)

	# A distant northern-European stone keep: towers, curtain wall and slate roofs.
	var castle_wall := _add_box("Distant castle curtain wall", Vector3(0, 4.2, -24.0), Vector3(32.0, 7.0, 1.8), Color.WHITE)
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_texture = load("res://assets/castle_stone.svg") as Texture2D
	stone_mat.roughness = 0.95
	castle_wall.material_override = stone_mat
	for x in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		_add_box("Castle battlement", Vector3(x * 1.25, 7.95, -24.0), Vector3(1.1, 0.65, 1.4), Color(0.55, 0.55, 0.50))
	for x in [-12.0, 12.0]:
		_add_cylinder("Castle round tower", Vector3(x * 1.25, 5.2, -24.0), 1.9, 10.4, Color(0.52, 0.53, 0.49))
		_add_cone_roof(x * 1.25, 10.8, -24.0)
	# Small leafy trees break up the green horizon.
	for side in [-1, 1]:
		for i in range(4):
			var tx := float(side) * (11.5 + float(i) * 2.3)
			var tz := -22.0 + float(i) * 6.0
			_add_cylinder("Tree trunk", Vector3(tx, 1.0, tz), 0.22, 2.0, Color(0.30, 0.19, 0.10))
			var crown := _make_sphere("Leafy tree crown", Vector3(tx, 2.45, tz), 1.0, Color(0.16, 0.34, 0.13))
			crown.scale = Vector3(1.0, 1.2, 0.9)

func _add_cone_roof(x: float, y: float, z: float) -> void:
	var roof := _make_cone("Slate castle tower roof", 1.85, 2.2, Color(0.16, 0.23, 0.29))
	roof.position = Vector3(x, y, z)
	add_child(roof)

func _build_stands() -> void:
	var seat_colors := [Color(0.10, 0.27, 0.66), Color(0.72, 0.10, 0.14), Color(0.91, 0.59, 0.12), Color(0.12, 0.43, 0.27), Color(0.76, 0.77, 0.81)]
	for side in [-1, 1]:
		for row in range(4):
			var x := float(side) * (6.4 + row * 0.62)
			var y := 1.2 + row * 0.72
			_add_box("Stone terrace", Vector3(x, y, -5.0), Vector3(2.0, 0.42, 25.0), Color(0.43, 0.34, 0.29))
			for z_index in range(16):
				var z := -15.5 + float(z_index) * 1.45
				var color: Color = seat_colors[(z_index + row * 3 + side * 2 + 20) % seat_colors.size()]
				_add_crowd_figure(Vector3(x, y + 0.42, z), color)
		_add_box("Grandstand canopy", Vector3(float(side) * 7.8, 5.0, -5.0), Vector3(3.2, 0.3, 25.0), Color(0.12, 0.25, 0.48))
	for x in [-4.7, 4.7]:
		_add_box("Gold torch pillar", Vector3(x, 2.2, -7.0), Vector3(0.24, 4.4, 0.24), Color(0.75, 0.48, 0.12))
		_add_glow_orb(Vector3(x, 4.55, -7.0), 0.22, Color(1.0, 0.42, 0.08))

func _add_crowd_figure(pos: Vector3, color: Color) -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.16
	capsule.height = 0.62
	body.mesh = capsule
	body.position = pos + Vector3(0, 0.24, 0)
	body.material_override = _mat(color)
	add_child(body)
	var head := _make_sphere("Spectator head", pos + Vector3(0, 0.66, 0), 0.13, Color(0.86, 0.65, 0.48))
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_royal_box() -> void:
	_add_box("Royal balcony", Vector3(-4.5, 2.2, -2.5), Vector3(2.5, 0.45, 2.2), Color(0.52, 0.08, 0.12))
	_add_box("Royal canopy", Vector3(-4.5, 4.0, -2.5), Vector3(2.8, 0.25, 2.5), Color(0.78, 0.08, 0.12))
	_add_box("King torso", Vector3(-4.5, 3.0, -2.3), Vector3(0.65, 0.9, 0.45), Color(0.35, 0.12, 0.5))
	_add_sphere("King head", Vector3(-4.5, 3.7, -2.3), 0.32, Color(0.86, 0.57, 0.37))
	_add_box("King crown", Vector3(-4.5, 4.08, -2.3), Vector3(0.5, 0.18, 0.4), Color(1.0, 0.73, 0.08))
	_add_label_3d("THE KING", Vector3(-4.5, 4.45, -2.1), Color(1.0, 0.85, 0.4))

func _build_flags() -> void:
	var banner_texture := load("res://assets/royal_banner.svg") as Texture2D
	for side in [-1, 1]:
		for z in [-12.0, -6.0, 0.0, 5.0]:
			var x := float(side) * 5.65
			_add_cylinder("Gold banner pole", Vector3(x, 3.0, z), 0.045, 6.0, Color(0.78, 0.58, 0.22))
			var flag := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(0.9, 1.45)
			flag.mesh = plane
			flag.position = Vector3(x - 0.42 * side, 3.9, z)
			var cloth := StandardMaterial3D.new()
			cloth.albedo_texture = banner_texture
			cloth.roughness = 0.9
			cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
			flag.material_override = cloth
			add_child(flag)

func _build_first_person_view() -> void:
	var rig := Node3D.new()
	rig.name = "FirstPersonViewModel"
	camera.add_child(rig)
	view_lance = rig

	var shaft := _make_cylinder("RIGHT HAND - your lance shaft", 0.045, 2.8, Color(0.48, 0.25, 0.10))
	shaft.rotation_degrees.x = 90
	shaft.position = Vector3(0.53, -0.39, -1.35)
	rig.add_child(shaft)
	var grip := _make_cylinder("RIGHT HAND - lance grip", 0.075, 0.42, Color(0.18, 0.12, 0.09))
	grip.rotation_degrees.x = 90
	grip.position = Vector3(0.53, -0.39, -0.42)
	rig.add_child(grip)
	var tip := _make_cone("RIGHT HAND - steel lance tip", 0.13, 0.42, Color(0.78, 0.88, 0.98))
	tip.rotation_degrees.x = -90
	tip.position = Vector3(0.53, -0.39, -2.92)
	rig.add_child(tip)

	var forearm := _add_capsule_child(rig, "RIGHT HAND - rounded armored forearm", Vector3(0.68, -0.65, -0.42), 0.15, 0.72, Color(0.12, 0.27, 0.61))
	forearm.rotation_degrees.x = 90
	var gauntlet := _make_sphere_child(rig, "RIGHT HAND - steel gauntlet", Vector3(0.53, -0.48, -0.55), 0.2, Color(0.72, 0.78, 0.85))
	var left_arm := _add_capsule_child(rig, "LEFT HAND - rounded offhand vambrace", Vector3(-0.65, -0.68, -0.3), 0.12, 0.56, Color(0.12, 0.27, 0.61))
	left_arm.rotation_degrees.x = 90
	var shield := MeshInstance3D.new()
	shield.name = "LEFT HAND - royal shield"
	var shield_plane := PlaneMesh.new()
	shield_plane.size = Vector2(0.48, 0.62)
	shield.mesh = shield_plane
	shield.position = Vector3(-0.67, -0.48, -0.58)
	var shield_material := StandardMaterial3D.new()
	shield_material.albedo_texture = load("res://assets/royal_shield.svg")
	shield_material.roughness = 0.42
	shield_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shield.material_override = shield_material
	rig.add_child(shield)

func _make_opponent(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "RivalJouster"
	root.position = pos
	root.scale = Vector3(1.35, 1.35, 1.35)
	add_child(root)

	# Silhouette: layered rounded armor rather than a stack of cubes.
	_add_capsule_child(root, "Crimson padded gambeson", Vector3(0, 0.0, 0), 0.34, 1.05, Color(0.20, 0.055, 0.075))
	_add_ellipsoid_child(root, "Sculpted crimson breastplate", Vector3(0, 0.24, 0.12), Vector3(0.43, 0.48, 0.22), Color(0.60, 0.055, 0.095))
	_add_ellipsoid_child(root, "Gold breastplate rim", Vector3(0, 0.26, 0.245), Vector3(0.36, 0.39, 0.035), Color(0.91, 0.62, 0.19))
	_add_ellipsoid_child(root, "Breastplate inset", Vector3(0, 0.26, 0.275), Vector3(0.32, 0.35, 0.035), Color(0.47, 0.045, 0.075))
	_add_ellipsoid_child(root, "Neck gorget", Vector3(0, 0.62, 0.06), Vector3(0.29, 0.17, 0.24), Color(0.72, 0.76, 0.81))
	for side in [-1, 1]:
		_add_ellipsoid_child(root, "Gold edged pauldron", Vector3(float(side) * 0.43, 0.38, 0.02), Vector3(0.29, 0.25, 0.29), Color(0.79, 0.57, 0.20))
		_add_ellipsoid_child(root, "Crimson pauldron enamel", Vector3(float(side) * 0.43, 0.40, 0.12), Vector3(0.235, 0.19, 0.22), Color(0.59, 0.045, 0.08))
		var upper_arm := _add_capsule_child(root, "Armored upper arm", Vector3(float(side) * 0.53, -0.02, 0.02), 0.13, 0.55, Color(0.69, 0.72, 0.77))
		upper_arm.rotation.z = float(side) * -0.18
		var forearm := _add_capsule_child(root, "Armored forearm", Vector3(float(side) * 0.61, -0.36, 0.08), 0.12, 0.43, Color(0.76, 0.79, 0.83))
		forearm.rotation.z = float(side) * 0.12
		_add_ellipsoid_child(root, "Leather gauntlet", Vector3(float(side) * 0.62, -0.59, 0.13), Vector3(0.15, 0.13, 0.16), Color(0.20, 0.12, 0.09))
		_add_ellipsoid_child(root, "Hip armor", Vector3(float(side) * 0.19, -0.62, 0.02), Vector3(0.20, 0.24, 0.22), Color(0.67, 0.70, 0.75))
		var leg := _add_capsule_child(root, "Steel greave", Vector3(float(side) * 0.19, -1.02, 0.02), 0.14, 0.58, Color(0.60, 0.65, 0.72))
		leg.rotation.z = float(side) * -0.05

	# Helmet with a distinct brow, visor slit, cheek guards and plume.
	_add_ellipsoid_child(root, "Steel helmet dome", Vector3(0, 0.91, 0.02), Vector3(0.34, 0.39, 0.32), Color(0.75, 0.80, 0.86))
	_add_ellipsoid_child(root, "Helmet gold brow", Vector3(0, 0.83, 0.30), Vector3(0.32, 0.075, 0.055), Color(0.94, 0.68, 0.23))
	_add_box_child(root, "Black visor opening", Vector3(0, 0.72, 0.315), Vector3(0.43, 0.105, 0.045), Color(0.035, 0.055, 0.075))
	_add_box_child(root, "Visor highlight", Vector3(0, 0.755, 0.343), Vector3(0.32, 0.018, 0.012), Color(0.78, 0.88, 0.95))
	for side in [-1, 1]:
		_add_ellipsoid_child(root, "Helmet cheek guard", Vector3(float(side) * 0.25, 0.63, 0.18), Vector3(0.11, 0.21, 0.15), Color(0.63, 0.68, 0.75))
	var crest := _add_capsule_child(root, "Crimson helmet plume", Vector3(0, 1.25, -0.02), 0.075, 0.55, Color(0.72, 0.055, 0.10))
	crest.rotation.z = -0.22

	# Heraldic chest cloth: an actual SVG texture on a thin plane.
	var tabard := MeshInstance3D.new()
	tabard.name = "Knight heraldic chest cloth"
	var tabard_mesh := PlaneMesh.new()
	tabard_mesh.size = Vector2(0.48, 0.48)
	tabard.mesh = tabard_mesh
	tabard.position = Vector3(0, 0.15, 0.315)
	var tabard_mat := StandardMaterial3D.new()
	tabard_mat.albedo_texture = load("res://assets/knight_heraldry.svg") as Texture2D
	tabard_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tabard_mat.roughness = 0.78
	tabard.material_override = tabard_mat
	root.add_child(tabard)

	# Twin metal jetpack tanks and bright, compact exhausts.
	for side in [-1, 1]:
		var tank := _make_cylinder("Jetpack steel pressure tank", 0.13, 0.72, Color(0.34, 0.40, 0.48))
		tank.position = Vector3(float(side) * 0.25, 0.02, -0.31)
		root.add_child(tank)
		_add_ellipsoid_child(root, "Jetpack brass valve", Vector3(float(side) * 0.25, 0.40, -0.31), Vector3(0.10, 0.07, 0.10), Color(0.90, 0.61, 0.19))
		_add_glow_orb_child(root, Vector3(float(side) * 0.25, -0.43, -0.31), 0.10, Color(1.0, 0.42, 0.10))

	var rival_lance := _make_cylinder("Rival lance", 0.035, 2.5, Color(0.52, 0.31, 0.14))
	rival_lance.rotation_degrees.x = 90
	rival_lance.position = Vector3(0.67, -0.04, 0.92)
	root.add_child(rival_lance)
	var rival_tip := _make_cone("Rival lance steel tip", 0.10, 0.34, Color(0.82, 0.88, 0.93))
	rival_tip.rotation_degrees.x = -90
	rival_tip.position = Vector3(0.67, -0.04, 2.25)
	root.add_child(rival_tip)
	return root

func _add_ellipsoid_child(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	item.mesh = mesh
	item.position = pos
	item.scale = size
	item.material_override = _mat(color)
	parent.add_child(item)
	return item

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

func _make_sphere_child(parent: Node3D, label: String, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	item.mesh = mesh
	item.position = pos
	item.material_override = _mat(color)
	parent.add_child(item)
	return item

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

func _add_cylinder(label: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var item := _make_cylinder(label, radius, height, color)
	item.position = pos
	add_child(item)
	return item

func _add_capsule_child(parent: Node3D, label: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	item.mesh = mesh
	item.position = pos
	item.material_override = _mat(color)
	parent.add_child(item)
	return item

func _add_cylinder_child(parent: Node3D, label: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var item := _make_cylinder(label, radius, height, color)
	item.position = pos
	parent.add_child(item)
	return item

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
