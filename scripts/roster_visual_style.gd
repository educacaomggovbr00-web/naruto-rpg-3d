class_name RosterVisualStyle
extends RefCounted

static func color(effect: String, fallback: Color = Color(0.20, 0.65, 1.0)) -> Color:
    match effect:
        "susanoo":
            return Color(0.64, 0.20, 1.0)
        "fire":
            return Color(1.0, 0.23, 0.04)
        "water":
            return Color(0.08, 0.52, 1.0)
        "wind":
            return Color(0.45, 0.94, 0.86)
        "lightning":
            return Color(0.45, 0.80, 1.0)
        "sand":
            return Color(0.86, 0.62, 0.22)
        "earth", "oil":
            return Color(0.70, 0.48, 0.20)
        "shadow":
            return Color(0.18, 0.10, 0.30)
        "mind":
            return Color(0.96, 0.34, 0.74)
        "insect":
            return Color(0.26, 0.22, 0.12)
        "steel", "puppet":
            return Color(0.72, 0.78, 0.86)
        "bone":
            return Color(0.92, 0.90, 0.82)
        "snake":
            return Color(0.38, 0.78, 0.26)
        "taijutsu":
            return Color(0.36, 1.0, 0.38)
        "chakra":
            return Color(0.22, 0.66, 1.0)
        _:
            return fallback

static func projectile_mesh(effect: String) -> PrimitiveMesh:
    if effect == "susanoo":
        var blade: BoxMesh = BoxMesh.new()
        blade.size = Vector3(1.8, 0.12, 0.28)
        return blade
    if effect in ["steel", "puppet", "bone", "snake"]:
        var box: BoxMesh = BoxMesh.new()
        box.size = Vector3(0.18, 0.18, 0.90) if effect != "bone" else Vector3(0.14, 0.14, 1.05)
        return box
    if effect in ["wind", "shadow"]:
        var disc: CylinderMesh = CylinderMesh.new()
        disc.top_radius = 0.42
        disc.bottom_radius = 0.42
        disc.height = 0.09
        disc.radial_segments = 12
        return disc
    var sphere: SphereMesh = SphereMesh.new()
    sphere.radius = 0.38
    sphere.height = 0.76
    sphere.radial_segments = 10
    sphere.rings = 5
    return sphere

static func projectile_scale(effect: String, radius: float) -> Vector3:
    var factor: float = clampf(radius / 0.45, 0.75, 2.2)
    if effect == "wind":
        return Vector3(factor * 1.35, factor * 0.75, factor * 1.35)
    if effect == "shadow":
        return Vector3(factor * 1.5, factor * 0.45, factor * 1.5)
    if effect in ["steel", "puppet", "bone", "snake"]:
        return Vector3.ONE * factor
    return Vector3.ONE * factor

static func orbit_speed(effect: String) -> float:
    if effect in ["lightning", "wind", "taijutsu"]:
        return 10.0
    if effect in ["sand", "earth", "water"]:
        return 4.0
    if effect in ["shadow", "insect", "mind"]:
        return 6.0
    return 7.0
