extends Node3D
## Original pooled presentation. No gameplay collision or per-frame allocation.
const CORE_SHADER = preload("res://assets/vfx/elemental_core.gdshader")
var element: String = "chakra"
var radius: float = 0.4
var heading: Vector3 = Vector3.BACK
var clock: float = 0.0
var form: String = "orb"
var burst: bool = false
var quality: int = 1
var core: MeshInstance3D
var mesh_bank: Dictionary = {}
var core_material: ShaderMaterial
var motes: MultiMeshInstance3D
var rings: Array[MeshInstance3D] = []
var tail_tip: Vector3 = Vector3.ZERO
var tint: Color = Color.CYAN

func _ready() -> void:
    core = MeshInstance3D.new()
    var ball = SphereMesh.new()
    ball.radius = 1.0
    ball.height = 2.0
    ball.radial_segments = 20
    ball.rings = 10
    mesh_bank["orb"] = ball
    var blade = BoxMesh.new()
    blade.size = Vector3(.22,.22,2.0)
    mesh_bank["blade"] = blade
    var spike = CylinderMesh.new()
    spike.top_radius = 0
    spike.bottom_radius = 1
    spike.height = 2
    spike.radial_segments = 8
    mesh_bank["spike"] = spike
    core.mesh = ball
    core_material = ShaderMaterial.new()
    core_material.shader = CORE_SHADER
    core.material_override = core_material
    core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(core)
    motes = MultiMeshInstance3D.new()
    var batch = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.use_colors = true
    var mote = SphereMesh.new()
    mote.radius = 1.0
    mote.height = 2.0
    mote.radial_segments = 6
    mote.rings = 3
    var material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    mote.material = material
    batch.mesh = mote
    batch.instance_count = 16
    batch.custom_aabb = AABB(Vector3(-5,-5,-5), Vector3(10,10,10))
    motes.multimesh = batch
    motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(motes)
    for index in range(2):
        var ring = MeshInstance3D.new()
        var torus = TorusMesh.new()
        torus.inner_radius = .93
        torus.outer_radius = 1.0
        torus.rings = 24
        torus.ring_segments = 6
        ring.mesh = torus
        ring.material_override = StandardMaterial3D.new()
        ring.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(ring)
        rings.append(ring)
    set_quality(quality)
    visible = false

func configure(kind: String, size: float, radial: bool = false, shape: String = "orb") -> void:
    var scene: Node = get_tree().current_scene
    if scene != null:
        var mobile: Node = scene.get_node_or_null("MobileQuality")
        if mobile != null:
            set_quality(mobile.level)
    scale = Vector3.ONE
    element = kind
    radius = clampf(size, .12, 3.2)
    burst = radial
    form = shape
    clock = 0.0
    tint = RosterVisualStyle.color(kind)
    core.mesh = mesh_bank["spike"] if kind == "bone" else mesh_bank["blade"] if kind in ["steel","puppet","susanoo"] else mesh_bank["orb"]
    core_material.set_shader_parameter("solid_mode", kind in ["steel","iron","bone","puppet"])
    core_material.set_shader_parameter("grain_mode", kind in ["sand","earth","oil"])
    core_material.set_shader_parameter("energy_color", tint)
    core_material.set_shader_parameter("fire_mode", kind in ["fire", "black_fire"])
    core_material.set_shader_parameter("dark_mode", kind in ["black_fire", "shadow"])
    for ring in rings:
        ring.material_override.albedo_color = tint.lightened(.25)
    visible = true
    update_visual(0.0)

func set_quality(level: int) -> void:
    quality = clampi(level,0,2)
    if motes != null:
        motes.multimesh.visible_instance_count = [6,10,16][quality]

func _physics_process(delta: float) -> void:
    if is_visible_in_tree():
        update_visual(delta)

func update_visual(delta: float) -> void:
    clock += delta
    core_material.set_shader_parameter("phase",clock)
    core.visible = not burst and element != "insect"
    core.scale = Vector3.ONE * radius * (1.0 + sin(clock * 19.0) * .035)
    core.rotation = Vector3.ZERO
    if form == "wave":
        core.basis = Basis(Quaternion(Vector3.BACK, heading.normalized()))
        core.scale = Vector3(radius*1.7,radius*.55,radius*.7)
    var forward: Vector3 = heading.normalized() if heading.length_squared() > .001 else Vector3.BACK
    if element in ["steel","puppet","susanoo"]:
        core.basis = Basis(Quaternion(Vector3.BACK,forward))
        core.scale = Vector3(radius*.55,radius*.55,radius*1.6)
        if element == "susanoo": core.scale.x *= 4.0
    elif element == "bone":
        core.basis = Basis(Quaternion(Vector3.UP,forward))
        core.scale = Vector3(radius*.18,radius*1.6,radius*.18)
    elif element == "shadow":
        core.scale = Vector3(radius*1.2,radius*.055,radius*1.7)
    elif element == "snake":
        core.basis = Basis(Quaternion(Vector3.BACK,forward))
        core.scale = Vector3(radius*.48,radius*.48,radius*.8)
    elif element == "wind":
        core.scale *= Vector3(1.25,.16,1.25)
    elif element == "water":
        core.basis = Basis(Quaternion(Vector3.BACK,forward))
        core.scale *= Vector3(.85,.85,1.35)
    if burst and clock >= .38:
        visible = false
        return
    var phase: float = clampf(clock / .38,0,1)
    var axis: Vector3 = heading.normalized() if heading.length_squared() > .001 else Vector3.BACK
    var frame: Basis = Basis(Quaternion(Vector3.BACK,axis))
    for index in range(motes.multimesh.visible_instance_count):
        var ratio: float = float(index + 1) / float(motes.multimesh.visible_instance_count)
        var angle: float = index * 2.399 + clock * (7.0 if element != "fire" else 3.0)
        var offset: Vector3
        var size: float
        if burst:
            offset = Vector3(cos(angle),.1 + sin(angle*2.0)*.12,sin(angle)) * radius * phase
            size = .12 * (1.0 - phase)
        else:
            offset = frame * Vector3(cos(angle)*radius*(1.3 if form == "wave" else .3)*ratio,sin(angle)*radius*.3*ratio,-radius*(.6+ratio*2.8))
            if element in ["fire", "black_fire"]: offset.y += ratio * radius * .5
            elif element == "insect":
                offset = frame * Vector3(cos(angle)*radius*.85,sin(angle*1.7)*radius*.6,-radius*(.5+ratio*1.6))
            elif element == "snake":
                offset = frame * Vector3(sin(clock*12.0-ratio*8.0)*radius*.45,0,-radius*(.4+ratio*3.0))
            elif element == "shadow": offset.y *= .06
            size = radius * (.25 - ratio*.09) if element in ["snake","insect","sand","earth"] else radius * (.22 - ratio*.16)
        if index == motes.multimesh.visible_instance_count - 1:
            tail_tip = offset
        motes.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * maxf(.001,size)),offset))
        var color: Color = tint.lerp(Color(1,.8,.25),1.0-ratio) if element == "fire" else tint.lightened((1.0-ratio)*.35)
        motes.multimesh.set_instance_color(index,color)
    for index in range(rings.size()):
        var ring: MeshInstance3D = rings[index]
        ring.visible = (burst or element in ["chakra","wind","water","mind","lightning","susanoo"]) and (quality > 0 or index == 0)
        ring.rotation = Vector3(0,clock*3,0) if burst else Vector3(clock*2.0+index*1.3,clock*3,clock)
        var size: float = radius * (phase * (1.0 if index == 0 else .76)) if burst else radius * (1.12+index*.14)
        ring.scale = Vector3.ONE * maxf(.001,size)
