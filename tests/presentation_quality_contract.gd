extends SceneTree
var failures := 0
var checks := 0
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
    checks += 1
    if not ok:
        failures += 1
        push_error(message)
func frames(count: int):
    for i in range(count): await process_frame
func run():
    root.size = Vector2i(1280,720)
    root.content_scale_size = Vector2i(1280,720)
    CharacterCatalog.initialize()
    var menu = load("res://selection.tscn").instantiate()
    root.add_child(menu)
    await frames(5)
    check(menu.roster_buttons.size() == 26, "All fighters have selectable portrait cards")
    for definition in CharacterCatalog.READY:
        var portrait = load("res://assets/ui/portraits/" + definition.character_id + ".png")
        check(portrait != null and portrait.get_size() == Vector2(256,256), definition.character_id + " portrait exists at native size")
        for jutsu_id in definition.jutsus:
            var jutsu = definition.find_jutsu(jutsu_id)
            check(jutsu.effect in RosterVisualStyle.EFFECTS, definition.character_id + ": supported elemental family " + jutsu.effect)
    check(menu.start_button.get_global_rect().end.y <= 720, "Start action fits 720p")
    menu.animation_toggle.pressed.emit()
    await frames(5)
    check(menu.animation_gallery.visible and menu.start_button.get_global_rect().end.y <= 720, "Animation gallery retains accessible actions")
    menu.roster_side = "cpu"
    menu._pick_roster(2)
    check(menu.cpu_pick.selected == 2 and menu.preview.fighters[1].definition == CharacterCatalog.READY[2], "Portrait changes CPU without changing player")
    menu.roster_side = "player"
    menu._pick_roster(3)
    check(menu.player_pick.selected == 3 and menu.technique_pick.item_count == CharacterCatalog.READY[3].jutsus.size(), "Portrait updates technique list")
    check(menu.preview.get_child(0).msaa_3d == Viewport.MSAA_4X and menu.preview.get_child(0).scaling_3d_scale == 1.0, "Menu preview keeps full resolution and MSAA")
    var effect = menu.preview.technique_visual
    for kind in RosterVisualStyle.EFFECTS:
        effect.configure(kind,.4)
        effect.heading = Vector3.RIGHT
        effect.update_visual(.1)
        check(effect.tail_tip.is_finite() and effect.core.scale.is_finite(), kind + " finite presentation")
        if kind == "insect": check(not effect.core.visible, "Insects render as swarm")
        if kind == "bone": check(effect.core.mesh is CylinderMesh, "Bone projectile has spike geometry")
        if kind in ["steel","puppet","susanoo"]: check(effect.core.mesh is BoxMesh, kind + " uses directional blade geometry")
        if kind == "shadow": check(effect.core.scale.y < effect.core.scale.x*.1, "Shadow remains flat")
    menu.preview.preview_technique(String(menu.technique_pick.get_item_metadata(0)))
    check(menu.preview.technique_timer > 0, "Menu plays selected technique")
    menu.preview.show_fighters(CharacterCatalog.HENRIQUE,CharacterCatalog.NARUTO)
    check(menu.preview.technique_timer == 0 and not effect.visible, "Roster change clears previous technique")
    var quality = load("res://scripts/mobile_quality.gd")
    check(quality.TARGET_SCALE[2] == 1.0 and quality.MIN_ADAPTIVE_SCALE[0] >= .7, "Mobile resolution has clear quality floors")
    check(load("res://assets/ui/shinobi_theme.tres") is Theme, "Shared menu theme is available in exports")
    menu.queue_free()
    await frames(3)
    print("PRESENTATION QUALITY CONTRACT: ", "PASS" if failures == 0 else "FAIL", " (", checks, " checks)")
    quit(1 if failures else 0)
