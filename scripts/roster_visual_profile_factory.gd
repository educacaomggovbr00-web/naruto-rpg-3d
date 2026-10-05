class_name RosterVisualProfileFactory
extends RefCounted

## Procedural visual identity for the 21 roster slots that still share rigged.glb.
## Colors/accessories are project-authored shorthand, intentionally low-cost for mobile.
const DATA: Dictionary = {
    "shikamaru": [Color("344b32"), Color("171c20"), Color("9ca68b"), ["ponytail", "vest"]],
    "choji": [Color("7d3f2b"), Color("2a2423"), Color("d9c18f"), ["headband", "vest", "arm_bands"]],
    "ino": [Color("7956a8"), Color("ece3d2"), Color("b5a2d8"), ["ponytail", "sash"]],
    "rock_lee": [Color("237c35"), Color("18251a"), Color("d94834"), ["headband", "leg_bands"]],
    "neji": [Color("ded8ca"), Color("3c3540"), Color("9b89bb"), ["long_hair", "vest"]],
    "tenten": [Color("7b4935"), Color("283438"), Color("d5aa6f"), ["twin_buns", "vest"]],
    "shino": [Color("5e6655"), Color("242827"), Color("6e7f9d"), ["hood", "glasses", "coat"]],
    "kiba": [Color("72746b"), Color("2c3030"), Color("b9b7a4"), ["hood", "fur_collar"]],
    "hinata": [Color("d3d6e7"), Color("3f4c78"), Color("9f8fc8"), ["hood", "coat"]],
    "gaara": [Color("6f3029"), Color("352d2a"), Color("c9a05c"), ["gourd", "sash"]],
    "kankuro": [Color("30293c"), Color("16151a"), Color("8b6a56"), ["hood", "puppet_pack"]],
    "temari": [Color("d2c69c"), Color("3a3030"), Color("7c5f44"), ["fan", "sash"]],
    "might_guy": [Color("2a833d"), Color("1b2520"), Color("d54b35"), ["vest", "leg_bands"]],
    "jiraiya": [Color("6c3942"), Color("d6d2c6"), Color("c08b54"), ["long_hair", "scroll", "vest"]],
    "tsunade": [Color("b7b192"), Color("556f5a"), Color("8f4669"), ["coat", "sash"]],
    "hiruzen": [Color("38434c"), Color("22282d"), Color("745d43"), ["armor", "staff", "headband"]],
    "orochimaru": [Color("d5d1c8"), Color("302b3e"), Color("806a9a"), ["long_hair", "rope_belt"]],
    "kabuto": [Color("6d768b"), Color("d8d9d4"), Color("8fb4b8"), ["glasses", "ponytail"]],
    "kimimaro": [Color("e3e2d9"), Color("805869"), Color("c8c5b6"), ["long_hair", "bone_spikes"]],
    "itachi": [Color("242126"), Color("791f28"), Color("b9b5aa"), ["cloak", "headband"]],
    "kisame": [Color("345f75"), Color("26363f"), Color("91a8ad"), ["sword_back", "vest"]]
}

static func build(id: String) -> RosterVisualProfileDefinition:
    var values: Array = DATA.get(id, [])
    if values.is_empty():
        return null
    var profile: RosterVisualProfileDefinition = RosterVisualProfileDefinition.new()
    profile.primary_color = values[0]
    profile.secondary_color = values[1]
    profile.accent_color = values[2]
    profile.tint_strength = 0.28
    var tags: Array = values[3]
    var packed: PackedStringArray = PackedStringArray()
    for tag: Variant in tags:
        packed.append(String(tag))
    profile.accessories = packed
    profile.evidence = "OUR_APPROXIMATION"
    return profile
