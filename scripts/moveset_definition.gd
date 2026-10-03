class_name MovesetDefinition
extends Resource
@export var ground: Array[AttackDefinition] = []
@export var aerial: Array[AttackDefinition] = []
@export var neutral_finisher: AttackDefinition
@export var up_finisher: AttackDefinition
@export var down_finisher: AttackDefinition
@export var side_finisher: AttackDefinition
@export var branch_step: int = 3

func attack(step: int, airborne: bool, branch: String = "neutral") -> AttackDefinition:
    var chain: Array[AttackDefinition] = aerial if airborne else ground
    if chain.is_empty():
        return null
    var index: int = clampi(step - 1, 0, chain.size() - 1)
    if not airborne and index == chain.size() - 1:
        match branch:
            "up": return up_finisher
            "down": return down_finisher
            "side": return side_finisher
            _: return neutral_finisher
    return chain[index]
