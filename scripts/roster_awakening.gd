extends Node3D
## Shared mobile-friendly Awakening for non-Naruto fighters.

var fighter: CharacterBody3D = null
var definition: AwakeningDefinition = null
var active: bool = false
var transforming: bool = false
var remaining: float = 0.0
var cooldown: float = 0.0
var full_charge_hold: float = 0.0
var aura: MeshInstance3D = null
var aura_material: StandardMaterial3D = null
var clock: float = 0.0

func _ready() -> void:
    fighter = get_parent() as CharacterBody3D
    definition = fighter.character_definition.awakening_definition
    process_physics_priority = 15
    _build_aura()

func _build_aura() -> void:
    aura = MeshInstance3D.new()
    var mesh: SphereMesh = SphereMesh.new()
    mesh.radius = 0.72
    mesh.height = 1.55
    mesh.radial_segments = 12
    mesh.rings = 6

    aura_material = StandardMaterial3D.new()
    aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    aura_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    aura_material.emission_enabled = true
    var color: Color = definition.energy_color if definition != null else Color(0.08, 0.55, 1.0)
    aura_material.albedo_color = Color(color.r, color.g, color.b, 0.16)
    aura_material.emission = color
    aura_material.emission_energy_multiplier = 1.15
    mesh.material = aura_material

    aura.mesh = mesh
    aura.position = Vector3(0.0, 0.10, 0.0)
    aura.scale = Vector3(1.08, 1.55, 0.92)
    aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(aura)
    aura.visible = false

func eligible() -> bool:
    if definition == null or not fighter.character_definition.has_awakening:
        return false
    return (
        not bool(fighter.call("is_defeated"))
        and not active
        and not transforming
        and cooldown <= 0.0
        and fighter.health <= fighter.max_health * definition.health_threshold
        and fighter.chakra >= fighter.max_chakra - 0.01
    )

func start() -> bool:
    if not eligible():
        return false
    if fighter.attack_active or fighter.stagger_timer > 0.0 or fighter.jutsu_timer > 0.0:
        return false
    if fighter.chakra_dash_timer > 0.0 or fighter.dodge_timer > 0.0 or not fighter.is_on_floor():
        return false

    fighter.specials.call("cancel")
    transforming = true
    remaining = definition.transform_duration
    fighter.chakra = 0.0
    fighter.is_charging_chakra = false
    fighter.is_guarding = false
    fighter.jutsu_timer = definition.transform_duration + 0.1
    fighter.animation_action_id += 1
    aura.visible = true
    return true

func _physics_process(delta: float) -> void:
    cooldown = maxf(cooldown - delta, 0.0)

    if bool(fighter.call("is_defeated")):
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
            remaining = definition.mode_duration
            fighter.jutsu_timer = 0.0
            fighter.camera_rig.call("add_combat_impact", 0.12, 2.2)
            if fighter.combat_feedback != null:
                fighter.combat_feedback.call("spawn_dash_burst", fighter.global_position)
    elif active:
        remaining -= delta
        fighter.chakra = minf(fighter.max_chakra, fighter.chakra + definition.chakra_regen_per_second * delta)
        if remaining <= 0.0:
            stop()
    else:
        full_charge_hold = full_charge_hold + delta if eligible() and fighter.is_charging_chakra else 0.0
        if full_charge_hold >= 0.6:
            start()

    if aura.visible:
        clock += delta
        var effect_speed: float = 5.0
        if definition.effect in ["lightning", "taijutsu", "wind"]:
            effect_speed = 9.0
        elif definition.effect in ["sand", "earth", "water"]:
            effect_speed = 3.5
        aura.rotation.y += delta * effect_speed

        var pulse: float = 1.0 + sin(clock * effect_speed * 1.6) * 0.07
        if transforming:
            pulse += 0.10
        aura.scale = Vector3(1.08, 1.55, 0.92) * pulse

func stop() -> void:
    if transforming:
        fighter.jutsu_timer = 0.0
    if active or transforming:
        cooldown = definition.recharge_delay if definition != null else 18.0

    active = false
    transforming = false
    full_charge_hold = 0.0
    remaining = 0.0

    if aura != null:
        aura.visible = false

func reset() -> void:
    stop()
    cooldown = 0.0

func movement_multiplier() -> float:
    return definition.movement_multiplier if active and definition != null else 1.0

func damage_multiplier() -> float:
    return definition.damage_multiplier if active and definition != null else 1.0
