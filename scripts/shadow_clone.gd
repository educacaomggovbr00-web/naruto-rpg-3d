extends CharacterBody3D

var support_pose: bool = false
var active: bool = false
var source: CharacterBody3D
var target: Node3D
var model: Node3D
var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var hitbox: Area3D
var lifetime: float = 0.0
var elapsed: float = 0.0
var attack_delay: float = 0.0
var attack_started: bool = false
var hit_open: bool = false
var clip_name: String = "attack_2"
var launch: float = 0.0
var damage: float = 6.0
var offset: Vector3 = Vector3.ZERO
var hurtbox: Area3D

func _ready() -> void:
    process_physics_priority = 15
    collision_layer = 0
    collision_mask = 1
    var body: CollisionShape3D = CollisionShape3D.new()
    var capsule: CapsuleShape3D = CapsuleShape3D.new()
    capsule.radius = 0.3
    capsule.height = 1.6
    body.shape = capsule
    add_child(body)
    hitbox = Area3D.new()
    hitbox.set_script(preload("res://scripts/combat_hitbox.gd"))
    hitbox.collision_layer = 0
    hitbox.collision_mask = 16
    var collision: CollisionShape3D = CollisionShape3D.new()
    var sphere: SphereShape3D = SphereShape3D.new()
    sphere.radius = 0.7
    collision.shape = sphere
    hitbox.add_child(collision)
    add_child(hitbox)
    hitbox.top_level = true
    hurtbox = Area3D.new()
    hurtbox.set_script(preload("res://scripts/combat_hurtbox.gd"))
    hurtbox.collision_layer = 0
    hurtbox.collision_mask = 0
    hurtbox.monitoring = false
    var vulnerable: CollisionShape3D = CollisionShape3D.new()
    vulnerable.shape = capsule
    hurtbox.add_child(vulnerable)
    add_child(hurtbox)
    visible = false

func prepare(actor: CharacterBody3D) -> void:
    source = actor
    var adapter: Node = source.get_node("RiggedCharacterAdapter")
    model = load(adapter.model_path).instantiate() as Node3D
    add_child(model)
    model.position = adapter.model_offset
    model.rotation_degrees.y = adapter.model_yaw_degrees
    model.scale = Vector3.ONE * adapter.applied_model_scale
    var meshes: Array[MeshInstance3D] = []
    adapter.call("_collect_mesh_instances", model, meshes)
    for mesh: MeshInstance3D in meshes:
        mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    skeleton = adapter.call("_find_skeleton", model)
    animation_player = adapter.call("_find_animation_player", model)
    # Same imported hierarchy/root paths, shared immutable baked clip data.
    animation_player.add_animation_library(&"combat", adapter.animation_player.get_animation_library(&"combat"))
    animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func summon(victim: Node3D, origin: Vector3, approach_offset: Vector3, delay: float, clip: String, lift: float = 0.0, power: float = 6.0) -> void:
    if model == null:
        return
    support_pose = false
    target = victim
    global_position = origin
    offset = approach_offset
    attack_delay = delay
    clip_name = clip
    launch = lift
    damage = power
    elapsed = 0.0
    lifetime = delay + 0.8
    attack_started = false
    hit_open = false
    velocity = Vector3.ZERO
    hitbox.call("deactivate")
    active = true
    visible = true
    hurtbox.collision_layer = 8
    animation_player.play(&"combat/run")
    source.combat_feedback.call("spawn_substitution", global_position)

func _physics_process(delta: float) -> void:
    if not active:
        return
    elapsed += delta
    lifetime -= delta
    if support_pose:
        animation_player.advance(delta)
        if lifetime <= 0.0 or source.defeated:
            recycle()
        return
    if lifetime <= 0.0 or not is_instance_valid(source) or source.defeated or not is_instance_valid(target) or not bool(target.call("is_targetable")):
        recycle()
        return
    var aim: Vector3 = target.global_position + offset - global_position
    var facing: Vector3 = target.global_position - global_position
    if Vector2(facing.x, facing.z).length() > 0.01:
        rotation.y = atan2(facing.x, facing.z)
    if not attack_started or not hit_open:
        velocity = aim.limit_length(1.0) * 16.0
        if not clip_name.begins_with("air_"):
            velocity.y = 0.0
        move_and_slide()
        if not attack_started and elapsed >= attack_delay:
            attack_started = true
            animation_player.play(StringName("combat/" + clip_name))
    animation_player.advance(delta)
    var manifest: Dictionary = source.rig_adapter.manifest["clips"][clip_name]
    var attack_time: float = elapsed - attack_delay
    if damage > 0.0 and attack_started and not hit_open and attack_time >= float(manifest.get("impact", 0.14)):
        hit_open = true
        hitbox.call("activate", self, damage, 2.0 if absf(launch) < 1.0 else 5.0, launch, 0.5, 0.09)
    var bone_name: String = "mixamorig_" + String(manifest.get("bone", "RightHand"))
    var bone: int = skeleton.find_bone(bone_name)
    if bone >= 0:
        hitbox.global_position = (skeleton.global_transform * skeleton.get_bone_global_pose(bone)).origin + global_basis.z * 0.16

func receive_combat_hit(_damage: float, _direction: Vector3, _knockback: float, _launch: float, _stun: float) -> float:
    recycle()
    return 0.0

func on_attack_connected(victim: Node, dealt: float, lift: float) -> void:
    source.call("on_attack_connected", victim, dealt, lift)

func recycle() -> void:
    if active and is_instance_valid(source):
        source.combat_feedback.call("spawn_substitution", global_position)
    active = false
    visible = false
    hurtbox.collision_layer = 0
    hitbox.call("deactivate")
    target = null
    animation_player.stop()

func present(origin: Vector3, heading: float, lifetime_seconds: float, clip: String = "jutsu") -> void:
    support_pose = true
    active = true
    visible = true
    global_position = origin
    rotation.y = heading
    lifetime = lifetime_seconds
    elapsed = 0.0
    hurtbox.collision_layer = 8
    hitbox.call("deactivate")
    animation_player.play(StringName("combat/" + clip))
    source.combat_feedback.call("spawn_substitution", global_position)

func get_damage_multiplier() -> float:
    return source.call("get_damage_multiplier")
