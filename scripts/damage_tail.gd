extends Control
## A bounded delayed segment shows recently lost health without hiding current HP.
var displayed_ratio: float = 1.0
var previous_ratio: float = 1.0
var hold: float = 0.0
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(delta: float) -> void:
    var bar: ProgressBar = get_parent() as ProgressBar
    var ratio: float = clampf(bar.value/maxf(bar.max_value,.001),0.0,1.0)
    if ratio < previous_ratio: hold = .35
    if ratio > displayed_ratio: displayed_ratio = ratio
    hold = maxf(hold-delta,0.0)
    if hold <= 0.0: displayed_ratio = move_toward(displayed_ratio,ratio,delta*.65)
    previous_ratio = ratio
    queue_redraw()
func _draw() -> void:
    var width: float = maxf(size.x-8.0,0.0)
    var segment: float = (displayed_ratio-previous_ratio)*width
    if segment > .5:
        draw_rect(Rect2(4.0+previous_ratio*width,3.0,segment,maxf(size.y-6.0,0.0)),Color("ffcf79"))
