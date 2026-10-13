extends CharacterBody3D

const SPEED := 6.0
const JUMP_VELOCITY := 7.0
const REACH := 6.0
const GRAVITY := 20.0

@onready var camera: Camera3D = $Camera3D
var world: VoxelWorld
var health := 20
var hunger := 20
var inventory: Dictionary = {1: 12, 2: 20, 3: 8, 4: 4, 5: 0, 6: 0}
var selected_block := 1
var survival_clock := 0.0
var attack_cooldown := 0.0

func _ready() -> void:
	world = get_parent().get_node("World") as VoxelWorld
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.0025)
		camera.rotate_x(-event.relative.y * 0.0025)
		camera.rotation.x = clampf(camera.rotation.x, -1.50, 1.50)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_1: selected_block = 1
		elif event.keycode == KEY_2: selected_block = 2
		elif event.keycode == KEY_3: selected_block = 3
		elif event.keycode == KEY_4: selected_block = 4
		elif event.keycode == KEY_5: selected_block = 5
		elif event.keycode == KEY_F5:
			get_parent().save_game()
		elif event.keycode == KEY_F9:
			get_parent().load_game()
		elif event.keycode == KEY_E:
			get_parent().toggle_inventory()
		elif event.keycode == KEY_C:
			craft_recipe()
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			mine_block()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			place_block()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * 7.0 * delta)
	move_and_slide()
	survival_clock += delta
	if survival_clock >= 18.0:
		survival_clock = 0.0
		hunger = maxi(0, hunger - 1)
		if hunger == 0:
			health = maxi(0, health - 1)
		get_parent().refresh_hud()
	if health <= 0:
		health = 20
		hunger = 15
		global_position = Vector3(32, 22, 32)

func raycast_block() -> Dictionary:
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z * REACH)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_ray(query)

func mine_block() -> void:
	var hit := raycast_block()
	if hit.is_empty():
		return
	var block_pos := Vector3i(floori(hit.position.x - hit.normal.x * 0.02), floori(hit.position.y - hit.normal.y * 0.02), floori(hit.position.z - hit.normal.z * 0.02))
	var kind := world.get_block(block_pos)
	if kind == VoxelWorld.AIR:
		return
	if world.set_block(block_pos, VoxelWorld.AIR):
		inventory[kind] = int(inventory.get(kind, 0)) + 1
		get_parent().refresh_hud()

func place_block() -> void:
	var hit := raycast_block()
	if hit.is_empty() or int(inventory.get(selected_block, 0)) <= 0:
		return
	var p := Vector3i(floori(hit.position.x + hit.normal.x * 0.02), floori(hit.position.y + hit.normal.y * 0.02), floori(hit.position.z + hit.normal.z * 0.02))
	var center := Vector3(p) + Vector3(0.5, 0.5, 0.5)
	if global_position.distance_to(center) < 1.35:
		return
	if world.get_block(p) != VoxelWorld.AIR:
		return
	if world.set_block(p, selected_block):
		inventory[selected_block] = int(inventory[selected_block]) - 1
		get_parent().refresh_hud()

func craft_recipe() -> void:
	# Simple starter recipe: combine two dirt blocks into one stone block.
	if int(inventory.get(VoxelWorld.DIRT, 0)) >= 2:
		inventory[VoxelWorld.DIRT] = int(inventory[VoxelWorld.DIRT]) - 2
		inventory[VoxelWorld.STONE] = int(inventory.get(VoxelWorld.STONE, 0)) + 1
		get_parent().show_message("Đã chế tạo 1 đá từ 2 đất")
	else:
		get_parent().show_message("Cần 2 khối đất để chế tạo 1 đá")
	get_parent().refresh_hud()

func save_player() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"health": health,
		"hunger": hunger,
		"inventory": inventory,
		"selected_block": selected_block
	}

func load_player(data: Dictionary) -> void:
	var p: Array = data.get("position", [32, 22, 32])
	if p.size() >= 3:
		global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	health = int(data.get("health", 20))
	hunger = int(data.get("hunger", 20))
	var saved_inventory = data.get("inventory", {})
	inventory.clear()
	for key in saved_inventory.keys():
		inventory[int(key)] = int(saved_inventory[key])
	selected_block = int(data.get("selected_block", 1))
