extends SubViewportContainer
## Lightweight character-select stage: larger silhouettes, anime lighting, no gameplay systems.
var stage: Node3D
var fighters: Array[CharacterBody3D] = []
var technique_visual: Node3D
var technique_timer: float = 0.0
var preview_clip: String = "idle"

func preview_animation(clip: String) -> void:
    technique_timer = 0.0
    if technique_visual != null: technique_visual.visible = false
    preview_clip = clip
    if not fighters.is_empty():
        fighters[0].preview_animation(clip)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(0, 220)
    stretch = true
    stretch_shrink = 1

    var viewport: SubViewport = SubViewport.new()
    viewport.size = Vector2i(760, 255)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d = Viewport.MSAA_4X
    viewport.scaling_3d_scale = 1.0
    add_child(viewport)

    stage = Node3D.new()
    viewport.add_child(stage)

    var environment: WorldEnvironment = WorldEnvironment.new()
    environment.environment = preload("res://scripts/anime_presentation.gd").environment(true)
    environment.environment.fog_enabled = false
    stage.add_child(environment)

    var key: DirectionalLight3D = DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-38, -24, 0)
    preload("res://scripts/anime_presentation.gd").sun(key, true)
    key.shadow_enabled = false
    stage.add_child(key)

    var fill: DirectionalLight3D = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-18, 148, 0)
    fill.light_color = Color("6ea5cb")
    fill.light_energy = 0.30
    fill.shadow_enabled = false
    stage.add_child(fill)

    var back_mesh: PlaneMesh = PlaneMesh.new()
    back_mesh.size = Vector2(18.0, 4.5)
    var back_material: StandardMaterial3D = StandardMaterial3D.new()
    back_material.albedo_color = Color("0a1d2b")
    back_material.roughness = 1.0
    back_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    back_mesh.material = back_material
    var backdrop: MeshInstance3D = MeshInstance3D.new()
    backdrop.mesh = back_mesh
    backdrop.position = Vector3(0, 1.55, -1.25)
    backdrop.rotation_degrees.x = 90.0
    stage.add_child(backdrop)

    var floor_mesh: PlaneMesh = PlaneMesh.new()
    floor_mesh.size = Vector2(8.0, 4.2)
    var floor_material: StandardMaterial3D = StandardMaterial3D.new()
    floor_material.albedo_color = Color("102a37")
    floor_material.roughness = 1.0
    floor_mesh.material = floor_material
    var floor: MeshInstance3D = MeshInstance3D.new()
    floor.mesh = floor_mesh
    stage.add_child(floor)

    for x: float in [-0.92, 0.92]:
        var disc_mesh: CylinderMesh = CylinderMesh.new()
        disc_mesh.top_radius = 0.72
        disc_mesh.bottom_radius = 0.78
        disc_mesh.height = 0.045
        disc_mesh.radial_segments = 24
        var disc_material: StandardMaterial3D = StandardMaterial3D.new()
        disc_material.albedo_color = Color("1d4d61")
        disc_material.emission_enabled = true
        disc_material.emission = Color("12384a")
        disc_material.emission_energy_multiplier = 0.55
        disc_mesh.material = disc_material
        var disc: MeshInstance3D = MeshInstance3D.new()
        disc.mesh = disc_mesh
        disc.position = Vector3(x, 0.025, 0)
        stage.add_child(disc)

    var camera: Camera3D = Camera3D.new()
    camera.position = Vector3(0, .94, 5.0)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.3
    camera.keep_aspect = Camera3D.KEEP_HEIGHT
    stage.add_child(camera)

    technique_visual = Node3D.new()
    technique_visual.set_script(preload("res://scripts/elemental_jutsu_visual.gd"))
    stage.add_child(technique_visual)
    show_fighters(CharacterCatalog.HENRIQUE, CharacterCatalog.NARUTO)

func show_fighters(player: CharacterDefinition, cpu: CharacterDefinition) -> void:
    for fighter: CharacterBody3D in fighters:
        if is_instance_valid(fighter):
            stage.remove_child(fighter)
            fighter.queue_free()
    fighters.clear()
    if technique_visual != null:
        technique_visual.visible = false
    technique_timer = 0.0

    for index: int in range(2):
        var actor: CharacterBody3D = CharacterBody3D.new()
        actor.set_script(preload("res://scripts/ui/fighter_preview_actor.gd"))
        actor.definition = player if index == 0 else cpu
        actor.position = Vector3(-0.92 if index == 0 else 0.92, 0.95, 0)
        actor.rotation.y = 0.14 if index == 0 else -0.14
        actor.scale = Vector3.ONE * 1.08
        stage.add_child(actor)
        fighters.append(actor)
        if index == 0:
            actor.preview_animation(preview_clip)

func preview_technique(id: String) -> void:
    if fighters.is_empty(): return
    var data: JutsuDefinition = fighters[0].definition.find_jutsu(id)
    if data == null: return
    fighters[0].preview_animation(data.animation_name)
    technique_timer = 1.0
    technique_visual.visible = false
    if data.strategy not in ["clones","barrage","trap"]:
        technique_visual.position = Vector3(-.92,1.0,.45)
        technique_visual.heading = Vector3.RIGHT
        technique_visual.configure(data.effect,.26,data.strategy == "burst","wave" if id == "henrique_katon_wave" else "orb")

func _physics_process(delta: float) -> void:
    if technique_timer <= 0.0: return
    technique_timer -= delta
    if technique_timer <= 0.0:
        technique_visual.visible = false
        fighters[0].preview_animation("idle")
