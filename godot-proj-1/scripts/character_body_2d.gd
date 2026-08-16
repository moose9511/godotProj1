extends CharacterBody2D

@onready var timer: Timer = $Timer

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
		print(str(extra_velocity) + " " + str(velocity))
	
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

	# apply extra velocity for one frame
	velocity += extra_velocity
	move_and_slide()
	
	# do wall slide and jump
	if direction != 0 and velocity.x == 0 and !is_on_floor():

		if Input.is_action_pressed("jump"):
			disable_movement()
			direction = -direction
			extra_velocity.x = direction * speed
			velocity.y = -jump_speed / 2
		else:
			velocity.y = 0
			
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
