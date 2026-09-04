extends CharacterBody2D

@onready var ledge_jump_timer: Timer = $Timers/LedgeJump
@onready var disable_movement_timer: Timer = $Timers/DisableMovement
@onready var shoot_timer: Timer = $Timers/Shoot
@onready var ray_left: RayCast2D = $RayLeft
@onready var ray_left2: RayCast2D = $RayLeft2
@onready var ray_right: RayCast2D = $RayRight
@onready var ray_right2: RayCast2D = $RayRight2
@onready var ammo: AnimatedSprite2D = $ammo
@onready var reload: AnimatedSprite2D = $reload
@onready var gun: Sprite2D = $gun
@onready var player_sprite: AnimatedSprite2D = $playerSprite
@onready var camera: Camera2D = $Camera2D

@export var jump_speed: float
@export var speed: float
@export var shoot_force: float
@export var slide_force: float
@export var ground_friction: float
@export var air_friction: float
@export var slide_friction: float
@export var reload_time: float

var extra_velocity: Vector2
var direction: Vector2
var move_direction: float
var pressed_jump: bool
var can_shoot: bool = true
var can_move: bool = true
var jumped: bool = true
var sliding: bool = false
var has_gun: bool = true
var is_ledge_jumping: bool = false
var reloading: bool = false

var posy = 0.0
func _ready() -> void:
	reload.sprite_frames.set_animation_speed("reload", reload.sprite_frames.get_frame_count("reload") / reload_time)
	
func _physics_process(delta: float) -> void:
	if can_move:
		move_direction = Input.get_axis("move_left", "move_right")
	velocity.x = move_direction * speed
	
	pressed_jump = Input.is_action_pressed("jump")
	
	# total movement direction
	direction = Vector2(move_direction * speed, 0) + extra_velocity
	
	if Input.is_action_pressed("slide"):
		sliding = false
		if extra_velocity.x != 0:
			sliding = true
	
	# check if there's time left to ledge jump
	is_ledge_jumping = false
	if ledge_jump_timer.time_left > 0:
		is_ledge_jumping = true
		
	# midair logic
	if not is_on_floor():
		midair_logic(delta)
	# grounded logic   
	if (is_on_floor() or is_ledge_jumping):
		ground_logic()
		
	check_shoot()
		
	# slows down extra velocity if player is going opposite move_direction
	if move_direction and move_direction != sign(extra_velocity.x):
		extra_velocity.x = move_toward(extra_velocity.x, 0, delta * speed * 2)

	check_wall_jump()
	
	velocity += extra_velocity
	move_and_slide()
	
	# undo extra velocity to avoid accumulation
	velocity -= extra_velocity
	
	# apply friction to extra force
	if is_on_floor() and Input.is_action_pressed("slide") and extra_velocity.x != 0:
		extra_velocity = extra_velocity.move_toward(Vector2.ZERO, delta * slide_friction)
	elif is_on_floor():
		extra_velocity = extra_velocity.move_toward(Vector2.ZERO, delta * ground_friction)
		
	# apply flip to gun sprite to stay upright
	process_flip()
		
func disable_movement():
	can_move = false
	disable_movement_timer.start()

func check_shoot():
		
	if reloading or not can_shoot:
		return
		
	if Input.is_action_just_pressed("shoot") and can_shoot:
		var force:Vector2 = -(get_global_mouse_position() - position).normalized() * shoot_force
		
		# start reload if player shoots into the ground to avoid spamming 
		if (is_on_floor() or is_ledge_jumping) and force.y >= 0:
			reloading = true
			shoot_timer.start()
		
		enable_shooting(false)
		
		extra_velocity += force
		velocity.y = 0

func ground_logic():
		# remove fall speed 
		if not is_ledge_jumping and not jumped:
			velocity.y = 0
			extra_velocity.y = 0
		# reload gun
		if extra_velocity.y >= 0:
			enable_shooting(not reloading)
			
		# do long jump if stopped sliding
		jumped = false
		if (Input.is_action_just_released("slide") or Input.is_action_just_pressed("jump")) and sliding:
			sliding = false
			extra_velocity.x += slide_force * sign(direction.x)
			jump(false)

		# jump when player presses jump and if they're moving while ledge jumping
		elif pressed_jump and ((is_ledge_jumping and direction.x != 0) or not is_ledge_jumping):
			jump()
			
		
	
func midair_logic(delta: float):
	# gives a little extra time to jump when falling off edge
		if !jumped:
			if ledge_jump_timer.time_left == 0:
				ledge_jump_timer.start()
			 
		# add gravity   
		velocity += get_gravity() * delta
		
func check_wall_jump():
	# checks if player is going in direction of wall
	if ((check_left_rays()[0] and move_direction < 0) or (check_right_rays()[0] and move_direction > 0)):
			
		# bounces off wall
		if !Input.is_action_pressed("slide") and not is_on_floor():
			#enable_shooting(true)
			disable_movement()
			move_direction = -sign(direction.x)
			velocity.x = move_direction * speed / 2
			extra_velocity.x = -sign(direction.x) * speed / 2
			velocity.y = -jump_speed
			
			extra_velocity.y = 0
			print(str(velocity) + ", " + str(extra_velocity) + "\n-----------")
		else:
			extra_velocity.x = 0
	# remove horizontal velocity when hitting a wall
	elif check_left_rays(false)[0] or check_right_rays(false)[0]:
		extra_velocity.x = 0
	
	# checks if player can almost reach the top of the platform to reload
	if (check_left_rays(false, false)[1] and not check_left_rays(false, false)[0] or
		check_right_rays(false, false)[1] and not check_right_rays(false, false)[0]):
		enable_shooting(true)

func check_left_rays(check_both = true, check_either = true) -> Array[bool]:
	var bool1 = ray_left.is_colliding()
	var bool2 = ray_left2.is_colliding()
	
	if check_both:
		return [bool1 and bool2]
	elif check_either:
		return [bool1 or bool2]
	return [bool1, bool2]

func check_right_rays(check_both = true, check_either = true) -> Array[bool]:
	var bool1 = ray_right.is_colliding()
	var bool2 = ray_right2.is_colliding()
	
	if check_both:
		return [bool1 and bool2]
	elif check_either:
		return [bool1 or bool2]
	return [bool1, bool2]

# set shooting permission and sets correct ammo counter
func enable_shooting(state: bool):
	can_shoot = state
	if state: ammo.set_frame_and_progress(0, 0)
	else: ammo.set_frame_and_progress(1, 0)
	
func process_flip():
	var mouse_position = get_global_mouse_position() - position + Vector2(0, 10)
	gun.rotation = atan2(mouse_position.y, mouse_position.x)
	
	if gun.rotation < deg_to_rad(-90) or gun.rotation > deg_to_rad(90):
		gun.flip_v = true
		player_sprite.flip_h = true
	else:
		gun.flip_v = false
		player_sprite.flip_h = false
		
func jump(lose_x_velocity: bool = true):
	ledge_jump_timer.stop()
	if lose_x_velocity:
		extra_velocity.x = move_toward(extra_velocity.x, 0, speed)
	
	velocity.y = -jump_speed 
	extra_velocity.y = 0
	
	jumped = true

func enable_gun():
	gun.visible = true
	ammo.visible = true
	has_gun = true

func _on_timer_timeout() -> void:
	can_move = true

func _on_reload_animation_finished() -> void:
	ammo.set_frame_and_progress(0, 0)
	reload.visible = false
	can_shoot = true


func _on_ledge_jump_timeout() -> void:
	jumped = true


func _on_shoot_timeout() -> void:
	reloading = false
