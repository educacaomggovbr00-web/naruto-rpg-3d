extends Node3D

var active: bool = false
var owner_fighter: CharacterBody3D = null
var target: Node3D = null
var direction: Vector3 = Vector3.BACK
var remaining: float = 0.0
var shape: SphereShape3D
var hit_mask: int = 16
var definition: JutsuDefinition = null
var orb: MeshInstance3D
var elemental_visual: Node3D
var material: StandardMaterial3D

func _ready() -> void:
    process_physics_priority = 15
    shape = SphereShape3D.new()
    orb = MeshInstance3D.new()
    material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.emission_enabled = true
    material.roughness = 0.55
    orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(orb)
    elemental_visual = Node3D.new()
    elemental_visual.set_script(preload("res://scripts/elemental_jutsu_visual.gd"))
    add_child(elemental_visual)
    visible = false

func launch_jutsu(source: CharacterBody3D, destination: Node3D, origin: Vector3, heading: Vector3, data: JutsuDefinition) -> void:
    owner_fighter = source
    target = destination
    definition = data
    global_position = origin
    direction = heading.normalized()
    hit_mask = 8 if source.collision_layer == 4 else 16
    shape.radius = data.hitbox_radius
    remaining = maxf(0.6, 1.4 + data.hitbox_radius * 0.35)
    var visual_mesh: PrimitiveMesh = RosterVisualStyle.projectile_mesh(data.effect)
    visual_mesh.material = material
    orb.mesh = visual_mesh
    orb.scale = RosterVisualStyle.projectile_scale(data.effect, data.hitbox_radius)
    var fallback_color: Color = Color(0.08, 0.55, 1.0)
    if source.has_method("get_character_definition"):
        var character: CharacterDefinition = source.call("get_character_definition") as CharacterDefinition
        if character != null:
            fallback_color = character.energy_color
    var color: Color = RosterVisualStyle.color(data.effect, fallback_color).lerp(fallback_color, 0.18)
    material.albedo_color = color
    material.emission = color
    var enhanced: bool = data.effect in RosterVisualStyle.EFFECTS
    orb.visible = not enhanced
    elemental_visual.visible = enhanced
    if enhanced:
        elemental_visual.configure(data.effect, clampf(data.hitbox_radius,.18,.85),false,"wave" if data.jutsu_id == "henrique_katon_wave" else "orb")
        elemental_visual.heading = direction
    active = true
    visible = true

func _physics_process(delta: float) -> void:
    if not active:
        return
    remaining -= delta
    if remaining <= 0.0 or not is_instance_valid(owner_fighter) or bool(owner_fighter.call("is_defeated")):
        recycle()
        return

    if is_instance_valid(target) and (not target.has_method("is_defeated") or not bool(target.call("is_defeated"))):
        var aim: Vector3 = target.global_position + Vector3.UP * 0.25 - global_position
        if aim.length_squared() > 0.001:
            direction = direction.slerp(aim.normalized(), minf(delta * definition.tracking_strength, 1.0)).normalized()

    elemental_visual.heading = direction
    var travel: Vector3 = direction * definition.movement_speed * delta
    var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    query.shape = shape
    query.transform = Transform3D(Basis.IDENTITY, global_position)
    query.motion = travel
    query.collision_mask = 1 | hit_mask
    query.collide_with_areas = true
    query.collide_with_bodies = true

    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var fractions: PackedFloat32Array = space.cast_motion(query)
    var fraction: float = fractions[0] if fractions.size() == 2 else 1.0
    global_position += travel * fraction

    query.motion = Vector3.ZERO
    query.transform.origin = global_position + direction * 0.02
    for contact: Dictionary in space.intersect_shape(query, 8):
        var collider: Node = contact["collider"] as Node
        if collider is Area3D and collider.has_method("get_fighter"):
            var fighter: Node = collider.call("get_fighter")
            if fighter != owner_fighter and fighter.has_method("receive_combat_hit"):
                var dealt: float = float(fighter.call(
                    "receive_combat_hit",
                    definition.damage * float(owner_fighter.call("get_damage_multiplier")),
                    direction,
                    definition.knockback,
                    definition.launch_force,
                    definition.hitstun
                ))
                if definition.effect == "black_fire" and dealt > 0.0 and not fighter.get_is_guarding():
                    preload("res://scripts/black_flame_status.gd").attach(fighter, owner_fighter)
                if definition.jutsu_id == "henrique_genjutsu" and dealt > 0.0 and not fighter.get_is_guarding():
                    preload("res://scripts/genjutsu_overlay.gd").attach(fighter)
                owner_fighter.call("on_attack_connected", fighter, dealt, definition.launch_force)
                _impact()
                recycle()
                return
        elif collider is StaticBody3D:
            _impact()
            recycle()
            return

    if fraction < 1.0:
        recycle()
        return

    var spin: float = RosterVisualStyle.orbit_speed(definition.effect)
    orb.rotation.y += delta * spin
    orb.rotation.x += delta * (spin * 0.45)

func _impact() -> void:
    var feedback: Node = owner_fighter.get_parent().get_node_or_null("CombatFeedback")
    if feedback != null:
        feedback.spawn_chakra_impact(global_position,RosterVisualStyle.color(definition.effect))

func recycle() -> void:
    active = false
    visible = false
    owner_fighter = null
    target = null
    definition = null

