extends Node3D

@export var hit_stop_enabled: bool = true

var flashes: Array[MeshInstance3D] = []
var lifetimes: Array[float] = []
var durations: Array[float] = []
var sizes: Array[float] = []
var pool_cursor: int = 0
var trail_timer: float = 0.0

var hit_stop_end_msec: int = 0
var normal_time_scale: float = 1.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    normal_time_scale = Engine.time_scale
    for i: int in range(32):
        var effect: MeshInstance3D = MeshInstance3D.new()
        var mesh: SphereMesh = SphereMesh.new()
        mesh.radius = 0.5
        mesh.height = 1.0
        mesh.radial_segments = 8
        mesh.rings = 4
        var material: StandardMaterial3D = StandardMaterial3D.new()
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mesh.material = material
        effect.mesh = mesh
        effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        effect.visible = false
        add_child(effect)
        flashes.append(effect)
        lifetimes.append(0.0)
        durations.append(0.0)
        sizes.append(0.0)

func _process(delta: float) -> void:
    for i: int in range(flashes.size()):
        if lifetimes[i] <= 0.0:
            continue
        lifetimes[i] = maxf(lifetimes[i] - delta, 0.0)
        var phase: float = 1.0 - lifetimes[i] / durations[i]
        flashes[i].scale = Vector3.ONE * sizes[i] * (1.0 + phase) * (1.0 - phase * phase)
        flashes[i].visible = lifetimes[i] > 0.0
    trail_timer -= delta
    var actor: Node3D = get_node_or_null("../Player") as Node3D
    if trail_timer <= 0.0 and actor != null:
        trail_timer = 0.06
        if float(actor.get("chakra_dash_timer")) > 0.06 or (actor.get("specials") != null and actor.specials.current == "rasengan"):
            spawn_dash_burst(actor.global_position - actor.global_basis.z * 0.4)
    if hit_stop_end_msec <= 0:
        return

    if Time.get_ticks_msec() >= hit_stop_end_msec:
        Engine.time_scale = normal_time_scale
        hit_stop_end_msec = 0

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

    if impact_kind == "guard":
        scale_value = 0.42
        color_value = Color(0.35, 0.85, 1.0, 1.0)
    elif impact_kind == "launcher":
        scale_value = 0.52
        color_value = Color(1.0, 0.42, 0.12, 1.0)
        lifetime = 0.13
    elif impact_kind == "slam":
        scale_value = 0.62
        color_value = Color(1.0, 0.18, 0.08, 1.0)
        lifetime = 0.15
    elif impact_kind == "bounce":
        scale_value = 0.58
        color_value = Color(1.0, 0.58, 0.15, 1.0)
        lifetime = 0.14

    _spawn_flash(world_position, scale_value, color_value, lifetime)

func spawn_substitution(world_position: Vector3) -> void:
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
            0.22
        )

func spawn_dash_burst(world_position: Vector3) -> void:
    _spawn_flash(
        world_position + Vector3.UP * 0.55,
        0.48,
        Color(0.10, 0.55, 1.0, 1.0),
        0.16
    )

func _spawn_flash(
    world_position: Vector3,
    start_scale: float,
    flash_color: Color,
    lifetime: float
) -> void:
    var index: int = pool_cursor
    pool_cursor = (pool_cursor + 1) % flashes.size()
    var effect: MeshInstance3D = flashes[index]
    var material: StandardMaterial3D = effect.mesh.material as StandardMaterial3D
    material.albedo_color = flash_color
    effect.global_position = world_position
    effect.visible = true
    effect.scale = Vector3.ONE * start_scale
    sizes[index] = start_scale
    durations[index] = lifetime
    lifetimes[index] = lifetime

func _exit_tree() -> void:
    Engine.time_scale = normal_time_scale
