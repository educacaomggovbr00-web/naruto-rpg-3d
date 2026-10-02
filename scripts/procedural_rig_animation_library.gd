extends RefCounted

const LIBRARY_NAME: StringName = &"proc"

static func install(animation_player: AnimationPlayer, skeleton: Skeleton3D) -> int:
    if animation_player == null or skeleton == null:
        return 0

    if animation_player.has_animation_library(LIBRARY_NAME):
        animation_player.remove_animation_library(LIBRARY_NAME)

    var library: AnimationLibrary = AnimationLibrary.new()
    var source_paths: Dictionary = _discover_bone_paths(animation_player, skeleton)

    _add_clip(library, &"idle", _build_idle(source_paths))
    _add_clip(library, &"run", _build_run(source_paths))
    _add_clip(library, &"air", _build_air(source_paths))
    _add_clip(library, &"attack_1", _build_attack_1(source_paths))
    _add_clip(library, &"attack_2", _build_attack_2(source_paths))
    _add_clip(library, &"attack_3", _build_attack_3(source_paths))
    _add_clip(library, &"attack_4", _build_attack_4(source_paths))
    _add_clip(library, &"air_attack_1", _build_air_attack_1(source_paths))
    _add_clip(library, &"air_attack_2", _build_air_attack_2(source_paths))
    _add_clip(library, &"air_attack_3", _build_air_attack_3(source_paths))
    _add_clip(library, &"air_attack_4", _build_air_attack_4(source_paths))
    _add_clip(library, &"guard", _build_guard(source_paths))
    _add_clip(library, &"dodge", _build_dodge(source_paths))
    _add_clip(library, &"chakra_dash", _build_dash(source_paths))
    _add_clip(library, &"chakra_charge", _build_charge(source_paths))
    _add_clip(library, &"jutsu", _build_jutsu(source_paths))
    _add_clip(library, &"hit", _build_hit(source_paths))
    _add_clip(library, &"defeat", _build_defeat(source_paths))

    var error: Error = animation_player.add_animation_library(LIBRARY_NAME, library)
    if error != OK:
        return 0

    return library.get_animation_list_size()

static func _add_clip(library: AnimationLibrary, name: StringName, animation: Animation) -> void:
    if animation == null:
        return
    if animation.get_track_count() <= 0:
        return
    library.add_animation(name, animation)

static func _discover_bone_paths(
    animation_player: AnimationPlayer,
    skeleton: Skeleton3D
) -> Dictionary:
    var discovered_paths: Dictionary = {}
    var result: Dictionary = {}
    var wanted: Array[String] = [
        "mixamorig:Hips",
        "mixamorig:Spine",
        "mixamorig:Spine1",
        "mixamorig:Spine2",
        "mixamorig:Neck",
        "mixamorig:Head",
        "mixamorig:LeftShoulder",
        "mixamorig:LeftArm",
        "mixamorig:LeftForeArm",
        "mixamorig:LeftHand",
        "mixamorig:RightShoulder",
        "mixamorig:RightArm",
        "mixamorig:RightForeArm",
        "mixamorig:RightHand",
        "mixamorig:LeftUpLeg",
        "mixamorig:LeftLeg",
        "mixamorig:LeftFoot",
        "mixamorig:RightUpLeg",
        "mixamorig:RightLeg",
        "mixamorig:RightFoot"
    ]

    for animation_value: String in animation_player.get_animation_list():
        var source_animation: Animation = animation_player.get_animation(StringName(animation_value))
        if source_animation == null:
            continue

        for track_index: int in range(source_animation.get_track_count()):
            if source_animation.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
                continue

            var track_path: NodePath = source_animation.track_get_path(track_index)
            var path_text: String = String(track_path)

            for bone_name: String in wanted:
                if discovered_paths.has(bone_name):
                    continue
                if path_text.ends_with(bone_name):
                    discovered_paths[bone_name] = track_path

    for bone_name: String in wanted:
        if not discovered_paths.has(bone_name):
            continue

        var bone_index: int = skeleton.find_bone(bone_name)
        if bone_index < 0:
            continue

        var rest_transform: Transform3D = skeleton.get_bone_rest(bone_index)
        var rest_rotation: Quaternion = rest_transform.basis.orthonormalized().get_rotation_quaternion()

        result[bone_name] = {
            "path": discovered_paths[bone_name],
            "rest_rotation": rest_rotation
        }

    return result

static func _animation(length: float, looping: bool) -> Animation:
    var animation: Animation = Animation.new()
    animation.length = length
    animation.step = 1.0 / 30.0
    animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
    return animation

static func _pose(
    animation: Animation,
    paths: Dictionary,
    bone_name: String,
    times: Array[float],
    degrees: Array[Vector3]
) -> void:
    if not paths.has(bone_name):
        return
    if times.size() != degrees.size():
        return

    var bone_data: Dictionary = paths[bone_name]
    var track_path: NodePath = bone_data["path"]
    var rest_rotation: Quaternion = bone_data["rest_rotation"]

    var track_index: int = animation.add_track(Animation.TYPE_ROTATION_3D)
    animation.track_set_path(track_index, track_path)

    for index: int in range(times.size()):
        var radians: Vector3 = Vector3(
            deg_to_rad(degrees[index].x),
            deg_to_rad(degrees[index].y),
            deg_to_rad(degrees[index].z)
        )
        var pose_offset: Quaternion = Quaternion.from_euler(radians)
        var final_rotation: Quaternion = (rest_rotation * pose_offset).normalized()
        animation.rotation_track_insert_key(
            track_index,
            times[index],
            final_rotation
        )

static func _v(x: float, y: float, z: float) -> Vector3:
    return Vector3(x, y, z)

static func _build_idle(paths: Dictionary) -> Animation:
    var a: Animation = _animation(1.60, true)
    var t: Array[float] = [0.0, 0.40, 0.80, 1.20, 1.60]

    _pose(a, paths, "mixamorig:Spine", t, [
        _v(0, 0, 0), _v(-2, 1, 0), _v(-4, 0, 0), _v(-2, -1, 0), _v(0, 0, 0)
    ])
    _pose(a, paths, "mixamorig:Head", t, [
        _v(0, 0, 0), _v(1, -1, 0), _v(2, 0, 0), _v(1, 1, 0), _v(0, 0, 0)
    ])
    _pose(a, paths, "mixamorig:LeftArm", t, [
        _v(0, 0, -4), _v(0, 0, -6), _v(0, 0, -5), _v(0, 0, -6), _v(0, 0, -4)
    ])
    _pose(a, paths, "mixamorig:RightArm", t, [
        _v(0, 0, 4), _v(0, 0, 6), _v(0, 0, 5), _v(0, 0, 6), _v(0, 0, 4)
    ])
    return a

static func _build_run(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.56, true)
    var t: Array[float] = [0.0, 0.14, 0.28, 0.42, 0.56]

    _pose(a, paths, "mixamorig:Spine", t, [
        _v(-9, 0, 0), _v(-12, 4, 0), _v(-9, 0, 0), _v(-12, -4, 0), _v(-9, 0, 0)
    ])
    _pose(a, paths, "mixamorig:LeftArm", t, [
        _v(0, 0, -28), _v(0, 0, 32), _v(0, 0, -28), _v(0, 0, 32), _v(0, 0, -28)
    ])
    _pose(a, paths, "mixamorig:RightArm", t, [
        _v(0, 0, 28), _v(0, 0, -32), _v(0, 0, 28), _v(0, 0, -32), _v(0, 0, 28)
    ])
    _pose(a, paths, "mixamorig:LeftUpLeg", t, [
        _v(34, 0, 0), _v(-38, 0, 0), _v(34, 0, 0), _v(-38, 0, 0), _v(34, 0, 0)
    ])
    _pose(a, paths, "mixamorig:RightUpLeg", t, [
        _v(-38, 0, 0), _v(34, 0, 0), _v(-38, 0, 0), _v(34, 0, 0), _v(-38, 0, 0)
    ])
    _pose(a, paths, "mixamorig:LeftLeg", t, [
        _v(18, 0, 0), _v(42, 0, 0), _v(18, 0, 0), _v(42, 0, 0), _v(18, 0, 0)
    ])
    _pose(a, paths, "mixamorig:RightLeg", t, [
        _v(42, 0, 0), _v(18, 0, 0), _v(42, 0, 0), _v(18, 0, 0), _v(42, 0, 0)
    ])
    return a

static func _build_air(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.70, true)
    var t: Array[float] = [0.0, 0.35, 0.70]

    _pose(a, paths, "mixamorig:Spine", t, [_v(-8, 0, 0), _v(-13, 0, 0), _v(-8, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(0, 0, -30), _v(0, 0, -42), _v(0, 0, -30)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(0, 0, 30), _v(0, 0, 42), _v(0, 0, 30)])
    _pose(a, paths, "mixamorig:LeftUpLeg", t, [_v(25, 0, 0), _v(38, 0, 0), _v(25, 0, 0)])
    _pose(a, paths, "mixamorig:RightUpLeg", t, [_v(-12, 0, 0), _v(-25, 0, 0), _v(-12, 0, 0)])
    _pose(a, paths, "mixamorig:LeftLeg", t, [_v(32, 0, 0), _v(48, 0, 0), _v(32, 0, 0)])
    return a

static func _build_attack_1(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.28, false)
    var t: Array[float] = [0.0, 0.07, 0.13, 0.21, 0.28]

    _pose(a, paths, "mixamorig:Spine", t, [_v(0, 0, 0), _v(0, -12, 0), _v(-5, 18, 0), _v(0, 6, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(0, 0, 0), _v(0, 0, 28), _v(-18, 0, 92), _v(-8, 0, 35), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightForeArm", t, [_v(0, 0, 0), _v(0, -28, 0), _v(0, -8, 0), _v(0, -18, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(0, 0, 0), _v(0, 0, -18), _v(0, 0, -28), _v(0, 0, -16), _v(0, 0, 0)])
    return a

static func _build_attack_2(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.29, false)
    var t: Array[float] = [0.0, 0.07, 0.14, 0.22, 0.29]

    _pose(a, paths, "mixamorig:Spine", t, [_v(0, 0, 0), _v(0, 13, 0), _v(-4, -20, 0), _v(0, -6, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(0, 0, 0), _v(0, 0, -30), _v(-18, 0, -94), _v(-8, 0, -36), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:LeftForeArm", t, [_v(0, 0, 0), _v(0, 28, 0), _v(0, 8, 0), _v(0, 18, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(0, 0, 0), _v(0, 0, 16), _v(0, 0, 26), _v(0, 0, 14), _v(0, 0, 0)])
    return a

static func _build_attack_3(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.31, false)
    var t: Array[float] = [0.0, 0.08, 0.15, 0.23, 0.31]

    _pose(a, paths, "mixamorig:Hips", t, [_v(0, 0, 0), _v(0, -14, 0), _v(0, 26, 0), _v(0, 8, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:Spine", t, [_v(0, 0, 0), _v(-8, -12, 0), _v(-16, 20, 0), _v(-5, 6, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightUpLeg", t, [_v(0, 0, 0), _v(-28, 0, 0), _v(-82, 0, 8), _v(-28, 0, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightLeg", t, [_v(0, 0, 0), _v(42, 0, 0), _v(15, 0, 0), _v(30, 0, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(0, 0, 0), _v(0, 0, -24), _v(0, 0, -48), _v(0, 0, -20), _v(0, 0, 0)])
    return a

static func _build_attack_4(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.40, false)
    var t: Array[float] = [0.0, 0.10, 0.18, 0.29, 0.40]

    _pose(a, paths, "mixamorig:Hips", t, [_v(0, 0, 0), _v(8, -18, 0), _v(-10, 20, 0), _v(-5, 8, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:Spine", t, [_v(0, 0, 0), _v(14, -16, 0), _v(-18, 26, 0), _v(-6, 8, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(0, 0, 0), _v(0, 0, -36), _v(-35, 0, -105), _v(-12, 0, -52), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(0, 0, 0), _v(0, 0, 30), _v(-24, 0, 82), _v(-10, 0, 42), _v(0, 0, 0)])
    return a

static func _build_air_attack_1(paths: Dictionary) -> Animation:
    var a: Animation = _build_attack_1(paths)
    a.length = 0.30
    return a

static func _build_air_attack_2(paths: Dictionary) -> Animation:
    var a: Animation = _build_attack_2(paths)
    a.length = 0.30
    return a

static func _build_air_attack_3(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.32, false)
    var t: Array[float] = [0.0, 0.09, 0.16, 0.24, 0.32]

    _pose(a, paths, "mixamorig:Spine", t, [_v(-8, 0, 0), _v(-18, -20, 0), _v(-12, 32, 0), _v(-5, 10, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightUpLeg", t, [_v(12, 0, 0), _v(-35, 0, 0), _v(-95, 0, 12), _v(-32, 0, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightLeg", t, [_v(28, 0, 0), _v(46, 0, 0), _v(8, 0, 0), _v(32, 0, 0), _v(0, 0, 0)])
    return a

static func _build_air_attack_4(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.42, false)
    var t: Array[float] = [0.0, 0.10, 0.20, 0.31, 0.42]

    _pose(a, paths, "mixamorig:Spine", t, [_v(-8, 0, 0), _v(18, 0, 0), _v(34, 0, 0), _v(-18, 0, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightUpLeg", t, [_v(18, 0, 0), _v(48, 0, 0), _v(78, 0, 0), _v(-65, 0, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightLeg", t, [_v(34, 0, 0), _v(58, 0, 0), _v(18, 0, 0), _v(4, 0, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(0, 0, -25), _v(0, 0, -50), _v(0, 0, -70), _v(0, 0, -20), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(0, 0, 25), _v(0, 0, 50), _v(0, 0, 70), _v(0, 0, 20), _v(0, 0, 0)])
    return a

static func _build_guard(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.70, true)
    var t: Array[float] = [0.0, 0.35, 0.70]

    _pose(a, paths, "mixamorig:Spine", t, [_v(-6, 0, 0), _v(-9, 0, 0), _v(-6, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(-18, 0, -62), _v(-22, 0, -68), _v(-18, 0, -62)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(-18, 0, 62), _v(-22, 0, 68), _v(-18, 0, 62)])
    _pose(a, paths, "mixamorig:LeftForeArm", t, [_v(0, 58, 0), _v(0, 66, 0), _v(0, 58, 0)])
    _pose(a, paths, "mixamorig:RightForeArm", t, [_v(0, -58, 0), _v(0, -66, 0), _v(0, -58, 0)])
    return a

static func _build_dodge(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.26, false)
    var t: Array[float] = [0.0, 0.08, 0.17, 0.26]

    _pose(a, paths, "mixamorig:Hips", t, [_v(0, 0, 0), _v(0, 0, -18), _v(0, 0, -28), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:Spine", t, [_v(0, 0, 0), _v(-18, 0, -24), _v(-10, 0, -34), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:LeftUpLeg", t, [_v(0, 0, 0), _v(28, 0, 0), _v(-18, 0, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightUpLeg", t, [_v(0, 0, 0), _v(-18, 0, 0), _v(28, 0, 0), _v(0, 0, 0)])
    return a

static func _build_dash(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.34, true)
    var t: Array[float] = [0.0, 0.17, 0.34]

    _pose(a, paths, "mixamorig:Spine", t, [_v(-28, 0, 0), _v(-34, 0, 0), _v(-28, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(18, 0, -18), _v(24, 0, -26), _v(18, 0, -18)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(18, 0, 18), _v(24, 0, 26), _v(18, 0, 18)])
    _pose(a, paths, "mixamorig:LeftUpLeg", t, [_v(-12, 0, 0), _v(20, 0, 0), _v(-12, 0, 0)])
    _pose(a, paths, "mixamorig:RightUpLeg", t, [_v(20, 0, 0), _v(-12, 0, 0), _v(20, 0, 0)])
    return a

static func _build_charge(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.80, true)
    var t: Array[float] = [0.0, 0.20, 0.40, 0.60, 0.80]

    _pose(a, paths, "mixamorig:Spine", t, [_v(6, 0, 0), _v(9, -3, 0), _v(12, 0, 0), _v(9, 3, 0), _v(6, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(-10, 0, -42), _v(-14, 0, -48), _v(-18, 0, -54), _v(-14, 0, -48), _v(-10, 0, -42)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(-10, 0, 42), _v(-14, 0, 48), _v(-18, 0, 54), _v(-14, 0, 48), _v(-10, 0, 42)])
    _pose(a, paths, "mixamorig:LeftUpLeg", t, [_v(10, 0, 0), _v(14, 0, 0), _v(10, 0, 0), _v(14, 0, 0), _v(10, 0, 0)])
    _pose(a, paths, "mixamorig:RightUpLeg", t, [_v(10, 0, 0), _v(14, 0, 0), _v(10, 0, 0), _v(14, 0, 0), _v(10, 0, 0)])
    return a

static func _build_jutsu(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.50, false)
    var t: Array[float] = [0.0, 0.12, 0.27, 0.40, 0.50]

    _pose(a, paths, "mixamorig:Spine", t, [_v(0, 0, 0), _v(-8, 0, 0), _v(-14, 0, 0), _v(-8, 0, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(0, 0, 0), _v(-34, 10, -70), _v(-48, 18, -82), _v(-26, 8, -52), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(0, 0, 0), _v(-34, -10, 70), _v(-48, -18, 82), _v(-26, -8, 52), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:LeftForeArm", t, [_v(0, 0, 0), _v(0, 72, 0), _v(0, 92, 0), _v(0, 52, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightForeArm", t, [_v(0, 0, 0), _v(0, -72, 0), _v(0, -92, 0), _v(0, -52, 0), _v(0, 0, 0)])
    return a

static func _build_hit(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.30, false)
    var t: Array[float] = [0.0, 0.09, 0.19, 0.30]

    _pose(a, paths, "mixamorig:Spine", t, [_v(0, 0, 0), _v(20, 0, 0), _v(10, 0, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:Head", t, [_v(0, 0, 0), _v(-12, 8, 0), _v(-5, 3, 0), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(0, 0, 0), _v(12, 0, -28), _v(6, 0, -14), _v(0, 0, 0)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(0, 0, 0), _v(12, 0, 28), _v(6, 0, 14), _v(0, 0, 0)])
    return a

static func _build_defeat(paths: Dictionary) -> Animation:
    var a: Animation = _animation(0.95, false)
    var t: Array[float] = [0.0, 0.24, 0.52, 0.76, 0.95]

    _pose(a, paths, "mixamorig:Hips", t, [_v(0, 0, 0), _v(0, 0, 10), _v(0, 0, 38), _v(0, 0, 72), _v(0, 0, 84)])
    _pose(a, paths, "mixamorig:Spine", t, [_v(0, 0, 0), _v(12, 0, 0), _v(25, 0, 0), _v(38, 0, 0), _v(45, 0, 0)])
    _pose(a, paths, "mixamorig:LeftArm", t, [_v(0, 0, 0), _v(15, 0, -18), _v(28, 0, -32), _v(42, 0, -44), _v(48, 0, -50)])
    _pose(a, paths, "mixamorig:RightArm", t, [_v(0, 0, 0), _v(15, 0, 18), _v(28, 0, 32), _v(42, 0, 44), _v(48, 0, 50)])
    return a
