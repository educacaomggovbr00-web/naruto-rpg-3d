extends Node3D

const RIG_ADAPTER_SCRIPT: Script = preload("res://scripts/rigged_character_adapter.gd")
const MANIFEST_PATH: String = "res://assets/animations/combat_manifest.json"
const SPRITE_LAYOUT: Array[String] = [
    "idle", "run", "sprint", "back_run",
    "guard", "attack_1", "attack_2", "attack_3",
    "attack_4", "air", "dodge", "hit",
    "defeat", "chakra_charge", "chakra_dash", "jutsu"
]

@export_file("*.glb") var model_path: String = "res://assets/characters/rigged.glb"
@export var fallback_visual_path: NodePath = NodePath("../VisualRoot")
@export var model_offset: Vector3 = Vector3(0.0, -0.95, 0.0)
@export var model_scale: float = 1.0
@export var auto_scale_model: bool = true
@export var ground_to_collision: bool = false
@export var target_character_height: float = 1.75
@export var fallback_import_scale: float = 0.01
@export var model_yaw_degrees: float = 180.0
@export var follow_hitbox_to_bones: bool = true

var manifest: Dictionary = {}
var player: CharacterBody3D = null
var rig_impl: Node3D = null
var sprite_visual: Sprite3D = null
var sprite_mode: bool = false
var sprite_status: String = "VISUAL: aguardando"
var sprite_frames: Dictionary = {}
var sprite_last_key: String = ""

func _ready() -> void:
    player = get_parent() as CharacterBody3D
    _load_manifest()
    if player == null:
        sprite_status = "VISUAL: parent não é CharacterBody3D"
        return

    var definition: CharacterDefinition = null
    if player.has_method("get_character_definition"):
        definition = player.call("get_character_definition") as CharacterDefinition

    if definition != null and definition.visual_mode == "sprite_2_5d":
        _setup_sprite(definition)
    else:
        _setup_rig()

func _physics_process(_delta: float) -> void:
    if rig_impl != null:
        rig_impl.visible = visible
    if sprite_mode and sprite_visual != null:
        _sync_sprite_state()

func _load_manifest() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
    if parsed is Dictionary:
        manifest = parsed

func _setup_rig() -> void:
    rig_impl = Node3D.new()
    rig_impl.name = "RiggedCharacterAdapter3D"
    rig_impl.set_script(RIG_ADAPTER_SCRIPT)
    rig_impl.set("model_path", model_path)
    rig_impl.set("fallback_visual_path", fallback_visual_path)
    rig_impl.set("model_offset", model_offset)
    rig_impl.set("model_scale", model_scale)
    rig_impl.set("auto_scale_model", auto_scale_model)
    rig_impl.set("ground_to_collision", ground_to_collision)
    rig_impl.set("target_character_height", target_character_height)
    rig_impl.set("fallback_import_scale", fallback_import_scale)
    rig_impl.set("model_yaw_degrees", model_yaw_degrees)
    rig_impl.set("follow_hitbox_to_bones", follow_hitbox_to_bones)
    player.add_child(rig_impl)

func _setup_sprite(definition: CharacterDefinition) -> void:
    if definition.sprite_atlas_path.is_empty() or not ResourceLoader.exists(definition.sprite_atlas_path):
        sprite_status = "SPRITE 2.5D: atlas ausente"
        return

    var atlas_source: Texture2D = ResourceLoader.load(definition.sprite_atlas_path) as Texture2D
    if atlas_source == null:
        sprite_status = "SPRITE 2.5D: atlas inválido"
        return

    var cell: Vector2i = definition.sprite_cell_size
    for index: int in range(SPRITE_LAYOUT.size()):
        var key: String = SPRITE_LAYOUT[index]
        var frame: AtlasTexture = AtlasTexture.new()
        frame.atlas = atlas_source
        var column: int = index % 4
        var row: int = index / 4
        frame.region = Rect2(
            Vector2(float(column * cell.x), float(row * cell.y)),
            Vector2(float(cell.x), float(cell.y))
        )
        sprite_frames[key] = frame

    sprite_visual = Sprite3D.new()
    sprite_visual.name = "Sprite2_5D"
    sprite_visual.texture = sprite_frames["idle"]
    sprite_visual.pixel_size = definition.sprite_pixel_size
    sprite_visual.position = definition.sprite_offset
    sprite_visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sprite_visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    sprite_visual.shaded = false
    add_child(sprite_visual)

    var fallback: Node3D = get_node_or_null(fallback_visual_path) as Node3D
    if fallback != null:
        fallback.visible = false
        fallback.process_mode = Node.PROCESS_MODE_DISABLED

    sprite_mode = true
    sprite_status = "SPRITE 2.5D: OK | %d poses" % sprite_frames.size()
    _sync_sprite_state()

func _sync_sprite_state() -> void:
    var key: String = _sprite_key()
    if key == sprite_last_key:
        return
    if not sprite_frames.has(key):
        key = "idle"
    sprite_visual.texture = sprite_frames[key]
    sprite_last_key = key

func _sprite_key() -> String:
    var state: String = String(player.call("get_animation_state"))
    if state == "attack" or state == "air_attack":
        return "attack_%d" % clampi(int(player.call("get_combo_step")), 1, 4)

    match state:
        "run":
            var flat_velocity: Vector3 = Vector3(player.velocity.x, 0.0, player.velocity.z)
            var speed: float = flat_velocity.length()
            if speed > 0.1 and flat_velocity.normalized().dot(player.global_basis.z) < -0.25:
                return "back_run"
            return "sprint" if speed > 9.0 else "run"
        "air":
            return "air"
        "guard":
            return "guard"
        "dodge":
            return "dodge"
        "hit", "knockback", "guard_break":
            return "hit"
        "defeat":
            return "defeat"
        "chakra_charge":
            return "chakra_charge"
        "chakra_dash":
            return "chakra_dash"
        "jutsu":
            return "jutsu"
        _:
            return "idle"

func snap_attack_hitbox(combo_step: int, airborne: bool) -> void:
    if rig_impl != null and rig_impl.has_method("snap_attack_hitbox"):
        rig_impl.call("snap_attack_hitbox", combo_step, airborne)

func get_attack_timing(combo_step: int, airborne: bool) -> Dictionary:
    if rig_impl != null and rig_impl.has_method("get_attack_timing"):
        var result: Variant = rig_impl.call("get_attack_timing", combo_step, airborne)
        if result is Dictionary:
            return result
    var state_name: String = ("air_attack_%d" if airborne else "attack_%d") % combo_step
    return manifest.get("clips", {}).get(state_name, {})

func get_hand_world_position(short_name: String = "RightHand") -> Vector3:
    if rig_impl != null and rig_impl.has_method("get_hand_world_position"):
        var result: Variant = rig_impl.call("get_hand_world_position", short_name)
        if result is Vector3:
            return result
    if player == null:
        return global_position
    var side: float = -0.22 if short_name == "LeftHand" else 0.22
    return player.global_position + Vector3.UP * 0.25 + player.global_basis.z * 0.55 + player.global_basis.x * side

func get_rig_status() -> String:
    if sprite_mode or rig_impl == null:
        return sprite_status
    if rig_impl.has_method("get_rig_status"):
        return String(rig_impl.call("get_rig_status"))
    return "RIG: carregando"

func is_rig_loaded() -> bool:
    if sprite_mode:
        return true
    return rig_impl != null and rig_impl.has_method("is_rig_loaded") and bool(rig_impl.call("is_rig_loaded"))

func get_available_animations_text() -> String:
    if sprite_mode:
        var names: PackedStringArray = PackedStringArray()
        for key: String in SPRITE_LAYOUT:
            names.append(key)
        return ", ".join(names)
    if rig_impl != null and rig_impl.has_method("get_available_animations_text"):
        return String(rig_impl.call("get_available_animations_text"))
    return "nenhuma"
