extends CharacterBody2D

@onready var ledge_jump_timer: Timer = $Timers/LedgeJump
@onready var disable_movement_timer: Timer = $Timers/DisableMovement
@onready var ray_left: RayCast2D = $RayLeft
@onready var ray_right: RayCast2D = $RayRight
@onready var ammo: AnimatedSprite2D = $ammo
@onready var reload: AnimatedSprite2D = $reload
@onready var gun: Sprite2D = $gun
@onready var player_sprite: AnimatedSprite2D = $playerSprite

@export var jump_speed: float
@export var speed: float
@export var shoot_force: float
@export var ground_friction: float
@export var air_friction: float
@export var slide_friction: float
@export var is_grounded: bool
@export var reload_time: float

var extra_velocity: Vector2
var direction: float
var can_shoot: bool = true
var can_move: bool = true
var jumped: bool = true

func _ready() -> void:
	reload.sprite_frames.set_animation_speed("reload", reload.sprite_frames.get_frame_count("reload") / reload_time)

func _physics_process(delta: float) -> void:
	
	# Get the input direction and handle the movement/deceleration.
	if can_move:
		direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed
	
	var pressed_jump := Input.is_action_pressed("jump")
	var dir := direction * speed + extra_velocity.x
	
	# midair and grounded logic
	if not is_on_floor():
		
		# gives a little extra time to jump when falling off edge
		if !jumped:
			if ledge_jump_timer.time_left == 0:
				ledge_jump_timer.start()
				print("asdf")
			if pressed_jump and dir != 0:
				jump( )
				
		velocity += get_gravity() * delta
	else:
		
		enable_shooting(true)
		velocity.y = 0
		extra_velocity.y = 0
		jumped = false
		
		if pressed_jump:
			jump()
			
	if Input.is_action_just_pressed("shoot") and can_shoot:
		enable_shooting(false)
		var force:Vector2 = -(get_global_mouse_position() - position).normalized() * shoot_force
		extra_velocity = force
		velocity.y = 0
		
	# slows down extra velocity if player is going opposite direction
	if direction and direction != sign(extra_velocity.x):
		extra_velocity.x = move_toward(extra_velocity.x, 0, delta * speed * 2)

	# apply extra velocity for one frame
	velocity += extra_velocity
	move_and_slide()
	
	# do automatic wall jump
	if (dir != 0 and ((ray_left.is_colliding() and sign(dir) == -1) or (ray_right.is_colliding()
		 and sign(dir) == 1)) and (direction != 0 or extra_velocity.x != 0)):
			
		# bounces off wall
		if !Input.is_action_pressed("slide"):
			enable_shooting(true)
			disable_movement()
			direction = -sign(dir)
			velocity.x = direction * speed
			extra_velocity.x = -sign(dir) * speed / 2
			velocity.y = -jump_speed / 1.5
		# slides down wall
		else:
			#velocity.y = 0
			extra_velocity.x = 0
	
	# undo extra velocity to avoid accumulation
	velocity -= extra_velocity
	
	# apply friction to extra force
	if is_on_floor() and Input.is_action_pressed("slide"):
		extra_velocity = extra_velocity.move_toward(Vector2.ZERO, delta * slide_friction)
	elif is_on_floor():
		extra_velocity = extra_velocity.move_toward(Vector2.ZERO, delta * ground_friction)
	else:
		extra_velocity = extra_velocity.move_toward(Vector2.ZERO, delta * air_friction)
		
	# apply flip
	process_flip()
		
func disable_movement():
	can_move = false
	disable_movement_timer.start()

# sets whether or not the player can shoot
# sets up animation stuff
func enable_shooting(state: bool):
	if !can_shoot and state and !reload.is_playing():
		reload.visible = true
		reload.play() 
	
	if !state:
		ammo.set_frame_and_progress(1, 0)
		can_shoot = false
	
func process_flip():
	var mouse_position = get_global_mouse_position() - position + Vector2(0, 10)
	gun.rotation = atan2(mouse_position.y, mouse_position.x) 
	
	if gun.rotation < deg_to_rad(-90) or gun.rotation > deg_to_rad(90):
		gun.flip_v = true
		player_sprite.flip_h = true
	else:
		gun.flip_v = false
		player_sprite.flip_h = false
		
func jump():
	extra_velocity.x = move_toward(extra_velocity.x, 0, speed)
	extra_velocity.y += -jump_speed
	jumped = true

func _on_timer_timeout() -> void:
	can_move = true


func _on_reload_animation_finished() -> void:
	ammo.set_frame_and_progress(0, 0)
	reload.visible = false
	can_shoot = true


func _on_ledge_jump_timeout() -> void:
	jumped = true
