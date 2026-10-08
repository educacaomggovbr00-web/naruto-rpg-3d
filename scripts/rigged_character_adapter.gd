extends Node3D

const COMBAT_LIBRARY: AnimationLibrary = preload("res://assets/animations/combat_mixamo.tres")
const TOON_MATERIAL: ShaderMaterial = preload("res://assets/characters/stylized/toon.tres")
const ANIME: Script = preload("res://scripts/anime_presentation.gd")
# Track paths are immutable after installation; playback stays per fighter.
static var library_cache: Dictionary = {}

const MANIFEST_PATH: String = "res://assets/animations/combat_manifest.json"
const REFERENCE_REST_PATH: String = "res://assets/animations/mixamo_reference_rest.json"
static var reference_rest_cache: Dictionary = {}
static var reference_rest_ready: bool = false

@export_file("*.glb") var model_path: String = "res://assets/characters/rigged.glb"
@export var fallback_visual_path: NodePath = NodePath("../VisualRoot")
@export var model_offset: Vector3 = Vector3(0.0, -0.95, 0.0)
@export var model_scale: float = 1.0
@export var auto_scale_model: bool = true
@export var ground_to_collision: bool = false
@export var target_character_height: float = 1.75
@export var fallback_import_scale: float = 0.01
@export var model_yaw_degrees: float = 180.0
@export var follow_hitbox_to_bones: bool = true

var model_instance: Node3D = null
var skeleton: Skeleton3D = null
var animation_player: AnimationPlayer = null
var animation_tree: AnimationTree = null
var playback: AnimationNodeStateMachinePlayback = null
var fallback_visual: Node3D = null

var rig_loaded: bool = false
var rig_status: String = "RIG: aguardando rigged.glb"
var current_state: String = ""
var available_animations: PackedStringArray = PackedStringArray()
var detected_source_height: float = 0.0
var detected_source_min_y: float = 0.0
var applied_model_scale: float = 1.0
var real_animation_count: int = 0
var manifest: Dictionary = {}
var last_action_id: int = -1
var landing_timer: float = 0.0
var was_airborne: bool = false
var chakra_aura: MeshInstance3D = null
var aura_base_scale: Vector3 = Vector3.ONE
var prefer_native_locomotion: bool = false
var native_locomotion_count: int = 0
var combat_retargeted: bool = false
var character_definition: CharacterDefinition = null
var roster_accessories: Array[Dictionary] = []
var requested_model_path: String = ""
var resolved_model_path: String = ""
var using_model_fallback: bool = false
var model_attempt_log: PackedStringArray = PackedStringArray()

var right_hand_bone: int = -1
var left_hand_bone: int = -1
var right_foot_bone: int = -1
var left_foot_bone: int = -1

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var attack_hitbox: Area3D = $"../AttackHitbox"

func _ready() -> void:
    process_physics_priority = 10
    fallback_visual = get_node_or_null(fallback_visual_path) as Node3D
    if player.has_method("get_character_definition"):
        character_definition = player.call("get_character_definition") as CharacterDefinition
        if character_definition != null:
            model_path = character_definition.model_path
            requested_model_path = character_definition.model_path
            auto_scale_model = character_definition.model_auto_scale
            ground_to_collision = character_definition.model_ground_to_collision
            model_scale = character_definition.model_scale_multiplier
            target_character_height = character_definition.model_target_height
            model_offset = character_definition.model_offset
            model_yaw_degrees = character_definition.model_yaw_degrees
            fallback_import_scale = character_definition.model_fallback_import_scale
            prefer_native_locomotion = character_definition.prefer_native_locomotion
    _try_load_rig()

func _physics_process(delta: float) -> void:
    if not rig_loaded:
        return

    _sync_animation_state(delta)
    animation_tree.advance(delta)
    _update_chakra_aura(delta)
    _sync_roster_accessories()

    var state: String = String(player.call("get_animation_state"))
    if follow_hitbox_to_bones and (state == "attack" or state == "air_attack"):
        snap_attack_hitbox(int(player.call("get_combo_step")), state == "air_attack")

func _try_load_rig() -> void:
    rig_loaded = false
    resolved_model_path = ""
    model_attempt_log.clear()

    if requested_model_path.is_empty():
        requested_model_path = model_path

    var candidates: PackedStringArray = PackedStringArray()
    if not requested_model_path.is_empty():
        candidates.append(requested_model_path)

    var fallback_path: String = ""
    if character_definition != null:
        fallback_path = character_definition.model_fallback_path
    if not fallback_path.is_empty() and fallback_path not in candidates:
        candidates.append(fallback_path)

    for candidate_path: String in candidates:
        using_model_fallback = candidate_path != requested_model_path
        if _try_load_rig_candidate(candidate_path):
            resolved_model_path = candidate_path
            model_path = candidate_path
            _finalize_loaded_rig()
            return
        _discard_rig_candidate()

    using_model_fallback = false
    rig_status = "RIG: nenhum modelo válido; verifique modelo final e fallback"


func _try_load_rig_candidate(candidate_path: String) -> bool:
    if not ResourceLoader.exists(candidate_path):
        model_attempt_log.append("%s | ausente" % candidate_path)
        return false

    var packed_scene: PackedScene = ResourceLoader.load(candidate_path) as PackedScene
    if packed_scene == null:
        model_attempt_log.append("%s | não abriu como PackedScene" % candidate_path)
        return false

    var instance_node: Node = packed_scene.instantiate()
    model_instance = instance_node as Node3D
    if model_instance == null:
        instance_node.free()
        model_attempt_log.append("%s | raiz não é Node3D" % candidate_path)
        return false

    add_child(model_instance)
    model_instance.position = Vector3.ZERO
    model_instance.rotation_degrees.y = model_yaw_degrees
    model_instance.scale = Vector3.ONE

    _apply_character_scale()
    model_instance.position = model_offset

    if ground_to_collision:
        var collision: CollisionShape3D = player.get_node_or_null("CollisionShape3D") as CollisionShape3D
        if collision != null and collision.shape is CapsuleShape3D:
            model_instance.position.y = collision.position.y - collision.shape.height * 0.5 - detected_source_min_y * applied_model_scale

    skeleton = _find_skeleton(model_instance)
    if skeleton == null:
        model_attempt_log.append("%s | Skeleton3D ausente" % candidate_path)
        return false

    _cache_combat_bones()
    if character_definition != null and character_definition.model_slot != null:
        if character_definition.model_slot.require_combat_bones and not _has_required_combat_bones():
            model_attempt_log.append("%s | ossos críticos incompatíveis" % candidate_path)
            return false
    elif not _has_required_combat_bones():
        model_attempt_log.append("%s | ossos críticos incompatíveis" % candidate_path)
        return false

    animation_player = _find_animation_player(model_instance)
    if animation_player == null:
        animation_player = AnimationPlayer.new()
        animation_player.name = "RuntimeAnimationPlayer"
        animation_player.root_node = NodePath("..")
        model_instance.add_child(animation_player)

    apply_visual_material(model_instance)

    if not _install_combat_library():
        model_attempt_log.append("%s | retarget/biblioteca de combate incompatível" % candidate_path)
        return false

    if prefer_native_locomotion:
        native_locomotion_count = _install_native_locomotion_library()

    _setup_animation_tree()
    _install_roster_visual_identity()
    model_attempt_log.append("%s | OK" % candidate_path)
    return true


func _finalize_loaded_rig() -> void:
    rig_loaded = true
    attack_hitbox.top_level = true

    # Always keep the character model selected by the roster definition visible.
    # Generic CC0 ninja skins are not injected over Player/CPU anymore.

    if is_instance_valid(fallback_visual):
        chakra_aura = fallback_visual.get_node_or_null("ChakraAura") as MeshInstance3D
        if chakra_aura != null:
            chakra_aura.reparent(self, true)
            aura_base_scale = chakra_aura.scale
            _tint_chakra_aura()
        fallback_visual.visible = false
        fallback_visual.process_mode = Node.PROCESS_MODE_DISABLED

    var source_label: String = "FALLBACK" if using_model_fallback else "FINAL"
    rig_status = "RIG: OK %s | %d CC0 | %d native | %d bones%s" % [
        source_label,
        real_animation_count,
        native_locomotion_count,
        skeleton.get_bone_count(),
        " | RETARGET" if combat_retargeted else ""
    ]


func _discard_rig_candidate() -> void:
    roster_accessories.clear()

    if animation_tree != null and is_instance_valid(animation_tree):
        animation_tree.free()
    animation_tree = null
    playback = null

    if model_instance != null and is_instance_valid(model_instance):
        model_instance.free()
    model_instance = null
    skeleton = null
    animation_player = null

    real_animation_count = 0
    native_locomotion_count = 0
    combat_retargeted = false
    detected_source_height = 0.0
    detected_source_min_y = 0.0
    applied_model_scale = 1.0


func _should_use_procedural_identity() -> bool:
    if character_definition == null or character_definition.visual_profile == null:
        return false
    if character_definition.model_slot == null:
        return true
    return using_model_fallback and character_definition.model_slot.procedural_identity_on_fallback


func _install_roster_visual_identity() -> void:
    roster_accessories.clear()
    if character_definition == null or character_definition.visual_profile == null or skeleton == null:
        return
    if not _should_use_procedural_identity():
        return

    var profile: RosterVisualProfileDefinition = character_definition.visual_profile
    for tag: String in profile.accessories:
        match tag:
            "headband":
                _add_box_accessory("Head", Vector3(0.34, 0.06, 0.18), Vector3(0.0, 0.09, 0.12), Vector3.ZERO, profile.secondary_color)
            "ponytail":
                _add_capsule_accessory("Head", 0.065, 0.34, Vector3(0.0, -0.06, -0.17), Vector3(18.0, 0.0, 0.0), profile.secondary_color)
            "long_hair":
                _add_capsule_accessory("Head", 0.15, 0.58, Vector3(0.0, -0.18, -0.13), Vector3(12.0, 0.0, 0.0), profile.secondary_color, Vector3(0.85, 1.0, 0.58))
            "twin_buns":
                _add_sphere_accessory("Head", 0.10, Vector3(-0.16, 0.09, -0.01), profile.secondary_color)
                _add_sphere_accessory("Head", 0.10, Vector3(0.16, 0.09, -0.01), profile.secondary_color)
            "vest":
                _add_box_accessory("Spine2", Vector3(0.54, 0.58, 0.28), Vector3(0.0, 0.0, 0.0), Vector3.ZERO, profile.primary_color)
            "coat":
                _add_box_accessory("Spine2", Vector3(0.60, 0.78, 0.30), Vector3(0.0, -0.07, -0.01), Vector3.ZERO, profile.primary_color)
            "cloak":
                _add_box_accessory("Spine2", Vector3(0.64, 0.86, 0.31), Vector3(0.0, -0.10, -0.02), Vector3.ZERO, profile.primary_color)
            "armor":
                _add_box_accessory("Spine2", Vector3(0.60, 0.64, 0.32), Vector3(0.0, 0.0, 0.0), Vector3.ZERO, profile.primary_color)
                _add_box_accessory("LeftShoulder", Vector3(0.22, 0.12, 0.24), Vector3(0.0, 0.0, 0.0), Vector3.ZERO, profile.secondary_color)
                _add_box_accessory("RightShoulder", Vector3(0.22, 0.12, 0.24), Vector3(0.0, 0.0, 0.0), Vector3.ZERO, profile.secondary_color)
            "sash":
                _add_box_accessory("Hips", Vector3(0.46, 0.10, 0.24), Vector3(0.0, 0.06, 0.0), Vector3.ZERO, profile.accent_color)
            "rope_belt":
                _add_cylinder_accessory("Hips", 0.29, 0.29, 0.12, Vector3(0.0, 0.05, 0.0), Vector3.ZERO, profile.accent_color)
            "hood":
                _add_cylinder_accessory("Neck", 0.27, 0.24, 0.13, Vector3(0.0, -0.03, -0.02), Vector3.ZERO, profile.secondary_color)
            "fur_collar":
                _add_cylinder_accessory("Neck", 0.31, 0.27, 0.12, Vector3(0.0, -0.04, -0.01), Vector3.ZERO, profile.accent_color)
            "glasses":
                _add_box_accessory("Head", Vector3(0.32, 0.055, 0.045), Vector3(0.0, 0.035, 0.205), Vector3.ZERO, profile.accent_color)
            "arm_bands":
                _add_box_accessory("LeftForeArm", Vector3(0.17, 0.08, 0.18), Vector3.ZERO, Vector3.ZERO, profile.accent_color)
                _add_box_accessory("RightForeArm", Vector3(0.17, 0.08, 0.18), Vector3.ZERO, Vector3.ZERO, profile.accent_color)
            "leg_bands":
                _add_box_accessory("LeftLeg", Vector3(0.19, 0.09, 0.20), Vector3(0.0, -0.10, 0.0), Vector3.ZERO, profile.accent_color)
                _add_box_accessory("RightLeg", Vector3(0.19, 0.09, 0.20), Vector3(0.0, -0.10, 0.0), Vector3.ZERO, profile.accent_color)
            "gourd":
                _add_sphere_accessory("Spine2", 0.31, Vector3(0.28, 0.02, -0.28), profile.accent_color, Vector3(0.82, 1.35, 0.68))
            "puppet_pack":
                _add_box_accessory("Spine2", Vector3(0.42, 0.58, 0.22), Vector3(0.0, 0.0, -0.27), Vector3.ZERO, profile.secondary_color)
            "fan":
                _add_box_accessory("Spine2", Vector3(0.58, 0.82, 0.055), Vector3(0.24, 0.06, -0.27), Vector3(0.0, 0.0, -18.0), profile.accent_color)
            "scroll":
                _add_cylinder_accessory("Spine2", 0.12, 0.12, 0.62, Vector3(0.27, 0.02, -0.26), Vector3(0.0, 0.0, 90.0), profile.accent_color)
            "staff":
                _add_cylinder_accessory("Spine2", 0.028, 0.028, 1.50, Vector3(0.28, -0.05, -0.25), Vector3(0.0, 0.0, 18.0), profile.accent_color)
            "bone_spikes":
                _add_cylinder_accessory("LeftForeArm", 0.015, 0.055, 0.36, Vector3(0.0, -0.06, -0.05), Vector3(90.0, 0.0, 0.0), profile.accent_color)
                _add_cylinder_accessory("RightForeArm", 0.015, 0.055, 0.36, Vector3(0.0, -0.06, -0.05), Vector3(90.0, 0.0, 0.0), profile.accent_color)
            "sword_back":
                _add_box_accessory("Spine2", Vector3(0.11, 1.12, 0.12), Vector3(0.25, -0.02, -0.26), Vector3(0.0, 0.0, -24.0), profile.accent_color)

    _sync_roster_accessories()

func _accessory_material(color: Color) -> Material:
    var base: StandardMaterial3D = StandardMaterial3D.new()
    base.albedo_color = color
    base.roughness = 0.90
    return ANIME.textured(base)

func _add_accessory(mesh: PrimitiveMesh, bone_name: String, offset: Vector3, rotation_degrees: Vector3, color: Color, scale: Vector3 = Vector3.ONE) -> void:
    var bone: int = _find_mixamo_bone(bone_name)
    if bone < 0:
        return

    mesh.material = _accessory_material(color)
    var node: MeshInstance3D = MeshInstance3D.new()
    node.mesh = mesh
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(node)

    var rotation: Vector3 = Vector3(
        deg_to_rad(rotation_degrees.x),
        deg_to_rad(rotation_degrees.y),
        deg_to_rad(rotation_degrees.z)
    )
    var basis: Basis = Basis.from_euler(rotation).scaled(scale)
    roster_accessories.append({
        "node": node,
        "bone": bone,
        "offset": Transform3D(basis, offset)
    })

func _add_box_accessory(bone_name: String, size: Vector3, offset: Vector3, rotation_degrees: Vector3, color: Color, scale: Vector3 = Vector3.ONE) -> void:
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    _add_accessory(mesh, bone_name, offset, rotation_degrees, color, scale)

func _add_sphere_accessory(bone_name: String, radius: float, offset: Vector3, color: Color, scale: Vector3 = Vector3.ONE) -> void:
    var mesh: SphereMesh = SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 10
    mesh.rings = 5
    _add_accessory(mesh, bone_name, offset, Vector3.ZERO, color, scale)

func _add_capsule_accessory(bone_name: String, radius: float, height: float, offset: Vector3, rotation_degrees: Vector3, color: Color, scale: Vector3 = Vector3.ONE) -> void:
    var mesh: CapsuleMesh = CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    mesh.radial_segments = 8
    mesh.rings = 3
    _add_accessory(mesh, bone_name, offset, rotation_degrees, color, scale)

func _add_cylinder_accessory(bone_name: String, top_radius: float, bottom_radius: float, height: float, offset: Vector3, rotation_degrees: Vector3, color: Color, scale: Vector3 = Vector3.ONE) -> void:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = top_radius
    mesh.bottom_radius = bottom_radius
    mesh.height = height
    mesh.radial_segments = 10
    _add_accessory(mesh, bone_name, offset, rotation_degrees, color, scale)

func _sync_roster_accessories() -> void:
    if skeleton == null or roster_accessories.is_empty():
        return

    for entry: Dictionary in roster_accessories:
        var node: MeshInstance3D = entry.get("node") as MeshInstance3D
        var bone: int = int(entry.get("bone", -1))
        var offset: Transform3D = entry.get("offset", Transform3D())
        if node == null or bone < 0:
            continue

        var pose: Transform3D = skeleton.get_bone_global_pose(bone)
        var world: Transform3D = skeleton.global_transform * pose
        var anchor: Transform3D = Transform3D(world.basis.orthonormalized(), world.origin)
        node.global_transform = anchor * offset

func _tint_chakra_aura() -> void:
    if chakra_aura == null:
        return
    var source: StandardMaterial3D = chakra_aura.get_active_material(0) as StandardMaterial3D
    if source == null:
        return
    var material: StandardMaterial3D = source.duplicate(true) as StandardMaterial3D
    if material == null:
        return
    var color: Color = Color(0.08, 0.55, 1.0)
    if player.has_method("get_character_definition"):
        var definition: CharacterDefinition = player.call("get_character_definition") as CharacterDefinition
        if definition != null:
            color = definition.energy_color
    material.albedo_color = Color(color.r, color.g, color.b, source.albedo_color.a)
    material.emission_enabled = true
    material.emission = color
    chakra_aura.material_override = material

func _update_chakra_aura(delta: float) -> void:
    if chakra_aura == null:
        return
    var state: String = String(player.call("get_animation_state"))
    chakra_aura.visible = state in ["chakra_dash", "chakra_charge", "jutsu"]
    if chakra_aura.visible:
        chakra_aura.rotation.y += delta * 6.0
        var pulse: float = 1.0 + sin(float(Time.get_ticks_msec()) * 0.025) * 0.06
        chakra_aura.scale = aura_base_scale * pulse

func _apply_character_scale() -> void:
    detected_source_height = _calculate_model_height()

    if auto_scale_model and detected_source_height > 0.001:
        applied_model_scale = (target_character_height / detected_source_height) * model_scale
    else:
        applied_model_scale = fallback_import_scale * model_scale

    applied_model_scale = clampf(applied_model_scale, 0.0001, 10.0)
    model_instance.scale = Vector3.ONE * applied_model_scale

func _calculate_model_height() -> float:
    if model_instance == null:
        return 0.0

    var bounds_min_y: float = INF
    var bounds_max_y: float = -INF
    var found_mesh: bool = false
    var root_inverse: Transform3D = model_instance.global_transform.affine_inverse()
    var mesh_nodes: Array[MeshInstance3D] = []
    _collect_mesh_instances(model_instance, mesh_nodes)

    for mesh_instance: MeshInstance3D in mesh_nodes:
        if mesh_instance.mesh == null:
            continue

        var aabb: AABB = mesh_instance.get_aabb()
        var p: Vector3 = aabb.position
        var s: Vector3 = aabb.size
        var corners: Array[Vector3] = [
            p,
            p + Vector3(s.x, 0.0, 0.0),
            p + Vector3(0.0, s.y, 0.0),
            p + Vector3(0.0, 0.0, s.z),
            p + Vector3(s.x, s.y, 0.0),
            p + Vector3(s.x, 0.0, s.z),
            p + Vector3(0.0, s.y, s.z),
            p + s
        ]

        for local_point: Vector3 in corners:
            var world_point: Vector3 = mesh_instance.global_transform * local_point
            var root_point: Vector3 = root_inverse * world_point
            bounds_min_y = minf(bounds_min_y, root_point.y)
            bounds_max_y = maxf(bounds_max_y, root_point.y)
            found_mesh = true

    if not found_mesh:
        return 0.0

    detected_source_min_y = bounds_min_y
    return maxf(bounds_max_y - bounds_min_y, 0.0)

func _collect_mesh_instances(root: Node, output: Array[MeshInstance3D]) -> void:
    if root is MeshInstance3D:
        output.append(root as MeshInstance3D)

    for child: Node in root.get_children():
        _collect_mesh_instances(child, output)

func apply_visual_material(root: Node) -> void:
    var use_toon: bool = model_path.begins_with("res://assets/characters/stylized/")
    if character_definition != null:
        use_toon = use_toon or character_definition.stylized_material

    var profile: RosterVisualProfileDefinition = null
    if _should_use_procedural_identity():
        profile = character_definition.visual_profile

    var meshes: Array[MeshInstance3D] = []
    _collect_mesh_instances(root, meshes)
    for mesh: MeshInstance3D in meshes:
        if use_toon:
            mesh.material_override = TOON_MATERIAL
            continue

        # Preserve textures, then add a mild per-character tint only for shared-rig slots.
        for index: int in range(mesh.mesh.get_surface_count()):
            var source: Material = mesh.get_active_material(index)
            if source is StandardMaterial3D:
                var anime_material: Material = ANIME.textured(source)
                if profile == null or not anime_material is StandardMaterial3D:
                    mesh.set_surface_override_material(index, anime_material)
                    continue

                var tinted: StandardMaterial3D = (anime_material as StandardMaterial3D).duplicate(true) as StandardMaterial3D
                if tinted == null:
                    mesh.set_surface_override_material(index, anime_material)
                    continue

                tinted.albedo_color = tinted.albedo_color.lerp(profile.primary_color, profile.tint_strength)
                mesh.set_surface_override_material(index, tinted)

func _cache_combat_bones() -> void:
    right_hand_bone = _find_mixamo_bone("RightHand")
    left_hand_bone = _find_mixamo_bone("LeftHand")
    right_foot_bone = _find_mixamo_bone("RightFoot")
    left_foot_bone = _find_mixamo_bone("LeftFoot")

func _find_mixamo_bone(short_name: String) -> int:
    var index: int = skeleton.find_bone("mixamorig_" + short_name)
    if index < 0:
        index = skeleton.find_bone("mixamorig:" + short_name)
    return index

func _install_combat_library() -> bool:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
    if not parsed is Dictionary:
        return false
    manifest = parsed
    var clips: Dictionary = manifest.get("clips", {})
    if not _has_required_combat_bones():
        push_error("Combat rig is missing a required body bone")
        return false
    if not _ensure_reference_rest_cache():
        push_error("Combat retarget reference rig is unavailable")
        return false

    var animation_root: Node = animation_player.get_node(animation_player.root_node)
    var skeleton_path: String = String(animation_root.get_path_to(skeleton))
    var bone_names: PackedStringArray = []
    for index: int in range(skeleton.get_bone_count()):
        bone_names.append(String(skeleton.get_bone_name(index)))

    # Godot 4 bone animation values include Bone Rest. Matching names alone is
    # insufficient when a Mixamo export uses a different rest orientation or
    # source unit. Retarget every kept track from the reference rest into the
    # target rest before installing the library.
    var rest_signature: String = ""
    for index: int in range(skeleton.get_bone_count()):
        rest_signature += str(skeleton.get_bone_rest(index))
    var retarget_required: bool = not _matches_reference_rest()
    combat_retargeted = retarget_required
    var cache_key: String = skeleton_path + "|" + ",".join(bone_names) + "|" + rest_signature.sha256_text()
    var library: AnimationLibrary = library_cache.get(cache_key) as AnimationLibrary
    if library == null:
        library = COMBAT_LIBRARY.duplicate(true) as AnimationLibrary
        for clip_name: StringName in library.get_animation_list():
            if not clips.has(String(clip_name)):
                return false
            var animation: Animation = library.get_animation(clip_name)
            for track: int in range(animation.get_track_count() - 1, -1, -1):
                var path: NodePath = animation.track_get_path(track)
                var source_bone_name: String = String(path.get_subname(0))
                var target_bone: int = _find_named_bone(skeleton, source_bone_name)
                if target_bone < 0 or not _has_reference_rest(source_bone_name):
                    animation.remove_track(track)
                    continue
                var source_rest: Transform3D = _reference_rest(source_bone_name)
                var target_bone_name: String = String(skeleton.get_bone_name(target_bone))
                if retarget_required:
                    var target_rest: Transform3D = skeleton.get_bone_rest(target_bone)
                    _retarget_track(animation, track, source_rest, target_rest)
                animation.track_set_path(track, NodePath(skeleton_path + ":" + target_bone_name))
        library_cache[cache_key] = library

    var result: Error = animation_player.add_animation_library(&"combat", library)
    real_animation_count = library.get_animation_list().size()
    return result == OK and real_animation_count == clips.size()

func _matches_reference_rest() -> bool:
    for index: int in range(skeleton.get_bone_count()):
        var bone_name: String = String(skeleton.get_bone_name(index))
        if not _has_reference_rest(bone_name):
            continue
        var source_rest: Transform3D = _reference_rest(bone_name)
        var target_rest: Transform3D = skeleton.get_bone_rest(index)
        if source_rest.origin.distance_to(target_rest.origin) > 0.001:
            return false
        var source_rotation: Quaternion = source_rest.basis.orthonormalized().get_rotation_quaternion()
        var target_rotation: Quaternion = target_rest.basis.orthonormalized().get_rotation_quaternion()
        if absf(source_rotation.dot(target_rotation)) < 0.99999:
            return false
    return true

func _ensure_reference_rest_cache() -> bool:
    if reference_rest_ready:
        return not reference_rest_cache.is_empty()
    reference_rest_ready = true
    reference_rest_cache.clear()
    if not FileAccess.file_exists(REFERENCE_REST_PATH):
        return false

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE_REST_PATH))
    if not parsed is Dictionary:
        return false
    var root_data: Dictionary = parsed
    var bones_value: Variant = root_data.get("bones", {})
    if not bones_value is Dictionary:
        return false
    var bones: Dictionary = bones_value

    for bone_value: String in bones:
        var entry_value: Variant = bones[bone_value]
        if not entry_value is Dictionary:
            continue
        var entry: Dictionary = entry_value
        var position_value: Variant = entry.get("p", [])
        var rotation_value: Variant = entry.get("q", [])
        if not position_value is Array or not rotation_value is Array:
            continue
        var position_data: Array = position_value
        var rotation_data: Array = rotation_value
        if position_data.size() != 3 or rotation_data.size() != 4:
            continue

        var position: Vector3 = Vector3(
            float(position_data[0]),
            float(position_data[1]),
            float(position_data[2])
        )
        var rotation: Quaternion = Quaternion(
            float(rotation_data[0]),
            float(rotation_data[1]),
            float(rotation_data[2]),
            float(rotation_data[3])
        ).normalized()
        reference_rest_cache[bone_value] = Transform3D(Basis(rotation), position)

    return not reference_rest_cache.is_empty()

func _reference_rest_key(bone_name: String) -> String:
    if reference_rest_cache.has(bone_name):
        return bone_name
    if bone_name.begins_with("mixamorig_"):
        var colon_name: String = bone_name.replace("mixamorig_", "mixamorig:")
        if reference_rest_cache.has(colon_name):
            return colon_name
    elif bone_name.begins_with("mixamorig:"):
        var underscore_name: String = bone_name.replace("mixamorig:", "mixamorig_")
        if reference_rest_cache.has(underscore_name):
            return underscore_name
    return ""

func _has_reference_rest(bone_name: String) -> bool:
    return not _reference_rest_key(bone_name).is_empty()

func _reference_rest(bone_name: String) -> Transform3D:
    var key: String = _reference_rest_key(bone_name)
    if key.is_empty():
        return Transform3D()
    var value: Variant = reference_rest_cache[key]
    if typeof(value) == TYPE_TRANSFORM3D:
        return value
    return Transform3D()

func _find_named_bone(target: Skeleton3D, bone_name: String) -> int:
    var index: int = target.find_bone(bone_name)
    if index >= 0:
        return index
    if bone_name.begins_with("mixamorig_"):
        index = target.find_bone(bone_name.replace("mixamorig_", "mixamorig:"))
    elif bone_name.begins_with("mixamorig:"):
        index = target.find_bone(bone_name.replace("mixamorig:", "mixamorig_"))
    return index

func _retarget_track(
    animation: Animation,
    track: int,
    source_rest: Transform3D,
    target_rest: Transform3D
) -> void:
    var track_type: int = animation.track_get_type(track)
    var key_count: int = animation.track_get_key_count(track)

    if track_type == Animation.TYPE_ROTATION_3D:
        var source_rest_rotation: Quaternion = source_rest.basis.orthonormalized().get_rotation_quaternion()
        var target_rest_rotation: Quaternion = target_rest.basis.orthonormalized().get_rotation_quaternion()
        for key: int in range(key_count):
            var value: Variant = animation.track_get_key_value(track, key)
            if typeof(value) != TYPE_QUATERNION:
                continue
            var source_rotation: Quaternion = value
            var relative_rotation: Quaternion = source_rest_rotation.inverse() * source_rotation
            var target_rotation: Quaternion = (target_rest_rotation * relative_rotation).normalized()
            animation.track_set_key_value(track, key, target_rotation)
        return

    if track_type == Animation.TYPE_POSITION_3D:
        var position_scale: float = _rest_length_ratio(source_rest.origin, target_rest.origin)
        for key: int in range(key_count):
            var value: Variant = animation.track_get_key_value(track, key)
            if typeof(value) != TYPE_VECTOR3:
                continue
            var source_position: Vector3 = value
            var relative_position: Vector3 = source_position - source_rest.origin
            animation.track_set_key_value(
                track,
                key,
                target_rest.origin + relative_position * position_scale
            )
        return

    if track_type == Animation.TYPE_SCALE_3D:
        var source_rest_scale: Vector3 = source_rest.basis.get_scale()
        var target_rest_scale: Vector3 = target_rest.basis.get_scale()
        for key: int in range(key_count):
            var value: Variant = animation.track_get_key_value(track, key)
            if typeof(value) != TYPE_VECTOR3:
                continue
            var source_scale: Vector3 = value
            var ratio: Vector3 = Vector3.ONE
            if absf(source_rest_scale.x) > 0.00001:
                ratio.x = source_scale.x / source_rest_scale.x
            if absf(source_rest_scale.y) > 0.00001:
                ratio.y = source_scale.y / source_rest_scale.y
            if absf(source_rest_scale.z) > 0.00001:
                ratio.z = source_scale.z / source_rest_scale.z
            animation.track_set_key_value(track, key, target_rest_scale * ratio)

func _rest_length_ratio(source_position: Vector3, target_position: Vector3) -> float:
    var source_length: float = source_position.length()
    var target_length: float = target_position.length()
    if source_length <= 0.00001 or target_length <= 0.00001:
        return 1.0
    return clampf(target_length / source_length, 0.001, 1000.0)

func _has_required_combat_bones() -> bool:
    var required: Array[String] = [
        "Hips",
        "Spine",
        "Spine1",
        "Spine2",
        "Head",
        "LeftArm",
        "LeftForeArm",
        "LeftHand",
        "RightArm",
        "RightForeArm",
        "RightHand",
        "LeftUpLeg",
        "LeftLeg",
        "LeftFoot",
        "RightUpLeg",
        "RightLeg",
        "RightFoot"
    ]
    for short_name: String in required:
        if _find_mixamo_bone(short_name) < 0:
            return false
    return true

func _install_native_locomotion_library() -> int:
    var library: AnimationLibrary = AnimationLibrary.new()
    var mappings: Dictionary = {
        "idle": "idle",
        "walk": "walk",
        "run": "run"
    }
    for destination: String in mappings:
        var source_name: StringName = _find_imported_animation(String(mappings[destination]))
        if source_name == StringName():
            continue
        var source: Animation = animation_player.get_animation(source_name)
        if source == null:
            continue
        var copy: Animation = source.duplicate(true) as Animation
        if copy == null:
            continue
        copy.loop_mode = Animation.LOOP_LINEAR
        var add_result: Error = library.add_animation(StringName(destination), copy)
        if add_result != OK:
            continue
    if library.get_animation_list_size() <= 0:
        return 0
    var result: Error = animation_player.add_animation_library(&"native", library)
    return library.get_animation_list_size() if result == OK else 0

func _find_imported_animation(lower_name: String) -> StringName:
    for animation_value: String in animation_player.get_animation_list():
        var text_name: String = String(animation_value)
        if text_name.begins_with("combat/") or text_name.begins_with("native/"):
            continue
        if text_name.to_lower() == lower_name:
            return StringName(text_name)
    return StringName()

func _animation_for_state(state_name: String) -> StringName:
    if prefer_native_locomotion:
        if state_name == "idle" and animation_player.has_animation(&"native/idle"):
            return &"native/idle"
        if state_name == "run" and animation_player.has_animation(&"native/walk"):
            return &"native/walk"
        if state_name == "sprint" and animation_player.has_animation(&"native/run"):
            return &"native/run"

    if state_name == "idle" and player.has_method("get_character_definition"):
        var definition: CharacterDefinition = player.call("get_character_definition") as CharacterDefinition
        if definition != null and not definition.idle_animation_override.is_empty():
            var override_name: StringName = StringName(definition.idle_animation_override)
            if animation_player.has_animation(override_name):
                return override_name

    return StringName("combat/" + state_name)

func _setup_animation_tree() -> void:
    available_animations = animation_player.get_animation_list()
    animation_player.stop()
    animation_tree = AnimationTree.new()
    animation_tree.name = "CombatAnimationTree"
    add_child(animation_tree)
    animation_tree.anim_player = animation_tree.get_path_to(animation_player)
    # Physics clocks for animation, hit-stop and gameplay are identical.
    animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var state_machine: AnimationNodeStateMachine = AnimationNodeStateMachine.new()
    var clips: Dictionary = manifest["clips"]
    var runtime_states: Dictionary = {}
    for state: String in clips:
        if not bool(clips[state].get("expansion", false)):
            runtime_states[state] = true
    if character_definition != null:
        var moves: MovesetDefinition = character_definition.moveset
        if moves != null:
            for attack: AttackDefinition in moves.ground + moves.aerial + [moves.neutral_finisher, moves.up_finisher, moves.down_finisher, moves.side_finisher]:
                if attack != null:
                    runtime_states[attack.animation_name] = true
        for jutsu: JutsuDefinition in character_definition.jutsu_definitions:
            runtime_states[jutsu.animation_name] = true
        if character_definition.ultimate_definition != null:
            runtime_states[character_definition.ultimate_definition.entry_clip] = true
            runtime_states[character_definition.ultimate_definition.finisher_clip] = true
    var index: int = 0
    for state_name: String in clips:
        var blend: AnimationNodeBlendTree = AnimationNodeBlendTree.new()
        var clip: AnimationNodeAnimation = AnimationNodeAnimation.new()
        clip.animation = _animation_for_state(state_name)
        blend.add_node(&"clip", clip, Vector2(0, 0))
        blend.add_node(&"speed", AnimationNodeTimeScale.new(), Vector2(180, 0))
        blend.connect_node(&"speed", 0, &"clip")
        blend.connect_node(&"output", 0, &"speed")
        state_machine.add_node(StringName(state_name), blend,
            Vector2(float(index % 4) * 190.0, float(floori(float(index) / 4.0)) * 115.0))
        index += 1
    # Explicit directed transitions: travel() now crossfades rather than teleporting
    # through an unconnected state machine. One-shots always restart at time zero.
    for from_state: String in clips:
        for to_state: String in clips:
            if from_state == to_state:
                continue
            # Gallery-only states travel through idle; active gameplay retains
            # direct fades. Avoid a 127² graph on every mobile/menu fighter.
            if from_state != "idle" and to_state != "idle" and (not runtime_states.has(from_state) or not runtime_states.has(to_state)):
                continue
            var transition: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
            transition.xfade_time = 0.08
            if to_state.begins_with("attack_") or to_state.begins_with("air_attack_") or bool(clips[to_state].get("expansion", false)):
                transition.xfade_time = 0.025
            elif to_state == "hit" or to_state == "dodge":
                transition.xfade_time = 0.035
            transition.reset = true
            state_machine.add_transition(StringName(from_state), StringName(to_state), transition)
    animation_tree.tree_root = state_machine
    animation_tree.active = true
    playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
    playback.start(&"idle", true)
    current_state = "idle"
    animation_tree.advance(0.0)

func _sync_animation_state(delta: float) -> void:
    if playback == null:
        return
    var airborne: bool = not player.is_on_floor()
    landing_timer = maxf(landing_timer - delta, 0.0)
    if was_airborne and not airborne:
        landing_timer = 0.18
    was_airborne = airborne
    var desired_state: String = _runtime_animation_state()
    var action_id: int = int(player.call("get_animation_action_id"))
    if desired_state == current_state:
        if action_id != last_action_id and not bool(manifest.get("clips", {}).get(desired_state, {}).get("loop", false)):
            playback.start(StringName(desired_state), true)
    else:
        current_state = desired_state
        playback.travel(StringName(desired_state), true)
        # Interrupt an in-progress locomotion fade immediately for combat input.
        playback.next()
    last_action_id = action_id
    if desired_state in ["run", "sprint", "strafe_left", "strafe_right", "back_run"]:
        var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
        var reference_speed: float = 12.0 if desired_state == "sprint" else 7.5
        animation_tree.set("parameters/%s/speed/scale" % desired_state,
            clampf(speed / reference_speed, 0.35, 1.8))

func _runtime_animation_state() -> String:
    var player_state: String = String(player.call("get_animation_state"))
    var combo_step: int = clampi(int(player.call("get_combo_step")), 1, 4)
    if player_state in ["attack", "air_attack"] and player.has_method("get_attack_animation"):
        return String(player.call("get_attack_animation"))
    if player_state == "attack":
        return "attack_%d" % combo_step
    if player_state == "air_attack":
        return "air_attack_%d" % combo_step
    if player_state == "jutsu" and player.has_method("get_special_animation"):
        return String(player.call("get_special_animation"))
    if player_state == "hit" and player.guard_meter <= 0.0:
        return "guard_break"
    if player_state == "run" and is_instance_valid(player.locked_target):
        var relative: Vector3 = player.global_basis.inverse() * player.velocity
        if absf(relative.x) > absf(relative.z) * 0.8:
            return "strafe_right" if relative.x > 0.0 else "strafe_left"
        if relative.z < -0.2:
            return "back_run"
    if player_state == "air":
        return "jump" if player.velocity.y > 0.5 else "fall"
    if landing_timer > 0.0 and player_state in ["idle", "run"]:
        return "land"
    if player_state == "run" and Vector2(player.velocity.x, player.velocity.z).length() > 9.0:
        return "sprint"
    return player_state

func get_hand_world_position(short_name: String = "RightHand") -> Vector3:
    var hand_bone: int = _find_mixamo_bone(short_name) if skeleton != null else -1
    if skeleton == null or hand_bone < 0:
        return player.global_position + Vector3.UP * 0.3 + player.global_basis.z * 0.6
    return (skeleton.global_transform * skeleton.get_bone_global_pose(hand_bone)).origin

func get_attack_timing(combo_step: int, airborne: bool) -> Dictionary:
    var state_name: String = ("air_attack_%d" if airborne else "attack_%d") % combo_step
    var clips: Dictionary = manifest.get("clips", {})
    return clips.get(state_name, {})

func snap_attack_hitbox(combo_step: int, airborne: bool) -> void:
    if not rig_loaded or skeleton == null or not follow_hitbox_to_bones:
        return

    var bone_index: int = _choose_strike_bone(combo_step, airborne)
    if bone_index < 0:
        return

    var bone_pose: Transform3D = skeleton.get_bone_global_pose(bone_index)
    var world_pose: Transform3D = skeleton.global_transform * bone_pose

    var reach_direction: Vector3 = player.global_basis.z.normalized()
    if reach_direction.length_squared() <= 0.001:
        reach_direction = Vector3.FORWARD

    attack_hitbox.global_transform = Transform3D(
        player.global_basis,
        world_pose.origin + reach_direction * 0.16
    )

func _choose_strike_bone(combo_step: int, airborne: bool) -> int:
    var timing: Dictionary = get_attack_timing(clampi(combo_step, 1, 4), airborne)
    if player.get("selected_attack") is AttackDefinition:
        timing = player.selected_attack.animation_timing(manifest)
    return _find_mixamo_bone(String(timing.get("bone", "RightHand")))

func _find_skeleton(root: Node) -> Skeleton3D:
    if root is Skeleton3D:
        return root as Skeleton3D

    for child: Node in root.get_children():
        var found: Skeleton3D = _find_skeleton(child)
        if found != null:
            return found

    return null

func _find_animation_player(root: Node) -> AnimationPlayer:
    if root is AnimationPlayer:
        return root as AnimationPlayer

    for child: Node in root.get_children():
        var found: AnimationPlayer = _find_animation_player(child)
        if found != null:
            return found

    return null

func get_rig_status() -> String:
    return rig_status

func is_rig_loaded() -> bool:
    return rig_loaded

func get_available_animations_text() -> String:
    if available_animations.is_empty():
        return "nenhuma"

    var names: Array[String] = []
    for animation_value: String in available_animations:
        names.append(String(animation_value))

    return ", ".join(names)
