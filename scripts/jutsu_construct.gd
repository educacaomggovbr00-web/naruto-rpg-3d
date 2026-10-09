extends Node3D
## Original articulated technique models. Rigid pieces follow real skeleton bones.
## One reusable skeleton per visual; no nodes, materials or meshes allocated per frame.
var skeleton: Skeleton3D
var attachments: Array[BoneAttachment3D] = []
var kind: String = ""
var clock: float = 0.0
var quality: int = 1
var body_material: StandardMaterial3D
var detail_material: StandardMaterial3D
var eye_material: StandardMaterial3D
var segments: int = 0

func _ready() -> void:
    skeleton = Skeleton3D.new()
    add_child(skeleton)
    body_material = _material(Color("5b9fae"), false)
    detail_material = _material(Color("e9dac0"), false)
    eye_material = _material(Color("fff0aa"), true)
    visible = false

func _material(color: Color, glowing: bool) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = .65
    material.emission_enabled = glowing
    material.emission = color
    material.emission_energy_multiplier = .45 if glowing else 0.0
    return material

func configure(model_kind: String, color: Color) -> void:
    clock = 0.0
    body_material.albedo_color = color.darkened(.18)
    body_material.emission_enabled = model_kind == "dragon"
    body_material.emission = color
    body_material.emission_energy_multiplier = .28
    detail_material.albedo_color = color.lightened(.35) if model_kind == "dragon" else Color("c5b294")
    if kind != model_kind:
        for attachment: BoneAttachment3D in attachments:
            skeleton.remove_child(attachment)
            attachment.queue_free()
        attachments.clear()
        skeleton.clear_bones()
        kind = model_kind
        if kind in ["dragon", "snake"]:
            _serpent()
        elif kind == "shark":
            _shark()
        elif kind == "puppet":
            _puppet()
        elif kind == "sand_hand":
            _hand()
    skeleton.reset_bone_poses()
    visible = true
    animate(0.0)

func _bone(label: String, parent: int, offset: Vector3) -> int:
    var index: int = skeleton.get_bone_count()
    skeleton.add_bone(label)
    skeleton.set_bone_parent(index,parent)
    skeleton.set_bone_rest(index,Transform3D(Basis.IDENTITY,offset))
    skeleton.set_bone_pose_position(index,offset)
    var attachment: BoneAttachment3D = BoneAttachment3D.new()
    attachment.bone_name = label
    skeleton.add_child(attachment)
    attachments.append(attachment)
    return index

func _piece(bone: int, size: Vector3, offset: Vector3, shape: String = "ball", detail: bool = false) -> MeshInstance3D:
    var node: MeshInstance3D = MeshInstance3D.new()
    if shape == "box":
        var box: BoxMesh = BoxMesh.new()
        box.size = Vector3.ONE
        node.mesh = box
    elif shape == "cone":
        var cone: CylinderMesh = CylinderMesh.new()
        cone.top_radius = 0.0
        cone.bottom_radius = .5
        cone.height = 1.0
        cone.radial_segments = 6
        node.mesh = cone
    else:
        var sphere: SphereMesh = SphereMesh.new()
        sphere.radius = .5
        sphere.height = 1.0
        sphere.radial_segments = 10
        sphere.rings = 5
        node.mesh = sphere
    node.scale = size
    node.position = offset
    node.material_override = detail_material if detail else body_material
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    attachments[bone].add_child(node)
    return node

func _serpent() -> void:
    segments = 12
    for index: int in range(segments):
        var bone: int = _bone("Spine_%02d" % index,index-1,Vector3.ZERO if index == 0 else Vector3(0,0,-.32))
        var width: float = lerpf(.65,.12,float(index)/float(segments-1))
        _piece(bone,Vector3(width,width*.82,.47),Vector3.ZERO)
        if kind == "dragon" and index > 0 and index < 9:
            _piece(bone,Vector3(.13,.3,.15),Vector3(0,width*.45,0),"cone",true)
    _piece(0,Vector3(.75,.4,.8),Vector3(0,.06,.28))
    var jaw: int = _bone("Jaw",0,Vector3(0,-.19,.16))
    _piece(jaw,Vector3(.6,.12,.65),Vector3(0,0,.2),"box",true)
    for side: float in [-1.0,1.0]:
        var eye: MeshInstance3D = _piece(0,Vector3(.13,.13,.12),Vector3(side*.31,.17,.39))
        eye.material_override = eye_material
        _piece(0,Vector3(.08,.24,.09),Vector3(side*.19,-.03,.55),"cone",true).rotation.z = PI
        if kind == "dragon":
            _piece(0,Vector3(.16,.62,.18),Vector3(side*.27,.4,-.08),"cone",true).rotation.z = side*-.3
            var whisker: MeshInstance3D = _piece(0,Vector3(.045,.045,.9),Vector3(side*.48,.02,.08),"box",true)
            whisker.rotation.y = side*.9

func _puppet() -> void:
    segments = 0
    var root_bone: int = _bone("Torso",-1,Vector3.ZERO)
    _piece(root_bone,Vector3(.6,.8,.35),Vector3.ZERO,"box")
    for index: int in range(3):
        _piece(root_bone,Vector3(.65,.05,.4),Vector3(0,float(index-1)*.23,0),"box",true)
    var head: int = _bone("Head",0,Vector3(0,.6,0))
    _piece(head,Vector3(.48,.48,.42),Vector3.ZERO)
    _piece(head,Vector3(.43,.09,.06),Vector3(0,-.07,.23),"box",true)
    for side: float in [-1.0,1.0]:
        var eye: MeshInstance3D = _piece(head,Vector3(.09,.08,.04),Vector3(side*.13,.08,.23),"box")
        eye.material_override = eye_material
        var arm: int = _bone("Arm_"+str(side),0,Vector3(side*.42,.23,0))
        _piece(arm,Vector3(.19,.52,.19),Vector3(0,-.24,0),"box")
        var forearm: int = _bone("Forearm_"+str(side),arm,Vector3(0,-.5,0))
        _piece(forearm,Vector3(.16,.5,.16),Vector3(0,-.23,0),"box",true)
        _piece(forearm,Vector3(.22,.22,.22),Vector3(0,-.48,0))
        var thigh: int = _bone("Leg_"+str(side),0,Vector3(side*.18,-.45,0))
        _piece(thigh,Vector3(.18,.5,.18),Vector3(0,-.24,0),"box")
        var shin: int = _bone("Shin_"+str(side),thigh,Vector3(0,-.5,0))
        _piece(shin,Vector3(.16,.45,.16),Vector3(0,-.22,0),"box",true)
        _piece(shin,Vector3(.22,.14,.35),Vector3(0,-.47,.08),"box")

func _hand() -> void:
    segments = 0
    var palm: int = _bone("Palm",-1,Vector3.ZERO)
    _piece(palm,Vector3(.95,.35,.9),Vector3.ZERO)
    for index: int in range(5):
        var finger: int = _bone("Finger_%d" % index,0,Vector3(float(index-2)*.2,0,.38))
        _piece(finger,Vector3(.18,.22,.48),Vector3(0,0,.2))
        var tip: int = _bone("Tip_%d" % index,finger,Vector3(0,0,.4))
        _piece(tip,Vector3(.16,.19,.4),Vector3(0,0,.17))

func animate(delta: float) -> void:
    clock += delta
    if kind in ["dragon","snake"]:
        for index: int in range(segments):
            var angle: float = sin(clock*7.0-float(index)*.55)*(.14 if kind == "dragon" else .22)
            skeleton.set_bone_pose_rotation(index,Quaternion(Vector3.UP,angle)*Quaternion(Vector3.RIGHT,sin(clock*5.0-float(index)*.4)*.07))
        skeleton.set_bone_pose_rotation(segments,Quaternion(Vector3.RIGHT,-.12-.18*(.5+.5*sin(clock*9.0))))
    elif kind == "shark":
        skeleton.set_bone_pose_rotation(2,Quaternion(Vector3.UP,sin(clock*9.0)*.4))
        skeleton.set_bone_pose_rotation(1,Quaternion(Vector3.RIGHT,-.12-.2*(.5+.5*sin(clock*7.0))))
    elif kind == "puppet":
        for index: int in range(2,skeleton.get_bone_count()):
            skeleton.set_bone_pose_rotation(index,Quaternion(Vector3.RIGHT,sin(clock*9.0+float(index)*.8)*.65)*Quaternion(Vector3.BACK,.15 if index%4 == 2 else -.15))
        skeleton.set_bone_pose_rotation(1,Quaternion(Vector3.UP,sin(clock*4.0)*.3))
    elif kind == "sand_hand":
        for index: int in range(1,skeleton.get_bone_count()):
            skeleton.set_bone_pose_rotation(index,Quaternion(Vector3.RIGHT,-(.35+.6*(.5+.5*sin(clock*6.0))) if index%2 == 0 else -.25))
    skeleton.force_update_all_bone_transforms()

func set_quality(level: int) -> void:
    quality = clampi(level,0,2)
    # Geometry remains recognizable on LOW; secondary horns/spines can be hidden.
    for index: int in range(attachments.size()):
        if kind == "dragon" and index > 0 and index < 9:
            for child: Node in attachments[index].get_children():
                if child is MeshInstance3D and child.mesh is CylinderMesh:
                    child.visible = quality > 0

func _shark() -> void:
    segments = 0
    var body: int = _bone("Body",-1,Vector3.ZERO)
    _piece(body,Vector3(.85,.75,1.9),Vector3.ZERO)
    _piece(body,Vector3(.72,.35,.7),Vector3(0,-.1,.8))
    var jaw: int = _bone("Jaw",0,Vector3(0,-.24,.6))
    _piece(jaw,Vector3(.62,.15,.6),Vector3(0,0,.12),"box",true)
    _piece(body,Vector3(.13,.8,.65),Vector3(0,.5,-.15),"cone")
    for side: float in [-1.0,1.0]:
        var fin: MeshInstance3D = _piece(body,Vector3(.17,.85,.45),Vector3(side*.65,-.13,.05),"cone")
        fin.rotation.z = side*-1.15
        var eye: MeshInstance3D = _piece(body,Vector3(.1,.1,.12),Vector3(side*.32,.16,.65))
        eye.material_override = eye_material
        for index: int in range(3):
            _piece(body,Vector3(.025,.23,.04),Vector3(side*.4,-.02,.2-float(index)*.12),"box",true)
    var tail: int = _bone("Tail",0,Vector3(0,0,-1.05))
    _piece(tail,Vector3(.28,.28,.75),Vector3(0,0,-.23))
    _piece(tail,Vector3(.14,1.1,.45),Vector3(0,0,-.58),"cone").rotation.x = .35
