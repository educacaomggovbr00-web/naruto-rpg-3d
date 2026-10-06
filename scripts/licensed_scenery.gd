extends Node3D
## CC0 meshes instanced by surface: opaque materials, no extra gameplay collision.
const SOURCES: Dictionary = {
    "oak": preload("res://assets/vendor/kenney_nature/tree_oak.glb"),
    "pine": preload("res://assets/vendor/kenney_nature/tree_pineTallA_detailed.glb"),
    "canopy": preload("res://assets/vendor/kenney_nature/tree_detailed.glb"),
    "bush": preload("res://assets/vendor/kenney_nature/plant_bushDetailed.glb"),
    "rock": preload("res://assets/vendor/kenney_nature/rock_largeA.glb"),
    "boulder": preload("res://assets/vendor/kenney_nature/rock_largeC.glb")
}
const PROP_SOURCES: Dictionary = {
    "lantern": preload("res://assets/vendor/kenney_fantasy_town/lantern.glb"),
    "stall_red": preload("res://assets/vendor/kenney_fantasy_town/stall-red.glb"),
    "stall_bench": preload("res://assets/vendor/kenney_fantasy_town/stall-bench.glb"),
    "banner_red": preload("res://assets/vendor/kenney_fantasy_town/banner-red.glb"),
    "cart": preload("res://assets/vendor/kenney_fantasy_town/cart.glb"),
    "fence_gate": preload("res://assets/vendor/kenney_fantasy_town/fence-gate.glb")
}
static var mesh_cache: Dictionary = {}
var batches: Array[MultiMeshInstance3D] = []
var props: Array[Node3D] = []
var instance_total: int = 0

static func parts(id: String) -> Array[Dictionary]:
    if mesh_cache.has(id):
        return mesh_cache[id]
    var scene: Node3D = SOURCES[id].instantiate() as Node3D
    var result: Array[Dictionary] = []
    _collect(scene, Transform3D.IDENTITY, result)
    scene.free()
    mesh_cache[id] = result
    return result

static func _collect(node: Node, parent_transform: Transform3D, result: Array[Dictionary]) -> void:
    var transform: Transform3D = parent_transform
    if node is Node3D:
        transform = parent_transform * node.transform
    if node is MeshInstance3D:
        result.append({"mesh": node.mesh, "transform": transform})
    for child: Node in node.get_children():
        _collect(child, transform, result)

func scatter(id: String, points: Array[Vector3], height: float, cell_size: float = 24.0) -> void:
    if points.is_empty():
        return
    var source_parts: Array[Dictionary] = parts(id)
    var bounds: AABB = AABB()
    var first: bool = true
    for part: Dictionary in source_parts:
        var part_bounds: AABB = part.transform * part.mesh.get_aabb()
        bounds = part_bounds if first else bounds.merge(part_bounds)
        first = false
    var factor: float = height / maxf(bounds.size.y, 0.01)
    # Small spatial cells avoid one world-sized MultiMesh that can never cull.
    var cells: Dictionary = {}
    for point: Vector3 in points:
        var cell: Vector2i = Vector2i(floori(point.x / cell_size), floori(point.z / cell_size))
        if not cells.has(cell):
            cells[cell] = []
        cells[cell].append(point)
    for cell: Vector2i in cells:
        var origin: Vector3 = Vector3(float(cell.x) * cell_size, 0, float(cell.y) * cell_size)
        for part: Dictionary in source_parts:
            var mesh: MultiMesh = MultiMesh.new()
            mesh.transform_format = MultiMesh.TRANSFORM_3D
            mesh.mesh = part.mesh
            mesh.instance_count = cells[cell].size()
            for i: int in range(mesh.instance_count):
                var point: Vector3 = cells[cell][i]
                var variation: float = 0.9 + float(i % 3) * 0.1
                var basis: Basis = Basis(Vector3.UP, point.x * 0.17 + point.z * 0.31).scaled(Vector3.ONE * factor * variation)
                var grounding: Vector3 = Vector3(0, -bounds.position.y, 0)
                mesh.set_instance_transform(i, Transform3D(basis, point - origin) * Transform3D(Basis.IDENTITY, grounding) * part.transform)
            var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
            node.name = "%s_%d_%d_%d" % [id, cell.x, cell.y, batches.size()]
            node.multimesh = mesh
            node.position = origin
            node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            add_child(node)
            batches.append(node)
        instance_total += cells[cell].size()
    set_quality(1)

func place_prop(
    id: String,
    world_position: Vector3,
    yaw_degrees: float = 0.0,
    uniform_scale: float = 1.0,
    visibility_range: float = 72.0
) -> Node3D:
    var packed: PackedScene = PROP_SOURCES.get(id) as PackedScene
    if packed == null:
        push_warning("Unknown licensed scenery prop: " + id)
        return null

    var instance: Node3D = packed.instantiate() as Node3D
    if instance == null:
        push_warning("Licensed scenery prop has no Node3D root: " + id)
        return null

    instance.name = "Kenney_" + id + "_" + str(props.size())
    instance.position = world_position
    instance.rotation_degrees.y = yaw_degrees
    instance.scale = Vector3.ONE * uniform_scale
    instance.set_meta("base_visibility_range", visibility_range)
    _prepare_prop_meshes(instance, visibility_range)
    add_child(instance)
    props.append(instance)
    return instance


func _prepare_prop_meshes(node: Node, visibility_range: float) -> void:
    if node is MeshInstance3D:
        var mesh_instance: MeshInstance3D = node as MeshInstance3D
        mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        mesh_instance.visibility_range_end = visibility_range
        mesh_instance.visibility_range_end_margin = 4.0
    for child: Node in node.get_children():
        _prepare_prop_meshes(child, visibility_range)


func set_quality(level: int) -> void:
    var quality_index: int = clampi(level, 0, 2)
    for batch: MultiMeshInstance3D in batches:
        batch.visibility_range_end = [48.0, 78.0, 112.0][quality_index]
        batch.visibility_range_end_margin = 4.0
    var prop_range_factor: float = [0.65, 1.0, 1.28][quality_index]
    for prop: Node3D in props:
        var base_range: float = float(prop.get_meta("base_visibility_range", 72.0))
        _prepare_prop_meshes(prop, base_range * prop_range_factor)
