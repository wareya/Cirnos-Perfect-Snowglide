extends HBoxContainer


signal input_requested(id)

const JOY_BUTTON_TEXT := [
    "DualShock Cross, Xbox A, Nintendo B",
    "DualShock Circle, Xbox B, Nintendo A",
    "DualShock Square, Xbox X, Nintendo Y",
    "DualShock Triangle, Xbox Y, Nintendo X",
    "L, L1",
    "R, R1",
    "L2",
    "R2",
    "L3",
    "R3",
    "Select, DualShock Share, Nintendo -",
    "Start, DualShock Options, Nintendo +",
    "D-Pad Up",
    "D-Pad Down",
    "D-Pad Left",
    "D-Pad Right",
    "Home, DualShock PS, Guide",
    "Xbox Share, PS5 Microphone, Nintendo Capture",
    "Xbox Paddle 1",
    "Xbox Paddle 2",
    "Xbox Paddle 3",
    "Xbox Paddle 4",
    "PS4/5 Touchpad",
]
const JOY_AXIS_TEXT := [
    "Axis 0 - (Left Stick Left)",
    "Axis 0 + (Left Stick Right)",
    "Axis 1 - (Left Stick Up)",
    "Axis 1 + (Left Stick Down)",
    "Axis 2 - (Right Stick Left)",
    "Axis 2 + (Right Stick Right)",
    "Axis 3 - (Right Stick Up)",
    "Axis 3 + (Right Stick Down)",
    "Axis 4 -",
    "Axis 4 +",
    "Axis 5 -",
    "Axis 5 +",
    "Axis 6 -",
    "Axis 6 + (L2)",
    "Axis 7 -",
    "Axis 7 + (R2)",
    "Axis 8 -",
    "Axis 8 +",
    "Axis 9 -",
    "Axis 9 +",
]
const MOUSE_BUTTON_TEXT := [
    "Left Button",
    "Right Button",
    "Middle Button",
    "Wheel Up Button",
    "Wheel Down Button",
    "Wheel Left Button",
    "Wheel Right Button",
    "X Button 1",
    "X Button 2",
]

var action: String
var input: InputEvent
var id: int


func init(a:String, i: InputEvent, can_delete_inputs: bool) -> void:
    action = a
    input = i
    if i is InputEventKey:
        id = 0
    elif i is InputEventJoypadButton:
        id = 1
    elif i is InputEventJoypadMotion:
        id = 2
    elif i is InputEventMouseButton:
        id = 3
    $Name.text = get_input_text(i)
    $Delete.visible = can_delete_inputs
    

func get_input_text(i: InputEvent) -> String:
    if i is InputEventKey:
        return i.as_text()
    elif i is InputEventJoypadButton:
        return "Device %d, Button %d (%s)." % [i.device, i.button_index, JOY_BUTTON_TEXT[i.button_index]]
    elif i is InputEventJoypadMotion:
        var index = i.axis * 2
        if i.axis_value == 1:
            index += 1
        return "Device %d, %s." % [i.device, JOY_AXIS_TEXT[index]]
    elif i is InputEventMouseButton:
        return "Device %d, %s." % [i.device, MOUSE_BUTTON_TEXT[i.button_index-1]]
    return i.as_text()


func _on_Edit_pressed() -> void:
    emit_signal("input_requested", id)


func _on_Delete_pressed() -> void:
    InputMap.action_erase_event(action, input)
    queue_free()


func set_input(i: InputEvent) -> void:
    InputMap.action_erase_event(action, input)
    input = i
    InputMap.action_add_event(action, input)
    $Name.text = get_input_text(i)
