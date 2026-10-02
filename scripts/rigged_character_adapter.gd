extends Node3D

@export_file("*.glb") var model_path: String = "res://assets/characters/rigged.glb"
@export var fallback_visual_path: NodePath = NodePath("../VisualRoot")
@export var model_offset: Vector3 = Vector3(0.0, -0.95, 0.0)
@export var model_scale: float = 1.0
@export var model_yaw_degrees: float = 180.0
@export var idle_fallback_animation: String = "happy"
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

var right_hand_bone: int = -1
var left_hand_bone: int = -1
var right_foot_bone: int = -1
var left_foot_bone: int = -1

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var attack_hitbox: Area3D = $"../AttackHitbox"

func _ready() -> void:
    fallback_visual = get_node_or_null(fallback_visual_path) as Node3D
    _try_load_rig()

func _physics_process(_delta: float) -> void:
    if not rig_loaded:
        return

    _sync_animation_state()

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
    model_instance.position = model_offset
    model_instance.rotation_degrees.y = model_yaw_degrees
    model_instance.scale = Vector3.ONE * model_scale

    skeleton = _find_skeleton(model_instance)
    animation_player = _find_animation_player(model_instance)

    if skeleton == null:
        rig_status = "RIG: Skeleton3D não encontrado"
        model_instance.queue_free()
        model_instance = null
        return

    _cache_combat_bones()
    _setup_animation_tree()

    rig_loaded = true
    attack_hitbox.top_level = true

    if is_instance_valid(fallback_visual):
        fallback_visual.visible = false
        fallback_visual.process_mode = Node.PROCESS_MODE_DISABLED

    var animation_count: int = available_animations.size()
    rig_status = "RIG: OK | %d ossos | %d animação(ões)" % [
        skeleton.get_bone_count(),
        animation_count
    ]

func _cache_combat_bones() -> void:
    right_hand_bone = skeleton.find_bone("mixamorig:RightHand")
    left_hand_bone = skeleton.find_bone("mixamorig:LeftHand")
    right_foot_bone = skeleton.find_bone("mixamorig:RightFoot")
    left_foot_bone = skeleton.find_bone("mixamorig:LeftFoot")

func _setup_animation_tree() -> void:
    if animation_player == null:
        rig_status = "RIG: sem AnimationPlayer; usando pose importada"
        return

    available_animations = animation_player.get_animation_list()
    if available_animations.is_empty():
        rig_status = "RIG: sem animações importadas"
        return

    animation_tree = AnimationTree.new()
    animation_tree.name = "RuntimeAnimationTree"
    add_child(animation_tree)
    animation_tree.anim_player = animation_tree.get_path_to(animation_player)

    var state_machine: AnimationNodeStateMachine = AnimationNodeStateMachine.new()
    var states: Array[String] = [
        "idle",
        "run",
        "air",
        "attack",
        "air_attack",
        "guard",
        "dodge",
        "chakra_dash",
        "chakra_charge",
        "jutsu",
        "hit",
        "defeat"
    ]

    for index: int in range(states.size()):
        var state_name: String = states[index]
        var animation_name: String = _choose_animation_for_state(state_name)
        var animation_node: AnimationNodeAnimation = AnimationNodeAnimation.new()
        animation_node.animation = StringName(animation_name)

        var column: int = index % 4
        var row: int = index / 4
        state_machine.add_node(
            StringName(state_name),
            animation_node,
            Vector2(float(column) * 190.0, float(row) * 115.0)
        )

    animation_tree.tree_root = state_machine
    animation_tree.active = true

    var playback_value: Variant = animation_tree.get("parameters/playback")
    playback = playback_value as AnimationNodeStateMachinePlayback

    if playback != null:
        playback.start(StringName("idle"), true)
        current_state = "idle"

func _choose_animation_for_state(state_name: String) -> String:
    var keywords: Array[String] = _keywords_for_state(state_name)

    for animation_value: StringName in available_animations:
        var animation_name: String = String(animation_value)
        var lower_name: String = animation_name.to_lower()

        if lower_name == "reset":
            continue

        for keyword: String in keywords:
            if lower_name.contains(keyword):
                return animation_name

    if state_name == "idle":
        for animation_value: StringName in available_animations:
            var animation_name: String = String(animation_value)
            if animation_name.to_lower() == idle_fallback_animation.to_lower():
                return animation_name

    for animation_value: StringName in available_animations:
        var animation_name: String = String(animation_value)
        if animation_name.to_lower() != "reset":
            return animation_name

    return String(available_animations[0])

func _keywords_for_state(state_name: String) -> Array[String]:
    match state_name:
        "idle":
            return ["idle", "happy", "stand", "breath"]
        "run":
            return ["run", "jog", "sprint", "walk"]
        "air":
            return ["jump", "fall", "air"]
        "attack":
            return ["attack", "punch", "kick", "combo", "melee"]
        "air_attack":
            return ["air_attack", "aerial", "jump_attack"]
        "guard":
            return ["guard", "block", "defend"]
        "dodge":
            return ["dodge", "roll", "evade", "sidestep"]
        "chakra_dash":
            return ["dash", "rush", "charge_forward"]
        "chakra_charge":
            return ["charge", "powerup", "power_up"]
        "jutsu":
            return ["jutsu", "cast", "skill", "spell"]
        "hit":
            return ["hit", "hurt", "damage", "reaction"]
        "defeat":
            return ["defeat", "death", "ko", "down"]
        _:
            return ["idle"]

func _sync_animation_state() -> void:
    if playback == null:
        return

    var desired_state: String = String(player.call("get_animation_state"))
    if desired_state == current_state:
        return

    current_state = desired_state
    playback.travel(StringName(desired_state), true)

func snap_attack_hitbox(combo_step: int, airborne: bool) -> void:
    if not rig_loaded or skeleton == null or not follow_hitbox_to_bones:
        return

    var bone_index: int = _choose_strike_bone(combo_step, airborne)
    if bone_index < 0:
        return

    var bone_pose: Transform3D = skeleton.get_bone_global_pose(bone_index)
    var world_pose: Transform3D = skeleton.global_transform * bone_pose

    var reach_direction: Vector3 = world_pose.basis.z.normalized()
    if reach_direction.length_squared() <= 0.001:
        reach_direction = player.global_basis.z.normalized()

    attack_hitbox.global_transform = Transform3D(
        world_pose.basis,
        world_pose.origin + reach_direction * 0.16
    )

func _choose_strike_bone(combo_step: int, airborne: bool) -> int:
    if airborne and combo_step >= 4:
        return right_foot_bone if right_foot_bone >= 0 else left_foot_bone

    match combo_step:
        1:
            return right_hand_bone
        2:
            return left_hand_bone
        3:
            return right_foot_bone if right_foot_bone >= 0 else right_hand_bone
        4:
            return left_foot_bone if left_foot_bone >= 0 else right_foot_bone
        _:
            return right_hand_bone

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
    for animation_value: StringName in available_animations:
        names.append(String(animation_value))

    return ", ".join(names)
