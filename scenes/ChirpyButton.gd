extends Button


func _ready():
    connect("pressed", EmitterFactory, "emit", [null, "confirm"])


var first_frame = true
var had_focus = false
func _process(delta):
    if first_frame:
        first_frame = false
        had_focus = has_focus()
        return
    
    if has_focus() and !had_focus:
        EmitterFactory.emit(null, "ButtonB")
    
    had_focus = has_focus()
