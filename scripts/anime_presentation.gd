extends RefCounted
## Shared visual direction. No combat, rig, physics or save changes.
const SURFACE: Shader = preload("res://assets/vfx/anime_surface.gdshader")
static func textured(source: StandardMaterial3D) -> Material:
    # Preserve uncommon imported material features instead of discarding them.
    if source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or source.normal_enabled or source.uv1_scale != Vector3.ONE or source.uv1_offset != Vector3.ZERO:
        return source
    # Imported materials are shared by ResourceLoader across actors/clones.
    # Change lighting in memory only; keep textures, colors and the GLB intact.
    source.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    source.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    source.roughness = 0.8
    source.rim_enabled = true
    source.rim = 0.15
    source.rim_tint = 0.5
    return source

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
    sky_material.ground_bottom_color = Color("5b7180")
    sky_material.ground_horizon_color = sky_material.sky_horizon_color
    result.sky.sky_material = sky_material
    result.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    result.ambient_light_color = Color("a9bddb")
    result.ambient_light_energy = 0.24
    result.fog_enabled = true
    result.fog_light_color = sky_material.sky_horizon_color
    result.fog_density = 0.0025
    return result

static func sun(light: DirectionalLight3D, dusk: bool = false) -> void:
    light.light_color = Color("ffdab5") if dusk else Color("fff0d8")
    light.light_energy = 1.05
