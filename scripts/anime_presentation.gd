extends RefCounted
## Shared mobile anime direction. Visual-only; gameplay is untouched.
const SURFACE: Shader = preload("res://assets/vfx/anime_surface.gdshader")
const OUTLINE: Shader = preload("res://assets/vfx/anime_outline.gdshader")
static var textured_cache: Dictionary = {}
static var outline_material: ShaderMaterial = null

static func _outline() -> ShaderMaterial:
    if outline_material == null:
        outline_material = ShaderMaterial.new()
        outline_material.shader = OUTLINE
        outline_material.set_shader_parameter("outline_color", Color("07101a"))
        outline_material.set_shader_parameter("outline_width", 0.0030)
        outline_material.set_shader_parameter("distance_growth", 0.35)
    return outline_material

static func textured(source: StandardMaterial3D) -> Material:
    if source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
        return source

    var key: RID = source.get_rid()
    if textured_cache.has(key):
        return textured_cache[key] as Material

    var result: StandardMaterial3D = source.duplicate(true) as StandardMaterial3D
    if result == null:
        return source

    result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    result.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    result.roughness = maxf(result.roughness, 0.82)
    result.rim_enabled = true
    result.rim = 0.13
    result.rim_tint = 0.42
    if result.next_pass == null:
        result.next_pass = _outline()

    textured_cache[key] = result
    return result

static func environment(dusk: bool = false, existing: Environment = null) -> Environment:
    var result: Environment = existing if existing != null else Environment.new()
    result.background_mode = Environment.BG_SKY

    if result.sky == null:
        result.sky = Sky.new()

    var sky_material: ProceduralSkyMaterial = result.sky.sky_material as ProceduralSkyMaterial
    if sky_material == null:
        sky_material = ProceduralSkyMaterial.new()

    sky_material.sky_top_color = Color("283f70") if dusk else Color("347fa5")
    sky_material.sky_horizon_color = Color("d78b72") if dusk else Color("83b8c7")
    sky_material.ground_bottom_color = Color("25374b") if dusk else Color("445d58")
    sky_material.ground_horizon_color = Color("a56f64") if dusk else Color("78a39d")
    sky_material.sun_angle_max = 6.0
    sky_material.sun_curve = 0.08
    result.sky.sky_material = sky_material

    result.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    result.ambient_light_color = Color("657ba4") if dusk else Color("748fa3")
    result.ambient_light_energy = 0.24
    result.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

    result.fog_enabled = true
    result.fog_light_color = sky_material.sky_horizon_color
    result.fog_density = 0.00075
    return result

static func sun(light: DirectionalLight3D, dusk: bool = false) -> void:
    light.light_color = Color("ffb76e") if dusk else Color("ffd49c")
    light.light_energy = 1.02
    light.shadow_bias = 0.11
    light.shadow_normal_bias = 1.25
