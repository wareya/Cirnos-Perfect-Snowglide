extends Area2D


var time_alive = 0.0
var death_timer = 0.5
func _process(delta):
    Engine.time_scale = 1.0
    if !Manager.is_paused():
        time_alive += delta
    
        if dead:
            Engine.time_scale = 0.5
            death_timer -= delta
            if death_timer <= 0.0:
                Manager.go_to_next_stage()
                Engine.time_scale = 1.0
            
    var active = get_tree().get_nodes_in_group("IceToken").size() == 0
    
    if active:
        $Sprite.modulate.a = 1.0
        $Sprite.position.y = round(sin(time_alive*4.5)*0.8)
        
        var player = get_tree().get_nodes_in_group("Player").pop_back()
        if player:
            if global_position.distance_to(player.global_position) < 16.0:
                die()
    else:
        $Sprite.modulate.a = 0.5
        $Sprite.position.y = 0.0

var dead = false
func die():
    if dead:
        return
    dead = true
    $Sprite.visible = false
    
    Manager.apply_records() # early safety save
    
    EmitterFactory.emit(self, "frogbreaker")
    
    var corners = [
        Vector2(-1, -1),
        Vector2( 1, -1),
        Vector2(-1,  1),
        Vector2( 1,  1),
    ];
    for i in 4:
        var shard = preload("res://scenes/Shard.tscn").instance()
        shard.set_texture($Sprite.texture)
        Manager.add_to_scene(shard)
        shard.global_position = global_position + corners[i]*4.0
        shard.set_frame(i)
    
