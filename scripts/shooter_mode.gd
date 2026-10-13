extends Node3D

const BOT_COUNT := 5
const KILLS_TO_WIN := 15
const ROUND_LENGTH := 180.0
const MAGAZINE_SIZE := 30

var player: CharacterBody3D
var camera: Camera3D
var bots: Array[CharacterBody3D] = []
var hud: Label
var center_message: Label
var health := 100
var ammo := MAGAZINE_SIZE
var reserve_ammo := 120
var kills := 0
var round_time := ROUND_LENGTH
var fire_cooldown := 0.0
var reload_time := 0.0
var reloading := false
var round_over := false
var bot_fire_timers: Dictionary = {}

func _ready() -> void:
	_build_environment()
	_build_arena()
	_build_player()
	_build_bots()
	_build_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_environment() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#8eb5cf")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 0.9)
	env.ambient_light_energy = 0.9
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

func _build_arena() -> void:
	_add_box(Vector3(0, -0.5, 0), Vector3(42, 1, 42), Color("#657d4a"))
	_add_box(Vector3(0, 2, -21), Vector3(42, 4, 1), Color("#8a765b"))
	_add_box(Vector3(0, 2, 21), Vector3(42, 4, 1), Color("#8a765b"))
	_add_box(Vector3(-21, 2, 0), Vector3(1, 4, 42), Color("#8a765b"))
	_add_box(Vector3(21, 2, 0), Vector3(1, 4, 42), Color("#8a765b"))
	# Minecraft-style block cover, crates and short walls.
	var cover := [
		[Vector3(-7, 1, -6), Vector3(4, 2, 2), Color("#9a7148")],
		[Vector3(7, 1, -7), Vector3(3, 2, 4), Color("#a7804f")],
		[Vector3(-10, 1, 5), Vector3(2, 2, 5), Color("#7b8b8b")],
		[Vector3(10, 1, 6), Vector3(5, 2, 2), Color("#7b8b8b")],
		[Vector3(0, 1, -11), Vector3(6, 2, 2), Color("#a7804f")],
		[Vector3(0, 1, 10), Vector3(6, 2, 2), Color("#a7804f")],
		[Vector3(-4, 0.5, 1), Vector3(2, 1, 2), Color("#5c7850")],
		[Vector3(5, 0.5, 2), Vector3(2, 1, 2), Color("#5c7850")],
		[Vector3(-13, 1.5, -12), Vector3(3, 3, 3), Color("#66875a")],
		[Vector3(13, 1.5, 12), Vector3(3, 3, 3), Color("#66875a")]
	]
	for item in cover:
		_add_box(item[0], item[1], item[2])

func _add_box(pos: Vector3, dimensions: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.2, 15)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0.48, 0)
	camera.current = true
	player.add_child(camera)
	# Simple blocky first-person weapon model.
	var gun := MeshInstance3D.new()
	var gun_mesh := BoxMesh.new()
	gun_mesh.size = Vector3(0.22, 0.18, 0.65)
	gun.mesh = gun_mesh
	gun.position = Vector3(0.32, -0.28, -0.58)
	var gun_material := StandardMaterial3D.new()
	gun_material.albedo_color = Color("#353b40")
	gun.material_override = gun_material
	camera.add_child(gun)
	var barrel := MeshInstance3D.new()
	var barrel_mesh := BoxMesh.new()
	barrel_mesh.size = Vector3(0.09, 0.09, 0.38)
	barrel.mesh = barrel_mesh
	barrel.position = Vector3(0.32, -0.23, -0.98)
	barrel.material_override = gun_material
	camera.add_child(barrel)
	add_child(player)

func _build_bots() -> void:
	var positions := [
		Vector3(-12, 1.1, -12), Vector3(12, 1.1, -12),
		Vector3(-13, 1.1, 7), Vector3(13, 1.1, -2),
		Vector3(0, 1.1, -16)
	]
	for i in range(BOT_COUNT):
		_spawn_bot(positions[i])

func _spawn_bot(pos: Vector3) -> void:
	var bot := CharacterBody3D.new()
	bot.name = "BlockBot_%d" % bots.size()
	bot.position = pos
	bot.set_meta("hp", 100)
	bot.set_meta("fire_timer", randf_range(0.7, 1.8))
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	bot.add_child(collision)
	_add_bot_cube(bot, Vector3(0, 0.05, 0), Vector3(0.72, 0.95, 0.42), Color("#a84a3d"))
	_add_bot_cube(bot, Vector3(0, 0.78, 0), Vector3(0.58, 0.58, 0.58), Color("#d5a47b"))
	_add_bot_cube(bot, Vector3(0, 0.83, -0.30), Vector3(0.34, 0.12, 0.06), Color("#242424"))
	add_child(bot)
	bots.append(bot)

func _add_bot_cube(parent: Node3D, pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(22, 18)
	hud.add_theme_font_size_override("font_size", 22)
	hud.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(hud)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -18)
	crosshair.add_theme_font_size_override("font_size", 30)
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(crosshair)
	var controls := Label.new()
	controls.text = "WASD: di chuyển  |  Space: nhảy  |  Chuột trái: bắn  |  R: nạp đạn  |  Esc: thả chuột"
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.position = Vector2(16, -42)
	controls.add_theme_font_size_override("font_size", 15)
	controls.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(controls)
	center_message = Label.new()
	center_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center_message.position = Vector2(-260, -80)
	center_message.size = Vector2(520, 160)
	center_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_message.add_theme_font_size_override("font_size", 30)
	center_message.add_theme_color_override("font_color", Color("#ffe9a8"))
	center_message.visible = false
	canvas.add_child(center_message)
	_update_hud()

func _process(delta: float) -> void:
	if round_over:
		return
	if fire_cooldown > 0.0:
		fire_cooldown -= delta
	if reloading:
		reload_time -= delta
		if reload_time <= 0.0:
			var needed := MAGAZINE_SIZE - ammo
			var loaded := mini(needed, reserve_ammo)
			ammo += loaded
			reserve_ammo -= loaded
			reloading = false
			_update_hud()
	round_time = maxf(0.0, round_time - delta)
	if round_time <= 0.0:
		_end_round("HẾT GIỜ! Bạn hạ được %d/%d bot." % [kills, KILLS_TO_WIN])
		return
	if health <= 0:
		_end_round("BẠN ĐÃ THUA! Nhấn Enter để chơi lại.")
		return
	if kills >= KILLS_TO_WIN:
		_end_round("CHIẾN THẮNG! Bạn đã hạ đủ %d bot." % KILLS_TO_WIN)
		return
	_update_hud()

func _physics_process(delta: float) -> void:
	if round_over:
		return
	if not player:
		return
	if not player.is_on_floor():
		player.velocity.y -= 22.0 * delta
	if Input.is_key_pressed(KEY_SPACE) and player.is_on_floor():
		player.velocity.y = 7.0
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	player.velocity.x = direction.x * 7.0
	player.velocity.z = direction.z * 7.0
	player.move_and_slide()
	for bot in bots:
		if not is_instance_valid(bot):
			continue
		var to_player := player.global_position - bot.global_position
		var distance := to_player.length()
		if distance > 2.5:
			var move_dir := Vector3(to_player.x, 0, to_player.z).normalized()
			bot.velocity.x = move_dir.x * 2.3
			bot.velocity.z = move_dir.z * 2.3
			bot.rotation.y = atan2(-move_dir.x, -move_dir.z)
		else:
			bot.velocity.x = move_toward(bot.velocity.x, 0.0, 8.0 * delta)
			bot.velocity.z = move_toward(bot.velocity.z, 0.0, 8.0 * delta)
		if not bot.is_on_floor():
			bot.velocity.y -= 22.0 * delta
		bot.move_and_slide()
		var timer := float(bot.get_meta("fire_timer", 1.0)) - delta
		if distance < 18.0 and timer <= 0.0:
			health = maxi(0, health - randi_range(4, 9))
			timer = randf_range(0.8, 1.6)
		bot.set_meta("fire_timer", timer)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not round_over:
		player.rotate_y(-event.relative.x * 0.0025)
		camera.rotate_x(-event.relative.y * 0.0025)
		camera.rotation.x = clampf(camera.rotation.x, -1.5, 1.5)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_R and not round_over:
			_start_reload()
		elif event.keycode == KEY_ENTER and round_over:
			get_tree().reload_current_scene()
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not round_over:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_LEFT and not round_over:
			_shoot()

func _shoot() -> void:
	if reloading or fire_cooldown > 0.0:
		return
	if ammo <= 0:
		_start_reload()
		return
	ammo -= 1
	fire_cooldown = 0.13
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin + (-camera.global_transform.basis.z * 60.0))
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target = hit.get("collider")
		if target is CharacterBody3D and bots.has(target):
			var hp := int(target.get_meta("hp", 100)) - 34
			target.set_meta("hp", hp)
			if hp <= 0:
				bots.erase(target)
			target.queue_free()
				kills += 1
				if not round_over:
					_spawn_bot(_random_bot_spawn())
	_update_hud()

func _random_bot_spawn() -> Vector3:
	var spots := [Vector3(-14, 1.1, -14), Vector3(14, 1.1, -14), Vector3(-14, 1.1, 10), Vector3(14, 1.1, 5), Vector3(0, 1.1, -16)]
	return spots[randi() % spots.size()]

func _start_reload() -> void:
	if reloading or ammo == MAGAZINE_SIZE or reserve_ammo <= 0:
		return
	reloading = true
	reload_time = 1.5
	_update_hud()

func _update_hud() -> void:
	if hud == null:
		return
	var minutes := int(round_time) / 60
	var seconds := int(round_time) % 60
	var ammo_text := "ĐANG NẠP..." if reloading else "%d / %d" % [ammo, reserve_ammo]
	hud.text = "MÁU: %d   |   ĐẠN: %s\nBOT: %d / %d   |   THỜI GIAN: %02d:%02d" % [health, ammo_text, kills, KILLS_TO_WIN, minutes, seconds]

func _end_round(message: String) -> void:
	round_over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	center_message.text = message + "\nNhấn Enter để chơi lại"
	center_message.visible = true
