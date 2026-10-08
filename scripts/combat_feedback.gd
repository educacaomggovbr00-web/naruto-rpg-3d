extends Node3D

@export var hit_stop_enabled: bool = true

var flashes: Array[MeshInstance3D] = []
var lifetimes: Array[float] = []
var durations: Array[float] = []
var sizes: Array[float] = []
var effect_budget: int = 32
var trail_interval: float = 0.06
var pool_cursor: int = 0
var trail_timer: float = 0.0
var elemental_impacts: Array[Node3D] = []
var elemental_cursor: int = 0
var elemental_budget: int = 4

var hit_stop_end_msec: int = 0
var normal_time_scale: float = 1.0

var manga_overlay: ColorRect = null
var manga_material: ShaderMaterial = null
var manga_impact: float = 0.0
var manga_center: Vector2 = Vector2(0.5, 0.5)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    normal_time_scale = Engine.time_scale
    _setup_manga_impact()
    for i: int in range(32):
        var effect: MeshInstance3D = MeshInstance3D.new()
        var mesh: QuadMesh = QuadMesh.new()
        mesh.size = Vector2(2.0, 2.0)
        var material: StandardMaterial3D = StandardMaterial3D.new()
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
        material.cull_mode = BaseMaterial3D.CULL_DISABLED
        material.albedo_texture = preload("res://assets/vendor/kenney_particles/star_01.png")
        material.no_depth_test = false
        mesh.material = material
        effect.mesh = mesh
        effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        effect.visible = false
        add_child(effect)
        flashes.append(effect)
        lifetimes.append(0.0)
        durations.append(0.0)
        sizes.append(0.0)
    for index: int in range(6):
        var impact: Node3D = Node3D.new()
        impact.set_script(preload("res://scripts/jutsu_impact.gd"))
        add_child(impact)
        elemental_impacts.append(impact)

func set_quality(level: int) -> void:
    elemental_budget = [2,4,6][clampi(level,0,2)]
    elemental_cursor = 0
    for index: int in range(elemental_impacts.size()):
        elemental_impacts[index].set_quality(level)
        if index >= elemental_budget:
            elemental_impacts[index].recycle()

func spawn_elemental_impact(origin: Vector3, kind: String, radius: float = .8, heading: Vector3 = Vector3.BACK) -> void:
    if elemental_impacts.is_empty():
        return
    var impact: Node3D = elemental_impacts[elemental_cursor]
    elemental_cursor = (elemental_cursor+1)%elemental_budget
    impact.activate(origin,kind,radius,heading)
    _spawn_flash(origin,minf(radius*.35,.5),RosterVisualStyle.color(kind).lightened(.3),.08)
    _trigger_manga_impact(origin,.28,RosterVisualStyle.color(kind))
    var audio: Node = get_node_or_null("../AudioManager")
    if audio != null:
        audio.play("heavy",-20.0)

func _process(delta: float) -> void:
    for i: int in range(flashes.size()):
        if lifetimes[i] <= 0.0:
            continue
        lifetimes[i] = maxf(lifetimes[i] - delta, 0.0)
        var phase: float = 1.0 - lifetimes[i] / durations[i]
        flashes[i].scale = Vector3.ONE * sizes[i] * (1.0 + phase) * (1.0 - phase * phase)
        flashes[i].visible = lifetimes[i] > 0.0
        var material: StandardMaterial3D = flashes[i].mesh.material as StandardMaterial3D
        material.albedo_color.a = 1.0 - phase
    trail_timer -= delta
    if trail_timer <= 0.0:
        trail_timer = trail_interval
        for title: String in ["Player", "EnemyDummy"]:
            var actor: Node3D = get_node_or_null("../" + title) as Node3D
            if actor != null and (float(actor.get("chakra_dash_timer")) > 0.06 or (actor.get("specials") != null and actor.specials.current in ["rasengan", "chidori", "raikiri"])):
                _spawn_flash(
                    actor.global_position - actor.global_basis.z * 0.4 + Vector3.UP * 0.55,
                    0.35,
                    _actor_energy_color(actor),
                    0.16
                )
    _update_manga_impact(delta)

    if hit_stop_end_msec <= 0:
        return

    if Time.get_ticks_msec() >= hit_stop_end_msec:
        Engine.time_scale = normal_time_scale
        hit_stop_end_msec = 0

func _actor_energy_color(actor: Node) -> Color:
    if actor != null and actor.has_method("get_character_definition"):
        var definition: CharacterDefinition = actor.call("get_character_definition") as CharacterDefinition
        if definition != null:
            return definition.energy_color
    return Color(0.1, 0.55, 1.0)

func hit_stop(duration: float, slow_scale: float = 0.10) -> void:
    if not hit_stop_enabled:
        return
    var duration_msec: int = int(maxf(duration, 0.01) * 1000.0)
    var requested_end: int = Time.get_ticks_msec() + duration_msec
    hit_stop_end_msec = maxi(hit_stop_end_msec, requested_end)
    Engine.time_scale = minf(Engine.time_scale, clampf(slow_scale, 0.03, 1.0))

func spawn_impact(world_position: Vector3, impact_kind: String = "normal") -> void:
    var scale_value: float = 0.34
    var color_value: Color = Color(1.0, 0.78, 0.22, 1.0)
    var lifetime: float = 0.10
    var manga_strength: float = 0.14

    if impact_kind == "guard":
        scale_value = 0.42
        color_value = Color(0.35, 0.85, 1.0, 1.0)
        manga_strength = 0.20
    elif impact_kind == "launcher":
        scale_value = 0.52
        color_value = Color(1.0, 0.42, 0.12, 1.0)
        lifetime = 0.13
        manga_strength = 0.40
    elif impact_kind == "slam":
        scale_value = 0.62
        color_value = Color(1.0, 0.18, 0.08, 1.0)
        lifetime = 0.15
        manga_strength = 0.68
    elif impact_kind == "bounce":
        scale_value = 0.58
        color_value = Color(1.0, 0.58, 0.15, 1.0)
        lifetime = 0.14
        manga_strength = 0.52

    var audio: Node = get_node_or_null("../AudioManager")
    if audio != null:
        audio.call("play", "guard" if impact_kind == "guard" else "heavy" if impact_kind in ["slam", "launcher", "bounce"] else "normal")
    _spawn_flash(world_position, scale_value, color_value, lifetime)
    _trigger_manga_impact(world_position, manga_strength, color_value)

func spawn_substitution(world_position: Vector3) -> void:
    var audio: Node = get_node_or_null("../AudioManager")
    if audio != null:
        audio.call("play", "smoke", -21.0)
    var offsets: Array[Vector3] = [
        Vector3(-0.42, 0.25, 0.0),
        Vector3(0.38, 0.35, 0.12),
        Vector3(0.0, 0.55, -0.25)
    ]

    for offset: Vector3 in offsets:
        _spawn_flash(
            world_position + offset,
            0.44,
            Color(0.82, 0.87, 0.92, 1.0),
            0.22,
            true
        )

func spawn_dash_burst(world_position: Vector3) -> void:
    var audio: Node = get_node_or_null("../AudioManager")
    if audio != null:
        audio.call("play", "dash", -21.0)
    _spawn_flash(
        world_position + Vector3.UP * 0.55,
        0.62,
        Color(0.10, 0.55, 1.0, 1.0),
        0.18
    )
    _trigger_manga_impact(world_position + Vector3.UP * 0.55, 0.20, Color(0.10, 0.55, 1.0, 1.0))

func spawn_chakra_impact(world_position: Vector3, energy_color: Color) -> void:
    var audio: Node = get_node_or_null("../AudioManager")
    if audio != null:
        audio.call("play", "heavy", -19.0)

    # Spread the same bounded billboard burst beyond the body silhouette so
    # the contact reads clearly on compact phone screens.
    _spawn_flash(world_position, 1.02, energy_color.lightened(0.14), 0.16)
    _spawn_flash(world_position + Vector3(0.42, 0.16, 0.0), 0.68, Color(0.88, 0.96, 1.0, 1.0), 0.11)
    _spawn_flash(world_position + Vector3(-0.38, -0.08, 0.16), 0.56, energy_color, 0.13)
    _trigger_manga_impact(world_position, 0.58, energy_color)

func _setup_manga_impact() -> void:
    var hud: CanvasLayer = get_node_or_null("../HUD") as CanvasLayer
    if hud == null:
        return
    manga_overlay = ColorRect.new()
    manga_overlay.name = "MangaImpactOverlay"
    manga_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    manga_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    manga_material = ShaderMaterial.new()
    manga_material.shader = preload("res://assets/vfx/manga_impact.gdshader")
    manga_material.set_shader_parameter("impact", 0.0)
    manga_overlay.material = manga_material
    manga_overlay.visible = false
    hud.add_child(manga_overlay)
    hud.move_child(manga_overlay, 0)


func _screen_uv(world_position: Vector3) -> Vector2:
    var camera: Camera3D = get_viewport().get_camera_3d()
    if camera == null or camera.is_position_behind(world_position):
        return manga_center
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
        return manga_center
    var screen_position: Vector2 = camera.unproject_position(world_position)
    return Vector2(
        clampf(screen_position.x / viewport_size.x, 0.06, 0.94),
        clampf(screen_position.y / viewport_size.y, 0.08, 0.92)
    )


func _trigger_manga_impact(world_position: Vector3, strength: float, flash_color: Color) -> void:
    if manga_material == null:
        return
    manga_impact = maxf(manga_impact, clampf(strength, 0.0, 1.0))
    manga_center = _screen_uv(world_position)
    manga_material.set_shader_parameter("impact_center", manga_center)
    manga_material.set_shader_parameter("flash_color", flash_color.lightened(0.24))


func _update_manga_impact(delta: float) -> void:
    if manga_overlay == null or manga_material == null:
        return

    var dash_strength: float = 0.0
    var actor: Node3D = get_node_or_null("../Player") as Node3D
    if actor != null and float(actor.get("chakra_dash_timer")) > 0.05:
        dash_strength = 0.10
        manga_center = _screen_uv(actor.global_position + Vector3.UP * 0.9)
        manga_material.set_shader_parameter("impact_center", manga_center)

    manga_impact = move_toward(manga_impact, 0.0, delta * 5.6)
    var visible_strength: float = maxf(manga_impact, dash_strength)
    manga_material.set_shader_parameter("impact", visible_strength)
    manga_overlay.visible = visible_strength > 0.015


func _spawn_flash(
    world_position: Vector3,
    start_scale: float,
    flash_color: Color,
    lifetime: float,
    smoke: bool = false
) -> void:
    var index: int = pool_cursor
    pool_cursor = (pool_cursor + 1) % mini(effect_budget, flashes.size())
    var effect: MeshInstance3D = flashes[index]
    var material: StandardMaterial3D = effect.mesh.material as StandardMaterial3D
    material.albedo_texture = preload("res://assets/vendor/kenney_particles/smoke_01.png") if smoke else preload("res://assets/vendor/kenney_particles/star_01.png")
    material.albedo_color = flash_color
    effect.global_position = world_position
    effect.visible = true
    effect.scale = Vector3.ONE * start_scale
    sizes[index] = start_scale
    durations[index] = lifetime
    lifetimes[index] = lifetime

func _exit_tree() -> void:
    Engine.time_scale = normal_time_scale
