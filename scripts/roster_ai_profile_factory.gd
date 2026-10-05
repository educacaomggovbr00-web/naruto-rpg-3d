class_name RosterAIProfileFactory
extends RefCounted

const DATA: Dictionary = {
    "naruto":      ["balanced",   3.2, 0.76, 0.18, 0.24, 0.30, 0.48, 0.38, 0.12, 0.45, 30.0, 1.08],
    "sasuke":      ["rushdown",   2.7, 0.82, 0.20, 0.30, 0.26, 0.46, 0.44, 0.14, 0.42, 28.0, 1.12],
    "sakura":      ["power",      2.2, 0.70, 0.28, 0.18, 0.20, 0.32, 0.34, 0.13, 0.48, 36.0, 0.94],
    "shikamaru":   ["controller", 7.0, 0.48, 0.30, 0.20, 0.48, 0.68, 0.18, 0.10, 0.42, 38.0, 0.88],
    "choji":       ["power",      2.3, 0.70, 0.34, 0.12, 0.18, 0.28, 0.32, 0.14, 0.52, 40.0, 0.86],
    "ino":         ["controller", 6.3, 0.50, 0.24, 0.22, 0.44, 0.62, 0.20, 0.10, 0.42, 38.0, 0.92],
    "rock_lee":    ["rushdown",   1.7, 0.92, 0.12, 0.38, 0.18, 0.24, 0.58, 0.16, 0.55, 26.0, 1.22],
    "neji":        ["counter",    2.5, 0.62, 0.40, 0.32, 0.36, 0.38, 0.26, 0.12, 0.48, 34.0, 1.08],
    "tenten":      ["zoner",      7.6, 0.52, 0.22, 0.24, 0.52, 0.72, 0.18, 0.11, 0.40, 36.0, 1.02],
    "shino":       ["controller", 7.8, 0.46, 0.30, 0.18, 0.50, 0.76, 0.16, 0.10, 0.44, 40.0, 0.90],
    "kiba":        ["rushdown",   2.0, 0.88, 0.14, 0.34, 0.20, 0.30, 0.54, 0.13, 0.48, 28.0, 1.18],
    "hinata":      ["counter",    2.6, 0.60, 0.42, 0.28, 0.34, 0.36, 0.24, 0.10, 0.50, 36.0, 1.02],
    "gaara":       ["zoner",      8.6, 0.42, 0.42, 0.16, 0.46, 0.80, 0.12, 0.13, 0.48, 42.0, 0.82],
    "kankuro":     ["zoner",      7.8, 0.46, 0.30, 0.22, 0.50, 0.76, 0.16, 0.11, 0.44, 40.0, 0.88],
    "temari":      ["zoner",      8.8, 0.48, 0.24, 0.26, 0.56, 0.80, 0.14, 0.12, 0.42, 38.0, 0.96],
    "kakashi":     ["balanced",   4.2, 0.66, 0.34, 0.32, 0.42, 0.50, 0.30, 0.14, 0.46, 34.0, 1.04],
    "might_guy":   ["rushdown",   1.8, 0.94, 0.12, 0.36, 0.20, 0.22, 0.60, 0.16, 0.58, 26.0, 1.20],
    "jiraiya":     ["balanced",   4.8, 0.62, 0.28, 0.20, 0.40, 0.58, 0.30, 0.13, 0.46, 36.0, 0.96],
    "tsunade":     ["power",      2.1, 0.76, 0.30, 0.16, 0.18, 0.24, 0.38, 0.15, 0.58, 40.0, 0.90],
    "hiruzen":     ["balanced",   5.2, 0.60, 0.30, 0.22, 0.44, 0.62, 0.24, 0.13, 0.48, 38.0, 0.94],
    "orochimaru":  ["controller", 6.0, 0.56, 0.32, 0.28, 0.48, 0.66, 0.20, 0.14, 0.50, 38.0, 0.98],
    "kabuto":      ["counter",    3.3, 0.60, 0.38, 0.34, 0.36, 0.40, 0.24, 0.12, 0.52, 34.0, 1.04],
    "kimimaro":    ["rushdown",   2.4, 0.82, 0.24, 0.26, 0.24, 0.34, 0.46, 0.15, 0.56, 32.0, 1.08],
    "itachi":      ["controller", 6.8, 0.50, 0.38, 0.34, 0.50, 0.70, 0.18, 0.16, 0.48, 36.0, 1.02],
    "kisame":      ["power",      3.5, 0.72, 0.32, 0.16, 0.26, 0.48, 0.36, 0.15, 0.55, 38.0, 0.92]
}

static func build(id: String) -> AIProfileDefinition:
    var v: Array = DATA.get(id, [])
    if v.is_empty():
        return AIProfileDefinition.new()
    var p: AIProfileDefinition = AIProfileDefinition.new()
    p.archetype = String(v[0])
    p.preferred_distance = float(v[1])
    p.aggression = float(v[2])
    p.guard_bias = float(v[3])
    p.dodge_bias = float(v[4])
    p.strafe_bias = float(v[5])
    p.jutsu_bias = float(v[6])
    p.dash_bias = float(v[7])
    p.ultimate_bias = float(v[8])
    p.awakening_bias = float(v[9])
    p.charge_threshold = float(v[10])
    p.decision_speed = float(v[11])
    p.evidence = "OUR_APPROXIMATION"
    return p
