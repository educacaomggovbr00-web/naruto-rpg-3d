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
var tail: MeshInstance3D
var tail_material: ShaderMaterial
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
    # Aura shell leaves the rig visible; no opaque sphere over the whole body.
    aura.mesh = null
    tail = MeshInstance3D.new()
    var vertices: PackedVector3Array = PackedVector3Array()
    var normals: PackedVector3Array = PackedVector3Array()
    var uvs: PackedVector2Array = PackedVector2Array()
    var indices: PackedInt32Array = PackedInt32Array()
    for i: int in range(11):
        var t: float = float(i) / 10.0
        var center: Vector3 = Vector3(0, -0.25 + t * t * 0.95, -0.3 - t * 1.45)
        var tangent: Vector3 = Vector3(0, t * 1.9, -1.45).normalized()
        var side: Vector3 = tangent.cross(Vector3.RIGHT).normalized()
        for j: int in range(9):
            var angle: float = float(j) * TAU / 8.0
            var normal: Vector3 = Vector3.RIGHT * cos(angle) + side * sin(angle)
            vertices.append(center + normal * (0.15 * (1.0 - t * 0.90)))
            normals.append(normal)
            uvs.append(Vector2(float(j) / 8.0, t))
            if i < 10 and j < 8:
                var v: int = i * 9 + j
                indices.append_array(PackedInt32Array([v, v + 9, v + 1, v + 1, v + 9, v + 10]))
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices
    var shape: ArrayMesh = ArrayMesh.new()
    shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    tail.mesh = shape
    tail_material = ShaderMaterial.new()
    tail_material.shader = preload("res://assets/vfx/chakra_tail.gdshader")
    tail.material_override = tail_material
    tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    tail.custom_aabb = AABB(Vector3(-0.5, -0.5, -2), Vector3(1, 2, 2))
    add_child(tail)
    tail.visible = false

func eligible() -> bool:
    return fighter.character_definition.has_awakening and not fighter.defeated and not active and not transforming and cooldown <= 0.0 and fighter.health <= fighter.max_health * health_threshold and fighter.chakra >= fighter.max_chakra - 0.01

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
        tail_material.set_shader_parameter("phase", clock)

func stop() -> void:
    if transforming:
        fighter.jutsu_timer = 0.0
    if active or transforming:
        cooldown = recharge_delay
    fighter.specials.sphere_visual.call("set_energy_color", Color(0.08, 0.55, 1.0))
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
