extends Node2D


export(Texture) var texture : Texture

func _ready():
    time_alive += randf()*104.0
    coord_offset.x += randf()*1024.0;
    coord_offset.y += randf()*1024.0;
    pass

var time_alive = 0.0
var coord_offset = Vector2()
func _process(delta):
    update()
    if Manager.is_paused():
        return
    time_alive += delta
    coord_offset += autoscroll * delta * 10.0 * coord_scale
    coord_offset.x += sin(time_alive)*10.0*autoscroll.y*delta

export var coord_scale = Vector2(1, 1)
export var autoscroll = Vector2(0, 0)
export var mirror_x = false
export var mirror_y = true
export var transpose = false

func _draw():
    var camera = get_tree().get_nodes_in_group("Camera").pop_back()
    if !camera:
        return
    
    if !texture:
        return
    var rect : Rect2 = camera.get_viewport_transform().affine_inverse().xform(Rect2(Vector2(), get_viewport().size))
    var size = texture.get_size() * coord_scale
    
    var base_coord = coord_offset# + (camera.global_position - rect.position)/2.0 * coord_scale
    base_coord = rect.position + coord_offset
    base_coord -= camera.global_position
    base_coord += camera.global_position * coord_scale
    
    base_coord.x = fmod(fmod(base_coord.x, size.x*2) + size.x*2, size.x*2)
    base_coord.y = fmod(fmod(base_coord.y, size.y*2) + size.y*2, size.y*2)
    
    var y_even = false
    for y in range(ceil(rect.size.y / size.y + 2)):
        if mirror_y:
            y_even = !y_even
        var x_even = false
        for x in range(ceil(rect.size.x / size.x + 2)):
            if mirror_x:
                x_even = !x_even
            #draw_texture(texture, )
            var tex_pos = rect.position - base_coord + Vector2(x, y) * size
            var tex_size = size
            var rect2 = Rect2(tex_pos, size)
            if !x_even:
                rect2.position.x -= size.x
                var t = rect2.position.x
                rect2.position.x = rect2.end.x
                rect2.end.x = t
            if !y_even:
                rect2.position.y -= size.y
                var t = rect2.position.y
                rect2.position.y = rect2.end.y
                rect2.end.y = t
            draw_texture_rect(texture, rect2, false, Color.white, transpose)
            
