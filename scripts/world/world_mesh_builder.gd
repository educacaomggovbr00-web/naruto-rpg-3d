extends Node3D
## Original village meshes, merged by sector. No Storm mesh/texture is imported.
const SECTOR_SIZE: float = 24.0
var batches: Dictionary = {}
var sectors: Array[MeshInstance3D] = []
var triangles: int = 0
var footprints: Array[Dictionary] = []
var collision_count: int = 0
var plaster: Color = Color("e9d5a6")
var timber: Color = Color("624736")
var tile: Color = Color("598c93")
var red: Color = Color("b7513f")
var dark: Color = Color("344b52")

func _ready() -> void:
    build()

func _batch(center: Vector3) -> SurfaceTool:
    var key: Vector2i = Vector2i(floori(center.x / SECTOR_SIZE), floori(center.z / SECTOR_SIZE))
    if not batches.has(key):
        var surface: SurfaceTool = SurfaceTool.new()
        surface.begin(Mesh.PRIMITIVE_TRIANGLES)
        batches[key] = surface
    return batches[key] as SurfaceTool

func triangle(center: Vector3, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
    var surface: SurfaceTool = _batch(center)
    var normal: Vector3 = (c - a).cross(b - a).normalized()
    for vertex: Vector3 in [a, c, b]:
        surface.set_color(color)
        surface.set_normal(normal)
        var key: Vector2i = Vector2i(floori(center.x / SECTOR_SIZE), floori(center.z / SECTOR_SIZE))
        surface.add_vertex(vertex - Vector3((float(key.x) + 0.5) * SECTOR_SIZE, 0, (float(key.y) + 0.5) * SECTOR_SIZE))
    triangles += 1

func quad(center: Vector3, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
    triangle(center, a, b, c, color)
    triangle(center, a, c, d, color)

func box(center: Vector3, size: Vector3, color: Color, solid: bool = false) -> void:
    var h: Vector3 = size * 0.5
    var corners: Array[Vector3] = []
    for z: int in [-1, 1]:
        for y: int in [-1, 1]:
            for x: int in [-1, 1]:
                corners.append(center + Vector3(float(x) * h.x, float(y) * h.y, float(z) * h.z))
    for face: Array in [[0, 1, 3, 2], [5, 4, 6, 7], [4, 0, 2, 6], [1, 5, 7, 3], [2, 3, 7, 6], [4, 5, 1, 0]]:
        quad(center, corners[face[0]], corners[face[1]], corners[face[2]], corners[face[3]], color)
    if solid:
        collider(center, size)

func collider(center: Vector3, size: Vector3) -> void:
    var body: StaticBody3D = StaticBody3D.new()
    body.position = center
    body.collision_layer = 1
    body.collision_mask = 0
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    collision_count += 1

func convex_collider(origin: Vector3, points: PackedVector3Array) -> void:
    var body: StaticBody3D = StaticBody3D.new()
    body.position = origin
    body.collision_layer = 1
    body.collision_mask = 0
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
    shape.points = points
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    collision_count += 1

func cylinder(center: Vector3, radius: float, height: float, color: Color, segments: int = 16, top_radius: float = -1.0) -> void:
    var upper_radius: float = radius if top_radius < 0.0 else top_radius
    var low: Vector3 = center - Vector3.UP * height * 0.5
    var high: Vector3 = center + Vector3.UP * height * 0.5
    for i: int in range(segments):
        var angle: float = TAU * float(i) / float(segments)
        var next: float = TAU * float(i + 1) / float(segments)
        var v: Vector3 = Vector3(cos(angle), 0, sin(angle))
        var w: Vector3 = Vector3(cos(next), 0, sin(next))
        quad(center, low + v * radius, low + w * radius, high + w * upper_radius, high + v * upper_radius, color)
        triangle(center, high, high + v * upper_radius, high + w * upper_radius, color.lightened(0.06))
        triangle(center, low, low + w * radius, low + v * radius, color.darkened(0.1))

func roof(origin: Vector3, width: float, depth: float, height: float, color: Color) -> void:
    # A walkable ridge terrace with four sloped eaves and tile ribs.
    var outer: Vector2 = Vector2(width, depth) * 0.58
    var inner: Vector2 = Vector2(width, depth) * 0.40
    var lower: Array[Vector3] = [Vector3(-outer.x, 0, -outer.y), Vector3(outer.x, 0, -outer.y), Vector3(outer.x, 0, outer.y), Vector3(-outer.x, 0, outer.y)]
    var upper: Array[Vector3] = [Vector3(-inner.x, height, -inner.y), Vector3(inner.x, height, -inner.y), Vector3(inner.x, height, inner.y), Vector3(-inner.x, height, inner.y)]
    var slope_points: PackedVector3Array = PackedVector3Array(lower)
    slope_points.append_array(PackedVector3Array(upper))
    convex_collider(origin, slope_points)
    for i: int in range(4):
        var j: int = (i + 1) % 4
        quad(origin, origin + lower[i], origin + lower[j], origin + upper[j], origin + upper[i], color)
        var ribs: int = maxi(4, int(lower[i].distance_to(lower[j]) / 0.7))
        for rib: int in range(ribs + 1):
            var t: float = float(rib) / float(ribs)
            var a: Vector3 = origin + lower[i].lerp(lower[j], t) + Vector3.UP * 0.025
            var b: Vector3 = origin + upper[i].lerp(upper[j], t) + Vector3.UP * 0.025
            var side: Vector3 = (lower[j] - lower[i]).normalized() * 0.035
            quad(origin, a - side, a + side, b + side, b - side, color.lightened(0.13))
    box(origin + Vector3.UP * (height - 0.06), Vector3(inner.x * 2, 0.12, inner.y * 2), color, true)

func building(origin: Vector3, width: float, depth: float, height: float, tint: Color, roof_tint: Color) -> void:
    footprints.append({"center": origin, "size": Vector3(width, 0, depth), "color": roof_tint})
    box(origin + Vector3.UP * height * 0.5, Vector3(width, height, depth), tint, true)
    box(origin + Vector3.UP * 0.25, Vector3(width + 0.1, 0.5, depth + 0.1), Color("947860"))
    roof(origin + Vector3.UP * height, width, depth, 0.65, roof_tint)
    # Inset shutters, floor rails, lintels and timber columns define facades.
    for front: int in [-1, 1]:
        var z: float = origin.z + float(front) * (depth * 0.5 + 0.035)
        for level: int in range(maxi(1, floori(height / 2.5))):
            var y: float = origin.y + 1.8 + float(level) * 2.3
            box(Vector3(origin.x, y + 0.62, z), Vector3(width + 0.12, 0.12, 0.10), timber)
            for window: int in range(maxi(1, floori(width / 2.1))):
                var x: float = origin.x - width * 0.5 + 1.1 + float(window) * 2.1
                box(Vector3(x, y, z), Vector3(1.3, 1.05, 0.08), timber)
                box(Vector3(x, y, z + float(front) * 0.055), Vector3(1.1, 0.87, 0.08), Color("8aafb0"))
                box(Vector3(x, y, z + float(front) * 0.11), Vector3(0.06, 1.0, 0.05), timber)
        for x: float in [-width * 0.5 + 0.2, width * 0.5 - 0.2]:
            box(Vector3(origin.x + x, origin.y + height * 0.5, z), Vector3(0.18, height, 0.16), timber)
    box(origin + Vector3(0, 1.0, depth * 0.5 + 0.09), Vector3(1.4, 2.0, 0.18), timber)
    box(origin + Vector3(0.45, 1.0, depth * 0.5 + 0.20), Vector3(0.10, 0.10, 0.06), Color("d7b566"))

func stairs(origin: Vector3, width: float, height: float, length: float) -> void:
    var count: int = ceili(height / 0.28)
    for i: int in range(count):
        var step_height: float = height * float(i + 1) / float(count)
        var z: float = origin.z - length * float(i + 0.5) / float(count)
        box(Vector3(origin.x, origin.y + step_height * 0.5, z), Vector3(width, step_height, length / float(count) + 0.02), Color("c9b997"))
    # One continuous ramp under visible treads prevents CharacterBody riser stalls.
    convex_collider(origin, PackedVector3Array([
        Vector3(-width * 0.5, 0, 0), Vector3(width * 0.5, 0, 0),
        Vector3(-width * 0.5, 0, -length), Vector3(width * 0.5, 0, -length),
        Vector3(-width * 0.5, height, -length), Vector3(width * 0.5, height, -length)
    ]))

func tree(origin: Vector3, radius: float = 2.2) -> void:
    cylinder(origin + Vector3.UP * 1.4, 0.24, 2.8, timber, 7)
    cylinder(origin + Vector3.UP * 3.2, radius, 2.7, Color("609b64"), 9, radius * 0.38)
    cylinder(origin + Vector3.UP * 4.0, radius * 0.8, 2.2, Color("91be72"), 9, radius * 0.20)
    collider(origin + Vector3.UP * 1.1, Vector3(0.4, 2.2, 0.4))

func signpost(origin: Vector3, title: String) -> void:
    var label: Label3D = Label3D.new()
    label.position = origin
    label.text = title
    label.font_size = 44
    label.pixel_size = 0.013
    label.modulate = Color("ffe4ad")
    label.outline_modulate = Color("402d20")
    label.outline_size = 8
    label.no_depth_test = false
    add_child(label)

func build() -> void:
    collider(Vector3(0, -0.3, 0), Vector3(156, 0.6, 132))
    for x: int in range(-78, 78, 24):
        for z: int in range(-66, 66, 24):
            var width: float = minf(24, 78 - x)
            var depth: float = minf(24, 66 - z)
            box(Vector3(float(x) + width * 0.5, -0.3, float(z) + depth * 0.5), Vector3(width, 0.6, depth), Color("8db876"))
    box(Vector3(0, 0.015, 0), Vector3(11, 0.03, 112), Color("cbb993"))
    box(Vector3(-10, 0.02, 5), Vector3(32, 0.04, 20), Color("d9c9a7"))
    for z: float in [-29.0, -10.0, 22.0, 40.0]:
        box(Vector3(-4, 0.02, z), Vector3(124, 0.04, 6), Color("cbb993"))
    # Raised banks keep traversal safe; water is opaque to avoid mobile overdraw.
    box(Vector3(34, -0.04, 0), Vector3(6, 0.06, 112), Color("65a5a6"))
    for x: float in [30.8, 37.2]:
        box(Vector3(x, 0.3, 0), Vector3(0.6, 0.6, 112), Color("a69375"), true)
    for z: float in [-10.0, 22.0]:
        box(Vector3(34, 0.72, z), Vector3(10, 0.24, 5.0), timber, true)
        for x: float in [29.5, 38.5]:
            stairs(Vector3(x, 0, z + 2.5), 1.6, 0.84, 4.0)
        for side: float in [-2.4, 2.4]:
            box(Vector3(34, 1.2, z + side), Vector3(9.5, 0.12, 0.12), timber)
    var palette: Array[Color] = [plaster, Color("ddc4a8"), Color("e0d4b8"), Color("e3ba91")]
    var number: int = 0
    for x: float in [-55.0, -41.0, -25.0, 18.0, 48.0, 62.0]:
        for z: float in [-20.0, 0.0, 31.0]:
            if (x == -25.0 and z == 0.0) or (x == 18.0 and z == 0.0):
                continue
            var tall: float = 3.2 if x == -25.0 and z == 31.0 else 3.2 + float(number % 3) * 1.4
            building(Vector3(x, 0, z), 8.0, 8.0, tall, palette[number % palette.size()], tile if number % 2 == 0 else red)
            number += 1
    # A connected staircase and roof walkway make verticality reachable by touch.
    stairs(Vector3(-31, 0, 48), 2.0, 3.85, 12.0)
    box(Vector3(-29, 3.72, 34.3), Vector3(8, 0.26, 3), timber, true)
    box(Vector3(-25, 3.72, 9), Vector3(2.2, 0.26, 20), timber, true)
    building(Vector3(-21, 0, -41), 17, 12, 6, plaster, red)
    signpost(Vector3(-21, 3.5, -34.85), "ACADEMIA")
    stairs(Vector3(-33, 0, -23), 2.0, 6.65, 18.0)
    box(Vector3(-30.5, 6.52, -42.7), Vector3(7, 0.26, 3), timber, true)
    # Original cylindrical administrative landmark and carved cliff silhouettes.
    cylinder(Vector3(0, 5, -46), 8, 10, Color("c06b53"), 24)
    collider(Vector3(0, 5, -46), Vector3(13, 10, 13))
    cylinder(Vector3(0, 10.3, -46), 9.2, 1.0, Color("58796d"), 24, 6.7)
    collider(Vector3(0, 10.85, -46), Vector3(12, 0.15, 12))
    signpost(Vector3(0, 6.5, -37.9), "TORRE DA FOLHA")
    box(Vector3(0, 12, -63), Vector3(150, 24, 7), Color("ad9a7b"), true)
    for i: int in range(4):
        var x: float = -21.0 + float(i) * 14.0
        cylinder(Vector3(x, 17, -58.8), 3.6, 5.8, Color("c2b293"), 12, 3.0)
        box(Vector3(x, 16.8, -55.1), Vector3(0.8, 1.8, 1.0), Color("b4a184"))
        for eye: float in [-1.2, 1.2]:
            box(Vector3(x + eye, 18.1, -55.2), Vector3(1.0, 0.20, 0.25), Color("827561"))
    # Ramen counter: stools, cloth segments and bowls are original opaque geometry.
    building(Vector3(-16, 0, 13), 9, 7, 3.4, plaster, red)
    box(Vector3(-16, 1.1, 17.2), Vector3(8, 0.2, 1.0), timber, true)
    for i: int in range(4):
        var x: float = -19.0 + float(i) * 2.0
        cylinder(Vector3(x, 0.65, 18.5), 0.34, 0.18, red, 8)
        cylinder(Vector3(x, 0.28, 18.5), 0.09, 0.56, timber, 6)
        cylinder(Vector3(x, 1.29, 17.2), 0.18, 0.16, Color("e6e0c5"), 10, 0.24)
        box(Vector3(x, 2.8, 17.2), Vector3(1.8, 0.8, 0.06), Color("eee3c5"))
    signpost(Vector3(-16, 3.05, 17.25), "ICHIRAKU")
    building(Vector3(18, 0, 9), 10, 7, 3.2, Color("c9d2b7"), tile)
    signpost(Vector3(18, 2.65, 12.65), "FERRAMENTAS")
    # South gate remains an actual opening, flanked by broad timber leaves.
    for x: float in [-12.0, 12.0]:
        box(Vector3(x, 4.0, 55), Vector3(8, 8, 1.2), Color("657e64"), true)
        for band: float in [1.2, 4.0, 6.8]:
            box(Vector3(x, band, 55.65), Vector3(8.2, 0.14, 0.15), timber)
    box(Vector3(0, 8.3, 55), Vector3(33, 0.6, 2), red)
    signpost(Vector3(0, 8.4, 56.05), "ALDEIA DA FOLHA")
    for x: float in [-77.0, 77.0]:
        box(Vector3(x, 6.0, 0), Vector3(2, 12, 132), Color("8c9478"), true)
    box(Vector3(0, 6, 65), Vector3(156, 12, 2), Color("8c9478"), true)
    for origin: Vector3 in [Vector3(-65,0,-42), Vector3(-52,0,46), Vector3(-36,0,46), Vector3(52,0,45), Vector3(64,0,-43), Vector3(18,0,43), Vector3(-12,0,-14), Vector3(18,0,-36)]:
        tree(origin)
    var material: ShaderMaterial = preload("res://assets/world/anime_scenery.tres")
    for key: Vector2i in batches:
        var surface: SurfaceTool = batches[key] as SurfaceTool
        surface.set_material(material)
        var instance: MeshInstance3D = MeshInstance3D.new()
        instance.name = "Sector_%d_%d" % [key.x, key.y]
        instance.position = Vector3((float(key.x) + 0.5) * SECTOR_SIZE, 0, (float(key.y) + 0.5) * SECTOR_SIZE)
        instance.mesh = surface.commit()
        instance.visibility_range_end = 110.0
        instance.visibility_range_end_margin = 6.0
        add_child(instance)
        sectors.append(instance)
    batches.clear()

func set_quality(level: int) -> void:
    for sector: MeshInstance3D in sectors:
        sector.visibility_range_end = [70.0, 100.0, 130.0][clampi(level, 0, 2)]
