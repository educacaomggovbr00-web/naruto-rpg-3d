extends CharacterBody3D
## Menu-only visual actor. No combat modules, pools, collisions or input.
var definition: CharacterDefinition
var locked_target: Node3D = null
var guard_meter: float = 100.0
var rig_adapter: Node3D
var preview_clip: String = "idle"
var preview_action_id: int = 0

func _ready() -> void:
    collision_layer = 0
    collision_mask = 0
    var hitbox: Area3D = Area3D.new()
    hitbox.name = "AttackHitbox"
    hitbox.monitoring = false
    hitbox.collision_layer = 0
    hitbox.collision_mask = 0
    add_child(hitbox)
    rig_adapter = Node3D.new()
    rig_adapter.name = "RiggedCharacterAdapter"
    rig_adapter.set_script(preload("res://scripts/rigged_character_adapter.gd"))
    rig_adapter.set("follow_hitbox_to_bones", false)
    add_child(rig_adapter)

func get_character_definition() -> CharacterDefinition:
    return definition

func get_animation_state() -> String:
    return preview_clip

func get_animation_action_id() -> int:
    return preview_action_id

func preview_animation(clip: String) -> void:
    if not rig_adapter.manifest.get("clips", {}).has(clip):
        return
    preview_clip = clip
    preview_action_id += 1
    # Gallery jumps directly to a requested pose; queued idle transitions would
    # make rapid touchscreen selection show an earlier clip for several frames.
    rig_adapter.current_state = clip
    rig_adapter.playback.start(StringName(clip), true)

func get_combo_step() -> int:
    return 1
