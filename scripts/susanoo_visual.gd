class_name SusanooVisual
extends Node3D

## Reusable mobile chakra avatar. Optional licensed GLB replaces authored proxy.
const MODEL_PATH: String = "res://assets/susanoo/susanoo_mobile.glb"
var sword_arm: Node3D
var shell: Node3D
var clock: float = 0.0
var quality_level: int = 1
var external_model: bool = false
var material: StandardMaterial3D
var imported_avatar: Node3D
var wings: Array[MeshInstance3D] = []
var slash_arc: MeshInstance3D
var appearance: float = 0.0

func _ready() -> void:
    material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = Color(0.55, 0.14, 1.0, 0.38)
    material.emission_enabled = true
    material.emission = Color(0.64, 0.20, 1.0)
    shell = Node3D.new()
    add_child(shell)
    if ResourceLoader.exists(MODEL_PATH):
        var scene: PackedScene = load(MODEL_PATH) as PackedScene
        if scene != null:
            imported_avatar = scene.instantiate() as Node3D
            shell.add_child(imported_avatar)
            # The prepared source uses centimeter-like units, Z-up before import.
            imported_avatar.scale = Vector3.ONE * 0.005
            imported_avatar.position.y = 0.32
            _style_import(imported_avatar)
            # A separate chakra blade swings with the combat animation while the
            # static downloaded armor remains a shell around the moving hero.
            sword_arm = Node3D.new()
            sword_arm.position = Vector3(-0.85, 1.8, 0.0)
            shell.add_child(sword_arm)
            _segment(sword_arm, Vector3.ZERO, Vector3(-0.15, -0.25, 2.2), 0.07)
            external_model = true
    if not external_model:
        _build_proxy()
    _build_slash_arc()
    visibility_changed.connect(func() -> void:
        if visible:
            appearance = 0.0)
    set_quality(quality_level)

func _build_slash_arc() -> void:
    var vertices: PackedVector3Array = PackedVector3Array()
    var normals: PackedVector3Array = PackedVector3Array()
    for step: int in range(16):
        var a: float = -1.1 + float(step) * 2.2 / 16.0
        var b: float = -1.1 + float(step + 1) * 2.2 / 16.0
        var outer_a: Vector3 = Vector3(sin(a), 0, cos(a)) * 2.65
        var outer_b: Vector3 = Vector3(sin(b), 0, cos(b)) * 2.65
        var inner_a: Vector3 = outer_a * 0.82
        var inner_b: Vector3 = outer_b * 0.82
        for vertex: Vector3 in [inner_a, outer_a, outer_b, inner_a, outer_b, inner_b]:
            vertices.append(vertex)
            normals.append(Vector3.UP)
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    var mesh: ArrayMesh = ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    slash_arc = MeshInstance3D.new()
    slash_arc.mesh = mesh
    slash_arc.position.y = 1.8
    var trail: StandardMaterial3D = material.duplicate() as StandardMaterial3D
    trail.cull_mode = BaseMaterial3D.CULL_DISABLED
    trail.albedo_color = Color(0.72, 0.40, 1.0, 0.65)
    slash_arc.material_override = trail
    slash_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    slash_arc.visible = false
    shell.add_child(slash_arc)

func _style_import(node: Node) -> void:
    if node is MeshInstance3D:
        var mesh: MeshInstance3D = node as MeshInstance3D
        mesh.material_override = material
        mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        # Broad wings are reserved for high quality to keep phone combat readable.
        if String(node.name) in ["Object_7", "Object_10"]:
            wings.append(mesh)
    for child: Node in node.get_children():
        _style_import(child)

func _build_proxy() -> void:
    # Original rib cage, skull, shoulders and sword; no extracted game geometry.
    for side: float in [-1.0, 1.0]:
        _segment(shell, Vector3(side * 0.18, 0.15, -0.24), Vector3(side * 0.50, 2.15, -0.24), 0.08)
        for row: int in range(5):
            var y: float = 0.30 + float(row) * 0.32
            var radius: float = 0.72 + float(row) * 0.04
            var last: Vector3 = Vector3(side * 0.18, y, -0.30)
            for step: int in range(1, 7):
                var angle: float = float(step) * PI / 6.0
                var point: Vector3 = Vector3(side * radius * sin(angle), y + sin(angle) * 0.06, -0.30 - radius * cos(angle))
                _segment(shell, last, point, 0.065)
                last = point
        _ball(shell, Vector3(side * 0.9, 2.12, -0.22), Vector3(0.52, 0.42, 0.52))
        _segment(shell, Vector3(side * 0.90, 2.05, -0.22), Vector3(side * 1.12, 1.25, -0.12), 0.17)
        _segment(shell, Vector3(side * 0.25, 2.92, -0.28), Vector3(side * 0.52, 3.45, -0.30), 0.055)
    _ball(shell, Vector3(0, 2.70, -0.27), Vector3(0.60, 0.72, 0.48))
    sword_arm = Node3D.new()
    sword_arm.position = Vector3(-0.9, 2.08, -0.22)
    shell.add_child(sword_arm)
    _segment(sword_arm, Vector3.ZERO, Vector3(-0.35, -0.55, 0.65), 0.17)
    _segment(sword_arm, Vector3(-0.35, -0.55, 0.65), Vector3(-0.35, -0.55, 2.45), 0.09)

func _ball(parent: Node3D, point: Vector3, size: Vector3) -> void:
    var mesh: SphereMesh = SphereMesh.new()
    mesh.radial_segments = 10
    mesh.rings = 5
    var instance: MeshInstance3D = _mesh(parent, mesh)
    instance.position = point
    instance.scale = size

func _segment(parent: Node3D, a: Vector3, b: Vector3, radius: float) -> void:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = radius * 0.7
    mesh.bottom_radius = radius
    mesh.height = a.distance_to(b)
    mesh.radial_segments = 6
    var instance: MeshInstance3D = _mesh(parent, mesh)
    instance.position = (a + b) * 0.5
    instance.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func _mesh(parent: Node3D, mesh: Mesh) -> MeshInstance3D:
    var instance: MeshInstance3D = MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = material
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(instance)
    return instance

func update_pose(delta: float, striking: bool, progress: float = 0.0) -> void:
    clock += delta
    appearance = minf(appearance + delta * 5.0, 1.0)
    shell.scale = Vector3.ONE * lerpf(0.55, 1.0 + sin(clock * 4.0) * 0.018, appearance)
    slash_arc.visible = quality_level > 0 and striking and progress > 0.18 and progress < 0.85
    if slash_arc.visible:
        slash_arc.rotation.y = lerpf(-0.70, 1.40, clampf(progress, 0.0, 1.0))
        slash_arc.scale = Vector3.ONE * (0.90 + progress * 0.16)
    if sword_arm != null:
        sword_arm.rotation.y = lerpf(-0.70, 1.40, clampf(progress, 0.0, 1.0)) if striking else sin(clock * 2.0) * 0.06

func set_quality(level: int) -> void:
    quality_level = clampi(level, 0, 2)
    for wing: MeshInstance3D in wings:
        wing.visible = quality_level == 2
    # Geometry is bounded and built once; no per-frame allocations/particles.
