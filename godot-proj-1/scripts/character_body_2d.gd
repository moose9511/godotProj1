extends CharacterBody2D

@onready var timer: Timer = $Timer
@onready var ray_left: RayCast2D = $RayLeft
@onready var ray_right: RayCast2D = $RayRight

@export var jump_speed: float
@export var speed: float
@export var shoot_force: float
@export var shoot_friction_ground: float
@export var shoot_friction_air: float
@export var is_grounded: bool

var extra_velocity: Vector2
var direction: float
var can_shoot: bool = true
var can_move: bool = true

func _physics_process(delta: float) -> void:
	
	if velocity != Vector2.ZERO:
		print(" " + str(velocity))
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		can_shoot = true
		velocity.y = 0
		extra_velocity.y = 0
		

	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		extra_velocity.y += -jump_speed

	# Get the input direction and handle the movement/deceleration.
	direction = Input.get_axis("move_left", "move_right")
	if can_move:
		velocity.x = direction * speed
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		can_shoot = false
		var force:Vector2 = -(get_global_mouse_position() - position).normalized() * shoot_force
		extra_velocity = force
		velocity.y = 0
		
	# slows down extra velocity if player is going opposite direction
	if direction and direction != sign(extra_velocity.x):
		extra_velocity.x = move_toward(extra_velocity.x, 0, delta * speed * 2)

	# apply extra velocity for one frame
	velocity += extra_velocity
	move_and_slide()
	
	# do wall slide and jump
	var dir := velocity + extra_velocity
	if ((ray_left.is_colliding() and sign(dir.x) == -1) or (ray_right.is_colliding() and sign(dir.x) == 1)) and (direction != 0 or extra_velocity.x != 0):
		print('a')
		# bounces off wall
		if Input.is_action_pressed("jump"):
			can_shoot = true
			disable_movement()
			direction = -direction
			#velocity.x = direction * speed
			extra_velocity.x = -extra_velocity.x 
			velocity.y = -jump_speed / 2
		# slides down wall
		else:
			velocity.y = 0
	
	# undo extra velocity to avoid accumulation
	velocity -= extra_velocity
	
	# apply friction to extra force
	if is_on_floor():
		extra_velocity = extra_velocity.move_toward(Vector2.ZERO, delta * shoot_friction_ground)
	else:
		extra_velocity = extra_velocity.move_toward(Vector2.ZERO, delta * shoot_friction_air)
		
func disable_movement():
	can_move = false
	timer.start()


func _on_timer_timeout() -> void:
	can_move = true
