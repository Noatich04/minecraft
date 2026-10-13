extends CharacterBody3D
class_name VoxelPlayer

const SPEED := 6.0
const JUMP_VELOCITY := 7.0
const REACH := 6.0
const GRAVITY := 20.0

# Item IDs above the block IDs are crafting materials, tools and weapons.
const STICKS := 101
const WOOD_PICKAXE := 102
const WOOD_SWORD := 103
const STONE_PICKAXE := 104
const STONE_SWORD := 105
const TORCH := 106
const SLIME_GEL := 108

@onready var camera: Camera3D = $Camera3D
var world: VoxelWorld
var health := 20
var hunger := 20
var inventory: Dictionary = {1: 12, 2: 20, 3: 8, 4: 4, 5: 0, 6: 0, 7: 0}
var selected_block := 1
var selected_weapon := 0
var survival_clock := 0.0

func _ready() -> void:
	world = get_parent().get_node("World") as VoxelWorld
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.0025)
		camera.rotate_x(-event.relative.y * 0.0025)
		camera.rotation.x = clampf(camera.rotation.x, -1.50, 1.50)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_1:
				selected_block = VoxelWorld.GRASS
				selected_weapon = 0
			KEY_2:
				selected_block = VoxelWorld.DIRT
				selected_weapon = 0
			KEY_3:
				selected_block = VoxelWorld.STONE
				selected_weapon = 0
			KEY_4:
				selected_block = VoxelWorld.WOOD
				selected_weapon = 0
			KEY_5:
				selected_block = VoxelWorld.LEAVES
				selected_weapon = 0
			KEY_6:
				selected_block = VoxelWorld.PLANKS
				selected_weapon = 0
			KEY_7:
				select_weapon(WOOD_SWORD)
			KEY_8:
				select_weapon(STONE_SWORD)
			KEY_F5:
				get_parent().save_game()
			KEY_F9:
				get_parent().load_game()
			KEY_E:
				get_parent().toggle_inventory()
			KEY_C:
				craft_recipe("planks")
			KEY_V:
				craft_recipe("sticks")
			KEY_B:
				craft_recipe("wood_pickaxe")
			KEY_N:
				craft_recipe("wood_sword")
			KEY_M:
				craft_recipe("stone_pickaxe")
			KEY_J:
				craft_recipe("stone_sword")
			KEY_K:
				craft_recipe("torches")
		get_parent().refresh_hud()
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			mine_block()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			place_block()

func select_weapon(item_id: int) -> void:
	if int(inventory.get(item_id, 0)) > 0:
		selected_weapon = item_id
		get_parent().show_message("Đã chọn " + item_name(item_id) + ".")
	else:
		selected_weapon = 0
		get_parent().show_message("Bạn chưa chế tạo " + item_name(item_id) + ".")

func item_name(item_id: int) -> String:
	match item_id:
		STICKS: return "que gỗ"
		WOOD_PICKAXE: return "cuốc gỗ"
		WOOD_SWORD: return "kiếm gỗ"
		STONE_PICKAXE: return "cuốc đá"
		STONE_SWORD: return "kiếm đá"
		TORCH: return "đuốc"
		SLIME_GEL: return "gel slime"
		_: return "vật phẩm"

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

	# Survival: hunger drains over time; starvation causes gradual damage.
	survival_clock += delta
	if survival_clock >= 24.0:
		survival_clock = 0.0
		if hunger > 0:
			hunger -= 1
		else:
			health = maxi(0, health - 1)
		get_parent().refresh_hud()
	if health <= 0:
		health = 20
		hunger = 15
		global_position = Vector3(32.5, world.terrain_height(32, 32) + 4.0, 32.5)
		velocity = Vector3.ZERO
		get_parent().show_message("Bạn đã hồi sinh.")

func take_damage(amount: int = 1) -> void:
	health = maxi(0, health - amount)
	get_parent().refresh_hud()
	if health <= 0:
		show_death_message()

func show_death_message() -> void:
	get_parent().show_message("Bạn đã gục ngã... đang hồi sinh.")

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
	var collider = hit.get("collider")
	if collider != null and collider.has_method("take_hit"):
		var damage := 1
		if selected_weapon == WOOD_SWORD and int(inventory.get(WOOD_SWORD, 0)) > 0:
			damage = 3
		elif selected_weapon == STONE_SWORD and int(inventory.get(STONE_SWORD, 0)) > 0:
			damage = 5
		collider.take_hit(damage)
		get_parent().show_message("Bạn gây %d sát thương." % damage)
		return
	var block_pos := Vector3i(
		floori(hit.position.x - hit.normal.x * 0.02),
		floori(hit.position.y - hit.normal.y * 0.02),
		floori(hit.position.z - hit.normal.z * 0.02)
	)
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
	var p := Vector3i(
		floori(hit.position.x + hit.normal.x * 0.02),
		floori(hit.position.y + hit.normal.y * 0.02),
		floori(hit.position.z + hit.normal.z * 0.02)
	)
	var center := Vector3(p) + Vector3(0.5, 0.5, 0.5)
	if global_position.distance_to(center) < 1.35:
		return
	if world.get_block(p) != VoxelWorld.AIR:
		return
	if world.set_block(p, selected_block):
		inventory[selected_block] = int(inventory[selected_block]) - 1
		get_parent().refresh_hud()

func craft_recipe(recipe: String) -> void:
	var ingredients: Dictionary = {}
	var output_id := 0
	var output_amount := 1
	var label := ""
	match recipe:
		"planks":
			ingredients = {VoxelWorld.WOOD: 1}
			output_id = VoxelWorld.PLANKS
			output_amount = 4
			label = "4 ván gỗ"
		"sticks":
			ingredients = {VoxelWorld.PLANKS: 2}
			output_id = STICKS
			output_amount = 4
			label = "4 que gỗ"
		"wood_pickaxe":
			ingredients = {VoxelWorld.PLANKS: 3, STICKS: 2}
			output_id = WOOD_PICKAXE
			label = "cuốc gỗ"
		"wood_sword":
			ingredients = {VoxelWorld.PLANKS: 2, STICKS: 1}
			output_id = WOOD_SWORD
			label = "kiếm gỗ"
		"stone_pickaxe":
			ingredients = {VoxelWorld.STONE: 3, STICKS: 2}
			output_id = STONE_PICKAXE
			label = "cuốc đá"
		"stone_sword":
			ingredients = {VoxelWorld.STONE: 2, STICKS: 1}
			output_id = STONE_SWORD
			label = "kiếm đá"
		"torches":
			ingredients = {STICKS: 1, VoxelWorld.WOOD: 1}
			output_id = TORCH
			output_amount = 4
			label = "4 đuốc"
		_:
			get_parent().show_message("Công thức không tồn tại.")
			return

	for ingredient_id in ingredients.keys():
		if int(inventory.get(ingredient_id, 0)) < int(ingredients[ingredient_id]):
			get_parent().show_message("Không đủ nguyên liệu để chế tạo " + label + ".")
			return
	for ingredient_id in ingredients.keys():
		inventory[ingredient_id] = int(inventory.get(ingredient_id, 0)) - int(ingredients[ingredient_id])
	inventory[output_id] = int(inventory.get(output_id, 0)) + output_amount
	get_parent().show_message("Đã chế tạo: " + label + ".")
	get_parent().refresh_hud()

func save_player() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"health": health,
		"hunger": hunger,
		"inventory": inventory,
		"selected_block": selected_block,
		"selected_weapon": selected_weapon
	}

func load_player(data: Dictionary) -> void:
	var p: Array = data.get("position", [32.5, 22, 32.5])
	if p.size() >= 3:
		global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	health = int(data.get("health", 20))
	hunger = int(data.get("hunger", 20))
	var saved_inventory = data.get("inventory", {})
	inventory.clear()
	for key in saved_inventory.keys():
		inventory[int(key)] = int(saved_inventory[key])
	selected_block = int(data.get("selected_block", 1))
	selected_weapon = int(data.get("selected_weapon", 0))
