extends CanvasLayer


const Action := preload("res://addons/editor_input_map/action.tscn")
const UI_ACTIONS_ORDER := ["ui_accept", "ui_select", "ui_cancel", "ui_focus_next", "ui_focus_prev", "ui_left", "ui_right", "ui_up", "ui_down", "ui_page_up", "ui_page_down", "ui_home", "ui_end"]

export var other_actions_order := PoolStringArray()
export var allow_add_actions := false
export var allow_add_inputs := true
export var allow_delete_actions := false
export var allow_delete_inputs := true

var key_confirm_ok: Button
var requester: Control
var cur_input: InputEvent


func _ready() -> void:
    set_process_unhandled_key_input(false)
    
    $InputMap/Margin/VBox/Top.visible = allow_add_actions
    
    $KeyConfirm.get_child(1).align = Label.ALIGN_CENTER
    if OS.is_ok_left_and_cancel_right():
        key_confirm_ok = $KeyConfirm.get_child(2).get_child(1)
        $JoyButtonConfirm.get_child(2).get_child(1).text = "Add"
        $JoyAxisConfirm.get_child(2).get_child(1).text = "Add"
        $MouseConfirm.get_child(2).get_child(1).text = "Add"
    else:
        key_confirm_ok = $KeyConfirm.get_child(2).get_child(3)
        $JoyButtonConfirm.get_child(2).get_child(3).text = "Add"
        $JoyAxisConfirm.get_child(2).get_child(3).text = "Add"
        $MouseConfirm.get_child(2).get_child(3).text = "Add"
        
    $JoyButtonConfirm/VBox/OptionButtons/Device.connect("item_selected", self, "on_option_button_selected", [$JoyButtonConfirm])
    $JoyButtonConfirm/VBox/OptionButtons/Index.connect("item_selected", self, "on_option_button_selected", [$JoyButtonConfirm])
    $JoyAxisConfirm/VBox/OptionButtons/Device.connect("item_selected", self, "on_option_button_selected", [$JoyAxisConfirm])
    $JoyAxisConfirm/VBox/OptionButtons/Index.connect("item_selected", self, "on_option_button_selected", [$JoyAxisConfirm])
    $MouseConfirm/VBox/OptionButtons/Device.connect("item_selected", self, "on_option_button_selected", [$MouseConfirm])
    $MouseConfirm/VBox/OptionButtons/Index.connect("item_selected", self, "on_option_button_selected", [$MouseConfirm])
    
    for action in UI_ACTIONS_ORDER:
        if InputMap.has_action(action):
            add_action_ready(action)
    for action in other_actions_order:
        if InputMap.has_action(action):
            add_action_ready(action)
    for action in InputMap.get_actions():
        if not action in UI_ACTIONS_ORDER and not action in other_actions_order:
            add_action_ready(action)
    

func _unhandled_key_input(event: InputEventKey) -> void:
    $KeyConfirm.dialog_text = event.as_text()
    cur_input = event
    key_confirm_ok.disabled = false


func add_action_ready(action: String) -> void:
    var a := Action.instance()
    a.init(action, allow_add_inputs, allow_delete_actions, allow_delete_inputs)
    $InputMap/Margin/VBox/Panel/VBox/Scroll/Actions.add_child(a)
    a.connect("input_requested", self, "on_input_requested", [a])
    for input in a.get_all_inputs():
        input.connect("input_requested", self, "on_input_requested", [input])

func find_focusable_child(parent : Node):
    if parent.has_method("is_visible_in_tree") and !parent.is_visible_in_tree():
        return null
    if parent is Control and parent.focus_mode == Control.FOCUS_ALL:
        return parent
    for c in parent.get_children():
        var r = find_focusable_child(c)
        if r:
            return r
    return null

func show_input_map() -> void:
    $InputMap.popup_centered()
    var r = find_focusable_child($InputMap/Margin/VBox/Panel/VBox/Scroll)
    print(r)
    if r:
        r.grab_focus()

func is_active():
    return $InputMap.visible

func hide_input_map():
    $InputMap.visible = false


func on_input_requested(id: int, r: Control) -> void:
    requester = r
    match id:
        0: # Key
            key_confirm_ok.disabled = true
            $KeyConfirm.dialog_text = "Press a key..."
            $KeyConfirm.popup_centered()
            set_process_unhandled_key_input(true)
        1: # Joy Button
            if r is HBoxContainer: # Input
                $JoyButtonConfirm/VBox/OptionButtons/Device.selected = r.input.device + 1
                $JoyButtonConfirm/VBox/OptionButtons/Index.selected = r.input.button_index
            else:
                $JoyButtonConfirm/VBox/OptionButtons/Device.selected = 1
                $JoyButtonConfirm/VBox/OptionButtons/Index.selected = 0
            $JoyButtonConfirm.popup_centered()
        2: # Joy Axis
            if r is HBoxContainer: # Input
                $JoyAxisConfirm/VBox/OptionButtons/Device.selected = r.input.device + 1
                $JoyAxisConfirm/VBox/OptionButtons/Index.selected = r.input.axis * 2
                if r.input.axis_value == 1:
                    $JoyAxisConfirm/VBox/OptionButtons/Index.selected += 1
            else:
                $JoyAxisConfirm/VBox/OptionButtons/Device.selected = 1
                $JoyAxisConfirm/VBox/OptionButtons/Index.selected = 0
            $JoyAxisConfirm.popup_centered()
        3: # Mouse Button
            if r is HBoxContainer: # Input
                $MouseConfirm/VBox/OptionButtons/Device.selected = r.input.device + 1
                $MouseConfirm/VBox/OptionButtons/Index.selected = r.input.button_index - 1
            else:
                $MouseConfirm/VBox/OptionButtons/Device.selected = 1
                $MouseConfirm/VBox/OptionButtons/Index.selected = 0
            $MouseConfirm.popup_centered()


func set_input() -> void:
    for input in InputMap.get_action_list(requester.action):
        if input is InputEventKey and cur_input is InputEventKey and input.scancode == cur_input.scancode:
            return
        if input is InputEventJoypadButton and cur_input is InputEventJoypadButton and input.button_index == cur_input.button_index:
            return
        if input is InputEventJoypadMotion and cur_input is InputEventJoypadMotion and input.axis == cur_input.axis and input.axis_value == cur_input.axis_value:
            return
        if input is InputEventMouseButton and cur_input is InputEventMouseButton and input.button_index == cur_input.button_index:
            return
    requester.set_input(cur_input)
    if requester is VBoxContainer: # Action
        requester.last_added_input.connect("input_requested", self, "on_input_requested", [requester.last_added_input])


func _on_KeyConfirm_confirmed() -> void:
    set_process_unhandled_key_input(false)
    set_input()


func _on_JoyButtonConfirm_confirmed() -> void:
    cur_input = InputEventJoypadButton.new()
    cur_input.device = $JoyButtonConfirm/VBox/OptionButtons/Device.selected - 1
    cur_input.button_index = $JoyButtonConfirm/VBox/OptionButtons/Index.selected
    set_input()


func _on_JoyAxisConfirm_confirmed() -> void:
    cur_input = InputEventJoypadMotion.new()
    cur_input.device = $JoyAxisConfirm/VBox/OptionButtons/Device.selected - 1
    cur_input.axis = $JoyAxisConfirm/VBox/OptionButtons/Index.selected / 2
    cur_input.axis_value = -1 if $JoyAxisConfirm/VBox/OptionButtons/Index.selected % 2 == 0 else 1
    set_input()


func _on_MouseConfirm_confirmed() -> void:
    cur_input = InputEventMouseButton.new()
    cur_input.device = $MouseConfirm/VBox/OptionButtons/Device.selected - 1
    cur_input.button_index = $MouseConfirm/VBox/OptionButtons/Index.selected + 1
    set_input()


func _on_LineEdit_text_changed(new_text: String) -> void:
    $InputMap/Margin/VBox/Top/Add.disabled = new_text == "" or InputMap.has_action(new_text)
    $InputMap/Margin/VBox/Top/Warning.visible = InputMap.has_action(new_text)
    if InputMap.has_action(new_text):
        $InputMap/Margin/VBox/Top/Warning.text = "An action with the name '%s' already exists." % new_text


func _on_LineEdit_text_entered(_new_text: String) -> void:
    add_action()


func add_action() -> void:
    if InputMap.has_action($InputMap/Margin/VBox/Top/LineEdit.text):
        return
    InputMap.add_action($InputMap/Margin/VBox/Top/LineEdit.text)
    var a := Action.instance()
    a.init($InputMap/Margin/VBox/Top/LineEdit.text, allow_add_inputs, allow_delete_actions, allow_delete_inputs)
    $InputMap/Margin/VBox/Panel/VBox/Scroll/Actions.add_child(a)
    a.connect("input_requested", self, "on_input_requested", [a])
    $InputMap/Margin/VBox/Top/LineEdit.text = ""
    $InputMap/Margin/VBox/Top/Add.disabled = true


func on_option_button_selected(_index:int, confirm: ConfirmationDialog) -> void:
    confirm.set_as_minsize()
