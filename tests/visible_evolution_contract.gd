extends SceneTree
var failures: int = 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)
func frames(count: int) -> void:
    for i: int in range(count):
        await physics_frame
        await process_frame
func run() -> void:
    CharacterCatalog.initialize()
    var flow: Node = root.get_node("GameFlow")
    flow.player_character = CharacterCatalog.find("henrique")
    flow.cpu_character = CharacterCatalog.find("naruto")
    flow.versus_mode = true
    for id: String in ArenaCatalog.IDS:
        flow.arena_id = id
        var arena: Node3D = load("res://main.tscn").instantiate()
        root.add_child(arena)
        arena.get_node("EnemyDummy").set_physics_process(false)
        await frames(30)
        check(arena.get_node("Player").is_on_floor(), id + " has a playable floor")
        check(arena.get_node("ArenaPresentation").get_child_count() > 2, id + " has scenery")
        if "--capture" in OS.get_cmdline_user_args() and id not in ["training", "courtyard"]:
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://docs/captures/arena_" + id + ".png")
        arena.queue_free()
        await frames(4)
    var avatar: SusanooVisual = SusanooVisual.new()
    root.add_child(avatar)
    await frames(1)
    for form: int in range(4):
        avatar.set_form(form)
        check(avatar.partial_shell.visible == (form <= 1), "Partial ribcage visibility")
        check(avatar.skeletal_shell.visible == (form == 1), "Skeletal upper body visibility")
        check(avatar.imported_avatar.visible == (form >= 2), "Armored avatar visibility")
        avatar.set_quality(0)
        check(not avatar.wings[0].visible, "Low quality hides wings in all forms")
        avatar.set_quality(2)
        check(avatar.wings[0].visible == (form == 3), "Wings distinguish perfect form")
    avatar.queue_free()
    var hero: CharacterDefinition = CharacterCatalog.find("henrique")
    check(hero.jutsus.size() == 7, "Henrique has seven independently tuned powers")
    check(hero.find_jutsu("henrique_nagashi").hitbox_radius > 3.0, "Nagashi is an area pulse")
    check(hero.find_jutsu("henrique_genjutsu").hitstun > 1.0, "Genjutsu changes combat control")
    check(hero.find_jutsu("henrique_amaterasu").effect == "black_fire", "Amaterasu uses black flame status")
    check(hero.find_jutsu("henrique_katon_wave").tracking_strength == 0.0, "Wave trades tracking for width")
    flow.arena_id = "forest"
    var battle: Node3D = load("res://main.tscn").instantiate()
    root.add_child(battle)
    var player: Node3D = battle.get_node("Player")
    var enemy: Node3D = battle.get_node("EnemyDummy")
    enemy.set_physics_process(false)
    await frames(30)
    var before_health: float = enemy.health
    preload("res://scripts/black_flame_status.gd").attach(enemy, player)
    preload("res://scripts/black_flame_status.gd").attach(enemy, player)
    check(enemy.find_children("BlackFlames", "", false, false).size() == 1, "Amaterasu cannot stack unbounded statuses")
    await frames(60)
    check(enemy.health < before_health, "Black flames deal delayed damage through normal hit contract")
    enemy._respawn()
    await frames(2)
    check(not enemy.has_node("BlackFlames"), "Respawn clears burning status")
    preload("res://scripts/genjutsu_overlay.gd").attach(player)
    await frames(2)
    check(player.has_node("GenjutsuOverlay"), "Genjutsu overlays affected player's view")
    await frames(100)
    check(not player.has_node("GenjutsuOverlay"), "Genjutsu view restores after effect")
    var settings: Node = root.get_node("CombatSettings")
    var old_outfit: int = settings.henrique_outfit
    settings.henrique_outfit = 1
    player.rig_adapter._install_roster_visual_identity()
    var count: int = player.rig_adapter.roster_accessories.size()
    player.rig_adapter._install_roster_visual_identity()
    await frames(2)
    check(count == 3 and player.rig_adapter.roster_accessories.size() == count, "Outfit uses three anchored meshes without duplicate accumulation")
    settings.henrique_outfit = old_outfit
    battle.queue_free()
    await frames(4)
    print("VISIBLE EVOLUTION CONTRACT: ", "PASS" if failures == 0 else "FAIL")
    quit(0 if failures == 0 else 1)
