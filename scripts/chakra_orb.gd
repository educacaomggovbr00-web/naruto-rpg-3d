extends MeshInstance3D
## Original VFX: opaque turbulent core, one additive shell, one instanced orbit draw.
## No screen textures, texture fetches, expensive noise, shadows or glow dependency.
var core_material: ShaderMaterial
var shell_material: ShaderMaterial
var shell: MeshInstance3D
var orbits: MultiMeshInstance3D
var clock: float = 0.0
var quality: int = 1

func _ready() -> void:
    var core: SphereMesh = SphereMesh.new()
    core.radius = 0.22
    core.height = 0.44
    core.radial_segments = 20
    core.rings = 10
    mesh = core
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    core_material = ShaderMaterial.new()
    core_material.shader = preload("res://assets/vfx/chakra_core.gdshader")
    material_override = core_material
    shell = MeshInstance3D.new()
    shell.mesh = core
    shell.scale = Vector3.ONE * 1.16
    shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    shell_material = ShaderMaterial.new()
    shell_material.shader = preload("res://assets/vfx/chakra_shell.gdshader")
    shell.material_override = shell_material
    add_child(shell)
    orbits = MultiMeshInstance3D.new()
    var batch: MultiMesh = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    var mote: SphereMesh = SphereMesh.new()
    mote.radius = 0.013
    mote.height = 0.026
    mote.radial_segments = 6
    mote.rings = 3
    var white: StandardMaterial3D = StandardMaterial3D.new()
    white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    white.albedo_color = Color(0.7, 0.93, 1.0)
    mote.material = white
    batch.mesh = mote
    batch.instance_count = 12
    batch.custom_aabb = AABB(Vector3.ONE * -0.4, Vector3.ONE * 0.8)
    orbits.multimesh = batch
    orbits.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(orbits)
    set_quality(1)

func set_quality(level: int) -> void:
    quality = clampi(level, 0, 2)
    if orbits != null:
        orbits.multimesh.visible_instance_count = [4, 8, 12][quality]
        shell.visible = quality > 0

func set_energy_color(color: Color) -> void:
    core_material.set_shader_parameter("energy_color", color)
    shell_material.set_shader_parameter("energy_color", color)

func _physics_process(delta: float) -> void:
    if not is_visible_in_tree():
        return
    clock += delta
    core_material.set_shader_parameter("phase", clock)
    shell_material.set_shader_parameter("phase", clock)
    shell.rotation = Vector3(clock * 1.4, clock * -2.1, clock * 0.8)
    for i: int in range(orbits.multimesh.visible_instance_count):
        var angle: float = clock * (4.0 + float(i % 3)) + float(i) * TAU / 12.0
        var tilt: float = float(i) * 2.4
        var point: Vector3 = Vector3(cos(angle), sin(angle) * sin(tilt), sin(angle) * cos(tilt)) * 0.29
        orbits.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, point))
