extends Node
## No alternative combat controller: missions use main.tscn unchanged.
var finished: bool = false
var boss_intro_timer: float = 0.0
var boss_banner: Label = null
var boss_phase_triggered: bool = false
var boss_phase_threshold: float = 0.32
var mob_enemies: Array[CharacterBody3D] = []
var boss_encounter: CanvasLayer = null

func _ready() -> void:
    var metrics: Node = Node.new()
    metrics.name = "BattleMetrics"
    metrics.set_script(preload("res://scripts/battle_metrics.gd"))
    get_parent().add_child.call_deferred(metrics)
    var pause_menu: CanvasLayer = CanvasLayer.new()
    pause_menu.name = "BattlePause"
    pause_menu.set_script(preload("res://scripts/battle_pause.gd"))
    get_parent().add_child.call_deferred(pause_menu)
    var audio: Node = Node.new()
    audio.name = "AudioManager"
    audio.set_script(preload("res://scripts/audio_manager.gd"))
    get_parent().add_child.call_deferred(audio)
    var layer: CanvasLayer = CanvasLayer.new()
    layer.layer = 30
    var button: Button = Button.new()
    button.text = "ALDEIA"
    button.position = Vector2(515, 12)
    button.custom_minimum_size = Vector2(155, 46)
    button.pressed.connect(GameFlow.enter_world)
    layer.add_child(button)
    add_child(layer)
    var versus: Button = Button.new()
    versus.text = "VERSUS"
    versus.position = Vector2(680, 12)
    versus.custom_minimum_size = Vector2(140, 46)
    versus.pressed.connect(GameFlow.enter_selection)
    layer.add_child(versus)
    if not GameFlow.pending_battle.is_empty() and int(GameFlow.progress.supplies) > 0:
        var fighter: Node = get_parent().get_node("Player")
        fighter.ninja_tools.stock.bomb += 1
        fighter.ninja_tools.stock.food_pills += 1
        GameFlow.progress.supplies -= 1
        GameFlow.save_progress()
    call_deferred("_apply_rpg_battle_setup")
    call_deferred("_setup_expansion")

func _setup_expansion() -> void:
    var fighter: CharacterBody3D = get_parent().get_node("Player")
    var enemy: CharacterBody3D = get_parent().get_node("EnemyDummy")
    var arena: Node3D = Node3D.new()
    arena.name = "ArenaInteractions"
    arena.set_script(preload("res://scripts/arena_interactions.gd"))
    get_parent().add_child(arena)
    if GameFlow.battle_rules_enabled:
        for actor: CharacterBody3D in [fighter, enemy]:
            var condition: Node3D = Node3D.new()
            condition.name = "BattleCondition"
            condition.set_script(preload("res://scripts/battle_condition.gd"))
            actor.add_child(condition)
        if GameFlow.arcade_mode == "boss" or (GameFlow.is_story_battle() and bool(GameFlow.current_story_battle_data().get("boss", false))):
            boss_encounter = CanvasLayer.new()
            boss_encounter.name = "BossEncounter"
            boss_encounter.set_script(preload("res://scripts/boss_encounter.gd"))
            boss_encounter.fighter = fighter
            boss_encounter.boss = enemy
            add_child(boss_encounter)
    if GameFlow.team_enabled:
        for actor: CharacterBody3D in [fighter, enemy]:
            if actor == enemy and GameFlow.arcade_mode == "mob":
                continue
            var team: CombatTeam = CombatTeam.new()
            team.name = "PlayerTeam" if actor == fighter else "EnemyTeam"
            team.add_to_group("combat_teams")
            team.configure(actor, enemy if actor == fighter else fighter, GameFlow.player_partners if actor == fighter else GameFlow.cpu_partners)
            get_parent().add_child(team)
    if GameFlow.team_enabled or GameFlow.battle_rules_enabled:
        var team_hud: CanvasLayer = CanvasLayer.new()
        team_hud.name = "TeamHUD"
        team_hud.set_script(preload("res://scripts/team/team_hud.gd"))
        team_hud.fighter = fighter
        team_hud.enemy = enemy
        get_parent().add_child(team_hud)
    if GameFlow.arcade_mode == "mob":
        _setup_mob(enemy)

func _setup_mob(enemy: CharacterBody3D) -> void:
    mob_enemies.append(enemy)
    var definitions: PackedStringArray = ["shino", "kiba"]
    for index: int in range(2):
        var template: Node = load("res://main.tscn").instantiate()
        var actor: CharacterBody3D = template.get_node("EnemyDummy")
        template.remove_child(actor)
        template.free()
        actor.name = "MobNinja%d" % index
        actor.character_override = CharacterCatalog.find(definitions[index])
        actor.position = Vector3(-4.0 if index == 0 else 4.0, 1.0, -7.0)
        actor.enable_arsenal = false
        actor.reactive_substitution = false
        get_parent().add_child(actor)
        actor.max_health = 45.0
        actor.health = 45.0
        actor.attack_damage = 6.0
        actor.decision_interval_min *= 1.4
        actor.decision_interval_max *= 1.4
        mob_enemies.append(actor)

func _apply_rpg_battle_setup() -> void:
    if GameFlow.versus_mode:
        var actor: Node = get_parent().get_node("Player")
        var opponent: Node = get_parent().get_node("EnemyDummy")
        if GameFlow.arcade_mode == "training":
            opponent.training_behavior = GamePreferences.training_behavior if GamePreferences.training_behavior < 2 else -1
            opponent.set_physics_process(true)
            opponent.enable_arsenal = false
            opponent.reactive_substitution = false
            var coach: CanvasLayer = CanvasLayer.new()
            coach.name = "TrainingCoach"
            coach.set_script(preload("res://scripts/training_coach.gd"))
            coach.fighter = actor
            add_child(coach)
        elif GameFlow.arcade_mode == "survival" and GameFlow.arcade_health > 0.0:
            actor.health = minf(actor.max_health, GameFlow.arcade_health)
        elif GameFlow.arcade_mode == "boss":
            opponent.max_health *= 1.35
            opponent.health = opponent.max_health
            _show_boss_intro("DESAFIO " + opponent.character_definition.display_name, opponent)
        if GameFlow.battle_mode == "survival" and GameFlow.arcade_mode.is_empty():
            _setup_free_battle()
        elif GameFlow.arcade_mode == "survival":
            var pressure: float = minf(float(GameFlow.survival_wave-1)*.035,.30)
            opponent.decision_interval_min /= 1.0+pressure
            opponent.decision_interval_max /= 1.0+pressure
        if not GameFlow.arcade_mode.is_empty() and GameFlow.arcade_mode != "boss":
            _show_story_intro(GameFlow.arcade_label())
        return
    GameFlow.ensure_rpg_progress()
    var fighter: Node = get_parent().get_node("Player")
    var cpu: Node = get_parent().get_node("EnemyDummy")
    var level: int = int(GameFlow.progress.level)

    # Small persistent bonuses: progression matters without invalidating character kits.
    var vitality_rank: int = GameFlow.skill_rank("vitality")
    var chakra_rank: int = GameFlow.skill_rank("chakra")
    var power_rank: int = GameFlow.skill_rank("power")
    var agility_rank: int = GameFlow.skill_rank("agility")

    fighter.max_health += float(maxi(level - 1, 0)) * 2.0 + float(vitality_rank) * 6.0
    fighter.health = fighter.max_health
    fighter.max_chakra += float(maxi(level - 1, 0)) * 1.25 + float(chakra_rank) * 5.0
    fighter.chakra = fighter.max_chakra
    fighter.rpg_damage_multiplier = 1.0 + float(power_rank) * 0.04
    fighter.move_speed += float(agility_rank) * 0.30
    fighter.run_speed += float(agility_rank) * 0.45

    var inventory: Dictionary = GameFlow.progress.inventory
    var stock_map: Dictionary = {
        "ramen": "ramen",
        "food_pill": "food_pills",
        "bomb": "bomb",
        "kunai_pack": "kunai_rain"
    }
    var consumed: bool = false
    for inventory_id: String in stock_map:
        if int(inventory.get(inventory_id, 0)) <= 0:
            continue
        var stock_id: String = String(stock_map[inventory_id])
        fighter.ninja_tools.stock[stock_id] = int(fighter.ninja_tools.stock.get(stock_id, 0)) + 1
        inventory[inventory_id] = int(inventory[inventory_id]) - 1
        consumed = true
    if consumed:
        GameFlow.save_progress()

    if not GameFlow.is_story_battle():
        return

    var mission: Dictionary = GameFlow.current_story_battle_data()
    if mission.is_empty():
        return

    boss_phase_triggered = false
    if bool(mission.get("boss", false)):
        var chapter: int = int(mission.get("chapter", 1))
        var boss_multiplier: float = 1.22 + minf(float(chapter) * 0.025, 0.18)
        cpu.max_health *= boss_multiplier
        cpu.health = cpu.max_health
        cpu.max_chakra *= 1.10
        cpu.chakra = cpu.max_chakra
        boss_intro_timer = 1.15
        _show_boss_intro(String(mission.get("title", "BOSS")), cpu)
    else:
        _show_story_intro(String(mission.get("title", "MISSÃO")))

func _show_story_intro(title: String) -> void:
    var layer: CanvasLayer = get_child(0) as CanvasLayer
    boss_banner = Label.new()
    boss_banner.text = "MISSÃO • " + title.to_upper()
    boss_banner.position = Vector2(320, 92)
    boss_banner.size = Vector2(640, 50)
    boss_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_banner.add_theme_font_size_override("font_size", 24)
    layer.add_child(boss_banner)
    boss_intro_timer = 0.85

func _show_boss_intro(title: String, cpu: Node) -> void:
    var layer: CanvasLayer = get_child(0) as CanvasLayer
    boss_banner = Label.new()
    boss_banner.text = "BOSS • " + title.to_upper()
    boss_banner.position = Vector2(260, 86)
    boss_banner.size = Vector2(760, 58)
    boss_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_banner.add_theme_font_size_override("font_size", 30)
    boss_banner.add_theme_color_override("font_color", Color("ffd089"))
    layer.add_child(boss_banner)
    var fighter: Node = get_parent().get_node("Player")
    if fighter.camera_rig.has_method("begin_sequence"):
        fighter.camera_rig.call("begin_sequence", cpu, 1.05)
        fighter.camera_rig.call("set_sequence_shot", "clash")

func _physics_process(_delta: float) -> void:
    if boss_intro_timer > 0.0:
        boss_intro_timer = maxf(boss_intro_timer - _delta, 0.0)
        if boss_intro_timer <= 0.0 and is_instance_valid(boss_banner):
            boss_banner.queue_free()
            boss_banner = null

    if finished or (GameFlow.pending_battle.is_empty() and not GameFlow.versus_mode):
        return
    var fighter: Node = get_parent().get_node("Player")
    var cpu: Node = get_parent().get_node("EnemyDummy")

    if (GameFlow.is_story_battle() or GameFlow.arcade_mode == "boss") and not boss_phase_triggered and cpu.targetable:
        var mission: Dictionary = GameFlow.current_story_battle_data() if GameFlow.is_story_battle() else {"boss":true,"title":cpu.character_definition.display_name}
        if (
            bool(mission.get("boss", false))
            and cpu.health <= cpu.max_health * boss_phase_threshold
        ):
            _trigger_boss_phase(cpu, fighter, mission)

    if GameFlow.arcade_mode == "training":
        fighter.chakra = fighter.max_chakra
        if fighter.combo_display_timer <= 0.0 and cpu.stagger_timer <= 0.0 and cpu.is_on_floor() and not fighter.attack_active and fighter.jutsu_timer <= 0.0:
            cpu.health = cpu.max_health
        if fighter.defeated:
            fighter.call("_respawn")
        if not cpu.targetable:
            cpu.call("_respawn")
        return
    if GameFlow.arcade_mode == "mob":
        var alive: int = 0
        for actor: CharacterBody3D in mob_enemies:
            if actor.targetable:
                alive += 1
            else:
                actor.set_physics_process(false)
        if fighter.defeated or alive == 0:
            finished = true
            GameFlow.finish_battle(alive == 0 and not fighter.defeated)
        return
    if fighter.defeated or not cpu.targetable:
        if GameFlow.versus_mode and GameFlow.battle_mode == "training":
            fighter.call("_respawn")
            cpu.call("_respawn")
            fighter.chakra = fighter.max_chakra
            _show_phase_banner("TREINAMENTO • NOVA TENTATIVA")
            return
        finished = true
        GameFlow.finish_battle(not cpu.targetable and not fighter.defeated)

    if GameFlow.versus_mode and GameFlow.battle_mode == "training":
        fighter.chakra = fighter.max_chakra
        if fighter.combo_display_timer <= 0.0 and cpu.stagger_timer <= 0.0 and cpu.is_on_floor() and not fighter.attack_active and fighter.jutsu_timer <= 0.0:
            cpu.health = cpu.max_health
            cpu.guard_meter = minf(cpu.guard_meter + _delta * 30.0, 100.0)

func _setup_free_battle() -> void:
    var fighter: Node = get_parent().get_node("Player")
    var cpu: Node = get_parent().get_node("EnemyDummy")
    var title: String = "VERSUS • " + GamePreferences.DIFFICULTIES[GamePreferences.difficulty]
    if GameFlow.battle_mode == "training":
        cpu.reactive_substitution = false
        title = "TREINAMENTO • CHAKRA INFINITO • NINJA: AGARRÃO"
    elif GameFlow.battle_mode == "survival":
        fighter.health = fighter.max_health * GameFlow.survival_health_ratio
        # Bounded pressure increase; hitboxes, damage and animation timing remain shared.
        var pressure: float = minf(float(GameFlow.survival_wave - 1) * 0.035, 0.30)
        cpu.decision_interval_min /= 1.0 + pressure
        cpu.decision_interval_max /= 1.0 + pressure
        title = "SOBREVIVÊNCIA • DUELO %d • RECORDE %d" % [GameFlow.survival_wave, int(GameFlow.progress.get("survival_best", 0))]
    _show_phase_banner(title)

func _trigger_boss_phase(cpu: Node, fighter: Node, mission: Dictionary) -> void:
    boss_phase_triggered = true
    cpu.chakra = cpu.max_chakra
    cpu.guard_meter = 100.0
    cpu.attack_cooldown = 0.0
    cpu.arsenal_delay = 0.0
    cpu.decision_interval_min = maxf(cpu.decision_interval_min * 0.78, 0.10)
    cpu.decision_interval_max = maxf(cpu.decision_interval_max * 0.78, 0.16)
    cpu.move_speed *= 1.08

    if cpu.has_method("_cancel_abilities"):
        cpu.call("_cancel_abilities")
    cpu.stagger_timer = 0.0
    cpu.invulnerable_timer = maxf(cpu.invulnerable_timer, 0.30)

    if is_instance_valid(cpu.awakening) and cpu.awakening.has_method("start"):
        cpu.awakening.call("start")

    _show_phase_banner("FASE 2 • " + String(mission.get("title", "BOSS")).to_upper())
    if is_instance_valid(boss_encounter):
        boss_encounter.call_deferred("start_qte")

    if is_instance_valid(fighter.camera_rig):
        if fighter.camera_rig.has_method("begin_sequence"):
            fighter.camera_rig.call("begin_sequence", cpu, 0.70)
            fighter.camera_rig.call("set_sequence_shot", "clash")
        if fighter.camera_rig.has_method("add_combat_impact"):
            fighter.camera_rig.call("add_combat_impact", 0.14, 2.8)

    var feedback: Node = get_parent().get_node_or_null("CombatFeedback")
    if feedback != null and feedback.has_method("spawn_dash_burst"):
        feedback.call("spawn_dash_burst", cpu.global_position)

func _show_phase_banner(text_value: String) -> void:
    if is_instance_valid(boss_banner):
        boss_banner.queue_free()
    var layer: CanvasLayer = get_child(0) as CanvasLayer
    boss_banner = Label.new()
    boss_banner.text = text_value
    boss_banner.position = Vector2(250, 86)
    boss_banner.size = Vector2(780, 58)
    boss_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_banner.add_theme_font_size_override("font_size", 28)
    boss_banner.add_theme_color_override("font_color", Color("ffbd69"))
    layer.add_child(boss_banner)
    boss_intro_timer = 0.95
