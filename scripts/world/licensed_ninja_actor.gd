extends Node3D
## Licensed background villagers use their own skeleton/native Idle clip.
## This adapter never drives combat bones, hitboxes, CPU or the player rig.
const MALE: PackedScene = preload("res://assets/vendor/quaternius_ninjas/Ninja_Male.glb")
const FEMALE: PackedScene = preload("res://assets/vendor/quaternius_ninjas/Ninja_Female.glb")
var model_instance: Node3D
var animation_player: AnimationPlayer
var rig_loaded: bool = false

func _ready() -> void:
    var feminine: bool = posmod(get_parent().get_parent().name.hash(), 2) == 1
    model_instance = (FEMALE if feminine else MALE).instantiate() as Node3D
    add_child(model_instance)
    var meshes: Array[MeshInstance3D] = []
    _collect_mesh_instances(model_instance, meshes)
    var bounds: AABB = AABB()
    var first: bool = true
    for mesh: MeshInstance3D in meshes:
        var transform: Transform3D = model_instance.global_transform.affine_inverse() * mesh.global_transform
        var local_bounds: AABB = transform * mesh.get_aabb()
        bounds = local_bounds if first else bounds.merge(local_bounds)
        first = false
        mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        for surface: int in range(mesh.mesh.get_surface_count()):
            var material: StandardMaterial3D = mesh.mesh.surface_get_material(surface) as StandardMaterial3D
            if material != null:
                mesh.set_surface_override_material(surface, preload("res://scripts/anime_presentation.gd").textured(material))
    var factor: float = 1.72 / maxf(bounds.size.y, 0.01)
    model_instance.scale = Vector3.ONE * factor
    model_instance.position.y = -bounds.position.y * factor
    _find_player(model_instance)
    if animation_player != null:
        for clip: String in animation_player.get_animation_list():
            if clip.ends_with("Idle"):
                animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
                animation_player.play(clip)
                break
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
