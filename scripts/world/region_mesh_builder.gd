extends Node3D

var region_id: String = "forest"
var collision_count: int = 0
var draw_instances: int = 0

func _ready() -> void:
    region_id = GameFlow.world_region
    build(region_id)

func build(id: String) -> void:
    for child: Node in get_children():
        child.queue_free()
    collision_count = 0
    draw_instances = 0

    _ground(Color("6d9564"))
    match id:
        "river":
            _build_river()
        "valley":
            _build_valley()
        _:
            _build_forest()

func _material(color: Color) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 1.0
    return material

func _box_mesh_node(position: Vector3, size: Vector3, color: Color, collision: bool = false) -> MeshInstance3D:
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    mesh.material = _material(color)
    var node: MeshInstance3D = MeshInstance3D.new()
    node.mesh = mesh
    node.position = position
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(node)
    draw_instances += 1
    if collision:
        _box_collision(position, size)
    return node

func _box_collision(position: Vector3, size: Vector3) -> void:
    var body: StaticBody3D = StaticBody3D.new()
    body.collision_layer = 1
    body.collision_mask = 0
    body.position = position
    var shape_node: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = size
    shape_node.shape = shape
    body.add_child(shape_node)
    add_child(body)
    collision_count += 1

func _ground(color: Color) -> void:
    _box_mesh_node(Vector3(0, -0.25, 0), Vector3(92, 0.5, 92), color, true)

func _make_multimesh(mesh: PrimitiveMesh, transforms: Array[Transform3D], name: String) -> void:
    if transforms.is_empty():
        return
    var multimesh: MultiMesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = mesh
    multimesh.instance_count = transforms.size()
    for index: int in range(transforms.size()):
        multimesh.set_instance_transform(index, transforms[index])
    var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
    node.name = name
    node.multimesh = multimesh
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(node)
    draw_instances += 1

func _forest_multimesh(points: Array[Vector3]) -> void:
    var scenery: Node3D = Node3D.new()
    scenery.name = "LicensedForest"
    scenery.set_script(preload("res://scripts/licensed_scenery.gd"))
    add_child(scenery)
    scenery.scatter("canopy", points, 5.0, 48.0)
    for point: Vector3 in points:
        _box_collision(point + Vector3.UP * 1.25, Vector3(0.75, 2.5, 0.75))
    draw_instances += scenery.batches.size()

func _build_forest() -> void:
    var points: Array[Vector3] = []
    for x: int in range(-40, 41, 8):
        for z: int in range(-40, 41, 10):
            if absf(float(x)) < 8.0 and absf(float(z)) < 34.0:
                continue
            if (x + z) % 3 == 0:
                points.append(Vector3(float(x), 0, float(z)))
    _forest_multimesh(points)
    _box_mesh_node(Vector3(0, 0.03, 0), Vector3(9, 0.06, 76), Color("a28d67"))
    _box_mesh_node(Vector3(0, 1.2, -34), Vector3(12, 2.4, 1.0), Color("66503b"), true)
    _box_mesh_node(Vector3(-4.5, 3.4, -34), Vector3(1.0, 4.4, 1.0), Color("66503b"), true)
    _box_mesh_node(Vector3(4.5, 3.4, -34), Vector3(1.0, 4.4, 1.0), Color("66503b"), true)

func _build_river() -> void:
    _box_mesh_node(Vector3(0, 0.02, 0), Vector3(14, 0.04, 92), Color("4f8995"))
    _box_collision(Vector3(-8.0, 0.6, 0), Vector3(2.0, 1.2, 92))
    _box_collision(Vector3(8.0, 0.6, 0), Vector3(2.0, 1.2, 92))
    _box_mesh_node(Vector3(0, 0.75, 0), Vector3(18, 0.35, 6.0), Color("6d4d34"), true)
    _box_mesh_node(Vector3(0, 1.25, -2.8), Vector3(18, 0.15, 0.18), Color("403027"))
    _box_mesh_node(Vector3(0, 1.25, 2.8), Vector3(18, 0.15, 0.18), Color("403027"))
    var trees: Array[Vector3] = []
    for side: int in [-1, 1]:
        for z: int in range(-38, 39, 10):
            trees.append(Vector3(float(side) * 24.0, 0, float(z)))
            if z % 20 == 0:
                trees.append(Vector3(float(side) * 36.0, 0, float(z + 4)))
    _forest_multimesh(trees)
    for z: int in [-30, -15, 15, 30]:
        _box_mesh_node(Vector3(-15, 0.45, float(z)), Vector3(3.0, 0.9, 2.0), Color("77756e"), true)
        _box_mesh_node(Vector3(15, 0.35, float(z + 5)), Vector3(2.5, 0.7, 2.5), Color("6f716b"), true)

func _build_valley() -> void:
    _box_mesh_node(Vector3(0, 0.02, 0), Vector3(10, 0.04, 92), Color("4d7f91"))
    for side: int in [-1, 1]:
        var x: float = float(side) * 29.0
        _box_mesh_node(Vector3(x, 9.0, 0), Vector3(18, 18, 92), Color("736f64"), true)
        _box_mesh_node(Vector3(float(side) * 16.0, 1.5, -28), Vector3(8, 3, 8), Color("817b6e"), true)
        _box_mesh_node(Vector3(float(side) * 18.0, 2.5, 24), Vector3(10, 5, 10), Color("777268"), true)
    _box_mesh_node(Vector3(0, 0.8, 10), Vector3(18, 0.4, 5), Color("72604a"), true)
    _box_mesh_node(Vector3(0, 2.5, -34), Vector3(14, 5, 2.5), Color("665e55"), true)
    _box_mesh_node(Vector3(-4.0, 5.7, -34), Vector3(3.0, 6.5, 3.0), Color("787169"), true)
    _box_mesh_node(Vector3(4.0, 5.7, -34), Vector3(3.0, 6.5, 3.0), Color("787169"), true)

func set_quality(level: int) -> void:
    var visibility: float = [48.0, 66.0, 86.0][clampi(level, 0, 2)]
    for child: Node in get_children():
        if child.has_method("set_quality"):
            child.set_quality(level)
        if child is GeometryInstance3D:
            child.visibility_range_end = visibility
