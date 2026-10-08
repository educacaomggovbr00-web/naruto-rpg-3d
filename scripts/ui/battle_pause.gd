extends Node
## Compatibility facade for the consolidated scene-owned pause controller.
func pause_battle() -> void:
    var menu: Node = get_parent().get_parent().get_node_or_null("BattlePause")
    if menu != null and not menu.owns_pause:
        menu.toggle()
func resume_battle() -> void:
    var menu: Node = get_parent().get_parent().get_node_or_null("BattlePause")
    if menu != null:
        menu.resume()
