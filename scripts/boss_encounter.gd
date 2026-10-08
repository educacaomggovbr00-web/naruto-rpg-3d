extends CanvasLayer
## Original three-step boss QTE and a telegraphed giant chakra attack.
## No global time-scale/pause changes; every exit releases cinematic locks.
var fighter: CharacterBody3D
var boss: CharacterBody3D
var phase: String = ""
var elapsed: float = 0.0
var step: int = 0
var successes: int = 0
var last_result: String = ""
var prompts: PackedStringArray = ["ATK", "DASH", "SUB"]
var panel: PanelContainer
var title: Label
var progress: ProgressBar
var giant: Node3D
var hazard: MeshInstance3D
var hazard_timer: float = 0.0
var hazard_origin: Vector3
var hazard_released: bool = false
var wall_running: bool = false
var wall_time: float = 0.0
var wall_origin: Vector3
var wall_destination: Vector3

func _ready() -> void:
    layer = 45
    panel = PanelContainer.new()
    panel.position = Vector2(355, 265)
    panel.size = Vector2(570, 165)
    add_child(panel)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    panel.add_child(column)
    title = Label.new()
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 23)
    column.add_child(title)
    progress = ProgressBar.new()
    progress.max_value = 1.8
    progress.show_percentage = false
    column.add_child(progress)
    var row: HBoxContainer = HBoxContainer.new()
    column.add_child(row)
    for command: String in prompts:
        var button: Button = Button.new()
        button.text = command
        button.custom_minimum_size = Vector2(175, 56)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(press.bind(command))
        row.add_child(button)
    panel.hide()
    giant = Node3D.new()
    giant.name = "BossChakraAvatar"
    boss.add_child(giant)
    if boss.character_definition.character_id in ["itachi", "sasuke", "henrique"]:
        var visual: SusanooVisual = SusanooVisual.new()
        giant.add_child(visual)
        visual.set_form(3)
        visual.scale = Vector3.ONE * 1.45
        visual.position.y = -.95
    else:
        var visual: Node3D = Node3D.new()
        visual.set_script(preload("res://scripts/elemental_jutsu_visual.gd"))
        giant.add_child(visual)
        visual.configure("water" if boss.character_definition.character_id == "kisame" else "snake", 2.2, true)
        visual.position.y = .7
    giant.hide()
    hazard = MeshInstance3D.new()
    var disk: CylinderMesh = CylinderMesh.new()
    disk.top_radius = 2.5
    disk.bottom_radius = 2.5
    disk.height = .025
    disk.radial_segments = 24
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = Color(1.0, .2, .1, .35)
    disk.material = material
    hazard.mesh = disk
    boss.get_parent().add_child(hazard)
    hazard.hide()

func start_qte() -> bool:
    if not phase.is_empty() or fighter.is_defeated() or boss.is_defeated() or fighter.invulnerable_timer > 0.0:
        return false
    if not fighter.begin_cinematic_lock(self):
        return false
    if not boss.begin_cinematic_lock(self):
        fighter.end_cinematic_lock(self)
        return false
    phase = "qte"
    elapsed = 0.0
    step = 0
    successes = 0
    giant.show()
    fighter.camera_rig.begin_sequence(boss, 6.5)
    fighter.camera_rig.set_sequence_shot("clash")
    panel.show()
    _prompt()
    return true

func _prompt() -> void:
    title.text = "CHEFE • %d/3 • APERTE %s" % [step + 1, prompts[step]]
    progress.value = 1.8

func press(command: String) -> void:
    if phase != "qte":
        return
    if command == prompts[step]:
        successes += 1
    step += 1
    elapsed = 0.0
    if step >= prompts.size():
        _finish_qte()
    else:
        _prompt()

func press_attack() -> void:
    press("ATK")

func press_defense() -> void:
    press("SUB")

func _unhandled_input(event: InputEvent) -> void:
    if phase != "qte" or not event.is_pressed() or (event is InputEventKey and event.echo):
        return
    var command: String = ""
    if event.is_action_pressed("pad_attack") or (event is InputEventKey and event.physical_keycode == KEY_J) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
        command = "ATK"
    elif event.is_action_pressed("pad_dash") or (event is InputEventKey and event.physical_keycode == KEY_Q):
        command = "DASH"
    elif event.is_action_pressed("pad_substitution") or (event is InputEventKey and event.physical_keycode == KEY_F):
        command = "SUB"
    if not command.is_empty():
        press(command)
        get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
    if fighter.is_defeated() or boss.is_defeated():
        cancel("ko")
        giant.hide()
        hazard.hide()
        return
    if phase == "qte":
        if not fighter.refresh_cinematic_lock(self) or not boss.refresh_cinematic_lock(self):
            cancel("interrupted")
            return
        elapsed += delta
        progress.value = maxf(0.0, 1.8 - elapsed)
        if elapsed >= 1.8:
            press("TIMEOUT")
    elif phase == "wall_run":
        if not fighter.refresh_cinematic_lock(self):
            cancel("interrupted")
            return
        wall_time += delta
        var t: float = clampf(wall_time / 1.2, 0.0, 1.0)
        fighter.global_position = wall_origin.lerp(wall_destination, t) + Vector3.UP * sin(t * PI) * 2.0
        fighter.animation_state = "run"
        if t >= 1.0:
            cancel("finished")
    elif giant.visible:
        if giant.get_child(0).has_method("update_pose"):
            giant.get_child(0).update_pose(delta, hazard_timer > 0.0, clampf(hazard_timer / 1.1, 0.0, 1.0), boss.velocity, .55)
        hazard_timer -= delta
        if hazard_timer <= -3.0:
            hazard_origin = fighter.global_position
            hazard_origin.y = .03
            hazard.global_position = hazard_origin
            hazard.show()
            hazard_timer = 1.1
            hazard_released = false
        elif hazard_timer <= 0.0 and not hazard_released:
            hazard_released = true
            hazard.hide()
            boss.combat_feedback.spawn_impact(hazard_origin, "slam")
            preload("res://scripts/arena_interactions.gd").impact(boss, hazard_origin, "earth", 2.0, 20.0)
            var distance: float = Vector2(fighter.global_position.x - hazard_origin.x, fighter.global_position.z - hazard_origin.z).length()
            if distance < 2.5 and fighter.global_position.y < 2.0:
                fighter.receive_combat_hit(12.0, (fighter.global_position - boss.global_position).normalized(), 6.0, -5.0, .5)

func _finish_qte() -> void:
    var won: bool = successes >= 2
    last_result = "SUCCESS" if won else "FAILED"
    cancel("qte_done")
    if won:
        boss.receive_combat_hit(10.0, fighter.global_basis.z, 4.0, 0.0, .4)
        fighter.chakra = minf(fighter.max_chakra, fighter.chakra + 12.0)
        if fighter.team != null:
            fighter.team.storm = minf(100.0, fighter.team.storm + 20.0)
    else:
        fighter.receive_combat_hit(6.0, -fighter.global_basis.z, 4.0, 0.0, .4)
    hazard_timer = -1.0

func start_wall_run() -> bool:
    if not GameFlow.is_story_battle() or not giant.visible or not phase.is_empty() or fighter.is_defeated() or fighter.stagger_timer > 0.0 or not fighter.is_on_floor() or maxf(absf(fighter.global_position.x), absf(fighter.global_position.z)) < 26.0:
        return false
    if not fighter.begin_cinematic_lock(self):
        return false
    phase = "wall_run"
    wall_time = 0.0
    wall_origin = fighter.global_position
    wall_destination = wall_origin
    if absf(wall_origin.x) > absf(wall_origin.z):
        wall_destination.z = clampf(wall_origin.z + 8.0, -24.0, 24.0)
    else:
        wall_destination.x = clampf(wall_origin.x + 8.0, -24.0, 24.0)
    fighter.camera_rig.begin_sequence(boss, 1.3)
    fighter.camera_rig.set_sequence_shot("chain")
    return true

func cancel(_reason: String = "cancelled") -> void:
    phase = ""
    panel.hide()
    if is_instance_valid(fighter):
        fighter.end_cinematic_lock(self)
        fighter.camera_rig.end_sequence()
    if is_instance_valid(boss):
        boss.end_cinematic_lock(self)

func _exit_tree() -> void:
    cancel("scene_exit")
    if is_instance_valid(giant):
        giant.queue_free()
    if is_instance_valid(hazard):
        hazard.queue_free()
