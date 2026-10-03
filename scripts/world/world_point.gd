extends Area3D
var data: Dictionary = {}
var marker: Node3D
var actor: CharacterBody3D = null
var timer: float = 0.0

func _ready() -> void:
    collision_layer = 0
    collision_mask = 2
    monitoring = data.kind == "scroll"
    monitorable = false
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: SphereShape3D = SphereShape3D.new()
    shape.radius = 0.9
    collision.shape = shape
    add_child(collision)
    marker = Node3D.new()
    add_child(marker)
    if data.kind == "scroll":
        var mesh: CylinderMesh = CylinderMesh.new()
        mesh.top_radius = 0.13
        mesh.bottom_radius = 0.13
        mesh.height = 0.7
        mesh.radial_segments = 10
        var parchment: StandardMaterial3D = StandardMaterial3D.new()
        parchment.albedo_color = Color("f5dc9f")
        mesh.material = parchment
        var model: MeshInstance3D = MeshInstance3D.new()
        model.mesh = mesh
        model.rotation.z = PI * 0.5
        marker.add_child(model)
    else:
        actor = CharacterBody3D.new()
        actor.set_script(preload("res://scripts/world/world_actor.gd"))
        actor.collision_layer = 0
        actor.collision_mask = 0
        add_child(actor)
        actor.position.y = 0.0
        add_to_group("world_interactables")
    var label: Label3D = Label3D.new()
    label.position.y = 1.5 if data.kind != "scroll" else 0.7
    label.text = data.label
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = 26
    label.outline_size = 6
    label.visibility_range_end = 28.0
    add_child(label)
    _refresh()
    GameFlow.progress_changed.connect(_refresh)

func _refresh() -> void:
    if data.kind == "scroll":
        visible = not GameFlow.progress.collected.has(data.id)
        set_physics_process(visible)

func _physics_process(delta: float) -> void:
    if data.kind != "scroll":
        return
    marker.rotation.y += delta * 1.5
    timer -= delta
    if timer > 0.0:
        return
    timer = 0.12
    for body: Node3D in get_overlapping_bodies():
        if body.is_in_group("world_player") and GameFlow.collect_scroll(data.id, data.mission):
            get_parent().call("toast", "Pergaminho recolhido: " + String(data.label))
            break
