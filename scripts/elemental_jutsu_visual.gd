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
var ribbons: Array[MeshInstance3D] = []
var ribbon_materials: Array[ShaderMaterial] = []
var profile: String = "energy"
var technique_id: String = ""
var weapons: Node3D
var construct: Node3D
var signature: Node3D

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
    mesh_bank["crescent"] = _crescent_mesh()
    var rock: SphereMesh = SphereMesh.new()
    rock.radius = 1.0
    rock.height = 2.0
    rock.radial_segments = 8
    rock.rings = 4
    mesh_bank["rock"] = rock
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
    var strip: PlaneMesh = PlaneMesh.new()
    strip.size = Vector2(2.0, 1.0)
    strip.subdivide_width = 2
    strip.subdivide_depth = 16
    for index: int in range(2):
        var ribbon: MeshInstance3D = MeshInstance3D.new()
        ribbon.mesh = strip
        ribbon.custom_aabb = AABB(Vector3(-4,-4,-10),Vector3(8,8,12))
        var ribbon_material: ShaderMaterial = ShaderMaterial.new()
        ribbon_material.shader = preload("res://assets/vfx/jutsu_ribbon.gdshader")
        ribbon_material.set_shader_parameter("seed", float(index) * 2.4)
        ribbon.material_override = ribbon_material
        ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(ribbon)
        ribbons.append(ribbon)
        ribbon_materials.append(ribbon_material)
    weapons = Node3D.new()
    add_child(weapons)
    var tools: Script = preload("res://scripts/licensed_ninja_tools.gd")
    for index: int in range(3):
        var weapon: MeshInstance3D = tools.create(tools.KUNAI if index == 1 else tools.SHURIKEN,.75)
        weapon.position += Vector3(float(index-1)*.55,0,float(index%2)*.3)
        weapons.add_child(weapon)
    construct = Node3D.new()
    construct.set_script(preload("res://scripts/jutsu_construct.gd"))
    add_child(construct)
    signature = Node3D.new()
    signature.set_script(preload("res://scripts/jutsu_signature.gd"))
    add_child(signature)
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
    technique_id = ""
    clock = 0.0
    construct.visible = false
    tint = RosterVisualStyle.color(kind)
    core_material.shader = preload("res://assets/vfx/elemental_volume.gdshader") if kind in ["fire","black_fire","water"] else CORE_SHADER
    profile = {"fire":"flame", "black_fire":"flame", "water":"stream", "wind":"crescent", "lightning":"electric", "sand":"grains", "earth":"grains", "oil":"grains", "insect":"swarm", "snake":"serpent", "shadow":"shadow", "steel":"weapon", "iron":"weapon", "bone":"weapon", "puppet":"weapon", "susanoo":"slash", "taijutsu":"crescent", "mind":"spiral"}.get(kind,"spiral")
    core.mesh = mesh_bank["spike"] if kind == "bone" else mesh_bank["blade"] if kind in ["steel","iron","puppet","susanoo"] else mesh_bank["orb"]
    if profile == "crescent":
        core.mesh = mesh_bank["crescent"]
    elif kind in ["earth","sand","oil"]:
        core.mesh = mesh_bank["rock"]
    core_material.set_shader_parameter("solid_mode", kind in ["steel","iron","bone","puppet"])
    core_material.set_shader_parameter("grain_mode", kind in ["sand","earth","oil"])
    core_material.set_shader_parameter("energy_color", tint)
    core_material.set_shader_parameter("fire_mode", kind in ["fire", "black_fire"])
    core_material.set_shader_parameter("dark_mode", kind in ["black_fire", "shadow"])
    for ring in rings:
        ring.material_override.albedo_color = tint.lightened(.25)
    for material: ShaderMaterial in ribbon_materials:
        material.set_shader_parameter("energy_color", tint)
        material.set_shader_parameter("fire_mode", kind in ["fire","black_fire"])
        material.set_shader_parameter("dark_mode", kind in ["black_fire","shadow"])
    signature.configure("",kind,radius,radial)
    visible = true
    update_visual(0.0)

func configure_jutsu(data: JutsuDefinition, size: float, radial: bool = false) -> void:
    var shape: String = "wave" if data.jutsu_id == "henrique_katon_wave" else "dragon" if data.jutsu_id.contains("dragon") and data.effect in ["water","fire"] else "orb"
    configure(data.effect,size,radial,shape)
    technique_id = data.jutsu_id
    signature.configure(technique_id,data.effect,radius,radial)
    var model: String = "shark" if technique_id.contains("shark") else "dragon" if technique_id.contains("dragon") and data.effect in ["fire","water","earth"] else "snake" if data.effect == "snake" else "puppet" if data.effect == "puppet" else "sand_hand" if data.effect == "sand" else ""
    if not model.is_empty():
        construct.configure(model,tint)
        construct.set_quality(quality)
    update_visual(0.0)

func set_quality(level: int) -> void:
    quality = clampi(level,0,2)
    if signature != null:
        signature.set_quality(quality)
    if construct != null:
        construct.set_quality(quality)
    if motes != null:
        motes.multimesh.visible_instance_count = [6,10,16][quality]

func _physics_process(delta: float) -> void:
    if is_visible_in_tree():
        update_visual(delta)

func update_visual(delta: float) -> void:
    clock += delta
    var forward: Vector3 = heading.normalized() if heading.length_squared() > .001 else Vector3.BACK
    if construct.visible:
        construct.quaternion = Quaternion(Vector3.BACK,forward)
        construct.scale = Vector3.ONE * radius * (1.35 if construct.kind == "puppet" else 1.65)
        construct.animate(delta)
    signature.radius = radius
    signature.update_visual(delta,forward)
    core_material.set_shader_parameter("phase",clock)
    core.visible = not burst and element != "insect"
    weapons.visible = element == "steel" and not burst
    if weapons.visible:
        core.visible = false
        weapons.basis = Basis(Quaternion(Vector3.BACK,forward)) * Basis(Vector3.UP,clock*10.0)
        weapons.scale = Vector3.ONE * radius
    core.scale = Vector3.ONE * radius * (1.0 + sin(clock * 19.0) * .035)
    core.rotation = Vector3.ZERO
    if form == "wave":
        core.quaternion = Quaternion(Vector3.BACK,forward)
        core.scale = Vector3(radius*1.7,radius*.55,radius*.7)
    if element in ["steel","iron","puppet","susanoo"]:
        core.quaternion = Quaternion(Vector3.BACK,forward)
        core.scale = Vector3(radius*.55,radius*.55,radius*1.6)
        if element == "susanoo": core.scale.x *= 4.0
    elif element == "bone":
        core.quaternion = Quaternion(Vector3.UP,forward)
        core.scale = Vector3(radius*.18,radius*1.6,radius*.18)
    elif element == "shadow":
        core.scale = Vector3(radius*1.2,radius*.055,radius*1.7)
    elif element == "snake":
        core.quaternion = Quaternion(Vector3.BACK,forward)
        core.scale = Vector3(radius*.48,radius*.48,radius*.8)
    elif element == "wind":
        core.scale *= Vector3(1.25,.16,1.25)
    elif element == "water":
        core.quaternion = Quaternion(Vector3.BACK,forward)
        core.scale *= Vector3(.85,.85,1.35)
    elif element in ["sand","earth","oil"]:
        core.scale *= .7
    if form == "dragon" and not burst:
        core.quaternion = Quaternion(Vector3.BACK,forward)
        core.scale = Vector3(radius*.65,radius*.7,radius*1.65)
    if burst and clock >= .38:
        visible = false
        return
    var phase: float = clampf(clock / .38,0,1)
    var axis: Vector3 = heading.normalized() if heading.length_squared() > .001 else Vector3.BACK
    var frame: Basis = Basis(Quaternion(Vector3.BACK,axis))
    if element in ["fire","black_fire"] and form != "wave" and not burst:
        core.quaternion = frame.get_rotation_quaternion()
        core.scale *= Vector3(.85,.85,1.15)
    for index: int in range(ribbons.size()):
        var ribbon: MeshInstance3D = ribbons[index]
        ribbon.visible = not burst and profile not in ["weapon","swarm","shadow","grains"] and (index == 0 or quality > 0)
        ribbon.basis = frame * Basis(Vector3.BACK, float(index)*PI*.5)
        ribbon.position = -axis * radius * .25
        var material: ShaderMaterial = ribbon_materials[index]
        material.set_shader_parameter("phase",clock)
        material.set_shader_parameter("width",radius * (1.1 if form == "wave" else .8 if profile == "flame" else .45))
        material.set_shader_parameter("length_scale",radius*(5.2 if form == "dragon" else 4.2 if profile in ["flame","stream"] else 3.0))
        material.set_shader_parameter("rise",radius*.7 if profile == "flame" else 0.0)
        material.set_shader_parameter("opacity",.8 if profile == "flame" else .5)
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
            elif form == "dragon":
                offset = frame * Vector3(sin(clock*8.0-ratio*7.0)*radius*.35,sin(ratio*8.0-clock*6.0)*radius*.3,-radius*(.5+ratio*3.2))
            elif element == "shadow": offset.y *= .06
            size = radius * (.25 - ratio*.09) if element in ["snake","insect","sand","earth"] else radius * (.22 - ratio*.16)
        if index == motes.multimesh.visible_instance_count - 1:
            tail_tip = offset
        var particle_shape: Vector3 = Vector3.ONE * maxf(.001,size)
        if profile == "flame": particle_shape *= Vector3(.7,1.8,.7)
        elif profile == "stream": particle_shape *= Vector3(.6,.6,2.0)
        elif profile == "electric": particle_shape *= Vector3(.3,.3,2.8)
        elif profile == "swarm": particle_shape *= Vector3(1.0,.35,.65)
        elif profile == "serpent": particle_shape *= Vector3(1.0,1.0,1.8)
        motes.multimesh.set_instance_transform(index,Transform3D(frame.scaled_local(particle_shape),offset))
        var color: Color = tint.lerp(Color(1,.8,.25),1.0-ratio) if element == "fire" else tint.lightened((1.0-ratio)*.35)
        motes.multimesh.set_instance_color(index,color)
    if signature.pattern in ["beetles","beetle_prison","shadow_path","shadow_needles","bone_field","scalpel","phoenix"] or (signature.pattern == "palms" and not technique_id.is_empty()):
        core.visible = false
        motes.visible = false
    else:
        motes.visible = true
    if construct.visible:
        core.visible = false
        weapons.visible = false
    for index in range(rings.size()):
        var ring: MeshInstance3D = rings[index]
        ring.visible = (burst or element in ["chakra","mind","lightning"]) and (quality > 0 or index == 0)
        ring.rotation = Vector3(0,clock*3,0) if burst else Vector3(clock*2.0+index*1.3,clock*3,clock)
        var size: float = radius * (phase * (1.0 if index == 0 else .76)) if burst else radius * (1.12+index*.14)
        ring.scale = Vector3.ONE * maxf(.001,size)

func _crescent_mesh() -> ArrayMesh:
    var vertices: PackedVector3Array = []
    var normals: PackedVector3Array = []
    var uv: PackedVector2Array = []
    var indices: PackedInt32Array = []
    for index: int in range(25):
        var t: float = float(index)/24.0
        var angle: float = lerpf(-1.65,1.65,t)
        var thickness: float = sin(t*PI)*.42
        for r: float in [1.0-thickness,1.0]:
            vertices.append(Vector3(cos(angle)*r,0,sin(angle)*r))
            normals.append(Vector3.UP)
            uv.append(Vector2(r,t))
        if index < 24:
            var start: int = index*2
            indices.append_array(PackedInt32Array([start,start+1,start+2,start+1,start+3,start+2]))
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uv
    arrays[Mesh.ARRAY_INDEX] = indices
    var mesh: ArrayMesh = ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return mesh
