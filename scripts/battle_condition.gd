extends Node3D
## Original damaged-accessory overlay; never modifies the supplied GLB/texture.
var fighter: CharacterBody3D
var armor_broken: bool = false
var weapon_broken: bool = false
var armor_pressure: float = 0.0
var weapon_pressure: float = 0.0
var damage_marks: Array[MeshInstance3D] = []

func _ready() -> void:
    fighter = get_parent() as CharacterBody3D
    fighter.battle_condition = self
    for index: int in range(3):
        var mark: MeshInstance3D = MeshInstance3D.new()
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = Vector3(.22, .045, .018)
        mark.mesh = mesh
        var material: StandardMaterial3D = StandardMaterial3D.new()
        material.albedo_color = Color("30262d")
        mark.material_override = material
        mark.rotation.z = -.45
        mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        mark.visible = false
        add_child(mark)
        damage_marks.append(mark)

func record_damage(damage: float, knockback: float, blocked: bool) -> void:
    if damage <= 0.0:
        return
    if not blocked:
        armor_pressure += damage + maxf(knockback - 5.0, 0.0)
        if armor_pressure >= 38.0 and not armor_broken:
            armor_broken = true
            fighter.combat_feedback.spawn_impact(fighter.global_position + Vector3.UP * .5, "launcher")
    elif fighter.character_definition.character_id in ["tenten", "temari", "kisame", "kankuro", "kimimaro"]:
        weapon_pressure += damage + maxf(knockback, 0.0)
        if weapon_pressure >= 34.0:
            weapon_broken = true
    _sync_marks()

func _physics_process(_delta: float) -> void:
    _sync_marks()

func _sync_marks() -> void:
    if fighter.rig_adapter.skeleton == null:
        return
    var skeleton: Skeleton3D = fighter.rig_adapter.skeleton
    var bone: int = skeleton.find_bone("mixamorig_Spine2")
    if bone < 0:
        return
    var chest: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone)
    for index: int in range(damage_marks.size()):
        damage_marks[index].visible = armor_broken and not fighter.is_defeated()
        damage_marks[index].global_transform = chest * Transform3D(Basis(Vector3.FORWARD, -.45), Vector3((index - 1) * .12, .04 * index, .16))

func damage_multiplier() -> float:
    return (1.08 if armor_broken else 1.0) * (.9 if weapon_broken else 1.0)

func received_multiplier() -> float:
    return 1.06 if armor_broken else 1.0

func reset() -> void:
    armor_broken = false
    weapon_broken = false
    armor_pressure = 0.0
    weapon_pressure = 0.0
    _sync_marks()

func _exit_tree() -> void:
    if is_instance_valid(fighter):
        fighter.battle_condition = null
