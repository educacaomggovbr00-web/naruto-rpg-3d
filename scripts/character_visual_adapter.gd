extends "res://scripts/rigged_character_adapter.gd"
## Keep the rig API, clips and bone hitboxes for combat; replace only its visible mesh.

const SPRITE_LAYOUT: Array[String] = [
    "idle", "run", "sprint", "back_run",
    "guard", "attack_1", "attack_2", "attack_3",
    "attack_4", "air", "dodge", "hit",
    "defeat", "chakra_charge", "chakra_dash", "jutsu"
]

var sprite_visual: Sprite3D = null
var sprite_mode: bool = false
var sprite_status: String = "SPRITE 2.5D: aguardando"
var sprite_frames: Dictionary = {}
var sprite_last_key: String = ""

func _ready() -> void:
    super._ready()
    if player.has_method("get_character_definition"):
        var definition: CharacterDefinition = player.call("get_character_definition") as CharacterDefinition
        if definition != null and definition.visual_mode == "sprite_2_5d":
            _setup_sprite(definition)

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if sprite_mode and sprite_visual != null:
        _sync_sprite_state()

func _setup_sprite(definition: CharacterDefinition) -> void:
    if definition.sprite_atlas_path.is_empty() or not ResourceLoader.exists(definition.sprite_atlas_path):
        sprite_status = "SPRITE 2.5D: atlas ausente"
        return

    var atlas_source: Texture2D = ResourceLoader.load(definition.sprite_atlas_path) as Texture2D
    if atlas_source == null:
        sprite_status = "SPRITE 2.5D: atlas inválido"
        return

    var cell: Vector2i = definition.sprite_cell_size
    if cell.x <= 0 or cell.y <= 0 or atlas_source.get_width() < cell.x * 4 or atlas_source.get_height() < cell.y * 4:
        sprite_status = "SPRITE 2.5D: dimensões inválidas; usando modelo 3D"
        return
    for index: int in range(SPRITE_LAYOUT.size()):
        var key: String = SPRITE_LAYOUT[index]
        var frame: AtlasTexture = AtlasTexture.new()
        frame.atlas = atlas_source
        var column: int = index % 4
        var row: int = floori(float(index) / 4.0)
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
    # Keep the pixel baseline on the floor even when the camera looks down.
    var collision: CollisionShape3D = player.get_node_or_null("CollisionShape3D") as CollisionShape3D
    var floor_y: float = -0.95
    if collision != null and collision.shape is CapsuleShape3D:
        floor_y = collision.position.y - collision.shape.height * 0.5
    sprite_visual.position.y = floor_y + (float(cell.y) * 0.5 - 8.0) * definition.sprite_pixel_size
    sprite_visual.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
    sprite_visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    sprite_visual.shaded = false
    add_child(sprite_visual)

    var fallback: Node3D = get_node_or_null(fallback_visual_path) as Node3D
    if fallback != null:
        fallback.visible = false
        fallback.process_mode = Node.PROCESS_MODE_DISABLED

    if model_instance != null:
        model_instance.visible = false
    sprite_mode = true
    sprite_status = "SPRITE 2.5D: OK | %d poses" % sprite_frames.size()
    _sync_sprite_state()

func _sync_sprite_state() -> void:
    # Update facing even while the current pose stays the same.
    var camera: Camera3D = get_viewport().get_camera_3d()
    if camera != null:
        var screen_facing: float = player.global_basis.z.dot(camera.global_basis.x)
        if absf(screen_facing) > 0.1:
            sprite_visual.flip_h = screen_facing < 0.0
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

func get_rig_status() -> String:
    return sprite_status if sprite_mode else super.get_rig_status()

func get_available_animations_text() -> String:
    return ", ".join(SPRITE_LAYOUT) if sprite_mode else super.get_available_animations_text()
