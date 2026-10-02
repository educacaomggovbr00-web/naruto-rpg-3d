extends Node3D

@onready var player: CharacterBody3D = get_parent()
@onready var torso: MeshInstance3D = $Torso
@onready var left_arm: Node3D = $LeftArmPivot
@onready var right_arm: Node3D = $RightArmPivot
@onready var left_leg: Node3D = $LeftLegPivot
@onready var right_leg: Node3D = $RightLegPivot
@onready var aura: MeshInstance3D = $ChakraAura

var motion_phase := 0.0
var aura_base_scale := Vector3.ONE

func _ready() -> void:
    aura_base_scale = aura.scale
    aura.visible = false

func _process(delta: float) -> void:
    var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
    _update_aura(delta)

    if player.attack_cooldown > 0.0:
        _attack_pose(delta)
    elif horizontal_speed > 0.25:
        _run_pose(delta, horizontal_speed)
    else:
        _idle_pose(delta)

func _update_aura(delta: float) -> void:
    aura.visible = player.chakra_dash_timer > 0.0
    if not aura.visible:
        return

    aura.rotation.y += delta * 7.0
    var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.025) * 0.06
    aura.scale = aura_base_scale * pulse

func _run_pose(delta: float, speed: float) -> void:
    motion_phase += delta * clamp(speed * 1.15, 6.0, 13.0)
    var stride := sin(motion_phase)
    var blend := clamp(delta * 14.0, 0.0, 1.0)

    left_leg.rotation.x = lerp_angle(left_leg.rotation.x, stride * 0.72, blend)
    right_leg.rotation.x = lerp_angle(right_leg.rotation.x, -stride * 0.72, blend)
    left_arm.rotation.x = lerp_angle(left_arm.rotation.x, -stride * 0.48, blend)
    right_arm.rotation.x = lerp_angle(right_arm.rotation.x, stride * 0.48, blend)

    torso.rotation.x = lerp_angle(torso.rotation.x, -0.08, blend)
    torso.rotation.y = lerp_angle(torso.rotation.y, 0.0, blend)
    torso.rotation.z = lerp_angle(torso.rotation.z, sin(motion_phase * 2.0) * 0.035, blend)

func _idle_pose(delta: float) -> void:
    motion_phase += delta * 2.0
    var blend := clamp(delta * 8.0, 0.0, 1.0)
    var breathe := sin(motion_phase) * 0.035

    left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, blend)
    right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, blend)
    left_arm.rotation.x = lerp_angle(left_arm.rotation.x, 0.08 + breathe, blend)
    right_arm.rotation.x = lerp_angle(right_arm.rotation.x, -0.08 - breathe, blend)

    torso.rotation.x = lerp_angle(torso.rotation.x, breathe * 0.4, blend)
    torso.rotation.y = lerp_angle(torso.rotation.y, 0.0, blend)
    torso.rotation.z = lerp_angle(torso.rotation.z, 0.0, blend)

func _attack_pose(delta: float) -> void:
    var blend := clamp(delta * 22.0, 0.0, 1.0)
    var left_target := Vector3(0.1, 0.0, 0.0)
    var right_target := Vector3(-0.1, 0.0, 0.0)
    var torso_y := 0.0
    var torso_z := 0.0

    match player.combo_step:
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
