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
    # Trees use original cylinder helper without its combat collider.
    for i: int in range(14):
        var angle: float = TAU * float(i) / 14.0
        var origin: Vector3 = Vector3(cos(angle), 0, sin(angle)) * (42.0 + float(i % 3) * 4.0)
        cylinder(origin + Vector3.UP * 3, 0.5, 6, timber, 7)
        cylinder(origin + Vector3.UP * 7, 3.6, 6, Color("527b54"), 10, 1.0)
        cylinder(origin + Vector3.UP * 9, 2.8, 5, Color("759655"), 10, 0.1)
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
    for instance: MeshInstance3D in detail:
        instance.visible = value > 0
    environment.environment.fog_enabled = value > 0
