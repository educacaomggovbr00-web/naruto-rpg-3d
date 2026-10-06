extends CharacterBody3D
@export var player_controlled: bool = false
@export var move_speed: float = 7.5
@export var sprint_speed: float = 13.0
@export var jump_speed: float = 10.0
var locked_target: Node3D = null
var guard_meter: float = 100.0
var animation_action_id: int = 0
var animation_state: String = "idle"
var rig_adapter: Node3D
var controls: Control
var camera_rig: Node3D
var air_jumps: int = 0
var coyote_time: float = 0.0
var jump_buffer: float = 0.0
var last_safe_position: Vector3 = Vector3(0, 0.95, 42)
var input_enabled: bool = true

func _ready() -> void:
    var hitbox: Area3D = Area3D.new()
    hitbox.name = "AttackHitbox"
    hitbox.collision_layer = 0
    hitbox.collision_mask = 0
    hitbox.monitoring = false
    add_child(hitbox)
    rig_adapter = Node3D.new()
    rig_adapter.name = "RiggedCharacterAdapter"
    if player_controlled:
        rig_adapter.set_script(preload("res://scripts/rigged_character_adapter.gd"))
    else:
        rig_adapter.set_script(preload("res://scripts/world/licensed_ninja_actor.gd"))
    if player_controlled:
        var definition: CharacterDefinition = get_character_definition()
        if definition != null:
            rig_adapter.model_path = definition.model_path
            move_speed = definition.movement_speed
            sprint_speed = definition.sprint_speed
    if player_controlled:
        rig_adapter.follow_hitbox_to_bones = false
    add_child(rig_adapter)
    if player_controlled:
        add_to_group("world_player")
        controls = get_node("../HUD/WorldControls")
        camera_rig = get_node("WorldCamera")
        last_safe_position = global_position
    else:
        set_physics_process(false)

func _unhandled_input(event: InputEvent) -> void:
    if player_controlled and input_enabled and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
        jump_buffer = 0.15

func _physics_process(delta: float) -> void:
    if not player_controlled:
        return
    var stick: Vector2 = Vector2.ZERO
    if input_enabled:
        stick = controls.move_vector
        var keys: Vector2 = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
        if keys.length_squared() > 0.0:
            stick = keys.limit_length(1.0)
        if controls.jump_queue > 0:
            controls.jump_queue = 0
            jump_buffer = 0.15
    coyote_time = maxf(coyote_time - delta, 0.0)
    jump_buffer = maxf(jump_buffer - delta, 0.0)
    if is_on_floor():
        coyote_time = 0.12
        air_jumps = 0
        last_safe_position = global_position
    var running: bool = input_enabled and (controls.sprint_touch != -1 or stick.length() >= 0.82 or Input.is_physical_key_pressed(KEY_SHIFT))
    var speed: float = sprint_speed if running else move_speed
    var direction: Vector3 = Basis(Vector3.UP, camera_rig.yaw) * Vector3(stick.x, 0, stick.y)
    velocity.x = move_toward(velocity.x, direction.x * speed, (30.0 if is_on_floor() else 9.0) * delta)
    velocity.z = move_toward(velocity.z, direction.z * speed, (30.0 if is_on_floor() else 9.0) * delta)
    if direction.length_squared() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-12.0 * delta))
    velocity.y -= 18.0 * delta
    if input_enabled and jump_buffer > 0.0 and (coyote_time > 0.0 or air_jumps == 0):
        velocity.y = jump_speed if coyote_time > 0.0 else jump_speed * 0.85
        if coyote_time <= 0.0:
            air_jumps = 1
        coyote_time = 0.0
        jump_buffer = 0.0
        animation_action_id += 1
    move_and_slide()
    if global_position.y < -6.0:
        global_position = last_safe_position
        velocity = Vector3.ZERO
    animation_state = "air" if not is_on_floor() else "run" if Vector2(velocity.x, velocity.z).length() > 0.3 else "idle"

func get_animation_state() -> String:
    return animation_state

func get_animation_action_id() -> int:
    return animation_action_id

func get_combo_step() -> int:
    return 1

func get_character_definition() -> CharacterDefinition:
    if not player_controlled:
        return null
    return GameFlow.player_character if GameFlow.player_character != null else CharacterCatalog.NARUTO
