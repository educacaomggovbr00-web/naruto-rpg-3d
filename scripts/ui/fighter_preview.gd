extends SubViewportContainer
## One lightweight shared viewport, used only by the selection screen.
var stage: Node3D
var fighters: Array[CharacterBody3D] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(0, 250)
    stretch = true
    stretch_shrink = 2

    var viewport: SubViewport = SubViewport.new()
    viewport.size = Vector2i(640, 250)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d = Viewport.MSAA_DISABLED
    viewport.scaling_3d_scale = 0.85
    add_child(viewport)

    stage = Node3D.new()
    viewport.add_child(stage)

    var environment: WorldEnvironment = WorldEnvironment.new()
    environment.environment = preload("res://scripts/anime_presentation.gd").environment(true)
    environment.environment.fog_enabled = false
    stage.add_child(environment)

    var key: DirectionalLight3D = DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-35, -28, 0)
    preload("res://scripts/anime_presentation.gd").sun(key, true)
    key.shadow_enabled = false
    stage.add_child(key)

    var floor_mesh: PlaneMesh = PlaneMesh.new()
    floor_mesh.size = Vector2(8.0, 3.8)
    var floor_material: StandardMaterial3D = StandardMaterial3D.new()
    floor_material.albedo_color = Color("10283a")
    floor_material.roughness = 1.0
    floor_mesh.material = floor_material
    var floor: MeshInstance3D = MeshInstance3D.new()
    floor.mesh = floor_mesh
    floor.position.y = 0.0
    stage.add_child(floor)

    for x: float in [-1.15, 1.15]:
        var disc_mesh: CylinderMesh = CylinderMesh.new()
        disc_mesh.top_radius = 0.62
        disc_mesh.bottom_radius = 0.68
        disc_mesh.height = 0.035
        disc_mesh.radial_segments = 24
        var disc_material: StandardMaterial3D = StandardMaterial3D.new()
        disc_material.albedo_color = Color("25465b")
        disc_material.emission_enabled = true
        disc_material.emission = Color("163449")
        disc_material.emission_energy_multiplier = 0.45
        disc_mesh.material = disc_material
        var disc: MeshInstance3D = MeshInstance3D.new()
        disc.mesh = disc_mesh
        disc.position = Vector3(x, 0.02, 0)
        stage.add_child(disc)

    var camera: Camera3D = Camera3D.new()
    camera.position = Vector3(0, 1.05, 5)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.18
    camera.keep_aspect = Camera3D.KEEP_HEIGHT
    stage.add_child(camera)

    show_fighters(CharacterCatalog.NARUTO, CharacterCatalog.NARUTO)

func show_fighters(player: CharacterDefinition, cpu: CharacterDefinition) -> void:
    for fighter: CharacterBody3D in fighters:
        if is_instance_valid(fighter):
            stage.remove_child(fighter)
            fighter.queue_free()
    fighters.clear()

    for index: int in range(2):
        var actor: CharacterBody3D = CharacterBody3D.new()
        actor.set_script(preload("res://scripts/ui/fighter_preview_actor.gd"))
        actor.definition = player if index == 0 else cpu
        actor.position = Vector3(-1.15 if index == 0 else 1.15, 0.95, 0)
        actor.rotation.y = 0.20 if index == 0 else -0.20
        stage.add_child(actor)
        fighters.append(actor)
