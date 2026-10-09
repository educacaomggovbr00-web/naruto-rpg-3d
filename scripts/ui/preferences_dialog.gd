extends AcceptDialog
func _ready() -> void:
    title = "CONTROLES E ÁUDIO"
    ok_button_text = "FECHAR"
    var column: VBoxContainer = VBoxContainer.new()
    add_child(column)
    preload("res://scripts/controls_audio_preferences_ui.gd").build(column)
    confirmed.connect(queue_free)
    canceled.connect(queue_free)
