extends Node3D
## CC0 Quaternius ninja skin for the existing combat actor.
## The actor's original Mixamo rig stays active for hitboxes, retargeted combat
## clips, bone queries and CPU logic; this native rig mirrors its broad state.
const MALE: PackedScene = preload("res://assets/vendor/quaternius_ninjas/Ninja_Male.glb")
const FEMALE: PackedScene = preload("res://assets/vendor/quaternius_ninjas/Ninja_Female.glb")
const BODY_SHADER: Script = preload("res://scripts/anime_presentation.gd")
var model_instance: Node3D
var animation_player: AnimationPlayer
var source_adapter: Node
var source_actor: CharacterBody3D
var current_clip: StringName = &""
var clip_names: PackedStringArray = PackedStringArray()
var rig_loaded: bool = false
static var bounds_by_type: Dictionary = {}

func _ready() -> void:
	set_process(false)
	source_adapter = get_parent()
	source_actor = source_adapter.get_parent() as CharacterBody3D
	if source_actor == null or source_actor.name not in ["Player", "EnemyDummy"]:
		queue_free()
		return
	var feminine: bool = source_actor.name == "EnemyDummy"
	model_instance = (FEMALE if feminine else MALE).instantiate() as Node3D
	model_instance.name = "LicensedNinja_%s" % ("Female" if feminine else "Male")
	add_child(model_instance)
	_collect_animation_player(model_instance)
	if animation_player == null:
		queue_free()
		return
	for clip: String in animation_player.get_animation_list():
		clip_names.append(clip)
		var animation: Animation = animation_player.get_animation(clip)
		if clip.ends_with("Idle") or clip.ends_with("Walk"):
			animation.loop_mode = Animation.LOOP_LINEAR
	var bounds: AABB = _get_bounds(feminine)
	var factor: float = 1.75 / maxf(bounds.size.y, 0.001)
	model_instance.scale = Vector3.ONE * factor
	model_instance.position.y = -bounds.position.y * factor
	model_instance.rotation_degrees.y = 180.0
	# Keep imported materials, but use one cheap toon pass with mobile-friendly
	# rough surfaces. Meshes and animation data remain shared between fighters.
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(model_instance, meshes)
	for mesh: MeshInstance3D in meshes:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.visibility_range_begin = 0.0
		for surface: int in range(mesh.mesh.get_surface_count()):
			var source: StandardMaterial3D = mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if source != null:
				mesh.set_surface_override_material(surface, BODY_SHADER.textured(source))
		# The full Mixamo rig still evaluates underneath this licensed visual.
		# Hiding only its mesh nodes retains bone poses used by combat systems.
	var old_meshes: Array[MeshInstance3D] = []
	source_adapter.call("_collect_mesh_instances", source_adapter.get("model_instance"), old_meshes)
	for mesh: MeshInstance3D in old_meshes:
		mesh.visible = false
	rig_loaded = not meshes.is_empty() and not clip_names.is_empty()
	set_process(true)
	_sync_animation(true)

func _process(_delta: float) -> void:
	_sync_animation(false)

func _sync_animation(restart: bool) -> void:
	if animation_player == null or source_adapter == null or source_adapter.get("rig_loaded") != true:
		return
	var state: String = String(source_adapter.get("current_state"))
	var desired: StringName = _clip_for_state(state)
	if desired == current_clip and not restart:
		return
	if desired.is_empty():
		return
	current_clip = desired
	# Imported Quaternius clips are packed under CharacterArmature|Clip.
	animation_player.play(current_clip, 0.12)

func _clip_for_state(state: String) -> StringName:
	var suffixes: PackedStringArray
	match state:
		"run", "sprint", "strafe_left", "strafe_right", "back_run", "chakra_dash":
			suffixes = PackedStringArray(["Walk"])
		"attack", "air_attack", "attack_1", "attack_2", "attack_3", "attack_4", "air_attack_1", "air_attack_2", "air_attack_3", "air_attack_4", "jutsu", "rasengan", "ninjutsu", "ultimate", "throw":
			suffixes = PackedStringArray(["Punch", "Shoot_OneHanded", "Idle"])
		"hit", "guard_break", "stun":
			suffixes = PackedStringArray(["RecieveHit", "ReceiveHit", "Idle"])
		"defeat", "ko":
			suffixes = PackedStringArray(["Defeat", "Idle"])
		_:
			suffixes = PackedStringArray(["Idle"])
	for suffix: String in suffixes:
		for clip: String in clip_names:
			if clip.ends_with(suffix):
				return StringName(clip)
	return StringName()

func _get_bounds(feminine: bool) -> AABB:
	if bounds_by_type.has(feminine):
		return bounds_by_type[feminine]
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(model_instance, meshes)
	var all_bounds: AABB = AABB()
	var first: bool = true
	var inverse: Transform3D = model_instance.global_transform.affine_inverse()
	for mesh: MeshInstance3D in meshes:
		var local: AABB = inverse * mesh.global_transform * mesh.get_aabb()
		all_bounds = local if first else all_bounds.merge(local)
		first = false
	if first:
		all_bounds = AABB(Vector3(-0.4, 0.0, -0.3), Vector3(0.8, 1.8, 0.6))
	bounds_by_type[feminine] = all_bounds
	return all_bounds

func _collect_animation_player(node: Node) -> void:
	if node is AnimationPlayer:
		animation_player = node
		return
	for child: Node in node.get_children():
		_collect_animation_player(child)

func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child: Node in node.get_children():
		_collect_meshes(child, result)
