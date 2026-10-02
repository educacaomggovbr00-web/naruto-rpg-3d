extends Area3D

@export var fighter_path: NodePath

func get_fighter() -> Node:
    if fighter_path.is_empty():
        return get_parent()
    return get_node(fighter_path)
