extends Node3D
## Storm 1 one-tail mode structure; values and current silhouette are our adaptations.
@export var health_threshold: float = 0.30
@export var transform_duration: float = 1.0
@export var mode_duration: float = 18.0
@export var recharge_delay: float = 20.0
var fighter: CharacterBody3D
var active: bool = false
var transforming: bool = false
var remaining: float = 0.0
var cooldown: float = 0.0
var full_charge_hold: float = 0.0
var aura: MeshInstance3D
var tail: MultiMeshInstance3D
var clock: float = 0.0

func _ready() -> void:
    fighter = get_parent() as CharacterBody3D
    process_physics_priority = 15
    aura = MeshInstance3D.new()
    aura.set_script(preload("res://scripts/chakra_orb.gd"))
    add_child(aura)
    aura.scale = Vector3(2.1, 4.2, 2.1)
    aura.call("set_energy_color", Color(1.0, 0.12, 0.025))
    aura.visible = false
    tail = MultiMeshInstance3D.new()
    var batch: MultiMesh = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    var bead: SphereMesh = SphereMesh.new()
    bead.radius = 0.13
    bead.height = 0.26
    bead.radial_segments = 8
    bead.rings = 4
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color(0.9, 0.06, 0.015)
    bead.material = material
    batch.mesh = bead
    batch.instance_count = 10
    batch.custom_aabb = AABB(Vector3(-2, -1, -3), Vector3(4, 4, 4))
    tail.multimesh = batch
    tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(tail)
    tail.visible = false

func eligible() -> bool:
    return not fighter.defeated and not active and not transforming and cooldown <= 0.0 and fighter.health <= fighter.max_health * health_threshold and fighter.chakra >= fighter.max_chakra - 0.01

func start() -> bool:
    if not eligible() or fighter.attack_active or fighter.stagger_timer > 0.0 or fighter.jutsu_timer > 0.0 or fighter.chakra_dash_timer > 0.0 or fighter.dodge_timer > 0.0 or not fighter.is_on_floor():
        return false
    fighter.specials.call("cancel")
    transforming = true
    remaining = transform_duration
    fighter.chakra = 0.0
    fighter.is_charging_chakra = false
    fighter.is_guarding = false
    fighter.jutsu_timer = transform_duration + 0.1
    fighter.animation_action_id += 1
    aura.visible = true
    return true

func _physics_process(delta: float) -> void:
    cooldown = maxf(cooldown - delta, 0.0)
    if fighter.defeated:
        stop()
        return
    if transforming:
        if fighter.stagger_timer > 0.0:
            stop()
            return
        remaining -= delta
        if remaining <= 0.0:
            transforming = false
            active = true
            remaining = mode_duration
            fighter.jutsu_timer = 0.0
            tail.visible = true
            fighter.camera_rig.call("add_combat_impact", 0.12, 2.0)
            fighter.combat_feedback.call("spawn_dash_burst", fighter.global_position)
    elif active:
        remaining -= delta
        if remaining <= 0.0:
            stop()
    else:
        full_charge_hold = full_charge_hold + delta if eligible() and fighter.is_charging_chakra else 0.0
        if full_charge_hold >= 0.6:
            start()
    if aura.visible:
        clock += delta
        for i: int in range(10):
            var t: float = float(i) / 9.0
            var point: Vector3 = Vector3(sin(clock * 3.0 + t * 2.0) * t * 0.32, -0.25 + t * 0.95, -0.3 - t * 1.45)
            var thickness: float = 1.0 - t * 0.65
            tail.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * thickness), point))

func stop() -> void:
    if transforming:
        fighter.jutsu_timer = 0.0
    if active or transforming:
        cooldown = recharge_delay
    active = false
    transforming = false
    full_charge_hold = 0.0
    remaining = 0.0
    if aura != null:
        aura.visible = false
        tail.visible = false

func reset() -> void:
    stop()
    cooldown = 0.0

func movement_multiplier() -> float:
    return 1.2 if active else 1.0

func damage_multiplier() -> float:
    return 1.35 if active else 1.0
