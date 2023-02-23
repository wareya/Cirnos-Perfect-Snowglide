extends Node2D


func _process(delta):
    update()

func draw_dot(location : Vector2, color : Color):
    draw_arc(location + Vector2(0, -2.0), 1.0, 0, PI*2.0, 32, color, 7.0*2.0, true)

func _draw():
    var camera = get_tree().get_nodes_in_group("Camera").pop_back()
    if !camera:
        return
    
    var _player = get_tree().get_nodes_in_group("Player").pop_back()
    if !_player:
        return
    
    var rect : Rect2 = get_viewport_transform().affine_inverse().xform(Rect2(Vector2(), get_viewport().size))
    
    var fg_color = Color.white
    var bg_color = Color.black
    
    draw_rect(rect, bg_color)
        
    var zoom = Vector2(0.2, 0.2)
    var size = rect.size*0.5
    for node in get_tree().get_nodes_in_group("Collision"):
        var collision : CollisionPolygon2D = node
        var colors = PoolColorArray()
        colors.resize(collision.polygon.size())
        colors.fill(fg_color)
        draw_set_transform(-camera.global_position*zoom + size + node.global_position*zoom, 0, zoom)
        draw_polygon(collision.polygon, colors, PoolVector2Array(), null, null, true)
    
    draw_set_transform(-camera.global_position*zoom + size, 0, zoom)
    
    for player in get_tree().get_nodes_in_group("Player"):
        draw_dot(player.global_position, Color.orange)
    for player in get_tree().get_nodes_in_group("IceToken"):
        draw_dot(player.global_position, Color(1.0, 0.0, 0.5))
    for player in get_tree().get_nodes_in_group("End"):
        draw_dot(player.global_position, Color.green)
    
