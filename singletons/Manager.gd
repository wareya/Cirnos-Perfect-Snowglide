extends CanvasLayer

# TODO:
# - trees
# - more levels


onready var records : Dictionary = {}
func build_records(do_load : bool = true) -> Dictionary:
    var ret = {}
    for i in stages.size():
        ret[str(i+1)] = {"time" : -1.0, "speed" : 0.0, "airtime" : 0.0}
    ret[str(-1)] = {"time" : -1.0, "speed" : 0.0, "airtime" : 0.0}
    if do_load and Savedata.load_exists():
        var data = Savedata.load_game()
        print(data)
        if data:
            for key in data:
                var subdata = data[key]
                if not key in ret:
                    ret[key] = subdata
                    if not "time" in ret[key]:
                        ret[key].time = -1.0
                    if not "speed" in ret[key]:
                        ret[key].speed = 0.0
                    if not "airtime" in ret[key]:
                        ret[key].airtime = 0.0
                else:
                    for subkey in subdata:
                        ret[key][subkey] = subdata[subkey]
                
    return ret

var max_speed_this_stage = 0.0
var max_airtime_this_stage = 0.0
# use also: stage_timer
func apply_records():
    var player = get_tree().get_nodes_in_group("Player").pop_back()
    if !player:
        return
    var stage = str(player.records_stage)
    print(stage)
    if not stage in records:
        records[stage] = {"time" : -1.0, "speed" : 0.0, "airtime" : 0.0}
    
    var end = get_tree().get_nodes_in_group("End").pop_back()
    if end and end.dead:
        records[stage].time = min(records[stage].time, stage_timer)
        if records[stage].time < 0:
            records[stage].time = stage_timer
    records[stage].speed = max(records[stage].speed, max_speed_this_stage)
    records[stage].airtime = max(records[stage].airtime, max_airtime_this_stage)
    
    Savedata.save_game()

func _ready():
    $EditorInputMap.show()
    $PauseMenu.hide()
    
    var root_viewport : Viewport = get_tree().get_root()
    root_viewport.get_texture().flags |= Texture.FLAG_FILTER
    
    $ViewportContainer/Viewport.get_texture().flags |= Texture.FLAG_FILTER
    
    $PauseMenu/BG/ReturnToMain.connect("pressed", self, "change_to", ["res://scenes/Main Menu.tscn"])
    $PauseMenu/BG/ReturnToGame.connect("pressed", $PauseMenu, "hide")
    $PauseMenu/BG/ToggleParticles.connect("pressed", self, "toggle_particles")
    $PauseMenu/BG/OpenInputEditor.connect("pressed", $EditorInputMap, "show_input_map")
    $PauseMenu/BG/RestartStage.connect("pressed", self, "restart_stage")
    
    records = build_records()
    
    yield(get_tree(), "idle_frame")
    
    $AudioStreamPlayer.play()

func restart_stage():
    change_to(get_tree().current_scene.filename)

var particles = true
func toggle_particles():
    particles = !particles

func change_to(stage_name : String):
    max_speed_this_stage = 0.0
    max_airtime_this_stage = 0.0
    apply_records()
    
    $PauseMenu.visible = false
    fade_to(1.0)
    yield(self, "fade_finished")
    var stage = load(stage_name)
    get_tree().change_scene_to(stage)
    stage_timer = 0.0
    fade_to(0.0)
    yield(self, "fade_finished")

func fade_to(new_target):
    fade_target = new_target
    fading = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
var first_frame = true
func _process(delta):
    #$Label.text = JSON.print(records, " ")
    #$Label.text = str(records)
    
    $CanvasLayer3/Label.text = str(Engine.get_frames_per_second()) + "fps"
    
    if !first_frame:
        $Fader.modulate.a = move_toward($Fader.modulate.a, fade_target, delta*3.0)
        if fading and $Fader.modulate.a == fade_target:
            fading = false
            emit_signal("fade_finished")
    
    first_frame = false
    
    var current_scene : Node = get_tree().current_scene
    
    if Input.is_action_just_pressed("pause") and !fading and current_scene.filename != "res://scenes/Main Menu.tscn":
        if $EditorInputMap.is_active():
            $EditorInputMap.hide_input_map()
        elif $PauseMenu.visible or !suppress_pause:
            $PauseMenu.visible = !$PauseMenu.visible
            if $PauseMenu.visible:
                apply_records() # early safety save
                $PauseMenu/BG/ReturnToGame.grab_focus()
    
    var music_bus = AudioServer.get_bus_index("Music")
    var effect : AudioEffectHighShelfFilter = AudioServer.get_bus_effect(music_bus, 0)
    var hz_target = 2000.0
    var gain_target = 1.0
    if $PauseMenu.visible:
        gain_target = 0.1
    effect.gain = move_toward(effect.gain, gain_target, delta)
    
    $CanvasLayer.visible = particles
    $CanvasLayer2.visible = particles
    
    var player = get_tree().get_nodes_in_group("Player").pop_back()
    $StageTimer.visible = player != null
    $Speedometer.visible = player != null
    $AirTimer.visible = player != null
    if player:
        var end = get_tree().get_nodes_in_group("End").pop_back()
        if !is_paused() and end and !end.dead:
            stage_timer += delta
        
        $Speedometer.text = "%.1f m/s" % [player.velocity.length()/16.0]
        
        $StageTimer.visible = !!end
        var seconds = fmod(stage_timer, 60.0)
        var minutes = round(stage_timer - seconds)/60.0
        if is_paused() or (end and end.dead):
            $StageTimer.text = "%02d:%02.03f" % [minutes, seconds]
        else:
            $StageTimer.text = "%02d:%02d" % [minutes, seconds]
        
        $AirTimer.visible = player.airtime > 1.2
        $AirTimer.text = "Airtime %02.03fs" % [player.airtime]

var stage_timer = 0.0

signal fade_finished

var fade_speed = 1.0
var fade_target = 0.0
var fading = true

var current_stage = 0

var stages : Array = [
    "res://scenes/Stage 1.tscn",
    "res://scenes/Stage 2.tscn",
    "res://scenes/Stage 3.tscn",
    "res://scenes/Stage 4.tscn",
    "res://scenes/Stage 5.tscn",
    "res://scenes/Stage 6.tscn",
    "res://scenes/Stage 7.tscn",
    "res://scenes/Stage 8.tscn",
    "res://scenes/Stage 9.tscn",
    "res://scenes/Stage 10.tscn",
    "res://scenes/Stage 11.tscn",
    "res://scenes/Stage 12.tscn",
    "res://scenes/Stage 13.tscn",
    "res://scenes/Stage 14.tscn",
    "res://scenes/Stage 15.tscn",
    "res://scenes/Stage 16.tscn",
    "res://scenes/Stage 17.tscn",
    "res://scenes/Stage End.tscn",
]

var final_stage = "res://scenes/Stage End.tscn"

var suppress_pause = false
func go_to_stage(which : int):
    if which == -1:
        Manager.change_to("res://scenes/Stage Playground.tscn")
        current_stage = -1
        return true
    suppress_pause = false
    for i in stages.size():
        if i+1 == which:
            Manager.change_to(stages[i])
            current_stage = i+1
            return true
    return false

func go_to_next_stage():
    
    var current_filename = get_tree().current_scene.filename
    if current_filename == final_stage:
        change_to("res://scenes/Main Menu.tscn")
        current_stage = 0
    
    print(current_filename)
    print(current_stage)
    
    var success = go_to_stage(current_stage+1)
    if !success:
        for i in stages.size():
            if stages[i] == current_filename:
                current_stage = i+1
                break
        success = go_to_stage(current_stage+1)
    if !success:
        Manager.change_to("res://scenes/Main Menu.tscn")
    
    print(current_stage)

func is_paused():
    var current_scene : Node = get_tree().current_scene
    if !current_scene:
        return true
    if current_scene.filename == "res://scenes/Main Menu.tscn":
        return false
    return $PauseMenu.visible or fading

func inform_zoom(zoom : Vector2):
    #$CanvasLayer/FG.coord_scale = zoom
    pass

func add_to_scene(node : Node):
    get_tree().current_scene.add_child(node)

