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
static var mesh_cache: Dictionary = {}
var batches: Array[MultiMeshInstance3D] = []
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

func set_quality(level: int) -> void:
    for batch: MultiMeshInstance3D in batches:
        batch.visibility_range_end = [48.0, 78.0, 112.0][clampi(level, 0, 2)]
        batch.visibility_range_end_margin = 4.0
