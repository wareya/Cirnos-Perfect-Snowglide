extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func move_toward_radians(a, b, t):
    var quarter = lerp(a, b, 0.25)
    var quarter_diff = abs(a - quarter)
    if quarter_diff > PI:
        quarter_diff -= PI*2.0
    
    var full_diff = quarter_diff*4.0
    
    if abs(full_diff) < t:
        return b
    else:
        return a + sign(full_diff) * t

var want_to_jump = false
var velocity = Vector2()
var angle = 0.0
var board_angle = 0.0
var anim_timer = 0.0
var time_alive = 0.0

var last_good_floor_normal = Vector2()
var max_coyote_time = 0.1
var coyote_time = 0.0

var was_on_floor = false
var prev_floor_normal = Vector2()

var records_stage = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if Manager.is_paused():
        $AudioStreamPlayer2D.playing = false
        return
    
    records_stage = Manager.current_stage
    
    max_coyote_time = 0.2
    
    time_alive += delta
    
    var gravity = 200.0
    var friction = 10.0
    var drag = 0.75
    var jumpvel = 120.0
    var accel = 140.0
    var angle_rate = 0.99
    
    var slide_threshold_normal = 0.95
    
    var wishdir = Vector2()
    
    if Input.is_action_pressed("ui_left"):
        wishdir.x -= 1
    if Input.is_action_pressed("ui_right"):
        wishdir.x += 1
    
    var t = Input.get_action_strength("stick_right") - Input.get_action_strength("stick_left")
    if abs(t) > 0.001 and abs(t) != 1:
        wishdir.x = clamp(t*2.0, -1.0, 1.0)
    #print(t)
    
    
    if Input.is_action_just_pressed("ui_accept"):
        want_to_jump = true
    elif !Input.is_action_pressed("ui_accept"):
        want_to_jump = false
    
    #print(angle)
    var started_on_floor = is_on_floor()
    var floor_normal = Vector2.UP
    
    coyote_time -= delta
    
    var new_angle = 0.0 + wishdir.x/180*PI*20.0 + 0.1*sin(time_alive*10.0)
    if is_on_floor():
        coyote_time = max_coyote_time
        floor_normal = get_floor_normal()
        
        #print(floor_normal)
        var diff = floor_normal.dot(prev_floor_normal)
        #print(diff)
        #print(floor_normal.y)
        if was_on_floor and diff < 0.4 and floor_normal.y > prev_floor_normal.y and floor_normal.y > -0.7:
        #if was_on_floor and floor_normal.y > -0.3 and prev_floor_normal.y < -0.6:
            last_good_floor_normal = prev_floor_normal
        else:
            last_good_floor_normal = floor_normal
        
        velocity *= pow(drag, delta)
        var real_friction = friction
        if abs(velocity.x) < 0.5 and last_good_floor_normal.y < -slide_threshold_normal and wishdir.x == 0:
            real_friction = max(friction, gravity*0.6)
        velocity = velocity.move_toward(Vector2(), delta*real_friction)
        velocity += (accel*wishdir*delta).rotated(angle)
        
        new_angle = atan2(last_good_floor_normal.y, last_good_floor_normal.x)+PI/2.0
    else:
        var new_vel : Vector2 = velocity + (accel*wishdir*delta*0.25).rotated(angle)
        velocity = new_vel
    
    
    if coyote_time > 0.0:
        if want_to_jump:
            coyote_time = 0.0
            want_to_jump = false
            EmitterFactory.emit(self, "jump")
            var n : Vector2 = last_good_floor_normal + Vector2.UP
            if n.length() > 1.0:
                n = n.normalized()
            velocity += jumpvel * n
    
    
    var rel_velocity = velocity.rotated(-angle)
    if rel_velocity.x < -5.0:
        $Sprite.flip_h = true
    if rel_velocity.x > 5.0:
        $Sprite.flip_h = false
    if wishdir.x < 0:
        $Sprite.flip_h = true
    if wishdir.x > 0:
        $Sprite.flip_h = false
    
    if !is_on_floor():
        $Sprite.frame = 3
        anim_timer = 0.0
    else:
        if abs(rel_velocity.x) > 80.0 or wishdir.x == 0:
            $Sprite.frame = 0
            anim_timer = 0.0
        else:
            anim_timer += delta
            anim_timer = fmod(anim_timer, 0.8)
            $Sprite.frame = 2 if anim_timer < 0.4 else 1
    
    var real_gravity = gravity
    
    if is_on_floor() and velocity.length() == 0.0 and floor_normal.y < -slide_threshold_normal:
        real_gravity = 0.0
    
    
    
    #print(floor_normal.y)
    
    velocity.y += real_gravity*delta/2.0
    var new_velocity = move_and_slide(velocity, Vector2.UP, floor_normal.y < -slide_threshold_normal, 4, PI, false)
    
    # prevent glitching on nearly-vertical floors
    if is_on_floor() and get_floor_normal().y <= 0.0:
        var amount = 0.01
        # stick to floors more at high speeds
        if get_floor_normal().y < -0.7 and velocity.length() > 100.0:
            amount = 0.2
        move_and_collide(-get_floor_normal()*amount, false, true, false)
    
    var did_landing = false
    if !started_on_floor and (new_velocity - velocity).length() > 20.0:
        EmitterFactory.emit(self, "land")
        did_landing = true
    
    velocity = new_velocity
    velocity.y += real_gravity*delta/2.0
    
    if did_landing:
        make_particle_splatter(get_floor_normal())
    
    #angle = move_toward_radians(angle, new_angle, angle_rate*delta)
    angle = lerp_angle(angle, new_angle, 1.0 - pow(1.0 - angle_rate, delta))
    board_angle = lerp_angle(board_angle, new_angle, 1.0 - pow(1.0 - pow(angle_rate, 0.000001), delta))
    $Sprite.rotation = angle
    if is_on_floor() and abs(rel_velocity.x) > 80.0:
        $Sprite.rotation += 0.1*sin(time_alive*5.0) * clamp(abs(rel_velocity.x/400.0), 0.0, 1.0)
    $Sprite2.rotation = board_angle
    
    
    
    var base_zoom = 1.0/3.0
    var max_zoom = 1.0/1.0
    
    var base_zoom_min_speed = 80.0
    var base_zoom_max_speed = 500.0
    
    var f = inverse_lerp(base_zoom_min_speed, base_zoom_max_speed, velocity.length())
    f = clamp(f, 0.0, 1.0)
    f = f*f
    var new_zoom = Vector2(1, 1)*lerp(base_zoom, max_zoom, f)
    
    var zoom_in_speed = 0.5
    var zoom_out_speed = 0.9
    
    var zoom_speed = zoom_in_speed if new_zoom.x < $Camera2D.zoom.x else zoom_out_speed
    
    #$Camera2D.zoom = Vector2(1.0, 1.0)/(2.0 + sin(time_alive))
    $Camera2D.zoom = lerp($Camera2D.zoom, new_zoom, 1.0 - pow(1.0 - zoom_speed, delta))
    
    if $AudioStreamPlayer2D.playing != true:
        $AudioStreamPlayer2D.playing = true
    
    var volume = velocity.length()
    volume /= 100.0
    volume = volume / (volume + 1)
    
    if !is_on_floor():
        volume = 0.0
    
    $AudioStreamPlayer2D.volume_db = volume_to_db(volume)
    
    was_on_floor = started_on_floor
    prev_floor_normal = floor_normal
    
    var new_floor_normal = get_floor_normal()
    
    # can't control emission rate/lifetime properly
    if false:
        $CPUParticles2D.emitting = false
        if is_on_floor() and abs(rel_velocity.x) > 40.0:
            $CPUParticles2D.direction = velocity.normalized()
            var speed = velocity.length()
            $CPUParticles2D.initial_velocity = speed/2.0
            $CPUParticles2D.emitting = true
            $CPUParticles2D.global_position = global_position - new_floor_normal*8.0
            var n2 = new_floor_normal.rotated(PI/2.0)
            if rel_velocity.x < 0.0:
                $CPUParticles2D.global_position += n2 * 6.0
            else:
                $CPUParticles2D.global_position -= n2 * 6.0
            #$CPUParticles2D.lifetime = min(1.0, (speed-40.0)/100.0)
            #$CPUParticles2D._rate

    # use fake particles
    advance_snow_timer(delta, rel_velocity, new_floor_normal)
    
    Manager.inform_zoom($Camera2D.zoom)
    
    if !is_on_floor():
        airtime += delta
    else:
        airtime = 0.0
    Manager.max_airtime_this_stage = max(airtime, Manager.max_airtime_this_stage)
    Manager.max_speed_this_stage = max(velocity.length(), Manager.max_speed_this_stage)

var airtime = 0.0

var particles = []

func make_particle_splatter(floor_normal):
    if !Manager.particles: return
    for i in 32:
        var particle = SnowParticle.new()
        particle.convey_velocity_splat(velocity, floor_normal)
        particles.push_back(particle)
        particle.global_position = global_position - get_floor_normal()*8.0
        

var snow_timer = 0.0
func advance_snow_timer(delta, rel_velocity, floor_normal):
    if Manager.particles and is_on_floor() and floor_normal.y <= 0.0 and abs(rel_velocity.x) > 40.0:
        snow_timer += max(0.0, abs(rel_velocity.x) - 40.0)*delta*4.0
        var max_per_frame = 20.0
        snow_timer = min(snow_timer, max_per_frame)
        
        while snow_timer >= 1.0:
            snow_timer -= 1.0
            if randf() < 0.5:
                var particle = SnowParticle.new()
                particle.convey_velocity(velocity, floor_normal)
                #Manager.add_to_scene(particle)
                #particles[particle] = null
                particles.push_back(particle)
                particle.global_position = global_position - get_floor_normal()*8.0
                var n2 = get_floor_normal().rotated(PI/2.0)
                if rel_velocity.x < 0.0:
                    particle.global_position += n2 * 6.0
                else:
                    particle.global_position -= n2 * 6.0
    
    var particle_gravity = 200.0
    var new = []
    for particle in particles:
        particle.lifetime -= delta
        if particle.lifetime > 0.0:
            particle.modulate.a = clamp(particle.lifetime/particle.max_lifetime*2.0, 0.0, 1.0)
            
            particle.velocity.y += particle_gravity*delta/2.0
            particle.global_position += particle.velocity*delta
            particle.velocity.y += particle_gravity*delta/2.0
        
            new.push_back(particle)
        
    particles = new
    
    update()
    

func _draw():
    for particle in particles:
        var offset = particle.offset
        draw_texture(particle.texture, particle.global_position - global_position - offset, particle.modulate)
    


class SnowParticle extends Reference:# extends Sprite:
    var max_lifetime = 1.0
    var lifetime
    var texture : Texture
    var offset : Vector2
    func _init():
        var which = randi() % 3
        if which == 0:
            texture = preload("res://assets/snowbig.png")
        elif which == 1:
            texture = preload("res://assets/snowmedium.png")
        else:
            texture = preload("res://assets/snowsmall.png")
        offset = texture.get_size()/2.0
        lifetime = max_lifetime
    
    func complex_mult(a : Vector2, b : Vector2):
        return Vector2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x)
    
    func convey_velocity_splat(player_velocity : Vector2, floor_normal : Vector2):
        var forwards = player_velocity.normalized()
        var speed = player_velocity.length()
        var multiplier = 100.0
        velocity = player_velocity * 0.5 * (1.0 - abs(forwards.dot(floor_normal)))
        var x = randf()-0.5
        var y = randf()-0.5
        velocity += complex_mult(floor_normal, Vector2(x*0.5, y) * multiplier * 0.5)
        x = randf()-0.5
        y = randf()-0.5
        velocity += complex_mult(floor_normal, Vector2((x-y)*0.5, y+y)/2.0 * multiplier * 0.5)
        
        velocity += complex_mult(floor_normal, Vector2(50.0, 0.0))
        
    func convey_velocity(player_velocity : Vector2, floor_normal : Vector2):
        var speed = player_velocity.length()
        max_lifetime = max_lifetime * min(1.0, (speed-40.0)/100.0)
        lifetime = max_lifetime
        var multiplier = speed * 0.2
        velocity = player_velocity * 0.5
        var x = randf()-0.5
        var y = randf()-0.5
        velocity += Vector2(x, y) * multiplier * 0.5
        x = randf()-0.5
        y = randf()-0.5
        velocity += Vector2(x-y, y+y)/2.0 * multiplier * 0.5
        
        velocity += complex_mult(floor_normal, Vector2(1.0, 0.0)) * multiplier
    
    var velocity : Vector2
    var modulate : Color = Color.white
    var global_position : Vector2
    func _process(delta):
        lifetime -= delta
        lifetime = max(lifetime, 0.0)
        if lifetime <= 0.0:
            queue_free()
            return
        
        modulate.a = clamp(lifetime/max_lifetime*4.0, 0.0, 1.0)
        
        #velocity.y += gravity*delta/2.0
        global_position += velocity*delta
        #velocity.y += gravity*delta/2.0
    
    var dead = false
    func queue_free():
        dead = true

func volume_to_db(vol : float):
    return log(vol)/log(10.0)*20.0

func db_to_volume(vol : float):
    return pow(10.0, vol/20.0)
