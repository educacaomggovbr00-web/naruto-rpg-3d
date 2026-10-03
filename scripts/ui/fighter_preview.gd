extends SubViewportContainer
## One small shared viewport, two single-surface rigs. Disposed with selection.
var stage: Node3D
var fighters: Array[CharacterBody3D] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(0, 210)
    stretch = true
    stretch_shrink = 2
    var viewport: SubViewport = SubViewport.new()
    viewport.size = Vector2i(560, 210)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d = Viewport.MSAA_DISABLED
    add_child(viewport)
    stage = Node3D.new()
    viewport.add_child(stage)
    var environment: WorldEnvironment = WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color("152c42")
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color("aec5df")
    environment.environment.ambient_light_energy = 0.65
    stage.add_child(environment)
    var light: DirectionalLight3D = DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-35, -35, 0)
    light.light_energy = 1.2
    stage.add_child(light)
    var camera: Camera3D = Camera3D.new()
    camera.position = Vector3(0, 1.05, 5)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.1
    camera.keep_aspect = Camera3D.KEEP_HEIGHT
    stage.add_child(camera)
    show_fighters(CharacterCatalog.NARUTO, CharacterCatalog.NARUTO)

func show_fighters(player: CharacterDefinition, cpu: CharacterDefinition) -> void:
    for fighter: CharacterBody3D in fighters:
        stage.remove_child(fighter)
        fighter.queue_free()
    fighters.clear()
    for index: int in range(2):
        var actor: CharacterBody3D = CharacterBody3D.new()
        actor.set_script(preload("res://scripts/ui/fighter_preview_actor.gd"))
        actor.definition = player if index == 0 else cpu
        actor.position = Vector3(-0.9 if index == 0 else 0.9, 0.95, 0)
        actor.rotation.y = 0.12 if index == 0 else -0.12
        stage.add_child(actor)
        fighters.append(actor)
