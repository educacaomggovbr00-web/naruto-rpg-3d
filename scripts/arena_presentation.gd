extends "res://scripts/world/world_mesh_builder.gd"
## Original dojo courtyard, merged static vertex-color batches. Decorative
## geometry stays beyond existing combat boundaries; no extra fighter colliders.
var environment: WorldEnvironment
var ground_material: ShaderMaterial
var detail: Array[MeshInstance3D] = []
const ANIME: Script = preload("res://scripts/anime_presentation.gd")

func collider(center: Vector3, size: Vector3) -> void:
    var body: StaticBody3D = StaticBody3D.new()
    body.position = center
    body.collision_layer = 32
    body.collision_mask = 0
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = size
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    add_child(body)

func convex_collider(origin: Vector3, points: PackedVector3Array) -> void:
    var body: StaticBody3D = StaticBody3D.new()
    body.position = origin
    body.collision_layer = 32
    body.collision_mask = 0
    var shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
    shape.points = points
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    add_child(body)

func build() -> void:
    var dusk: bool = GameFlow.arena_id == "courtyard"
    environment = WorldEnvironment.new()
    environment.name = "ArenaEnvironment"
    environment.environment = ANIME.environment(dusk)
    add_child(environment)
    ground_material = ShaderMaterial.new()
    ground_material.shader = preload("res://assets/vfx/arena_ground.gdshader")
    ground_material.set_shader_parameter("courtyard", dusk)
    get_parent().get_node("Ground/Mesh").material_override = ground_material
    var sun: DirectionalLight3D = get_parent().get_node("Sun")
    ANIME.sun(sun, dusk)
    for side: Node in get_parent().get_node("ArenaWalls").get_children():
        side.get_node("Mesh").visible = false
    # Same physical boundary, enriched wall caps, buttresses and timber rails.
    for coordinate: float in [-29.5, 29.5]:
        box(Vector3(0, 1.6, coordinate), Vector3(60, 3.2, 0.5), plaster)
        box(Vector3(coordinate, 1.6, 0), Vector3(0.5, 3.2, 60), plaster)
        for height: float in [0.25, 2.8]:
            box(Vector3(0, height, coordinate), Vector3(60.1, 0.16, 0.65), timber)
            box(Vector3(coordinate, height, 0), Vector3(0.65, 0.16, 60.1), timber)
        box(Vector3(0, 3.25, coordinate), Vector3(60.5, 0.22, 1.1), tile)
        box(Vector3(coordinate, 3.25, 0), Vector3(1.1, 0.22, 60.5), tile)
        for post: float in [-27.0, -18.0, -9.0, 0.0, 9.0, 18.0, 27.0]:
            box(Vector3(post, 1.6, coordinate), Vector3(0.34, 3.35, 0.8), timber)
            box(Vector3(coordinate, 1.6, post), Vector3(0.8, 3.35, 0.34), timber)
    # Gate silhouette and two roofed training halls beyond playable bounds.
    for x: float in [-7.0, 7.0]:
        box(Vector3(x, 4, -32), Vector3(0.9, 8, 1), red)
    box(Vector3(0, 7.8, -32), Vector3(18, 0.8, 2), red)
    roof(Vector3(0, 8.2, -32), 20, 4, 1.3, tile)
    for x: float in [-22.0, 22.0]:
        box(Vector3(x, 3, -39), Vector3(17, 6, 10), plaster)
        roof(Vector3(x, 6, -39), 19, 12, 2.0, tile)
        for window: float in [-5.0, 0.0, 5.0]:
            box(Vector3(x + window, 3.5, -33.9), Vector3(3.4, 2.7, 0.12), dark)
            for slat: float in [-1.1, 0.0, 1.1]:
                box(Vector3(x + window + slat, 3.5, -33.8), Vector3(0.1, 2.7, 0.1), timber)
        box(Vector3(x, 5.7, -33.75), Vector3(17.6, 0.22, 0.25), timber)
    # Small tiled shop roofs rise over the rear wall and fill the central gap
    # between the larger halls; their lower floors remain outside combat space.
    for x: float in [-6.0, 6.0]:
        box(Vector3(x, 2.5, -48), Vector3(4.8, 5.0, 6.0), plaster)
        roof(Vector3(x, 5.0, -48), 5.8, 7.2, 1.5, tile)
        box(Vector3(x, 3.5, -44.9), Vector3(1.9, 2.8, 0.12), dark)
        box(Vector3(x, 5.0, -44.82), Vector3(4.2, 0.20, 0.24), timber)
        for frame_x: float in [-2.1, 2.1]:
            box(Vector3(x + frame_x, 3.3, -44.8), Vector3(0.18, 3.5, 0.24), red)
        for noren: float in [-1.0, 0.0, 1.0]:
            box(Vector3(x + noren, 4.6, -44.72), Vector3(0.9, 1.0, 0.16), Color("293f59"))
    # Additional torii crossbars and ridge ornaments reinforce the skyline.
    for y: float in [6.9, 8.9]:
        box(Vector3(0, y, -32), Vector3(20, 0.24, 2.15), timber)
    for x: float in [-22.0, 22.0]:
        box(Vector3(x, 8.2, -39), Vector3(18.8, 0.3, 1.2), red)
        for crest: float in [-7.0, -3.5, 0.0, 3.5, 7.0]:
            box(Vector3(x + crest, 8.42, -39), Vector3(0.16, 0.24, 1.0), Color("dac18d"))
    licensed_scenery = Node3D.new()
    licensed_scenery.name = "LicensedScenery"
    licensed_scenery.set_script(preload("res://scripts/licensed_scenery.gd"))
    add_child(licensed_scenery)
    var trees: Array[Vector3] = []
    var rocks: Array[Vector3] = []
    for i: int in range(18):
        var angle: float = TAU * float(i) / 18.0
        trees.append(Vector3(cos(angle), 0, sin(angle)) * (40.0 + float(i % 3) * 4.0))
        if i % 3 == 0:
            rocks.append(Vector3(cos(angle), 0, sin(angle)) * 34.0)
    licensed_scenery.scatter("pine", trees, 11.0)
    licensed_scenery.scatter("boulder", rocks, 1.8)

    # Visible CC0 street dressing around the combat ring. These stay outside
    # the playable core so they improve the shot without changing combat flow.
    for x: float in [-20.0, 20.0]:
        licensed_scenery.place("town_stall", Vector3(x, 0, -31.0), 3.0, 180.0, 72.0)
        licensed_scenery.place("town_lantern", Vector3(x * 0.72, 0, -27.0), 3.2, 180.0, 76.0)
        licensed_scenery.place("town_banner", Vector3(x * 0.55, 0, 29.5), 3.3, 0.0, 76.0)
    licensed_scenery.place("town_cart", Vector3(-24.0, 0, 24.5), 1.9, 35.0, 62.0)
    licensed_scenery.place("town_cart", Vector3(23.0, 0, 23.0), 1.8, -25.0, 62.0)
    licensed_scenery.place("town_bench", Vector3(-9.0, 0, 30.2), 1.0, 0.0, 58.0)
    licensed_scenery.place("town_bench", Vector3(9.0, 0, 30.2), 1.0, 180.0, 58.0)

    # Real CC0 Japanese architecture from Quaternius/KayKit. These replace the
    # generic gate silhouette as the dominant skyline while staying outside the
    # combat collider so gameplay remains unchanged.
    licensed_scenery.place_arch("torii", Vector3(0, 0, -31.2), 10.5, 0.0, 108.0)
    licensed_scenery.place_arch("temple", Vector3(-22.5, 0, -39.0), 10.0, 8.0, 122.0)
    licensed_scenery.place_arch("temple_small", Vector3(22.0, 0, -38.0), 8.0, -10.0, 116.0)
    licensed_scenery.place_arch("shrine", Vector3(0, 0, 34.0), 6.0, 180.0, 88.0)

    for x: float in [-14.0, 14.0]:
        var target: MeshInstance3D = preload("res://scripts/licensed_ninja_tools.gd").create(preload("res://assets/vendor/mehrasaur_weapons/aim-board.obj"), 1.8, false)
        target.rotation.x = PI * 0.5
        target.position += Vector3(x, 1.2, 30.5)
        target.visibility_range_end = 52.0
        add_child(target)
    var material: ShaderMaterial = preload("res://assets/world/anime_scenery.tres")
    for key: Vector2i in batches:
        var surface: SurfaceTool = batches[key]
        surface.set_material(material)
        var instance: MeshInstance3D = MeshInstance3D.new()
        instance.mesh = surface.commit()
        instance.position = Vector3((float(key.x) + 0.5) * SECTOR_SIZE, 0, (float(key.y) + 0.5) * SECTOR_SIZE)
        # Existing boundary walls provide collision. Geometry receives sun shadows
        # but does not fill the mobile shadow map with outside decorations.
        instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(instance)
        sectors.append(instance)
        if absf(instance.position.x) > 36.0 or absf(instance.position.z) > 36.0:
            detail.append(instance)
    batches.clear()

func set_quality(value: int) -> void:
    if licensed_scenery != null:
        licensed_scenery.set_quality(value)
    for instance: MeshInstance3D in detail:
        instance.visible = value > 0
    environment.environment.fog_enabled = value > 0
