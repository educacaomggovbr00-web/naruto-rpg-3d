@tool
extends EditorExportPlugin

var reject_payload: bool = false

func _get_name() -> String:
    return "PublicReleaseAssetGate"

func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
    reject_payload = false
    if not features.has("public_release"):
        return
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset_registry.json"))
    var errors: Array[String] = []
    var registered: Dictionary = {}
    if not parsed is Dictionary:
        errors.append("Registro de assets ausente/inválido")
    else:
        if not parsed.get("presentation_distribution_authorized", false):
            errors.append("Autorização de distribuição da apresentação/personagens não registrada")
        for entry: Dictionary in parsed.get("assets", []):
            var path: String = "res://" + String(entry.get("path", ""))
            if not path.begins_with("res://assets/") or path.contains("..") or registered.has(path):
                errors.append("Caminho inválido/duplicado no registro")
                continue
            registered[path] = true
            var status: String = String(entry.get("status", "UNKNOWN_LICENSE"))
            if status not in ["SAFE_FOR_RELEASE", "NEEDS_ATTRIBUTION"]:
                errors.append("Asset não liberado: " + path)
            if FileAccess.get_sha256(path) != String(entry.get("sha256", "")):
                errors.append("Asset alterado sem revisão: " + path)
            if status == "NEEDS_ATTRIBUTION" and String(entry.get("credit", "")).is_empty():
                errors.append("Crédito obrigatório ausente: " + path)
            for image: Dictionary in entry.get("embedded_images", []):
                var image_path: String = "res://" + String(image["path"])
                if not image_path.begins_with("res://assets/") or image_path.contains(".."):
                    errors.append("Imagem embutida com caminho inválido")
                    continue
                registered[image_path] = true
                if FileAccess.file_exists(image_path) and FileAccess.get_sha256(image_path) != String(image["sha256"]):
                    errors.append("Imagem embutida alterada: " + image_path)
        _check_unregistered("res://assets", registered, errors)
    if not errors.is_empty():
        reject_payload = true
        get_export_platform().add_message(EditorExportPlatform.EXPORT_MESSAGE_ERROR, "Licenças", "Export público bloqueado; payload excluído. " + "; ".join(errors))

func _export_file(_path: String, _type: String, _features: PackedStringArray) -> void:
    if reject_payload:
        # An export backend may still write a container after an error message.
        # Never put uncleared content in that container, including imported data.
        skip()

func _check_unregistered(folder: String, registered: Dictionary, errors: Array[String]) -> void:
    if FileAccess.file_exists(folder.path_join(".gdignore")):
        return
    var directory: DirAccess = DirAccess.open(folder)
    if directory == null:
        return
    for subfolder: String in directory.get_directories():
        _check_unregistered(folder.path_join(subfolder), registered, errors)
    for file: String in directory.get_files():
        var path: String = folder.path_join(file)
        if file.get_extension().to_lower() in ["glb", "gltf", "fbx", "tres", "png", "jpg", "webp", "ogg", "wav", "mp3", "gdshader"] and not registered.has(path):
            errors.append("Asset não registrado: " + path)
