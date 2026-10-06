extends SceneTree

const SCRIPT_PATHS = [
	"res://scripts/rigged_character_adapter.gd",
	"res://scripts/character_visual_adapter.gd",
	"res://scripts/licensed_combat_ninja.gd",
]

func _initialize() -> void:
	var failures: int = 0
	for path: String in SCRIPT_PATHS:
		var loaded_script: Script = load(path) as Script
		if loaded_script == null:
			push_error("Combat skin script failed to load: " + path)
			failures += 1
	print("LICENSED COMBAT SKIN COMPILE: %s (%d scripts)" % ["PASS" if failures == 0 else "FAIL", SCRIPT_PATHS.size()])
	quit(0 if failures == 0 else 1)
