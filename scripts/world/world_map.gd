extends Control
var village: Node3D
var map_rect: Rect2

func world_to_map(point: Vector3) -> Vector2:
    return map_rect.position + Vector2((point.x + 78.0) / 156.0, (point.z + 66.0) / 132.0) * map_rect.size

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.04, 0.06, 0.88))
    map_rect = Rect2(size * Vector2(0.12, 0.12), size * Vector2(0.76, 0.74))
    draw_rect(map_rect, Color("96a784"))
    draw_rect(map_rect, Color("eddbb9"), false, 3.0)
    for road: Array in [[Vector3(0,0,-56),Vector3(0,0,56)], [Vector3(-66,0,22),Vector3(58,0,22)], [Vector3(-66,0,-10),Vector3(58,0,-10)], [Vector3(-66,0,40),Vector3(58,0,40)], [Vector3(-66,0,-29),Vector3(58,0,-29)]]:
        draw_line(world_to_map(road[0]), world_to_map(road[1]), Color("d9c6a3"), 16.0)
    draw_line(world_to_map(Vector3(34,0,-56)), world_to_map(Vector3(34,0,56)), Color("65a5a6"), 15.0)
    for footprint: Dictionary in village.get_node("Geometry").footprints:
        var center: Vector3 = footprint.center
        var dimensions: Vector3 = footprint.size
        var start: Vector2 = world_to_map(center - dimensions * 0.5)
        var finish: Vector2 = world_to_map(center + dimensions * 0.5)
        draw_rect(Rect2(start, finish - start), footprint.color)
    for point: Area3D in village.points:
        if point.data.kind == "scroll" and GameFlow.progress.collected.has(point.data.id):
            continue
        var center: Vector2 = world_to_map(point.global_position)
        var color: Color = Color("ffe491") if point.data.kind == "scroll" else Color("394f49")
        draw_circle(center, 5.0, color)
        draw_string(ThemeDB.fallback_font, center + Vector2(8, -7), point.data.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("172c29"))
    var actor: CharacterBody3D = village.get_node("Player")
    var player_point: Vector2 = world_to_map(actor.global_position)
    draw_circle(player_point, 7, Color("cf4d30"))
    var heading: Vector2 = Vector2(sin(actor.rotation.y), cos(actor.rotation.y))
    draw_line(player_point, player_point + heading * 16, Color("fff5d7"), 3.0)
    draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.12, size.y * 0.09), "ALDEIA DA FOLHA — telhados, missões e treino", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff1d4"))
    draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.12, size.y * 0.92), "MAPA / M para voltar | vermelho: você | dourado: pergaminhos", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff1d4"))
