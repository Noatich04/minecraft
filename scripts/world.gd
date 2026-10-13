extends Node3D
class_name VoxelWorld

const CHUNK_SIZE := 16
const WORLD_SIZE := 64
const MAX_HEIGHT := 30
const AIR := 0
const GRASS := 1
const DIRT := 2
const STONE := 3
const WOOD := 4
const LEAVES := 5
const SAND := 6
const BLOCK_NAMES := {GRASS: "Cỏ", DIRT: "Đất", STONE: "Đá", WOOD: "Gỗ", LEAVES: "Lá", SAND: "Cát"}
const BLOCK_COLORS := {
	GRASS: Color(0.30, 0.67, 0.22),
	DIRT: Color(0.45, 0.29, 0.16),
	STONE: Color(0.48, 0.50, 0.53),
	WOOD: Color(0.42, 0.27, 0.12),
	LEAVES: Color(0.16, 0.48, 0.16),
	SAND: Color(0.78, 0.70, 0.45)
}

var blocks: Dictionary = {}
var chunk_nodes: Dictionary = {}
var terrain_noise := FastNoiseLite.new()
var cave_noise := FastNoiseLite.new()
var world_seed: int = 0
var edits: Dictionary = {}
var vertex_material: StandardMaterial3D

const FACE_DATA = [
	{"n": Vector3i(1, 0, 0), "v": [Vector3(1,0,0), Vector3(1,1,0), Vector3(1,1,1), Vector3(1,0,1)]},
	{"n": Vector3i(-1, 0, 0), "v": [Vector3(0,0,1), Vector3(0,1,1), Vector3(0,1,0), Vector3(0,0,0)]},
	{"n": Vector3i(0, 1, 0), "v": [Vector3(0,1,0), Vector3(0,1,1), Vector3(1,1,1), Vector3(1,1,0)]},
	{"n": Vector3i(0, -1, 0), "v": [Vector3(0,0,1), Vector3(0,0,0), Vector3(1,0,0), Vector3(1,0,1)]},
	{"n": Vector3i(0, 0, 1), "v": [Vector3(1,0,1), Vector3(1,1,1), Vector3(0,1,1), Vector3(0,0,1)]},
	{"n": Vector3i(0, 0, -1), "v": [Vector3(0,0,0), Vector3(0,1,0), Vector3(1,1,0), Vector3(1,0,0)]}
]

func _ready() -> void:
	terrain_noise.seed = randi()
	world_seed = terrain_noise.seed
	terrain_noise.frequency = 0.035
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_gain = 0.52
	cave_noise.seed = world_seed + 9281
	cave_noise.frequency = 0.09
	vertex_material = StandardMaterial3D.new()
	vertex_material.vertex_color_use_as_albedo = true
	vertex_material.roughness = 1.0
	generate_world()

func terrain_height(x: int, z: int) -> int:
	return clampi(9 + int(terrain_noise.get_noise_2d(x, z) * 10.0), 3, MAX_HEIGHT - 4)

func generate_world() -> void:
	for node in chunk_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	chunk_nodes.clear()
	blocks.clear()
	for x in range(WORLD_SIZE):
		for z in range(WORLD_SIZE):
			var h := terrain_height(x, z)
			for y in range(h + 1):
				var kind := STONE
				if y == h:
					kind = GRASS
				elif y >= h - 3:
					kind = DIRT
				elif y > 2 and cave_noise.get_noise_3d(float(x), float(y), float(z)) > 0.48:
					continue
				if h <= 5 and y == h:
					kind = SAND
				blocks[Vector3i(x, y, z)] = kind
	add_trees()
	rebuild_all_chunks()

func add_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	for i in range(48):
		var x := rng.randi_range(3, WORLD_SIZE - 4)
		var z := rng.randi_range(3, WORLD_SIZE - 4)
		var h := terrain_height(x, z)
		if blocks.get(Vector3i(x, h, z), AIR) != GRASS:
			continue
		var trunk_height := rng.randi_range(3, 5)
		for y in range(1, trunk_height + 1):
			blocks[Vector3i(x, h + y, z)] = WOOD
		for lx in range(-2, 3):
			for lz in range(-2, 3):
				for ly in range(trunk_height - 1, trunk_height + 2):
					if abs(lx) + abs(lz) + abs(ly - trunk_height) > 4:
						continue
					var p := Vector3i(x + lx, h + ly, z + lz)
					if blocks.get(p, AIR) == AIR:
						blocks[p] = LEAVES

func chunk_key(pos: Vector3i) -> Vector2i:
	return Vector2i(floori(float(pos.x) / CHUNK_SIZE), floori(float(pos.z) / CHUNK_SIZE))

func rebuild_all_chunks() -> void:
	for node in chunk_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	chunk_nodes.clear()
	for cx in range(ceili(float(WORLD_SIZE) / CHUNK_SIZE)):
		for cz in range(ceili(float(WORLD_SIZE) / CHUNK_SIZE)):
			rebuild_chunk(Vector2i(cx, cz))

func rebuild_chunk(key: Vector2i) -> void:
	if chunk_nodes.has(key) and is_instance_valid(chunk_nodes[key]):
		chunk_nodes[key].queue_free()
	chunk_nodes.erase(key)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_faces := false
	var start_x := key.x * CHUNK_SIZE
	var start_z := key.y * CHUNK_SIZE
	for x in range(start_x, mini(start_x + CHUNK_SIZE, WORLD_SIZE)):
		for z in range(start_z, mini(start_z + CHUNK_SIZE, WORLD_SIZE)):
			for y in range(MAX_HEIGHT + 1):
				var kind: int = blocks.get(Vector3i(x, y, z), AIR)
				if kind == AIR:
					continue
				var color: Color = BLOCK_COLORS.get(kind, Color.MAGENTA)
				for face in FACE_DATA:
					var normal: Vector3i = face["n"]
					if blocks.get(Vector3i(x, y, z) + normal, AIR) != AIR:
						continue
					for v in face["v"]:
						st.set_normal(Vector3(normal))
						st.set_color(color)
						st.add_vertex(Vector3(x - start_x, y, z - start_z) + v)
					var base := st.get_vertex_count() - 4
					st.add_index(base)
					st.add_index(base + 1)
					st.add_index(base + 2)
					st.add_index(base)
					st.add_index(base + 2)
					st.add_index(base + 3)
					has_faces = true
	if not has_faces:
		return
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, vertex_material)
	var body := StaticBody3D.new()
	body.name = "Chunk_%d_%d" % [key.x, key.y]
	body.position = Vector3(start_x, 0, start_z)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	body.add_child(collision)
	add_child(body)
	chunk_nodes[key] = body

func get_block(pos: Vector3i) -> int:
	return int(blocks.get(pos, AIR))

func set_block(pos: Vector3i, kind: int) -> bool:
	if pos.x < 0 or pos.z < 0 or pos.x >= WORLD_SIZE or pos.z >= WORLD_SIZE or pos.y < 0 or pos.y > MAX_HEIGHT:
		return false
	if kind == AIR:
		blocks.erase(pos)
	else:
		blocks[pos] = kind
	edits[pos] = kind
	var key := chunk_key(pos)
	rebuild_chunk(key)
	if pos.x % CHUNK_SIZE == 0 and key.x > 0:
		rebuild_chunk(Vector2i(key.x - 1, key.y))
	if pos.x % CHUNK_SIZE == CHUNK_SIZE - 1 and key.x < 3:
		rebuild_chunk(Vector2i(key.x + 1, key.y))
	if pos.z % CHUNK_SIZE == 0 and key.y > 0:
		rebuild_chunk(Vector2i(key.x, key.y - 1))
	if pos.z % CHUNK_SIZE == CHUNK_SIZE - 1 and key.y < 3:
		rebuild_chunk(Vector2i(key.x, key.y + 1))
	return true

func save_world() -> Dictionary:
	var saved_blocks: Array = []
	for pos in edits.keys():
		saved_blocks.append([pos.x, pos.y, pos.z, int(edits[pos])])
	return {"seed": world_seed, "edits": saved_blocks}

func load_world(data: Dictionary) -> void:
	world_seed = int(data.get("seed", world_seed))
	terrain_noise.seed = world_seed
	cave_noise.seed = world_seed + 9281
	generate_world()
	edits.clear()
	for entry in data.get("edits", []):
		if entry.size() >= 4:
			var p := Vector3i(int(entry[0]), int(entry[1]), int(entry[2]))
			var kind := int(entry[3])
			if kind == AIR:
				blocks.erase(p)
			else:
				blocks[p] = kind
			edits[p] = kind
	rebuild_all_chunks()
