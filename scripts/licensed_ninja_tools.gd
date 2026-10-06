extends RefCounted
## Immutable shared imported meshes; projectile sweeps remain authoritative.
const SHURIKEN: Mesh = preload("res://assets/vendor/mehrasaur_weapons/shaken-juji.obj")
const KUNAI: Mesh = preload("res://assets/vendor/mehrasaur_weapons/kunai-gata-01.obj")
static var metal: StandardMaterial3D

static func create(mesh: Mesh, length: float, use_metal: bool = true) -> MeshInstance3D:
    if metal == null:
        metal = StandardMaterial3D.new()
        # Bright matte steel stays legible in the small mobile gameplay view;
        # metallic materials otherwise render almost black without reflections.
        metal.albedo_color = Color("e6f4ff")
        metal.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        metal.roughness = 0.4
    var node: MeshInstance3D = MeshInstance3D.new()
    node.mesh = mesh
    if use_metal:
        node.material_override = metal
    var bounds: AABB = mesh.get_aabb()
    var factor: float = length / maxf(maxf(bounds.size.x, bounds.size.y), bounds.size.z)
    node.scale = Vector3.ONE * factor
    node.position = -bounds.get_center() * factor
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return node
