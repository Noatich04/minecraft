extends Node3D

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const MOB_SCENE = preload("res://scenes/mob.tscn")
const SAVE_PATH := "user://voxel_world.json"

var world: VoxelWorld
var player: VoxelPlayer
var hud_label: Label
var help_label: Label
var inventory_panel: PanelContainer
var inventory_label: Label
var message_label: Label
var message_timer := 0.0
var inventory_open := false

func _ready() -> void:
	_build_environment()
	world = VoxelWorld.new()
	world.name = "World"
	add_child(world)
	player = PLAYER_SCENE.instantiate() as VoxelPlayer
	player.name = "Player"
	add_child(player)
	player.global_position = Vector3(32.5, world.terrain_height(32, 32) + 4.0, 32.5)
	_build_hud()
	_spawn_mobs()
	refresh_hud()
	show_message("Sinh tồn: slime gây sát thương. Thu thập gỗ/đá để chế tạo đồ.")

func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message_label.text = ""

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.48, 0.72, 0.94, 1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.80, 0.92)
	env.ambient_light_energy = 0.8
	env_node_setup(environment_node, env)
	add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.shadow_enabled = true
	add_child(sun)

func env_node_setup(node: WorldEnvironment, env: Environment) -> void:
	node.environment = env

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)
	hud_label = Label.new()
	hud_label.position = Vector2(18, 14)
	hud_label.add_theme_font_size_override("font_size", 18)
	hud_label.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(hud_label)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -18)
	crosshair.add_theme_font_size_override("font_size", 28)
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(crosshair)
	help_label = Label.new()
	help_label.text = "WASD di chuyển | Space nhảy | Chuột trái phá/đánh | Chuột phải đặt\n1-6 chọn khối | 7 kiếm gỗ | 8 kiếm đá | E túi đồ | F5 lưu | F9 tải | Esc thả chuột\nC ván | V que | B cuốc gỗ | N kiếm gỗ | M cuốc đá | J kiếm đá | K đuốc"
	help_label.position = Vector2(18, 585)
	help_label.add_theme_font_size_override("font_size", 14)
	help_label.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(help_label)
	message_label = Label.new()
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-320, 70)
	message_label.size = Vector2(640, 40)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(message_label)
	inventory_panel = PanelContainer.new()
	inventory_panel.position = Vector2(18, 115)
	inventory_panel.custom_minimum_size = Vector2(370, 440)
	inventory_panel.visible = false
	canvas.add_child(inventory_panel)
	inventory_label = Label.new()
	inventory_label.add_theme_font_size_override("font_size", 16)
	inventory_panel.add_child(inventory_label)

func _spawn_mobs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(8):
		var mob := MOB_SCENE.instantiate() as CharacterBody3D
		mob.name = "Slime_%d" % i
		add_child(mob)
		var x := rng.randi_range(8, VoxelWorld.WORLD_SIZE - 8)
		var z := rng.randi_range(8, VoxelWorld.WORLD_SIZE - 8)
		mob.global_position = Vector3(x + 0.5, world.terrain_height(x, z) + 2.0, z + 0.5)

func refresh_hud() -> void:
	if not is_instance_valid(player) or hud_label == null:
		return
	var inventory: Dictionary = player.inventory
	var selected := int(player.selected_block)
	var weapon_text := "Không cầm vũ khí"
	if player.selected_weapon != 0:
		weapon_text = player.item_name(player.selected_weapon)
	hud_label.text = "Máu: %d/20    Đói: %d/20\nKhối: %s (%d) | Vũ khí: %s\nCỏ: %d | Đất: %d | Đá: %d | Gỗ: %d | Ván: %d" % [
		player.health, player.hunger, VoxelWorld.BLOCK_NAMES.get(selected, "Khối"), selected, weapon_text,
		int(inventory.get(1, 0)), int(inventory.get(2, 0)), int(inventory.get(3, 0)),
		int(inventory.get(4, 0)), int(inventory.get(7, 0))
	]
	if inventory_open:
		_update_inventory_panel()

func _update_inventory_panel() -> void:
	var inventory: Dictionary = player.inventory
	inventory_label.text = "TÚI ĐỒ & CÔNG THỨC\n\nKHỐI\nCỏ: %d   Đất: %d   Đá: %d\nGỗ: %d   Lá: %d   Cát: %d\nVán gỗ: %d\n\nVẬT PHẨM\nQue gỗ: %d   Cuốc gỗ: %d   Kiếm gỗ: %d\nCuốc đá: %d   Kiếm đá: %d\nĐuốc: %d   Gel slime: %d\n\nCÔNG THỨC (bấm phím)\nC: 1 gỗ → 4 ván gỗ\nV: 2 ván gỗ → 4 que gỗ\nB: 3 ván + 2 que → cuốc gỗ\nN: 2 ván + 1 que → kiếm gỗ\nM: 3 đá + 2 que → cuốc đá\nJ: 2 đá + 1 que → kiếm đá\nK: 1 gỗ + 1 que → 4 đuốc\n\nKiếm gỗ gây 3 sát thương; kiếm đá gây 5.\nNhấn E để đóng túi đồ." % [
		int(inventory.get(1, 0)), int(inventory.get(2, 0)), int(inventory.get(3, 0)),
		int(inventory.get(4, 0)), int(inventory.get(5, 0)), int(inventory.get(6, 0)),
		int(inventory.get(7, 0)), int(inventory.get(101, 0)), int(inventory.get(102, 0)),
		int(inventory.get(103, 0)), int(inventory.get(104, 0)), int(inventory.get(105, 0)),
		int(inventory.get(106, 0)), int(inventory.get(108, 0))
	]

func toggle_inventory() -> void:
	inventory_open = not inventory_open
	inventory_panel.visible = inventory_open
	if inventory_open:
		_update_inventory_panel()

func show_message(text: String) -> void:
	if message_label:
		message_label.text = text
		message_timer = 3.0

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		show_message("Không thể mở tệp lưu.")
		return
	var data := {"world": world.save_world(), "player": player.save_player()}
	file.store_string(JSON.stringify(data))
	file.close()
	show_message("Đã lưu thế giới: " + SAVE_PATH)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		show_message("Chưa có dữ liệu lưu. Nhấn F5 để lưu trước.")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		show_message("Không đọc được tệp lưu.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		show_message("Tệp lưu bị lỗi.")
		return
	world.load_world(parsed.get("world", {}))
	player.load_player(parsed.get("player", {}))
	refresh_hud()
	show_message("Đã tải thế giới.")
