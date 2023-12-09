extends CharacterBody2D

# Walking and Running Speed
const MAX_SPEED = 1200.0
var WALKING_SPEED = 150.0
var RUNNING_SPEED = 300.0
var SPEED = 150.0  # Default speed, can be modified by dash or other abilities
var DASH_SPEED = 600.0  # Speed for the dash ability

# Jumping
var JUMP_VELOCITY = -400.0
var jump_buffer_time = 15
var jump_buffer_counter = 0
var coyote_time = 15
var coyote_counter = 0
#var jump_counter = 0
var max_fall_speed = 2000.0

# Double Jump
var hasJumped = false
var DoubleJumpIntensity = 0.85  # Change this variable to jump higher on the second jump

# Wall Jumping
var wallJump = -800.0
var jumpWall = 60

# Wall Sliding
var wallSlideSpeed = 120.0

var Dashed = false
var dashTimer = -0.1  # seconds between each key press for a dash ability to take activated

# Crouching
var crouching = false
	
	
# Gravity
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Last Direction
var direction : Vector2
var lastdirection : Vector2  # Used for determining whether the idle animation should be flipped horizontally or not

@onready var anim = get_node("AnimationPlayer")
@onready var animsprite = get_node("AnimatedSprite2D")


# Is the player next to a wall?
func nextToWall():
	return nextToRightWall() or nextToLeftWall()


# Is the player next to a wall on the player's right?
func nextToRightWall():
	return $RightWall.is_colliding()


# Is the player next to a wall on the player's left?
func nextToLeftWall():
	return $LeftWall.is_colliding()

func handle_crouch():
	if Input.is_action_pressed("CrouchControl"):
		crouching = true
		SPEED = 0.0
	else:
		crouching = false

func handle_dash():
	if Input.is_action_just_pressed("ui_dash") and !Dashed and !crouching:
			if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
				Dashed = true
				dashTimer = 0.25
				
	if Dashed:
		if dashTimer > 0:
			SPEED = DASH_SPEED
		else:
			Dashed = !is_on_floor()

func handle_jump():
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_counter = jump_buffer_time
	
	if jump_buffer_counter > 0:
		jump_buffer_counter -= 1
	
	if jump_buffer_counter > 0:
		if coyote_counter > 0 or Dashed and !hasJumped or nextToRightWall() or nextToLeftWall():
			hasJumped = true
			velocity.y = JUMP_VELOCITY
			jump_buffer_counter = 0
			coyote_counter = 0
			anim.play("Jump")
		
		# Wall Jump from wall on the player's right side	
		if nextToRightWall(): # Wall Jumping
			velocity.x = lerp(velocity.x, (velocity.x + wallJump), 0.6)
			velocity.y -= jumpWall
			animsprite.flip_h = true
		
		# Wall Jump from wall on the player's left side
		if nextToLeftWall():
			velocity.x = lerp(velocity.x, (velocity.x - wallJump), 0.6)
			velocity.y -= jumpWall
			animsprite.flip_h = false
	
	# Different jump heights based on how long you hold the space bar
	if Input.is_action_just_released("ui_accept"):
		if velocity.y < 0:
			velocity.y += 150
			
func handle_animation():
	if lastdirection[0] == 1:
		get_node("AnimatedSprite2D").flip_h = false
	elif lastdirection[0] == -1:
		get_node("AnimatedSprite2D").flip_h = true
	lastdirection = direction
	
	if crouching:
		anim.play("Crouch")
	elif velocity.y > 0 and !nextToWall():
			anim.play("Fall")
	elif direction and (direction[1] == 0):
		if velocity.y == 0: #If the player is not jumping or falling
			anim.play("Run")
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		anim.play("Idle")
		
func handle_wall_slide():	
	if nextToWall() and velocity.y > 0:
		velocity.y = wallSlideSpeed
		if nextToRightWall():
			animsprite.flip_h = true
			anim.play("Fall") #TODO: make wall sliding animations
		if nextToLeftWall():
			animsprite.flip_h = false
			anim.play("Fall") #TODO: make wall sliding animations
			
func handle_falling(delta):
	if is_on_floor():
		coyote_counter = coyote_time
		hasJumped = false
	
	else:
		if coyote_counter > 0:
			coyote_counter -= 1

		if dashTimer > 0:
			velocity.y = 0
		else:
			velocity.y += gravity * delta

# This function runs 60 timer per second, calls (all of) the other functions
func _physics_process(delta):
	# Get player direction
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") 
	# Reset has_dashed when on the floor and reset coyote time
	if dashTimer > 0:
		dashTimer -= delta
	
	handle_falling(delta)
	
	handle_jump()
	
	handle_wall_slide()
	
	# Should the player start running?
	if not crouching:
		SPEED = WALKING_SPEED if !Input.is_action_pressed("ShiftRun") else RUNNING_SPEED
	
	handle_dash()
	
	handle_crouch()
	
	handle_animation()
	
	# Makes sure the player stays within the maximum allowed speed
	velocity.x = lerp(velocity[0], (direction[0] * SPEED), 0.1) # Movement smoothing
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	move_and_slide()
