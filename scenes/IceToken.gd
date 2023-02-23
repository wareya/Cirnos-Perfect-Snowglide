extends Area2D

var time_alive = 0.0
func _process(delta):
    if !Manager.is_paused():
        time_alive += delta
    
    $Sprite.position.y = round(sin(time_alive*4.5)*0.8)
    
    var player = get_tree().get_nodes_in_group("Player").pop_back()
    if player:
        if global_position.distance_to(player.global_position) < 16.0:
            die()

func die():
    EmitterFactory.emit(self, "icebreaker")
    var corners = [
        Vector2(-1, -1),
        Vector2( 1, -1),
        Vector2(-1,  1),
        Vector2( 1,  1),
    ];
    for i in 4:
        var shard = preload("res://scenes/Shard.tscn").instance()
        Manager.add_to_scene(shard)
        shard.global_position = global_position + corners[i]*4.0
        shard.set_frame(i)
    queue_free()
