extends Node3D

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var torso: MeshInstance3D = $Torso
@onready var left_arm: Node3D = $LeftArmPivot
@onready var right_arm: Node3D = $RightArmPivot
@onready var left_leg: Node3D = $LeftLegPivot
@onready var right_leg: Node3D = $RightLegPivot
@onready var aura: MeshInstance3D = $ChakraAura

var motion_phase: float = 0.0
var aura_base_scale: Vector3 = Vector3.ONE

func _ready() -> void:
    aura_base_scale = aura.scale
    aura.visible = false

func _process(delta: float) -> void:
    var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
    var attack_cooldown: float = float(player.call("get_attack_cooldown"))
    var is_guarding: bool = bool(player.call("get_is_guarding"))

    _update_aura(delta)

    if is_guarding:
        _guard_pose(delta)
    elif attack_cooldown > 0.0:
        _attack_pose(delta)
    elif horizontal_speed > 0.25:
        _run_pose(delta, horizontal_speed)
    else:
        _idle_pose(delta)

func _update_aura(delta: float) -> void:
    var dash_timer: float = float(player.call("get_chakra_dash_timer"))
    var jutsu_timer: float = float(player.call("get_jutsu_timer"))
    var charging: bool = bool(player.call("get_is_charging"))

    aura.visible = dash_timer > 0.0 or jutsu_timer > 0.0 or charging
    if not aura.visible:
        aura.scale = aura_base_scale
        return

    aura.rotation.y += delta * (9.0 if jutsu_timer > 0.0 else 6.0)

    var pulse: float = 1.0 + sin(float(Time.get_ticks_msec()) * 0.025) * 0.06
    if charging:
        pulse += 0.08
    if jutsu_timer > 0.0:
        pulse += 0.22

    aura.scale = aura_base_scale * pulse

func _run_pose(delta: float, speed: float) -> void:
    motion_phase += delta * clampf(speed * 1.15, 6.0, 13.0)
    var stride: float = sin(motion_phase)
    var blend: float = clampf(delta * 14.0, 0.0, 1.0)

    left_leg.rotation.x = lerp_angle(left_leg.rotation.x, stride * 0.72, blend)
    right_leg.rotation.x = lerp_angle(right_leg.rotation.x, -stride * 0.72, blend)
    left_arm.rotation.x = lerp_angle(left_arm.rotation.x, -stride * 0.48, blend)
    right_arm.rotation.x = lerp_angle(right_arm.rotation.x, stride * 0.48, blend)

    torso.rotation.x = lerp_angle(torso.rotation.x, -0.08, blend)
    torso.rotation.y = lerp_angle(torso.rotation.y, 0.0, blend)
    torso.rotation.z = lerp_angle(torso.rotation.z, sin(motion_phase * 2.0) * 0.035, blend)

func _idle_pose(delta: float) -> void:
    motion_phase += delta * 2.0
    var blend: float = clampf(delta * 8.0, 0.0, 1.0)
    var breathe: float = sin(motion_phase) * 0.035

    left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, blend)
    right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, blend)
    left_arm.rotation.x = lerp_angle(left_arm.rotation.x, 0.08 + breathe, blend)
    right_arm.rotation.x = lerp_angle(right_arm.rotation.x, -0.08 - breathe, blend)

    torso.rotation.x = lerp_angle(torso.rotation.x, breathe * 0.4, blend)
    torso.rotation.y = lerp_angle(torso.rotation.y, 0.0, blend)
    torso.rotation.z = lerp_angle(torso.rotation.z, 0.0, blend)

func _guard_pose(delta: float) -> void:
    var blend: float = clampf(delta * 18.0, 0.0, 1.0)
    left_arm.rotation = left_arm.rotation.lerp(Vector3(-0.85, 0.0, 0.75), blend)
    right_arm.rotation = right_arm.rotation.lerp(Vector3(-0.85, 0.0, -0.75), blend)
    left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.12, blend)
    right_leg.rotation.x = lerp_angle(right_leg.rotation.x, -0.12, blend)
    torso.rotation.x = lerp_angle(torso.rotation.x, -0.10, blend)
    torso.rotation.y = lerp_angle(torso.rotation.y, 0.0, blend)
    torso.rotation.z = lerp_angle(torso.rotation.z, 0.0, blend)

func _attack_pose(delta: float) -> void:
    var blend: float = clampf(delta * 22.0, 0.0, 1.0)
    var left_target: Vector3 = Vector3(0.1, 0.0, 0.0)
    var right_target: Vector3 = Vector3(-0.1, 0.0, 0.0)
    var torso_y: float = 0.0
    var torso_z: float = 0.0
    var combo_step: int = int(player.call("get_combo_step"))

    match combo_step:
        1:
            right_target = Vector3(-1.45, 0.0, -0.22)
            left_target = Vector3(0.35, 0.0, 0.20)
            torso_y = -0.22
        2:
            left_target = Vector3(-1.35, 0.0, 0.25)
            right_target = Vector3(0.30, 0.0, -0.18)
            torso_y = 0.24
        3:
            right_target = Vector3(-1.05, 0.0, -0.50)
            left_target = Vector3(-0.65, 0.0, 0.42)
            torso_y = -0.36
            torso_z = -0.10
        4:
            right_target = Vector3(-0.55, 0.0, -1.05)
            left_target = Vector3(-0.55, 0.0, 1.05)
            torso_y = 0.62
            torso_z = 0.08

    left_arm.rotation = left_arm.rotation.lerp(left_target, blend)
    right_arm.rotation = right_arm.rotation.lerp(right_target, blend)
    left_leg.rotation.x = lerp_angle(left_leg.rotation.x, -0.12, blend)
    right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.18, blend)
    torso.rotation.x = lerp_angle(torso.rotation.x, -0.06, blend)
    torso.rotation.y = lerp_angle(torso.rotation.y, torso_y, blend)
    torso.rotation.z = lerp_angle(torso.rotation.z, torso_z, blend)
