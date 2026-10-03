extends MultiMeshInstance3D
## Original opaque electrical forks: 16 segments in a single draw, no particles.
var clock: float = 0.0
func _ready() -> void:
    var batch: MultiMesh = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    var segment: CylinderMesh = CylinderMesh.new()
    segment.top_radius = 0.008
    segment.bottom_radius = 0.013
    segment.height = 1.0
    segment.radial_segments = 4
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color(0.65, 0.86, 1.0)
    segment.material = material
    batch.mesh = segment
    batch.instance_count = 16
    batch.custom_aabb = AABB(Vector3.ONE * -0.75, Vector3.ONE * 1.5)
    multimesh = batch
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    visible = false

func _physics_process(delta: float) -> void:
    if not is_visible_in_tree():
        return
    clock += delta
    for branch: int in range(8):
        var angle: float = float(branch) * TAU / 8.0 + clock * 3.0
        var direction: Vector3 = Vector3(cos(angle), sin(angle * 2.3 + clock * 19.0) * 0.6, sin(angle)).normalized()
        var bend: Vector3 = direction * (0.22 + sin(clock * 23.0 + branch) * 0.05)
        var tip: Vector3 = direction * 0.55 + Vector3.UP * sin(clock * 31.0 + branch) * 0.1
        _segment(branch * 2, Vector3.ZERO, bend)
        _segment(branch * 2 + 1, bend, tip)

func _segment(index: int, start: Vector3, finish: Vector3) -> void:
    var axis: Vector3 = finish - start
    var rotation_basis: Basis = Basis(Quaternion(Vector3.UP, axis.normalized()))
    multimesh.set_instance_transform(index, Transform3D(rotation_basis.scaled(Vector3(1, axis.length(), 1)), (start + finish) * 0.5))
