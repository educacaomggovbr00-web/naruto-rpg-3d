extends Node
## The first scene has no meshes, animation library, pools or combat shaders.
func _ready() -> void:
    call_deferred("_open_selection")

func _open_selection() -> void:
    GameFlow.enter_selection()
