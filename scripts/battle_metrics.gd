extends Node
## Confirmed leader contacts only; no proximity or visual-effect inferred damage.
var elapsed: float = 0.0
var hits: int = 0
var guarded_hits: int = 0
var damage: float = 0.0
var received: float = 0.0
var best_combo: int = 0
var combo: int = 0
var combo_timeout: float = 0.0
func _ready() -> void:
    get_parent().get_node("Player").combat_hit_recorded.connect(record_hit)
    get_parent().get_node("EnemyDummy").combat_hit_recorded.connect(record_received)
func _physics_process(delta: float) -> void:
    elapsed += delta
    combo_timeout = maxf(0.0,combo_timeout-delta)
    if combo_timeout <= 0.0: combo = 0
func record_hit(amount: float, guarded: bool) -> void:
    if amount <= 0.0 or not is_finite(amount): return
    damage += amount
    if guarded:
        guarded_hits += 1
        return
    hits += 1
    combo += 1
    best_combo = maxi(best_combo,combo)
    combo_timeout = 1.6
func record_received(amount: float, _guarded: bool) -> void:
    if amount > 0.0 and is_finite(amount): received += amount
func reset() -> void:
    elapsed = 0.0
    hits = 0
    guarded_hits = 0
    damage = 0.0
    received = 0.0
    best_combo = 0
    combo = 0
    combo_timeout = 0.0
func summary() -> String:
    return "DANO %.1f  •  ACERTOS %d  •  MELHOR SEQUÊNCIA %d\nNA GUARDA %d  •  RECEBIDO %.1f  •  TEMPO %02d:%02d" % [damage,hits,best_combo,guarded_hits,received,int(elapsed)/60,int(elapsed)%60]
