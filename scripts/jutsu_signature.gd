extends Node3D
## Original technique accents. Fixed geometry; purely visual, never a hitbox.
const PATTERNS: Dictionary = {
    "wind_scythe":"sickle", "great_sickle_wind":"sickle",
    "phoenix_flower":"phoenix", "henrique_katon_wave":"fan", "henrique_nagashi":"electric_field",
    "henrique_genjutsu":"illusion", "shadow_bind":"shadow_path", "shadow_sewing":"shadow_needles",
    "rotation":"dome", "protective_palms":"dome", "water_prison":"prison",
    "sixty_four_palms":"palms", "gentle_fist":"palms", "chakra_scalpel":"scalpel", "nerve_rupture":"scalpel",
    "chakra_flower_burst":"petals", "cherry_blossom_impact":"petals",
    "bone_dance":"bone_field", "clematis_dance":"bone_spear", "twin_dragons":"arsenal",
    "fang_over_fang":"drill", "beast_combo":"drill", "primary_lotus":"lotus",
    "leaf_whirlwind":"lotus", "leaf_hurricane":"lotus", "dynamic_entry":"speed",
    "insect_swarm":"beetles", "beetle_sphere":"beetle_prison", "poison_puppet":"poison",
    "sand_coffin":"sand_wrap", "sand_burial":"sand_sink", "ground_smash":"fissure",
    "heaven_kick":"fissure", "human_boulder":"boulder", "partial_expansion":"boulder"
}
var technique_id: String = ""
var pattern: String = ""
var element: String = "chakra"
var radius: float = .4
var clock: float = 0.0
var quality: int = 1
var radial: bool = false
var particles: MultiMeshInstance3D
var dome: MeshInstance3D
var mesh_bank: Dictionary = {}
var dome_material: StandardMaterial3D
var tint: Color = Color.CYAN

func _ready() -> void:
    var sphere: SphereMesh = SphereMesh.new()
    sphere.radius = 1.0
    sphere.height = 2.0
    sphere.radial_segments = 10
    sphere.rings = 5
    mesh_bank["orb"] = sphere
    var line: BoxMesh = BoxMesh.new()
    line.size = Vector3.ONE
    mesh_bank["line"] = line
    var cone: CylinderMesh = CylinderMesh.new()
    cone.top_radius = 0
    cone.bottom_radius = 1.0
    cone.height = 2.0
    cone.radial_segments = 8
    mesh_bank["spike"] = cone
    mesh_bank["petal"] = _silhouette(false)
    mesh_bank["beetle"] = _silhouette(true)
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    particles = MultiMeshInstance3D.new()
    var batch: MultiMesh = MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.use_colors = true
    batch.instance_count = 24
    batch.mesh = sphere
    batch.custom_aabb = AABB(Vector3(-16,-16,-16),Vector3(32,32,32))
    particles.multimesh = batch
    particles.material_override = material
    particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(particles)
    dome = MeshInstance3D.new()
    dome.mesh = sphere
    dome_material = StandardMaterial3D.new()
    dome_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    dome_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    dome_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    dome.material_override = dome_material
    dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(dome)
    set_quality(quality)
    visible = false

func configure(id: String, kind: String, size: float, burst: bool) -> void:
    technique_id = id
    element = kind
    radius = clampf(size,.12,3.2)
    radial = burst
    clock = 0.0
    dome.rotation = Vector3.ZERO
    pattern = PATTERNS.get(id, "rasengan" if id.contains("rasengan") else {"fire":"embers","black_fire":"black_flame","lightning":"electric_forks","water":"droplets","wind":"sickle","insect":"beetles","shadow":"shadow_path","bone":"bone_spear","earth":"fissure","sand":"sand_wrap","oil":"viscous","mind":"illusion","steel":"arsenal","iron":"arsenal","puppet":"strings","snake":"scales","susanoo":"slash","taijutsu":"speed","chakra":"palms"}.get(kind,"palms"))
    if radial and kind == "bone" and id.is_empty(): pattern = "bone_field"
    var mesh_kind: String = "beetle" if pattern in ["beetles","beetle_prison"] else "petal" if pattern == "petals" else "spike" if pattern in ["bone_field","bone_spear","embers","black_flame","phoenix"] else "line" if pattern in ["shadow_path","shadow_needles","electric_field","electric_forks","palms","scalpel","arsenal","drill","lotus","speed","fissure","strings","slash","fan","sickle"] else "orb"
    particles.multimesh.mesh = mesh_bank[mesh_kind]
    tint = RosterVisualStyle.color(kind)
    dome_material.albedo_color = Color(tint.r,tint.g,tint.b,.13 if pattern == "dome" else .2)
    visible = true
    update_visual(0.0,Vector3.BACK)

func set_quality(level: int) -> void:
    quality = clampi(level,0,2)
    if particles != null:
        particles.multimesh.visible_instance_count = [8,16,24][quality]

func update_visual(delta: float, heading: Vector3) -> void:
    clock += delta
    if radial and clock > .38:
        visible = false
        return
    var ground_y: float = to_local(Vector3(global_position.x,.035,global_position.z)).y
    var axis: Vector3 = heading.normalized() if heading.length_squared() > .001 else Vector3.BACK
    var frame: Basis = Basis(Quaternion(Vector3.BACK,axis))
    var progress: float = clampf(clock/.38,0.0,1.0)
    var spread: float = lerpf(.2,1.0,progress) if radial else 1.0
    var count: int = particles.multimesh.visible_instance_count
    for index: int in range(count):
        var ratio: float = float(index)/float(count)
        var angle: float = ratio*TAU+clock*5.0
        var offset: Vector3 = Vector3(cos(angle),sin(angle*1.7)*.2,sin(angle))*radius*.75*spread
        var size: Vector3 = Vector3.ONE*radius*.075
        var orientation: Basis = Basis.IDENTITY
        var color: Color = tint.lightened(.2)
        match pattern:
            "shadow_path", "shadow_needles":
                offset = frame*Vector3(sin(ratio*8.0+clock*6.0)*radius*.35,0,-ratio*radius*4.0)
                offset.y = ground_y
                size = Vector3(radius*(.08 if pattern == "shadow_path" else .04),.015,radius*.26)
                orientation = frame
                color = Color("24132f")
            "dome", "prison", "beetle_prison":
                var elevation: float = sin(ratio*PI)
                offset = Vector3(cos(angle),elevation,sin(angle))*radius*spread
                size = Vector3.ONE*radius*(.065 if pattern == "beetle_prison" else .045)
                orientation = Basis(Vector3.UP,angle)
            "beetles":
                offset = frame*Vector3(cos(angle)*radius*.9,sin(angle*2.7)*radius*.65,-ratio*radius*2.3)
                size = Vector3.ONE*radius*.12
                orientation = frame*Basis(Vector3.BACK,sin(clock*23.0+index)*.65)
                color = Color("262438").lightened(.06*float(index%3))
            "petals":
                offset = Vector3(cos(angle)*radius*spread,sin(clock*4.0+ratio*9.0)*radius*.45+.25,sin(angle)*radius*spread)
                size = Vector3.ONE*radius*.16
                orientation = Basis(Vector3.RIGHT,clock*4.0+index)*Basis(Vector3.UP,angle)
                color = Color("ff80b8").lightened(ratio*.3)
            "electric_field", "electric_forks":
                var direction: Vector3 = Vector3(cos(angle),sin(float(index)*2.3)*.4,sin(angle))
                offset = direction*radius*(.3+ratio)*spread
                size = Vector3(.018,.018,radius*.55)
                orientation = Basis(Quaternion(Vector3.BACK,direction.normalized()))
                color = Color("c5f8ff") if index%3 == 0 else tint
            "bone_field":
                offset = Vector3(cos(angle)*radius*spread,.2,sin(angle)*radius*spread)
                size = Vector3(radius*.08,radius*(.3+ratio*.55)*spread,radius*.08)
                color = Color("ebe1c7")
            "bone_spear":
                offset = frame*Vector3(cos(angle)*radius*.22,sin(angle)*radius*.22,-ratio*radius*.9)
                size = Vector3(radius*.045,radius*.75,radius*.045)
                orientation = frame*Basis(Vector3.RIGHT,PI*.5)
                color = Color("ebe1c7")
            "scalpel":
                offset = frame*Vector3((float(index%2)-.5)*radius*.32,0,float(index/2)*radius*.08)
                size = Vector3(radius*.035,radius*.07,radius*.42)
                orientation = frame
                color = Color("91ffe7")
            "sickle":
                var sweep: float = lerpf(-1.5,1.5,ratio)+clock*2.0
                offset = Vector3(cos(sweep),.1,sin(sweep))*radius*spread
                size = Vector3(radius*.025,radius*.025,radius*.22)
                orientation = Basis(Vector3.UP,-sweep)
                color = Color("c9f6ec")
            "drill", "lotus", "rasengan":
                offset = frame*Vector3(cos(angle)*radius*.8,sin(angle)*radius*.8,(ratio-.5)*radius*2.0)
                size = Vector3(radius*.03,radius*.03,radius*.35)
                orientation = frame*Basis(Vector3.BACK,angle)
            "fissure":
                offset = Vector3(cos(angle)*radius*spread,ground_y,sin(angle)*radius*spread)
                size = Vector3(radius*.035,.018,radius*.65*spread)
                orientation = Basis(Vector3.UP,-angle+PI*.5)
                color = Color("3e3028")
            "palms", "speed", "slash", "fan":
                offset = frame*Vector3(cos(angle)*radius*.65,sin(angle)*radius*.65,-ratio*radius)
                size = Vector3(radius*.03,radius*.035,radius*.65)
                orientation = frame
            "phoenix":
                var lobe: float = float(index%5)-2.0
                offset = frame*Vector3(lobe*radius*.42,sin(clock*8.0+index)*radius*.12,-float(index/5)*radius*.2)
                size = Vector3(radius*.17,radius*.35,radius*.17)
                orientation = frame*Basis(Vector3.RIGHT,PI*.5)
                color = Color("ffb438") if index%3 == 0 else Color("ed4a10")
            "embers", "black_flame":
                offset = frame*Vector3(cos(angle)*radius*.7,sin(angle)*radius*.45,-ratio*radius*2.0)
                size = Vector3(radius*.07,radius*.28,radius*.07)
                color = Color("180c22") if pattern == "black_flame" else Color("ffc25a")
            "arsenal":
                offset = frame*Vector3(cos(angle)*radius*.7,sin(angle)*radius*.7,-ratio*radius*1.7)
                size = Vector3(radius*.025,radius*.06,radius*.35)
                orientation = frame*Basis(Vector3.BACK,angle)
                color = Color("d2deea")
            "illusion":
                offset = Vector3(cos(angle),sin(angle),sin(angle*3.0)*.2)*radius*spread
                size = Vector3.ONE*radius*(.07+.03*sin(clock*8.0+index))
                color = Color("c140ff") if index%2 == 0 else Color("ff5375")
            "sand_wrap", "sand_sink":
                offset = Vector3(cos(angle)*radius*(1.0-ratio*.4),sin(ratio*PI)*radius*spread,sin(angle)*radius*(1.0-ratio*.4))
                if pattern == "sand_sink": offset.y *= 1.0-progress
                size = Vector3.ONE*radius*.11
                color = Color("c99c52").lightened(ratio*.2)
            "poison":
                offset = frame*Vector3(cos(angle)*radius*.6,sin(angle)*radius*.5,-ratio*radius*2.0)
                size = Vector3.ONE*radius*.14
                color = Color("8875a2")
            "strings":
                offset = frame*Vector3(cos(angle)*radius*.2,sin(angle)*radius*.2,-ratio*radius*2.0)
                size = Vector3(.008,.008,radius*.3)
                orientation = frame
                color = Color("87ddeb")
        particles.multimesh.set_instance_transform(index,Transform3D(orientation.scaled_local(size),offset))
        particles.multimesh.set_instance_color(index,color)
    dome.visible = pattern in ["dome","prison","boulder"]
    dome.scale = Vector3.ONE*radius*maxf(.01,spread)
    dome.position = Vector3(0,0,0)
    if pattern == "dome":
        dome.position.y = ground_y
    if pattern == "boulder":
        dome_material.albedo_color = Color(tint.r,tint.g,tint.b,.28)
        dome.rotation = Vector3(clock*9.0,clock*4.0,0)

func _silhouette(insect: bool) -> ArrayMesh:
    var vertices: PackedVector3Array = []
    var triangles: Array = [Vector3(0,.12,.8),Vector3(-.5,0,0),Vector3(0,0,-.7),Vector3(0,.12,.8),Vector3(0,0,-.7),Vector3(.5,0,0)]
    if insect:
        for side: float in [-1.0,1.0]:
            triangles.append_array([Vector3(0,.08,.3),Vector3(side*.85,.12,.1),Vector3(side*.4,0,-.45)])
            for index: int in range(3):
                var z: float = float(index-1)*.35
                triangles.append_array([Vector3(side*.3,0,z),Vector3(side*.85,0,z-.3),Vector3(side*.35,0,z-.1)])
    for vertex: Vector3 in triangles: vertices.append(vertex)
    var normals: PackedVector3Array = []
    normals.resize(vertices.size())
    normals.fill(Vector3.UP)
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    var mesh: ArrayMesh = ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return mesh
