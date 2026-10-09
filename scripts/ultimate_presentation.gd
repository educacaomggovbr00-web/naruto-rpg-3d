extends Node3D
## Visual-only direction after confirmed entry. Never changes damage, locks or hitboxes.
var visual: Node3D
var family: String = "chakra"
var active: bool = false
var fighter: Node3D
var target: Node3D
var elapsed: float = 0.0
var duration: float = 1.1
var beat: int = -1

func _ready() -> void:
    visual = Node3D.new()
    visual.set_script(preload("res://scripts/elemental_jutsu_visual.gd"))
    add_child(visual)
    visual.set_physics_process(false)
    top_level = true
    visible = false

func begin(actor: Node3D, victim: Node3D, element: String, seconds: float) -> void:
    stop()
    fighter = actor
    target = victim
    family = element
    duration = maxf(seconds,.1)
    var data: JutsuDefinition = JutsuDefinition.new()
    data.effect = family
    data.jutsu_id = "ultimate_shark" if actor.character_definition.character_id == "kisame" else "ultimate_dragon" if actor.character_definition.character_id == "hiruzen" else "ultimate_construct"
    visual.configure_jutsu(data,.6)
    active = true
    visible = true
    update_sequence(0.0)

func update_sequence(delta: float) -> void:
    if not active or not is_instance_valid(fighter) or not is_instance_valid(target):
        stop()
        return
    elapsed += delta
    var progress: float = clampf(elapsed/duration,0,1)
    var next_beat: int = 0 if progress < .32 else 1 if progress < .76 else 2
    if next_beat != beat:
        beat = next_beat
        fighter.camera_rig.set_sequence_shot(["ultimate_prepare","ultimate_sweep","ultimate_finish"][beat])
    var start: Vector3 = fighter.global_position + Vector3.UP*.85
    var finish: Vector3 = target.global_position + Vector3.UP*.85
    var axis: Vector3 = finish-start
    visual.heading = axis.normalized() if axis.length_squared() > .001 else fighter.global_basis.z
    global_position = start.lerp(finish,smoothstep(.2,.85,progress))
    if family in ["sand","shadow","mind","insect"]:
        global_position = finish
    if family in ["sand","earth","taijutsu"]:
        global_position.y += sin(progress*PI)*.7
    visual.radius = lerpf(.3,.95,smoothstep(0,.8,progress))
    visual.update_visual(delta)

func finish_impact() -> void:
    if is_instance_valid(fighter) and is_instance_valid(target) and fighter.combat_feedback != null:
        fighter.combat_feedback.spawn_elemental_impact(target.global_position+Vector3.UP*.65,family,1.25,visual.heading)
    stop()

func stop() -> void:
    active = false
    visible = false
    elapsed = 0.0
    beat = -1
    fighter = null
    target = null
    if visual != null:
        visual.visible = false
        visual.scale = Vector3.ONE
