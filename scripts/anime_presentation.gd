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
        outline_material.set_shader_parameter("outline_color", Color("07101d"))
        outline_material.set_shader_parameter("outline_width", 0.008)
    return outline_material

static func textured(source: StandardMaterial3D) -> Material:
    # Transparent imported materials keep their specialized pipeline untouched.
    if source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
        return source

    var key: RID = source.get_rid()
    if textured_cache.has(key):
        return textured_cache[key] as Material

    # Never mutate the imported GLB material: player, CPU, clones and previews
    # can share the same source Resource. A deep copy preserves texture maps.
    var result: StandardMaterial3D = source.duplicate(true) as StandardMaterial3D
    if result == null:
        return source
    result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    result.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    result.roughness = maxf(result.roughness, 0.78)
    result.rim_enabled = true
    result.rim = 0.16
    result.rim_tint = 0.48
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

    sky_material.sky_top_color = Color("354f85") if dusk else Color("4f9fc8")
    sky_material.sky_horizon_color = Color("e59f83") if dusk else Color("91c8d8")
    sky_material.ground_bottom_color = Color("39495d") if dusk else Color("57736d")
    sky_material.ground_horizon_color = Color("b68073") if dusk else Color("86b9b3")
    sky_material.sun_angle_max = 8.0
    sky_material.sun_curve = 0.10
    result.sky.sky_material = sky_material

    result.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    result.ambient_light_color = Color("728bb1") if dusk else Color("8fa9bf")
    result.ambient_light_energy = 0.20
    result.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

    result.fog_enabled = true
    result.fog_light_color = sky_material.sky_horizon_color
    result.fog_density = 0.00125
    return result

static func sun(light: DirectionalLight3D, dusk: bool = false) -> void:
    light.light_color = Color("ffc178") if dusk else Color("ffe0ad")
    light.light_energy = 1.18
    light.shadow_bias = 0.10
    light.shadow_normal_bias = 1.35
