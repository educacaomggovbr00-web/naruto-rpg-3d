extends Node3D
## Bounded marks and original breakable props, using the existing arena bounds.
const MARK_BUDGET: int = 24
var marks: MultiMeshInstance3D
var mark_life: Array[float] = []
var cursor: int = 0
var props: Array[StaticBody3D] = []
var edge_cooldowns: Dictionary = {}

func _ready() -> void:
    marks = MultiMeshInstance3D.new()
    var batch: MultiMesh = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.use_colors = true
    batch.instance_count = MARK_BUDGET
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = 1.0
    mesh.bottom_radius = 1.0
    mesh.height = .008
    mesh.radial_segments = 12
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.roughness = 1.0
    mesh.material = material
    batch.mesh = mesh
    marks.multimesh = batch
    marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(marks)
    for index: int in range(MARK_BUDGET):
        mark_life.append(0.0)
        batch.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))
    if _flow().battle_rules_enabled:
        for side: float in [-1.0, 1.0]:
            for z: float in [-18.0, -6.0, 6.0, 18.0]:
                var prop: StaticBody3D = StaticBody3D.new()
                prop.set_script(preload("res://scripts/breakable_prop.gd"))
                prop.position = Vector3(side * 24.0, .75, z)
                add_child(prop)
                props.append(prop)

func mark_impact(origin: Vector3, effect: String, radius: float = 1.0) -> void:
    if not _flow().battle_rules_enabled:
        return
    var color: Color = Color("34211b") if effect in ["fire", "black_fire", "oil"] else Color("2c4653") if effect in ["water", "lightning"] else Color("584a39")
    var position: Vector3 = Vector3(clampf(origin.x, -28.0, 28.0), .017, clampf(origin.z, -28.0, 28.0))
    marks.multimesh.set_instance_transform(cursor, Transform3D(Basis.IDENTITY.scaled(Vector3(clampf(radius, .3, 2.2), 1.0, clampf(radius, .3, 2.2))), position))
    marks.multimesh.set_instance_color(cursor, Color(color.r, color.g, color.b, .72))
    mark_life[cursor] = 14.0
    cursor = (cursor + 1) % MARK_BUDGET

func area_damage(origin: Vector3, radius: float, damage: float) -> void:
    if not _flow().battle_rules_enabled:
        return
    for prop: StaticBody3D in props:
        if is_instance_valid(prop) and prop.global_position.distance_to(origin) <= radius + .75:
            prop.receive_scenery_hit(damage)

func _physics_process(delta: float) -> void:
    for index: int in range(MARK_BUDGET):
        if mark_life[index] <= 0.0:
            continue
        mark_life[index] = maxf(0.0, mark_life[index] - delta)
        var color: Color = marks.multimesh.get_instance_color(index)
        color.a = .72 * minf(mark_life[index] / 3.0, 1.0)
        marks.multimesh.set_instance_color(index, color)
        if mark_life[index] <= 0.0:
            marks.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))
    if not _flow().battle_rules_enabled or _flow().arena_id not in ["valley", "ruins"]:
        return
    for name_value: String in ["Player", "EnemyDummy"]:
        var actor: CharacterBody3D = get_parent().get_node(name_value)
        edge_cooldowns[name_value] = maxf(0.0, float(edge_cooldowns.get(name_value, 0.0)) - delta)
        var near_edge: bool = maxf(absf(actor.global_position.x), absf(actor.global_position.z)) >= 27.8
        var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
        if near_edge and speed >= 7.0 and actor.stagger_timer > 0.0 and edge_cooldowns[name_value] <= 0.0:
            edge_cooldowns[name_value] = 3.0
            actor.receive_combat_hit(4.0, -actor.global_position.normalized(), 5.0, -5.0, .45)
            mark_impact(actor.global_position, "earth", .9)

static func impact(source: Node, origin: Vector3, effect: String, radius: float = 1.0, damage: float = 0.0) -> void:
    var arena: Node = source.get_parent().get_node_or_null("ArenaInteractions")
    if arena != null:
        arena.mark_impact(origin, effect, radius)
        arena.area_damage(origin, radius, damage)

func _flow() -> Node:
    return get_tree().root.get_node("GameFlow")
