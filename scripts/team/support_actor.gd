extends "res://scripts/ui/fighter_preview_actor.gd"
## A short-lived, vulnerable partner with its own roster mesh and animation.
var squad: Node
var member_index: int = -1
var linked_avatar: SusanooVisual = null
var linked_aura: MeshInstance3D = null
var clock: float = 0.0

func _ready() -> void:
    super._ready()
    var hurtbox: Area3D = Area3D.new()
    hurtbox.set_script(preload("res://scripts/combat_hurtbox.gd"))
    hurtbox.collision_layer = 8 if squad.fighter.collision_layer == 2 else 16
    hurtbox.collision_mask = 0
    hurtbox.monitoring = false
    var collision: CollisionShape3D = CollisionShape3D.new()
    var capsule: CapsuleShape3D = CapsuleShape3D.new()
    capsule.radius = .4
    capsule.height = 1.7
    collision.shape = capsule
    hurtbox.add_child(collision)
    add_child(hurtbox)
    if squad.linked_remaining > 0.0:
        if definition.character_id == "henrique":
            linked_avatar = SusanooVisual.new()
            linked_avatar.position.y = -.95
            add_child(linked_avatar)
            linked_avatar.set_form(3)
            linked_avatar.set_quality(GraphicsPreferences.read_quality())
        else:
            linked_aura = MeshInstance3D.new()
            var mesh: SphereMesh = SphereMesh.new()
            mesh.radius = .7
            mesh.height = 1.8
            mesh.radial_segments = 10
            mesh.rings = 5
            linked_aura.mesh = mesh
            var material: StandardMaterial3D = StandardMaterial3D.new()
            material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
            material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            material.albedo_color = Color(definition.energy_color.r, definition.energy_color.g, definition.energy_color.b, .16)
            linked_aura.material_override = material
            linked_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            add_child(linked_aura)

func _physics_process(delta: float) -> void:
    clock += delta
    if linked_avatar != null:
        linked_avatar.visible = squad.linked_remaining > 0.0
        linked_avatar.update_pose(delta, true, fmod(clock, .8) / .8, Vector3.ZERO, .5)
    if linked_aura != null:
        linked_aura.visible = squad.linked_remaining > 0.0
        linked_aura.scale = Vector3.ONE * (1.0 + sin(clock * 9.0) * .06)

func receive_combat_hit(damage: float, _direction: Vector3, _knockback: float, _launch: float, _stun: float) -> float:
    if damage > 0.0:
        squad.interrupt_support(member_index)
    return 0.0

func is_targetable() -> bool:
    return false

func get_is_guarding() -> bool:
    return false
