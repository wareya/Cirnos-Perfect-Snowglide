extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    $CanvasLayer/Buttons.visible = true
    $CanvasLayer/ColorRect.visible = false
    $CanvasLayer/RichTextLabel.visible = false
    $CanvasLayer/ClearButton.visible = false
    
    var i = 1
    for stage in Manager.stages.slice(0, -1):
        var button = preload("res://scenes/MainMenuButton.tscn").instance()
        button.text = "Stage %d" % [i]
        $CanvasLayer/Buttons.add_child(button)
        button.connect("pressed", Manager, "go_to_stage", [i])
        
        i += 1
    
    var button = preload("res://scenes/MainMenuButton.tscn").instance()
    button.text = "Playground"
    $CanvasLayer/Buttons.add_child(button)
    button.connect("pressed", Manager, "go_to_stage", [-1])
    
    button = preload("res://scenes/MainMenuButton.tscn").instance()
    button.text = "Records"
    $CanvasLayer/Buttons.add_child(button)
    button.connect("pressed", self, "show_records")
    
    $CanvasLayer/Buttons.get_children().front().grab_focus()
    
    $CanvasLayer/ClearButton.connect("pressed", self, "clear_pressed")
    
    $CanvasLayer/Buttons.modulate.a = 0.0
    
    $CanvasLayer2/Sprite.position.x = 1280.0
    $Sprite2.position.x = -1280.0

var clear_press_count = 10
func clear_pressed():
    clear_press_count -= 1
    if clear_press_count <= 0:
        clear_press_count = 10
        Manager.records = Manager.build_records(false)
        Savedata.save_game()
        show_records()
    $CanvasLayer/ClearButton.text = "Clear Records (click %d times)" % [clear_press_count]

func show_records():
    $CanvasLayer/Buttons.visible = false
    $CanvasLayer/ColorRect.visible = true
    $CanvasLayer/RichTextLabel.visible = true
    $CanvasLayer/ClearButton.visible = true
    
    $CanvasLayer/RichTextLabel.bbcode_text = "[center]Records[/center]\n\n"
    
    for record in Manager.records:
        var name = "Stage " + str(record)
        if int(record) < 0:
            name = "Playground"
        var data = Manager.records[record]
        var time_part = ""
        
        if data.time >= 0:
            var seconds = fmod(data.time, 60.0)
            var minutes = round(data.time - seconds)/60.0
            if minutes > 0:
                time_part = "Time: %d:%02.03f   " % [minutes, seconds]
            else:
                time_part = "Time: %02.03fs   " % [seconds]
        
        var to_add = name + (" - %sSpeed: %0.3f m/s   Airtime: %02.03fs\n" % [time_part, data.speed/16.0, data.airtime])
        
        $CanvasLayer/RichTextLabel.bbcode_text += to_add

func refocus_back():
    yield(get_tree(), "idle_frame")
    $CanvasLayer/Buttons.get_children().back().grab_focus()

var lifetime = 0.0
func _process(delta):
    lifetime += delta
    
    if !Manager.fading:
        $CanvasLayer/Buttons.modulate.a = move_toward($CanvasLayer/Buttons.modulate.a, 1.0, delta*2.0)
    
    $CanvasLayer2/Sprite.position.x = lerp($CanvasLayer2/Sprite.position.x, 0.0, 1.0 - pow(1.0 - 0.95, delta))
    $CanvasLayer2/Sprite.position.x += sin(lifetime*0.8814734)*0.5
    $CanvasLayer2/Sprite.position.y = round(cos(lifetime*1.5813)*10.0)
    
    $Sprite2.position.x = lerp($Sprite2.position.x, 0.0, 1.0 - pow(1.0 - 0.95, delta))
    $Sprite2.position.x += sin(lifetime*1.2814734)*0.25
    $Sprite2.position.y = sin(lifetime)*20.0
    
    $Sprite3.position.x = $Sprite2.position.x + cos(lifetime*1.052+0.15) * 15.0 - 5.0
    $Sprite3.position.y = $Sprite2.position.y + sin(lifetime*1.252+1.15) * 10.0 - 5.0
    
    
    if $CanvasLayer/RichTextLabel.visible:
        if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept"):
            $CanvasLayer/Buttons.visible = true
            $CanvasLayer/ColorRect.visible = false
            $CanvasLayer/RichTextLabel.visible = false
            $CanvasLayer/ClearButton.visible = false
            refocus_back()
    pass
