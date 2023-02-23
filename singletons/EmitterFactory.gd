extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var sounds = {
"jump": preload("res://sounds/HybridFoley.wav"),
"land": preload("res://sounds/HybridFoley2.wav"),
"icebreaker": preload("res://sounds/icebreaker.wav"),
"frogbreaker": preload("res://sounds/frogbreaker.wav"),
"ButtonA": preload("res://sounds/ButtonA.wav"),
"ButtonB": preload("res://sounds/ButtonB.wav"),
"confirm": preload("res://sounds/confirm.wav"),
}


class Emitter2D extends AudioStreamPlayer2D:
    var ready = false
    var frame_counter = 0

    func _process(_delta):
        if ready and !playing:
            frame_counter += 1
        if frame_counter > 2:
            queue_free()

    func emit(parent : Node, sound, arg_position, channel):
        parent.add_child(self)
        position = arg_position
        var abs_position = global_position
        parent.remove_child(self)
        parent.get_tree().get_root().add_child(self)
        global_position = abs_position
        stream = sound
        bus = channel
        play()
        ready = true

class Emitter extends AudioStreamPlayer:
    var ready = false
    var frame_counter = 0

    func _process(_delta):
        if ready and !playing:
            frame_counter += 1
        if frame_counter > 2:
            queue_free()

    func emit(parent : Node, sound, channel):
        parent.add_child(self)
        stream = sound
        bus = channel
        volume_db = -3
        play()
        ready = true


    
func emit(parent, sound, arg_position = Vector2(), channel = "SFX"):
    if parent:
        Emitter2D.new().emit(parent, sounds[sound], arg_position, channel)
    else:
        Emitter.new().emit(get_tree().current_scene, sounds[sound], channel)

var player = AudioStreamPlayer.new()
var receive = AudioStreamGenerator.new()
var send = AudioEffectCapture.new()

var send_ready = false

func _ready():
    yield(get_tree(), "idle_frame")
    
    receive.mix_rate = AudioServer.get_mix_rate()
    receive.buffer_length = 0.1
    player.stream = receive
    player.bus = "Reverb"
    player.play()
    add_child(player)
    
    send_ready = true


var time_since_init = 0.0
