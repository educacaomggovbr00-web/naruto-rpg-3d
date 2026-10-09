class_name SusanooVisual
extends Node3D

## Reusable mobile chakra avatar. Optional licensed GLB replaces authored proxy.
const MODEL_PATH: String = "res://assets/susanoo/susanoo_mobile_rigged.glb"
var sword_arm: Node3D
var shell: Node3D
var clock: float = 0.0
var walk_phase: float = 0.0
var quality_level: int = 1
var external_model: bool = false
var material: StandardMaterial3D
var imported_avatar: Node3D
var wings: Array[MeshInstance3D] = []
var pose_blend: float = 0.0
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var current_clip: String = ""
var form: int = 3
var partial_shell: Node3D
var skeletal_shell: Node3D
var skeletal_arms: Array[Node3D] = []
var target_avatar_scale: float = 0.006
const FORM_NAMES: PackedStringArray = ["Parcial", "Esquelético", "Armadura", "Perfeito"]

static func strike_angle(progress: float, impact_phase: float = 0.42) -> float:
    var phase: float = clampf(progress, 0.0, 1.0)
    var impact: float = clampf(impact_phase, 0.15, 0.80)
    var windup: float = impact * 0.65
    if phase < windup:
        return lerpf(0.0, -0.85, smoothstep(0.0, windup, phase))
    if phase < impact:
        return lerpf(-0.85, 1.40, smoothstep(windup, impact, phase))
    return lerpf(1.40, 0.0, smoothstep(impact, 1.0, phase))

func _ready() -> void:
    material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    material.roughness = 0.55
    material.metallic = 0.15
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = Color(0.32, 0.12, 0.60, 0.86)
    material.emission_enabled = true
    material.emission = Color(0.25, 0.07, 0.48)
    shell = Node3D.new()
    add_child(shell)
    if ResourceLoader.exists(MODEL_PATH):
        var scene: PackedScene = load(MODEL_PATH) as PackedScene
        if scene != null:
            imported_avatar = scene.instantiate() as Node3D
            shell.add_child(imported_avatar)
            # The prepared source uses centimeter-like units, Z-up before import.
            imported_avatar.scale = Vector3.ONE * 0.005
            imported_avatar.position.y = 0.32
            _style_import(imported_avatar)
            _find_rig(imported_avatar)
            # The source sword is now rigidly weighted to the left hand; it
            # follows the real arm chain instead of a disconnected proxy blade.
            external_model = true
    if not external_model:
        _build_proxy()
    _build_forms()
    set_form(form)
    set_quality(quality_level)

func _find_rig(node: Node) -> void:
    if node is Skeleton3D:
        skeleton = node as Skeleton3D
    if node is AnimationPlayer:
        animation_player = node as AnimationPlayer
        animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
        animation_player.active = true
    for child: Node in node.get_children():
        _find_rig(child)

func _sample_animation(clip: String, phase: float) -> void:
    if animation_player == null or not animation_player.has_animation(clip):
        return
    if current_clip != clip:
        current_clip = clip
        animation_player.play(clip)
    var animation: Animation = animation_player.get_animation(clip)
    animation_player.seek(clampf(phase, 0.0, 1.0) * animation.length, true)

func _style_import(node: Node) -> void:
    if node is MeshInstance3D:
        var mesh: MeshInstance3D = node as MeshInstance3D
        mesh.material_override = material
        mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        # Broad wings are reserved for high quality to keep phone combat readable.
        if String(node.name) == "Object_7":
            wings.append(mesh)
            var wing_material: StandardMaterial3D = material.duplicate() as StandardMaterial3D
            wing_material.albedo_color.a = 0.34
            mesh.material_override = wing_material
    for child: Node in node.get_children():
        _style_import(child)

func _build_proxy() -> void:
    # Original rib cage, skull, shoulders and sword; no extracted game geometry.
    for side: float in [-1.0, 1.0]:
        _segment(shell, Vector3(side * 0.18, 0.15, -0.24), Vector3(side * 0.50, 2.15, -0.24), 0.08)
        for row: int in range(5):
            var y: float = 0.30 + float(row) * 0.32
            var radius: float = 0.72 + float(row) * 0.04
            var last: Vector3 = Vector3(side * 0.18, y, -0.30)
            for step: int in range(1, 7):
                var angle: float = float(step) * PI / 6.0
                var point: Vector3 = Vector3(side * radius * sin(angle), y + sin(angle) * 0.06, -0.30 - radius * cos(angle))
                _segment(shell, last, point, 0.065)
                last = point
        _ball(shell, Vector3(side * 0.9, 2.12, -0.22), Vector3(0.52, 0.42, 0.52))
        _segment(shell, Vector3(side * 0.90, 2.05, -0.22), Vector3(side * 1.12, 1.25, -0.12), 0.17)
        _segment(shell, Vector3(side * 0.25, 2.92, -0.28), Vector3(side * 0.52, 3.45, -0.30), 0.055)
    _ball(shell, Vector3(0, 2.70, -0.27), Vector3(0.60, 0.72, 0.48))
    sword_arm = Node3D.new()
    sword_arm.position = Vector3(-0.9, 2.08, -0.22)
    shell.add_child(sword_arm)
    _segment(sword_arm, Vector3.ZERO, Vector3(-0.35, -0.55, 0.65), 0.17)
    _segment(sword_arm, Vector3(-0.35, -0.55, 0.65), Vector3(-0.35, -0.55, 2.45), 0.09)

func _ball(parent: Node3D, point: Vector3, size: Vector3) -> void:
    var mesh: SphereMesh = SphereMesh.new()
    mesh.radial_segments = 10
    mesh.rings = 5
    var instance: MeshInstance3D = _mesh(parent, mesh)
    instance.position = point
    instance.scale = size

func _segment(parent: Node3D, a: Vector3, b: Vector3, radius: float) -> void:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = radius * 0.7
    mesh.bottom_radius = radius
    mesh.height = a.distance_to(b)
    mesh.radial_segments = 6
    var instance: MeshInstance3D = _mesh(parent, mesh)
    instance.position = (a + b) * 0.5
    instance.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func _mesh(parent: Node3D, mesh: Mesh) -> MeshInstance3D:
    var instance: MeshInstance3D = MeshInstance3D.new()
    instance.mesh = mesh
    instance.material_override = material
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(instance)
    return instance

func update_pose(delta: float, striking: bool, progress: float = 0.0, local_velocity: Vector3 = Vector3.ZERO, impact_phase: float = 0.42, summon: float = 1.0, guarding: bool = false) -> void:
    # Hit-stop freezes this clock too. Motion remains independent per avatar.
    var dt: float = maxf(delta, 0.0)
    clock += dt
    walk_phase = fmod(walk_phase + Vector2(local_velocity.x,local_velocity.z).length()*dt/7.0,1.0)
    if imported_avatar != null:
        imported_avatar.scale = imported_avatar.scale.lerp(Vector3.ONE * target_avatar_scale, 1.0 - exp(-dt * 12.0))
    var speed: float = minf(Vector2(local_velocity.x, local_velocity.z).length() / 12.5, 1.0)
    var angle: float = strike_angle(progress, impact_phase) if striking else 0.0
    if striking:
        # Remap the authored impact at .42 to the selected attack's actual hit.
        var phase: float = clampf(progress, 0.0, 1.0)
        var impact: float = clampf(impact_phase, 0.15, 0.80)
        var mapped: float = phase / impact * 0.42 if phase <= impact else 0.42 + (phase - impact) / (1.0 - impact) * 0.58
        _sample_animation("slash", mapped)
    elif summon < 1.0:
        _sample_animation("summon", summon)
    elif guarding:
        _sample_animation("guard", 0.5)
    elif speed > 0.08:
        _sample_animation("walk", walk_phase)
    else:
        _sample_animation("idle", fmod(clock, 2.4) / 2.4)
    pose_blend = lerpf(pose_blend, angle, 1.0 - exp(-dt * 18.0))
    shell.scale = Vector3.ONE * (0.15 + 0.85 * smoothstep(0.0, 1.0, clampf(summon, 0.0, 1.0))) * (1.0 + sin(clock * 4.0) * 0.012)
    shell.position.y = sin(clock * lerpf(2.0, 9.0, speed)) * lerpf(0.012, 0.045, speed)
    shell.rotation = Vector3(clampf(local_velocity.z * 0.006, -0.08, 0.08), pose_blend * 0.18,
        clampf(-local_velocity.x * 0.008, -0.10, 0.10))
    material.emission_energy_multiplier = 1.0 + (0.35 * sin(PI * clampf(progress, 0.0, 1.0)) if striking else 0.0)
    for index: int in range(skeletal_arms.size()):
        skeletal_arms[index].rotation.x = angle * (1.0 if index == 0 else -0.35)
    if sword_arm != null:
        # Strike follows the manifest's impact; recovery returns continuously to
        # neutral, including interruption, rather than snapping from full swing.
        sword_arm.rotation = Vector3(-absf(pose_blend) * 0.12, angle if striking else pose_blend + sin(clock * 2.0) * 0.04, pose_blend * 0.16)

func reset_pose() -> void:
    clock = 0.0
    walk_phase = 0.0
    pose_blend = 0.0
    current_clip = ""
    _sample_animation("idle", 0.0)
    if shell != null:
        shell.transform = Transform3D.IDENTITY
    if sword_arm != null:
        sword_arm.rotation = Vector3.ZERO

func set_quality(level: int) -> void:
    quality_level = clampi(level, 0, 2)
    for wing: MeshInstance3D in wings:
        wing.visible = quality_level == 2 and form == 3
    # Geometry is bounded and built once; no per-frame allocations/particles.


func _build_forms() -> void:
    partial_shell = Node3D.new()
    partial_shell.name = "PartialRibcage"
    shell.add_child(partial_shell)
    for side: float in [-1.0, 1.0]:
        _segment(partial_shell, Vector3(side * 0.2, 0.1, -0.65), Vector3(side * 0.2, 2.3, -0.65), 0.08)
        for row: int in range(6):
            var y: float = 0.25 + row * 0.33
            var last: Vector3 = Vector3(side * 0.2, y, -0.65)
            for step: int in range(1, 9):
                var angle: float = step * PI / 8.0
                var point: Vector3 = Vector3(side * 1.25 * sin(angle), y, -0.15 - 1.1 * cos(angle))
                _segment(partial_shell, last, point, 0.06)
                last = point
    skeletal_shell = Node3D.new()
    skeletal_shell.name = "SkeletalUpperBody"
    shell.add_child(skeletal_shell)
    _segment(skeletal_shell, Vector3(0, 1.6, -0.55), Vector3(0, 3.5, -0.55), 0.13)
    _ball(skeletal_shell, Vector3(0, 3.1, -0.55), Vector3(0.6, 0.75, 0.5))
    for side: float in [-1.0, 1.0]:
        _segment(skeletal_shell, Vector3(side * 0.2, 3.35, -0.55), Vector3(side * 0.65, 3.9, -0.55), 0.07)
        var arm: Node3D = Node3D.new()
        arm.position = Vector3(side * 1.1, 2.5, -0.55)
        skeletal_shell.add_child(arm)
        skeletal_arms.append(arm)
        _ball(arm, Vector3.ZERO, Vector3(0.35, 0.35, 0.35))
        _segment(arm, Vector3.ZERO, Vector3(side * 0.4, -0.7, 0.1), 0.13)
        _segment(arm, Vector3(side * 0.4, -0.7, 0.1), Vector3(side * 0.6, -0.8, 1.0), 0.11)
        for finger: int in range(4):
            _segment(arm, Vector3(side * 0.6 + finger * 0.07, -0.8, 1), Vector3(side * 0.6 + finger * 0.07, -0.95, 1.3), 0.035)

func set_form(value: int) -> void:
    form = clampi(value, 0, 3)
    if partial_shell == null:
        return
    partial_shell.visible = form <= 1
    skeletal_shell.visible = form == 1
    if imported_avatar != null:
        imported_avatar.visible = form >= 2
        target_avatar_scale = 0.006 if form == 3 else 0.005
    set_quality(quality_level)
