extends Node3D
## Fixed-size impact pool: animated shell, ground pressure ring and instanced debris.
## Visual only. No gameplay timers, lights, physics bodies or global RNG.
var active: bool = false
var kind: String = "chakra"
var clock: float = 0.0
var duration: float = .5
var radius: float = .8
var heading: Vector3 = Vector3.BACK
var quality: int = 1
var shell: MeshInstance3D
var ring: MeshInstance3D
var sparks: MultiMeshInstance3D
var smoke: MultiMeshInstance3D
var smoke_material: ShaderMaterial
var shell_material: ShaderMaterial
var ring_material: StandardMaterial3D

func _ready() -> void:
    shell = MeshInstance3D.new()
    var sphere: SphereMesh = SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    sphere.radial_segments = 20
    sphere.rings = 10
    shell.mesh = sphere
    shell_material = ShaderMaterial.new()
    shell_material.shader = preload("res://assets/vfx/jutsu_impact.gdshader")
    shell.material_override = shell_material
    shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(shell)
    ring = MeshInstance3D.new()
    var torus: TorusMesh = TorusMesh.new()
    torus.inner_radius = .94
    torus.outer_radius = 1.0
    torus.rings = 32
    torus.ring_segments = 4
    ring.mesh = torus
    ring_material = StandardMaterial3D.new()
    ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ring.material_override = ring_material
    ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(ring)
    sparks = MultiMeshInstance3D.new()
    var batch: MultiMesh = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.use_colors = true
    var fragment: SphereMesh = SphereMesh.new()
    fragment.radius = 1.0
    fragment.height = 2.0
    fragment.radial_segments = 5
    fragment.rings = 3
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    fragment.material = material
    batch.mesh = fragment
    batch.instance_count = 24
    batch.custom_aabb = AABB(Vector3(-8,-8,-8),Vector3(16,16,16))
    sparks.multimesh = batch
    sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(sparks)
    smoke = MultiMeshInstance3D.new()
    var cloud_batch: MultiMesh = MultiMesh.new()
    cloud_batch.transform_format = MultiMesh.TRANSFORM_3D
    var puff: SphereMesh = SphereMesh.new()
    puff.radius = 1.0
    puff.height = 2.0
    puff.radial_segments = 10
    puff.rings = 5
    cloud_batch.mesh = puff
    cloud_batch.instance_count = 6
    cloud_batch.custom_aabb = AABB(Vector3(-8,-8,-8),Vector3(16,16,16))
    smoke.multimesh = cloud_batch
    smoke_material = ShaderMaterial.new()
    smoke_material.shader = preload("res://assets/vfx/jutsu_smoke.gdshader")
    smoke.material_override = smoke_material
    smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(smoke)
    set_quality(quality)
    visible = false

func set_quality(level: int) -> void:
    quality = clampi(level,0,2)
    if sparks != null:
        sparks.multimesh.visible_instance_count = [8,16,24][quality]
        smoke.multimesh.visible_instance_count = [2,4,6][quality]

func activate(origin: Vector3, element: String, size: float, direction: Vector3) -> void:
    global_position = origin
    kind = element
    radius = clampf(size,.35,2.2)
    heading = direction.normalized() if direction.length_squared() > .001 else Vector3.BACK
    duration = .32 if kind in ["lightning","steel","taijutsu","bone"] else .6 if kind in ["water","sand","earth","oil"] else .48
    clock = 0.0
    scale = Vector3.ONE
    shell_material.set_shader_parameter("energy_color",RosterVisualStyle.color(kind))
    shell_material.set_shader_parameter("fire_mode",kind in ["fire","black_fire"])
    shell_material.set_shader_parameter("dark_mode",kind in ["black_fire","shadow"])
    ring_material.albedo_color = RosterVisualStyle.color(kind).lightened(.2)
    smoke_material.set_shader_parameter("smoke_color",Color("645443") if kind in ["earth","sand"] else Color("30343b"))
    ring.position.y = -origin.y + .035
    active = true
    visible = true
    update_visual(0.0)

func _process(delta: float) -> void:
    if active:
        update_visual(delta)

func update_visual(delta: float) -> void:
    clock += delta
    var progress: float = clampf(clock/duration,0.0,1.0)
    if progress >= 1.0:
        recycle()
        return
    var color: Color = RosterVisualStyle.color(kind)
    shell_material.set_shader_parameter("progress",progress)
    var expansion: float = radius * (.25 + sin(progress*PI*.5)*.9)
    shell.scale = Vector3.ONE * expansion
    if kind in ["fire","black_fire"]: shell.scale.y *= 1.3
    elif kind == "water": shell.scale *= Vector3(1.0,.7,1.0)
    elif kind in ["wind","susanoo","shadow"]: shell.scale.y *= .18
    shell.visible = quality > 0 or kind in ["fire","black_fire","water","chakra"]
    ring.visible = kind not in ["mind","insect","steel","bone"] and global_position.y < 2.2
    ring.scale = Vector3(radius*(.3+progress*1.65),.15,radius*(.3+progress*1.65))
    ring_material.albedo_color.a = (1.0-progress)*.65
    smoke.visible = kind in ["fire","black_fire","earth","sand","oil","chakra"]
    smoke_material.set_shader_parameter("progress",progress)
    for index: int in range(smoke.multimesh.visible_instance_count):
        var angle: float = float(index)*2.399963
        var distance: float = radius*(.3+progress*.7)
        var offset: Vector3 = Vector3(cos(angle)*distance,progress*radius*.75,sin(angle)*distance)
        var size: float = radius*(.15+progress*.35)
        smoke.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*size),offset))
    var frame: Basis = Basis(Quaternion(Vector3.BACK,heading))
    for index: int in range(sparks.multimesh.visible_instance_count):
        var angle: float = float(index)*2.399963
        var lift: float = .3 + float(index%5)*.17
        var travel: float = radius*progress*(1.3+float(index%3)*.25)
        var offset: Vector3 = Vector3(cos(angle)*travel,lift*radius*sin(progress*PI)-progress*progress*.25,sin(angle)*travel)
        if kind == "lightning": offset = frame * Vector3(offset.x,offset.z*.6,offset.y)
        var size: float = radius*(.055 if kind in ["lightning","steel","wind"] else .08)*(1.0-progress)
        var proportions: Vector3 = Vector3(.45,.45,2.8) if kind in ["lightning","steel","wind"] else Vector3(.6,1.4,.6) if kind in ["fire","black_fire","water"] else Vector3.ONE
        sparks.multimesh.set_instance_transform(index,Transform3D(frame.scaled_local(proportions*maxf(.001,size)),offset))
        sparks.multimesh.set_instance_color(index,color.lightened(.45 if index%3 == 0 and kind != "black_fire" else .06))

func recycle() -> void:
    active = false
    visible = false
    clock = 0.0
