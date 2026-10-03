extends Node3D

const COMBAT_LIBRARY: AnimationLibrary = preload("res://assets/animations/combat_mixamo.tres")
const TOON_MATERIAL: StandardMaterial3D = preload("res://assets/characters/stylized/toon.tres")
# Track paths are immutable after installation; playback stays per fighter.
static var library_cache: Dictionary = {}

const MANIFEST_PATH: String = "res://assets/animations/combat_manifest.json"

@export_file("*.glb") var model_path: String = "res://assets/characters/rigged.glb"
@export var fallback_visual_path: NodePath = NodePath("../VisualRoot")
@export var model_offset: Vector3 = Vector3(0.0, -0.95, 0.0)
@export var model_scale: float = 1.0
@export var auto_scale_model: bool = true
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
var applied_model_scale: float = 1.0
var real_animation_count: int = 0
var manifest: Dictionary = {}
var last_action_id: int = -1
var landing_timer: float = 0.0
var was_airborne: bool = false
var chakra_aura: MeshInstance3D = null
var aura_base_scale: Vector3 = Vector3.ONE

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
        var definition: CharacterDefinition = player.call("get_character_definition") as CharacterDefinition
        if definition != null:
            model_path = definition.model_path
            auto_scale_model = definition.model_auto_scale
            model_scale = definition.model_scale_multiplier
            model_offset = definition.model_offset
            model_yaw_degrees = definition.model_yaw_degrees
            fallback_import_scale = definition.model_fallback_import_scale
    _try_load_rig()

func _physics_process(delta: float) -> void:
    if not rig_loaded:
        return

    _sync_animation_state(delta)
    animation_tree.advance(delta)
    _update_chakra_aura(delta)

    var state: String = String(player.call("get_animation_state"))
    if follow_hitbox_to_bones and (state == "attack" or state == "air_attack"):
        snap_attack_hitbox(int(player.call("get_combo_step")), state == "air_attack")

func _try_load_rig() -> void:
    if not ResourceLoader.exists(model_path):
        rig_status = "RIG: coloque rigged.glb em assets/characters/"
        return

    var packed_scene: PackedScene = ResourceLoader.load(model_path) as PackedScene
    if packed_scene == null:
        rig_status = "RIG: GLB não abriu como PackedScene"
        return

    var instance_node: Node = packed_scene.instantiate()
    model_instance = instance_node as Node3D
    if model_instance == null:
        instance_node.queue_free()
        rig_status = "RIG: raiz do GLB não é Node3D"
        return

    add_child(model_instance)
    model_instance.position = Vector3.ZERO
    model_instance.rotation_degrees.y = model_yaw_degrees
    model_instance.scale = Vector3.ONE

    _apply_character_scale()
    model_instance.position = model_offset

    skeleton = _find_skeleton(model_instance)
    animation_player = _find_animation_player(model_instance)

    if skeleton == null:
        rig_status = "RIG: Skeleton3D não encontrado"
        model_instance.queue_free()
        model_instance = null
        return

    _cache_combat_bones()
    apply_visual_material(model_instance)
    if animation_player == null or not _install_combat_library():
        rig_status = "RIG: biblioteca real incompleta; confira o log"
        model_instance.queue_free()
        model_instance = null
        return
    _setup_animation_tree()

    rig_loaded = true
    attack_hitbox.top_level = true

    if is_instance_valid(fallback_visual):
        chakra_aura = fallback_visual.get_node_or_null("ChakraAura") as MeshInstance3D
        if chakra_aura != null:
            chakra_aura.reparent(self, true)
            aura_base_scale = chakra_aura.scale
        fallback_visual.visible = false
        fallback_visual.process_mode = Node.PROCESS_MODE_DISABLED

    rig_status = "RIG: OK | %d clips reais CC0" % real_animation_count

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

    return maxf(bounds_max_y - bounds_min_y, 0.0)

func _collect_mesh_instances(root: Node, output: Array[MeshInstance3D]) -> void:
    if root is MeshInstance3D:
        output.append(root as MeshInstance3D)

    for child: Node in root.get_children():
        _collect_mesh_instances(child, output)

func apply_visual_material(root: Node) -> void:
    var use_toon: bool = model_path.begins_with("res://assets/characters/stylized/")
    if player.has_method("get_character_definition"):
        use_toon = bool(player.call("get_character_definition").stylized_material)
    if not use_toon:
        return
    var meshes: Array[MeshInstance3D] = []
    _collect_mesh_instances(root, meshes)
    for mesh: MeshInstance3D in meshes:
        mesh.material_override = TOON_MATERIAL

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
    var animation_root: Node = animation_player.get_node(animation_player.root_node)
    var skeleton_path: String = String(animation_root.get_path_to(skeleton))
    var bone_names: PackedStringArray = []
    for index: int in range(skeleton.get_bone_count()):
        bone_names.append(String(skeleton.get_bone_name(index)))
    # Same rest rig can drive different original meshes. Different rigs must
    # never accidentally share retargeted transforms just because names match.
    var rest_signature: String = ""
    for index: int in range(skeleton.get_bone_count()):
        rest_signature += str(skeleton.get_bone_rest(index))
    var cache_key: String = skeleton_path + "|" + ",".join(bone_names) + "|" + rest_signature.sha256_text()
    var library: AnimationLibrary = library_cache.get(cache_key) as AnimationLibrary
    if library == null:
        library = COMBAT_LIBRARY.duplicate(true) as AnimationLibrary
        for clip_name: StringName in library.get_animation_list():
            if not clips.has(String(clip_name)):
                return false
            var animation: Animation = library.get_animation(clip_name)
            for track: int in range(animation.get_track_count()):
                var path: NodePath = animation.track_get_path(track)
                var bone_name: String = String(path.get_subname(0))
                if skeleton.find_bone(bone_name) < 0:
                    push_error("Combat clip %s: missing bone %s" % [clip_name, bone_name])
                    return false
                animation.track_set_path(track, NodePath(skeleton_path + ":" + bone_name))
        library_cache[cache_key] = library
    # Original happy remains in the import, but is never selected for combat.
    var result: Error = animation_player.add_animation_library(&"combat", library)
    real_animation_count = library.get_animation_list().size()
    return result == OK and real_animation_count == clips.size()

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
    var index: int = 0
    for state_name: String in clips:
        var blend: AnimationNodeBlendTree = AnimationNodeBlendTree.new()
        var clip: AnimationNodeAnimation = AnimationNodeAnimation.new()
        clip.animation = StringName("combat/" + state_name)
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
            var transition: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
            transition.xfade_time = 0.08
            if to_state.begins_with("attack_") or to_state.begins_with("air_attack_"):
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
        if action_id != last_action_id and desired_state in ["hit", "jutsu", "rasengan", "guard_break", "dodge", "chakra_dash", "attack_1", "attack_2", "attack_3", "attack_4", "air_attack_1", "air_attack_2", "air_attack_3", "air_attack_4"]:
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
