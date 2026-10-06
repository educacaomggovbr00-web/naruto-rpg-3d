extends Node

# Logical combat state machine shared by the human player and CPU.
# Logical states may be more detailed than the current 27-animation library;
# get_visual_state() maps them onto clips that already exist on mobile.

var fighter: CharacterBody3D = null
var state: String = "idle"
var previous_state: String = "idle"
var state_time: float = 0.0
var transition_serial: int = 0

var forced_state: String = ""
var forced_remaining: float = 0.0
var recovery_pending: bool = false
var recovery_delay: float = 0.0

func _ready() -> void:
    fighter = get_parent() as CharacterBody3D

func configure(owner_fighter: CharacterBody3D) -> void:
    fighter = owner_fighter
    clear_transient()
    resolve()

func tick(delta: float) -> void:
    if fighter == null:
        return

    state_time += delta
    recovery_delay = maxf(recovery_delay - delta, 0.0)

    if forced_remaining > 0.0:
        forced_remaining = maxf(forced_remaining - delta, 0.0)
        if forced_remaining <= 0.0:
            forced_state = ""

    if (
        recovery_pending
        and recovery_delay <= 0.0
        and forced_state.is_empty()
        and fighter.is_on_floor()
    ):
        recovery_pending = false
        force_state("recovery", 0.18)

    resolve()

func resolve() -> String:
    if fighter == null:
        return state

    var next_state: String = _derive_state()
    _set_state(next_state)
    return state

func force_state(next_state: String, duration: float) -> void:
    if next_state.is_empty():
        return
    if forced_state != next_state:
        forced_state = next_state
        forced_remaining = maxf(duration, 0.01)
        _set_state(next_state)
    else:
        forced_remaining = maxf(forced_remaining, duration)

func clear_transient() -> void:
    forced_state = ""
    forced_remaining = 0.0
    recovery_pending = false
    recovery_delay = 0.0

func mark_hit(
    knockback: float,
    launch_velocity: float,
    hitstun: float,
    blocked: bool,
    guard_broken: bool = false
) -> String:
    if guard_broken:
        force_state("guard_break", maxf(hitstun, 0.55))
        return "guard_break"

    if blocked:
        force_state("guard_hit", maxf(hitstun, 0.14))
        return "guard_hit"

    var reaction: String = "hit_light"
    var duration: float = maxf(hitstun, 0.18)

    if launch_velocity > 1.0:
        reaction = "launcher"
        duration = maxf(duration, 0.34)
        recovery_pending = true
        recovery_delay = 0.12
    elif launch_velocity < -1.0:
        reaction = "slam"
        duration = maxf(duration, 0.38)
        recovery_pending = true
        recovery_delay = 0.08
    elif knockback >= 7.0:
        reaction = "knockdown"
        duration = maxf(duration, 0.42)
        recovery_pending = true
        recovery_delay = duration
    elif knockback >= 4.5:
        reaction = "knockback"
        duration = maxf(duration, 0.30)

    force_state(reaction, duration)
    return reaction

func mark_bounce(kind: String) -> void:
    recovery_pending = true
    recovery_delay = 0.10
    force_state("slam" if kind == "ground" else "knockdown", 0.32)

func mark_substitution() -> void:
    recovery_pending = false
    force_state("substitution", 0.20)

func mark_dash_confirm(blocked: bool) -> void:
    force_state("dash_recoil" if blocked else "dash_confirm", 0.10 if blocked else 0.065)

func mark_special_phase(phase: String, duration: float) -> void:
    if phase.is_empty():
        return
    force_state(phase, duration)

func allows_action(action: String) -> bool:
    var logical: String = resolve()

    if logical == "defeat":
        return false

    if action == "substitution":
        return true

    if logical == "cinematic":
        return false

    if logical in [
        "hit_light", "knockback", "launcher", "slam", "knockdown",
        "guard_break", "guard_hit", "substitution", "dash_recoil",
        "rasengan_startup", "rasengan_drive", "rasengan_impact"
    ]:
        return false

    if action == "movement":
        return logical in ["idle", "run", "air", "recovery"]

    if action == "attack":
        return logical in ["idle", "run", "air", "recovery", "dash_confirm", "chakra_dash"]

    if action in ["jutsu", "dash", "dodge", "guard", "charge"]:
        return logical in ["idle", "run", "air", "recovery", "attack", "air_attack"]

    return true

func get_state() -> String:
    resolve()
    return state

func get_previous_state() -> String:
    return previous_state

func get_state_time() -> float:
    return state_time

func get_transition_serial() -> int:
    return transition_serial

func get_visual_state() -> String:
    var logical: String = resolve()
    match logical:
        "hit_light":
            return "hit"
        "guard_hit":
            return "guard"
        "launcher", "slam", "knockdown":
            return "knockback"
        "recovery":
            return "land"
        "substitution":
            return "dodge"
        "dash_confirm":
            return "chakra_dash"
        "dash_recoil":
            return "hit"
        "rasengan_startup", "rasengan_drive", "rasengan_impact":
            return "jutsu"
        "rasengan_recovery":
            return "idle"
        "cinematic":
            return "jutsu"
        _:
            return logical

func camera_profile() -> Dictionary:
    var logical: String = get_state()
    var profile: Dictionary = {
        "fov_offset": 0.0,
        "distance_offset": 0.0,
        "roll_degrees": 0.0
    }

    match logical:
        "chakra_dash":
            profile.fov_offset = 1.5
            profile.distance_offset = 0.35
            profile.roll_degrees = -0.45
        "dash_confirm":
            profile.fov_offset = -1.0
            profile.distance_offset = -0.35
        "substitution":
            profile.fov_offset = 2.5
            profile.distance_offset = 0.45
            profile.roll_degrees = 0.8
        "launcher":
            profile.fov_offset = -1.5
            profile.distance_offset = 0.55
        "slam", "knockdown":
            profile.fov_offset = -2.0
            profile.distance_offset = 0.35
        "recovery":
            profile.fov_offset = -0.6
            profile.distance_offset = -0.15
        "rasengan_startup":
            profile.fov_offset = -2.2
            profile.distance_offset = -0.45
        "rasengan_drive":
            profile.fov_offset = 2.8
            profile.distance_offset = 0.30
            profile.roll_degrees = -0.6
        "rasengan_impact":
            profile.fov_offset = -4.0
            profile.distance_offset = -0.70
        "rasengan_recovery":
            profile.fov_offset = -0.8
        _:
            pass

    return profile

func _derive_state() -> String:
    if _bool_property("defeated", false) or _is_defeated_method():
        return "defeat"

    if _has_live_object_property("cinematic_owner"):
        return "cinematic"

    if not forced_state.is_empty() and forced_remaining > 0.0:
        return forced_state

    if _float_property("stagger_timer") > 0.0:
        return "knockback" if fighter.velocity.length() > 6.0 else "hit_light"

    if _float_property("dodge_timer") > 0.0:
        return "dodge"

    if _bool_property("is_guarding", false) or _bool_property("guarding", false):
        return "guard"

    if _float_property("chakra_dash_timer") > 0.0:
        return "chakra_dash"

    if _float_property("jutsu_timer") > 0.0:
        return "jutsu"

    if _bool_property("is_charging_chakra", false):
        return "chakra_charge"

    if _bool_property("attack_active", false):
        var airborne_attack: bool = _bool_property("attack_is_airborne", false) or _bool_property("attack_airborne", false)
        return "air_attack" if airborne_attack else "attack"

    if not fighter.is_on_floor():
        return "air"

    if Vector2(fighter.velocity.x, fighter.velocity.z).length() > 0.35:
        return "run"

    return "idle"

func _set_state(next_state: String) -> void:
    if next_state == state:
        return
    previous_state = state
    state = next_state
    state_time = 0.0
    transition_serial += 1

func _float_property(property_name: String) -> float:
    var value: Variant = fighter.get(property_name)
    if value == null:
        return 0.0
    return float(value)

func _bool_property(property_name: String, fallback: bool) -> bool:
    var value: Variant = fighter.get(property_name)
    if value == null:
        return fallback
    return bool(value)

func _has_live_object_property(property_name: String) -> bool:
    var value: Variant = fighter.get(property_name)
    return value is Object and is_instance_valid(value)

func _is_defeated_method() -> bool:
    return fighter.has_method("is_defeated") and bool(fighter.call("is_defeated"))
