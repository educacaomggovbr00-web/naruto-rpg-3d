extends StaticBody3D
var health: float = 18.0
var broken: bool = false
var mesh: MeshInstance3D
var debris: MultiMeshInstance3D
var debris_time: float = 0.0

func _ready() -> void:
    collision_layer = 1
    collision_mask = 0
    var box: BoxShape3D = BoxShape3D.new()
    box.size = Vector3(1.15, 1.5, 1.15)
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = box
    add_child(collision)
    mesh = MeshInstance3D.new()
    var visual: BoxMesh = BoxMesh.new()
    visual.size = box.size
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color("70503a")
    visual.material = material
    mesh.mesh = visual
    add_child(mesh)
    debris = MultiMeshInstance3D.new()
    var batch: MultiMesh = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.instance_count = 6
    batch.visible_instance_count = 0
    var fragment: BoxMesh = BoxMesh.new()
    fragment.size = Vector3(.18, .24, .12)
    fragment.material = material
    batch.mesh = fragment
    debris.multimesh = batch
    debris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(debris)

func receive_scenery_hit(damage: float) -> void:
    if broken or damage <= 0.0:
        return
    health = maxf(0.0, health - damage)
    if health <= 0.0:
        broken = true
        set_deferred("collision_layer", 0)
        mesh.visible = false
        debris_time = .9
        debris.multimesh.visible_instance_count = 6

func _physics_process(delta: float) -> void:
    if debris_time <= 0.0:
        return
    debris_time = maxf(0.0, debris_time - delta)
    var t: float = .9 - debris_time
    for index: int in range(6):
        var angle: float = index * TAU / 6.0
        var position: Vector3 = Vector3(cos(angle) * t * 2.0, maxf(-.65, .4 + t * 1.8 - t * t * 5.0), sin(angle) * t * 2.0)
        debris.multimesh.set_instance_transform(index, Transform3D(Basis(Vector3.UP, angle + t * 5.0), position))
    if debris_time <= 0.0:
        debris.multimesh.visible_instance_count = 0
