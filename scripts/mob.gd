extends CharacterBody3D

var health := 5
var attack_timer := 0.0
var player: VoxelPlayer

func _ready() -> void:
	add_to_group("mobs")
	player = get_parent().get_node("Player") as CharacterBody3D

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	attack_timer -= delta
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if distance > 1.6 and distance < 22.0:
		var dir := Vector3(to_player.x, 0, to_player.z).normalized()
		velocity.x = dir.x * 2.2
		velocity.z = dir.z * 2.2
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 5.0 * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	move_and_slide()
	if distance < 1.7 and attack_timer <= 0.0:
		attack_timer = 1.3
		player.take_damage(1)

func take_hit(damage: int = 1) -> void:
	health -= damage
	if health <= 0:
		queue_free()
