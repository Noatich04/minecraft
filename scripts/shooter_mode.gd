extends Node3D

const ENEMIES_PER_ROUND := 5
const WINS_TO_MATCH := 10
const SIDE_SWITCH_AT := 7
const ROUND_LENGTH := 180.0
const ROUND_BREAK := 2.5
const MAGAZINE_SIZE := 30

var player: CharacterBody3D
var camera: Camera3D
var bots: Array[CharacterBody3D] = []
var allies: Array[CharacterBody3D] = []
var hud: Label
var center_message: Label
var health := 100
var ammo := MAGAZINE_SIZE
var reserve_ammo := 120
var kills := 0
var player_round_wins := 0
var enemy_round_wins := 0
var round_number := 1
var side_switched := false
var intermission_time := 0.0
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
	_spawn_allies()
	_spawn_enemies()

func _spawn_allies() -> void:
	var z_near := -13.0 if side_switched else 13.0
	var z_back := -16.0 if side_switched else 16.0
	var positions := [
		Vector3(-4, 1.1, z_near), Vector3(4, 1.1, z_near),
		Vector3(-9, 1.1, z_back), Vector3(9, 1.1, z_back)
	]
	for i in range(4):
		_spawn_bot(positions[i], true)

func _spawn_enemies() -> void:
	for pos in _enemy_spawn_positions():
		_spawn_bot(pos, false)

func _spawn_bot(pos: Vector3, is_ally: bool) -> void:
	var bot := CharacterBody3D.new()
	bot.name = ("AllyBot_%d" % allies.size()) if is_ally else ("EnemyBot_%d" % bots.size())
	bot.position = pos
	bot.set_meta("hp", 100)
	bot.set_meta("team", "blue" if is_ally else "red")
	bot.set_meta("fire_timer", randf_range(0.7, 1.8))
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	bot.add_child(collision)
	var team_color := Color("#3d78c5") if is_ally else Color("#b8413b")
	_add_bot_cube(bot, Vector3(0, 0.05, 0), Vector3(0.72, 0.95, 0.42), team_color)
	_add_bot_cube(bot, Vector3(0, 0.78, 0), Vector3(0.58, 0.58, 0.58), Color("#d5a47b"))
	_add_bot_cube(bot, Vector3(0, 0.83, -0.30), Vector3(0.34, 0.12, 0.06), Color("#242424"))
	add_child(bot)
	if is_ally:
		allies.append(bot)
	else:
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
	if intermission_time > 0.0:
		intermission_time -= delta
		if intermission_time <= 0.0:
			_begin_next_round()
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
		_finish_round(false, "Hết giờ")
		return
	if health <= 0 and allies.is_empty():
		_finish_round(false, "Toàn đội xanh đã bị hạ")
		return
	if bots.is_empty():
		_finish_round(true, "Đã tiêu diệt toàn bộ 5 địch")
		return
	_update_hud()

func _physics_process(delta: float) -> void:
	if round_over or intermission_time > 0.0:
		return
	if not player:
		return
	if health > 0:
		if not player.is_on_floor():
			player.velocity.y -= 22.0 * delta
		if Input.is_key_pressed(KEY_SPACE) and player.is_on_floor():
			player.velocity.y = 7.0
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		player.velocity.x = direction.x * 7.0
		player.velocity.z = direction.z * 7.0
		player.move_and_slide()
	# Both teams seek opponents and exchange fire.
	for bot in allies.duplicate():
		_process_combat_bot(bot, bots, true, delta)
	for bot in bots.duplicate():
		_process_combat_bot(bot, allies, false, delta)

func _process_combat_bot(bot: CharacterBody3D, opponents: Array[CharacterBody3D], is_ally: bool, delta: float) -> void:
	if not is_instance_valid(bot):
		return
	var targets: Array[Node3D] = []
	for opponent in opponents:
		if is_instance_valid(opponent):
			targets.append(opponent)
	if not is_ally and health > 0 and is_instance_valid(player):
		targets.append(player)
	if targets.is_empty():
		bot.velocity.x = move_toward(bot.velocity.x, 0.0, 8.0 * delta)
		bot.velocity.z = move_toward(bot.velocity.z, 0.0, 8.0 * delta)
		return
	var target: Node3D = targets[0]
	var best_distance := bot.global_position.distance_to(target.global_position)
	for candidate in targets:
		var candidate_distance := bot.global_position.distance_to(candidate.global_position)
		if candidate_distance < best_distance:
			target = candidate
			best_distance = candidate_distance
	var to_target := target.global_position - bot.global_position
	var flat_dir := Vector3(to_target.x, 0, to_target.z).normalized()
	if best_distance > 8.0:
		bot.velocity.x = flat_dir.x * 2.8
		bot.velocity.z = flat_dir.z * 2.8
	else:
		bot.velocity.x = move_toward(bot.velocity.x, 0.0, 8.0 * delta)
		bot.velocity.z = move_toward(bot.velocity.z, 0.0, 8.0 * delta)
	bot.rotation.y = atan2(-flat_dir.x, -flat_dir.z)
	if not bot.is_on_floor():
		bot.velocity.y -= 22.0 * delta
	bot.move_and_slide()
	var timer := float(bot.get_meta("fire_timer", 1.0)) - delta
	if best_distance < 20.0 and timer <= 0.0:
		var damage := randi_range(5, 11)
		if target == player:
			health = maxi(0, health - damage)
		else:
			var target_hp := int(target.get_meta("hp", 100)) - damage
			target.set_meta("hp", target_hp)
			if target_hp <= 0:
				if is_ally:
					bots.erase(target)
				else:
					allies.erase(target)
				target.queue_free()
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
	if health <= 0 or reloading or fire_cooldown > 0.0:
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
	_update_hud()

func _random_bot_spawn() -> Vector3:
	var spots := _enemy_spawn_positions()
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
	var side_text := "ĐỘI XANH" if not side_switched else "ĐỘI ĐỎ"
	var switch_text := "ĐÃ ĐỔI BÊN" if side_switched else "ĐỔI BÊN KHI ĐẠT 7 HIỆP"
	hud.text = "HIỆP %d   |   TỶ SỐ %d - %d\\n%s   |   MÁU: %d   |   ĐẠN: %s\\nĐỊCH CÒN: %d/5   |   ĐỒNG ĐỘI CÒN: %d/4   |   %s   |   %02d:%02d" % [round_number, player_round_wins, enemy_round_wins, side_text, health, ammo_text, bots.size(), allies.size(), switch_text, minutes, seconds]

func _finish_round(player_won: bool, reason: String) -> void:
	if round_over or intermission_time > 0.0:
		return
	if player_won:
		player_round_wins += 1
	else:
		enemy_round_wins += 1
	_update_hud()
	if player_round_wins >= WINS_TO_MATCH or enemy_round_wins >= WINS_TO_MATCH:
		round_over = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var result := "CHIẾN THẮNG CHUNG CUỘC!" if player_round_wins >= WINS_TO_MATCH else "THUA TRẬN!"
		center_message.text = "%s\\nTỶ SỐ CUỐI: %d - %d\\nNhấn Enter để chơi lại" % [result, player_round_wins, enemy_round_wins]
		center_message.visible = true
		return
	if not side_switched and (player_round_wins >= SIDE_SWITCH_AT or enemy_round_wins >= SIDE_SWITCH_AT):
		side_switched = true
		center_message.text = "ĐỔI BÊN!\\nHai bên đổi vị trí hồi sinh.\\n%s\\nTỶ SỐ: %d - %d" % [("Bạn thắng hiệp!" if player_won else "Đội địch thắng hiệp!"), player_round_wins, enemy_round_wins]
	else:
		center_message.text = "%s\\n%s\\nTỶ SỐ: %d - %d" % [("THẮNG HIỆP!" if player_won else "THUA HIỆP!"), reason, player_round_wins, enemy_round_wins]
	center_message.visible = true
	intermission_time = ROUND_BREAK
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _begin_next_round() -> void:
	round_number = player_round_wins + enemy_round_wins + 1
	kills = 0
	health = 100
	ammo = MAGAZINE_SIZE
	reserve_ammo = 120
	reloading = false
	reload_time = 0.0
	round_time = ROUND_LENGTH
	fire_cooldown = 0.0
	for bot in bots + allies:
		if is_instance_valid(bot):
			bot.queue_free()
	bots.clear()
	allies.clear()
	player.position = Vector3(0, 1.2, -15 if side_switched else 15)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	_spawn_allies()
	_spawn_enemies()
	center_message.visible = false
	_update_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _enemy_spawn_positions() -> Array[Vector3]:
	if side_switched:
		return [Vector3(-12, 1.1, 12), Vector3(12, 1.1, 12), Vector3(-13, 1.1, -7), Vector3(13, 1.1, 2), Vector3(0, 1.1, 16)]
	return [Vector3(-12, 1.1, -12), Vector3(12, 1.1, -12), Vector3(-13, 1.1, 7), Vector3(13, 1.1, -2), Vector3(0, 1.1, -16)]
