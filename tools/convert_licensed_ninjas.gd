extends SceneTree
## Offline conversion: godot --headless --path . --script res://tools/convert_licensed_ninjas.gd -- /path/to/FBX
func _initialize() -> void:
    var arguments: PackedStringArray = OS.get_cmdline_user_args()
    if arguments.size() != 1:
        push_error("Pass the extracted pack's FBX directory")
        quit(1)
        return
    for title: String in ["Ninja_Male", "Ninja_Female"]:
        var document: FBXDocument = FBXDocument.new()
        var state: FBXState = FBXState.new()
        var result: Error = document.append_from_file(arguments[0].path_join(title + ".fbx"), state)
        if result != OK:
            push_error("FBX read failed: " + error_string(result))
            quit(1)
            return
        var scene: Node3D = document.generate_scene(state)
        var gltf: GLTFDocument = GLTFDocument.new()
        var output: GLTFState = GLTFState.new()
        result = gltf.append_from_scene(scene, output)
        if result == OK:
            result = gltf.write_to_filesystem(output, "res://assets/vendor/quaternius_ninjas/" + title + ".glb")
        scene.free()
        if result != OK:
            push_error("GLB write failed: " + error_string(result))
            quit(1)
            return
    quit(0)
