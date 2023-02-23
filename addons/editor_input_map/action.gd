extends VBoxContainer


signal input_requested(id)
signal input_added(input)

const InputClass := preload("res://addons/editor_input_map/input.tscn")

var action: String
var last_added_input: HBoxContainer
var allow_delete_inputs: bool

onready var add_pop: PopupMenu = $HBox/Add.get_popup()


func _ready() -> void:
    add_pop.connect("id_pressed", self, "on_add_id_pressed")


func init(a: String, can_add: bool, can_delete: bool, can_delete_inputs: bool) -> void:
    action = a
    $HBox/Name.text = a
    $HBox/Deadzone.value = InputMap.action_get_deadzone(action)
    for input in InputMap.get_action_list(a):
        var i := InputClass.instance()
        i.init(action, input, can_delete_inputs)
        $Inputs.add_child(i)
    $HBox/Add.visible = can_add
    $HBox/Delete.visible = can_delete
    allow_delete_inputs = can_delete_inputs


func get_all_inputs() -> Array:
    return $Inputs.get_children()


func _on_Name_toggled(button_pressed: bool) -> void:
    $Inputs.visible = not button_pressed


func _on_Deadzone_value_changed(value: float) -> void:
    InputMap.action_set_deadzone(action, value)


func on_add_id_pressed(id: int) -> void:
    emit_signal("input_requested", id)


func _on_Delete_pressed() -> void:
    InputMap.erase_action(action)
    queue_free()


func set_input(input: InputEvent) -> void:
    var i := InputClass.instance()
    i.init(action, input, allow_delete_inputs)
    $Inputs.add_child(i)
    last_added_input = i
