extends RigidBody2D

var lifetime = 4.0
var linear_velocity_memory
var angular_velocity_memory
var first = true
func _physics_process(delta):
    if first:
        inertia = 1.0
        apply_central_impulse(Vector2(randf()-0.5, -randf())*160.0)
        apply_torque_impulse((randf()-0.5)*36.0)
    first = false
    if !sleeping:
        angular_velocity_memory = angular_velocity
        linear_velocity_memory = linear_velocity
    if Manager.is_paused():
        sleeping = true
        return
    if sleeping:
        angular_velocity = angular_velocity_memory
        linear_velocity = linear_velocity_memory
    sleeping = false
    
    lifetime -= delta
    $Sprite.modulate.a = clamp(lifetime, 0.0, 1.0)
    if lifetime <= 0.0:
        queue_free()

func set_frame(i : int):
    $Sprite.frame = i

func set_texture(texture : Texture):
    $Sprite.texture = texture
