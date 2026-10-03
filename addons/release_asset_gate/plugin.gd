@tool
extends EditorPlugin

var gate: EditorExportPlugin

func _enter_tree() -> void:
    gate = preload("res://addons/release_asset_gate/export_gate.gd").new()
    add_export_plugin(gate)

func _exit_tree() -> void:
    remove_export_plugin(gate)
    gate = null
