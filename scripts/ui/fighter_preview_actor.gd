extends CharacterBody3D
## Menu-only visual actor. No combat modules, pools, collisions or input.
var definition: CharacterDefinition
var locked_target: Node3D = null
var guard_meter: float = 100.0
var rig_adapter: Node3D
var static_preview: Node3D = null
const LOCAL_NARUTO_PREVIEW: String = "res://external/character_assets/naruto_sketchfab.glb"

func _ready() -> void:
    collision_layer = 0
    collision_mask = 0
    var hitbox: Area3D = Area3D.new()
    hitbox.name = "AttackHitbox"
    hitbox.monitoring = false
    hitbox.collision_layer = 0
    hitbox.collision_mask = 0
    add_child(hitbox)
    if definition != null and definition.character_id == "naruto" and ResourceLoader.exists(LOCAL_NARUTO_PREVIEW):
        _load_static_preview(LOCAL_NARUTO_PREVIEW)
        return
    rig_adapter = Node3D.new()
    rig_adapter.name = "RiggedCharacterAdapter"
    rig_adapter.set_script(preload("res://scripts/rigged_character_adapter.gd"))
    rig_adapter.follow_hitbox_to_bones = false
    add_child(rig_adapter)

func _load_static_preview(path: String) -> void:
    var packed: PackedScene = ResourceLoader.load(path) as PackedScene
    if packed == null:
        return
    static_preview = packed.instantiate() as Node3D
    if static_preview == null:
        return
    add_child(static_preview)
    static_preview.rotation_degrees.y = 180.0
    var bounds: AABB = _visual_bounds(static_preview)
    if bounds.size.y > 0.001:
        var factor: float = 1.75 / bounds.size.y
        static_preview.scale = Vector3.ONE * factor
        static_preview.position.y = -bounds.position.y * factor

func _visual_bounds(root: Node3D) -> AABB:
    var meshes: Array[MeshInstance3D] = []
    _collect_meshes(root, meshes)
    var first: bool = true
    var combined: AABB = AABB()
    var inv: Transform3D = root.global_transform.affine_inverse()
    for mesh: MeshInstance3D in meshes:
        if mesh.mesh == null:
            continue
        var box: AABB = mesh.get_aabb()
        var local_transform: Transform3D = inv * mesh.global_transform
        var transformed: AABB = local_transform * box
        combined = transformed if first else combined.merge(transformed)
        first = false
    return combined

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        output.append(node as MeshInstance3D)
    for child: Node in node.get_children():
        _collect_meshes(child, output)

func get_character_definition() -> CharacterDefinition:
    return definition

func get_animation_state() -> String:
    return "idle"

func get_animation_action_id() -> int:
    return 0

func get_combo_step() -> int:
    return 1
