extends Node3D
## Licensed background villagers use their own skeleton/native Idle clip.
## This adapter never drives combat bones, hitboxes, CPU or the player rig.
const MALE: PackedScene = preload("res://assets/vendor/quaternius_ninjas/Ninja_Male.glb")
const FEMALE: PackedScene = preload("res://assets/vendor/quaternius_ninjas/Ninja_Female.glb")
static var material_cache: Dictionary = {}
static var bounds_cache: Dictionary = {}
var model_instance: Node3D
var animation_player: AnimationPlayer
var rig_loaded: bool = false

func _ready() -> void:
    var feminine: bool = posmod(get_parent().get_parent().name.hash(), 2) == 1
    model_instance = (FEMALE if feminine else MALE).instantiate() as Node3D
    add_child(model_instance)
    var meshes: Array[MeshInstance3D] = []
    _collect_mesh_instances(model_instance, meshes)
    _find_player(model_instance)
    if animation_player != null:
        for clip: String in animation_player.get_animation_list():
            if clip.ends_with("Idle"):
                animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
                animation_player.play(clip)
                animation_player.advance(0.0)
                break
    var bounds: AABB = AABB()
    var first: bool = true
    for mesh: MeshInstance3D in meshes:
        var local_bounds: AABB
        if bounds_cache.has(feminine):
            local_bounds = bounds_cache[feminine]
        else:
            local_bounds = posed_mesh_bounds(mesh)
        bounds = local_bounds if first else bounds.merge(local_bounds)
        first = false
        mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        for surface: int in range(mesh.mesh.get_surface_count()):
            var material: StandardMaterial3D = mesh.mesh.surface_get_material(surface) as StandardMaterial3D
            if material != null:
                var key: RID = material.get_rid()
                if not material_cache.has(key):
                    var toon: StandardMaterial3D = material.duplicate() as StandardMaterial3D
                    toon.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
                    toon.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
                    toon.roughness = 0.9
                    toon.albedo_color = toon.albedo_color.lightened(0.12)
                    # Source mesh units are centimeters below a scaled FBX root.
                    # A fixed object-space hull produces huge fragmented outlines.
                    toon.next_pass = null
                    material_cache[key] = toon
                mesh.set_surface_override_material(surface, material_cache[key])
    bounds_cache[feminine] = bounds
    var factor: float = 1.72 / maxf(bounds.size.y, 0.01)
    model_instance.scale = Vector3.ONE * factor
    model_instance.position.y = -bounds.position.y * factor
    rig_loaded = not meshes.is_empty() and animation_player != null

func set_active(enabled: bool) -> void:
    # World proximity updates pause native skeleton evaluation outside the budget.
    if animation_player != null:
        animation_player.active = enabled

func _find_player(node: Node) -> void:
    if node is AnimationPlayer:
        animation_player = node
    for child: Node in node.get_children():
        _find_player(child)

func _collect_mesh_instances(node: Node, output: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        output.append(node)
    for child: Node in node.get_children():
        _collect_mesh_instances(child, output)

func posed_mesh_bounds(mesh: MeshInstance3D) -> AABB:
    var model_inverse: Transform3D = model_instance.global_transform.affine_inverse()
    var skeleton: Skeleton3D = mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
    if mesh.skin == null or skeleton == null:
        return model_inverse * mesh.global_transform * mesh.get_aabb()
    skeleton.force_update_all_bone_transforms()
    var transforms: Array[Transform3D] = []
    for bind: int in range(mesh.skin.get_bind_count()):
        var bone: int = skeleton.find_bone(mesh.skin.get_bind_name(bind))
        if bone < 0:
            bone = mesh.skin.get_bind_bone(bind)
        transforms.append(skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind))
    var to_model: Transform3D = model_inverse * skeleton.global_transform
    var result: AABB = AABB()
    var first: bool = true
    for surface: int in range(mesh.mesh.get_surface_count()):
        var arrays: Array = mesh.mesh.surface_get_arrays(surface)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
        var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
        var influences: int = bones.size() / vertices.size()
        for vertex: int in range(vertices.size()):
            var position: Vector3 = Vector3.ZERO
            for influence: int in range(influences):
                var offset: int = vertex * influences + influence
                if weights[offset] > 0.0:
                    position += (transforms[bones[offset]] * vertices[vertex]) * weights[offset]
            position = to_model * position
            result = AABB(position, Vector3.ZERO) if first else result.expand(position)
            first = false
    return result
