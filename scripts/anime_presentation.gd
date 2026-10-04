extends RefCounted
## Shared visual direction. No combat, rig, physics or save changes.
const SURFACE: Shader = preload("res://assets/vfx/anime_surface.gdshader")
static var textured_cache: Dictionary = {}

static func textured(source: StandardMaterial3D) -> Material:
    # Transparent imported materials keep their specialized pipeline untouched.
    if source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
        return source

    var key: RID = source.get_rid()
    if textured_cache.has(key):
        return textured_cache[key] as Material

    # Never mutate the imported GLB material: player, CPU, clones and previews
    # can share the same source Resource. A deep copy preserves all texture maps.
    var result: StandardMaterial3D = source.duplicate(true) as StandardMaterial3D
    if result == null:
        return source
    result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    result.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    result.roughness = maxf(result.roughness, 0.72)
    result.rim_enabled = true
    result.rim = 0.20
    result.rim_tint = 0.58
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
    sky_material.sky_top_color = Color("586da3") if dusk else Color("4b9ed0")
    sky_material.sky_horizon_color = Color("f5c49d") if dusk else Color("d5eef4")
    sky_material.ground_bottom_color = Color("4d6575") if dusk else Color("5b7180")
    sky_material.ground_horizon_color = sky_material.sky_horizon_color
    sky_material.sun_angle_max = 10.0
    sky_material.sun_curve = 0.12
    result.sky.sky_material = sky_material
    result.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    result.ambient_light_color = Color("9eb5d8") if dusk else Color("b3c8df")
    result.ambient_light_energy = 0.28
    result.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    result.fog_enabled = true
    result.fog_light_color = sky_material.sky_horizon_color
    result.fog_density = 0.0022
    return result

static func sun(light: DirectionalLight3D, dusk: bool = false) -> void:
    light.light_color = Color("ffcf9f") if dusk else Color("fff0d8")
    light.light_energy = 1.10
    light.shadow_bias = 0.08
    light.shadow_normal_bias = 1.2
