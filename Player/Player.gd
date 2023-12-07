
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
var jumpNumber = 2
var wallJump = -800.0
var jumpWall = 60








# Wall Sliding
var wallSlideSpeed = 120.0








# Dash Ability
var Dashed = false
var has_dashed = false
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


# Wall Sliding
func wallSlide():
	if nextToWall() and velocity.y > 0:
		velocity.y = wallSlideSpeed
		if nextToRightWall():
			animsprite.flip_h = true
			anim.play("Fall") #TODO: make wall sliding animations
		if nextToLeftWall():
			animsprite.flip_h = false
			anim.play("Fall") #TODO: make wall sliding animations


# Jump Function
func jump():
	
	
	
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_counter = jump_buffer_time
	
	
	
	
	if jump_buffer_counter > 0:
		jump_buffer_counter -= 1
	
	
	
	
	
	
	if jump_buffer_counter > 0 and (coyote_counter > 0) and !crouching and jumpNumber > 0:
		jumpNumber = 0
		velocity.y = JUMP_VELOCITY
		jump_buffer_counter = 0
		coyote_counter = 0
		anim.play("Jump")
		
			
			
			
		# Wall Jump from wall on the player's right side	
		if not is_on_floor() and nextToRightWall(): # Wall Jumping
			velocity.x = lerp(velocity.x, (velocity.x + wallJump), 0.6)
			velocity.y -= jumpWall
			animsprite.flip_h = true
		
		
		
		
		
		# Wall Jump from wall on the player's left side
		if not is_on_floor() and nextToLeftWall():
			velocity.x = lerp(velocity.x, (velocity.x - wallJump), 0.6)
			velocity.y -= jumpWall
			animsprite.flip_h = false
	
	
	
	# Different jump heights based on how long you hold the space bar
	if Input.is_action_just_released("ui_accept") and !crouching:
		if velocity.y < 0:
			velocity.y += 150


# Update the timer that determines when the dash should end
func update_dash_timer(delta):
	dashTimer -= delta


# Check which direction the player is facing
func get_player_direction():
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") 


# Should the player start running? (WHY ARE YOU RUNNING, WHY ARE YOU RUNNING???)
func start_running():
	if Input.is_action_just_pressed("ShiftRun") and !crouching: #Hold shift to run
		SPEED = RUNNING_SPEED	


# Should the player stop running?
func stop_running():
	if Input.is_action_just_released("ShiftRun"): #Release shift to stop running
		SPEED = WALKING_SPEED


# Is the player currently falling? If yes: play "Fall" animation
func is_falling():
	if velocity.y > 0:
		if not crouching and !nextToWall():
			anim.play("Fall")


# Enables gravity
func enable_gravity(delta):
	if not is_on_floor():
		if coyote_counter > 0:
			coyote_counter -= 1
				
		#	if jump_counter < 1 and not nextToWall(): THIS HAS TO DO WITH DOUBLE JUMPING
		#		coyote_counter = 1
		#		jump_counter += 1
		#		if jump_counter == 1:
		#			hasJumped = true
		#			if has_dashed == 0:
		#				has_dashed = 1
		
		if not Dashed:
			velocity.y += gravity * delta
		elif Dashed:
			velocity.y = 0


# Reset dash ability and coyote time when the player is on the floor
func reset_dash_and_coyote_time():
	if is_on_floor() or nextToWall():
		if (SPEED == WALKING_SPEED) or (SPEED == RUNNING_SPEED and !Dashed):
			has_dashed = false
		if !Dashed:
			coyote_counter = coyote_time
		jumpNumber = 2


# The crouch ability
func enable_crouch():
	if Input.is_action_just_pressed("CrouchControl"):
		anim.play("Crouch")
		crouching = true
		SPEED = 0.0
	
	if Input.is_action_just_released("CrouchControl"):
		crouching = false
		SPEED = WALKING_SPEED
	
	# Get the input direction and handle the movement/deceleration.
	if direction[0] == -1:
		get_node("AnimatedSprite2D").flip_h = true
		lastdirection = direction
	elif direction[0] == 1:
		get_node("AnimatedSprite2D").flip_h = false
		lastdirection = direction	


# The Dash ability
func enable_dash():
# Check for dashing input
	if Input.is_action_just_pressed("ui_dash") and !Dashed and !crouching:
		if !has_dashed:
			if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
				Dashed = true
				has_dashed = true
				SPEED = DASH_SPEED
				dashTimer = 0.5
	
	
	
	
	
	#Handle the rest of the dash
	if Dashed and dashTimer <= 0.25:
		SPEED = WALKING_SPEED if !Input.is_action_pressed("ShiftRun") else RUNNING_SPEED
		coyote_counter = coyote_time
		if !(SPEED >= DASH_SPEED):
			Dashed = false
			if is_on_floor():
				has_dashed = false
	
	
	
	
	
	
	# Handle early exit from dash
	if Input.is_action_pressed("ui_dash") and Dashed and dashTimer <= 0.25:
		SPEED = WALKING_SPEED if !Input.is_action_pressed("ShiftRun") else RUNNING_SPEED
		if !(SPEED >= DASH_SPEED):
			Dashed = false
			if is_on_floor():
				has_dashed = false	


# Basic player movement with smoothing enabled by using the lerp() function
func basic_movement_with_smoothing():
	if direction and (direction[1] == 0):
		velocity.x = lerp(velocity[0], (direction[0] * SPEED), 0.1) # Movement smoothing
		if velocity.y == 0: #If the player is not jumping or falling
			if not crouching:
				anim.play("Run")
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		if velocity.y == 0: #If the player is not jumping or falling
			if not crouching:
				anim.play("Idle")
			if lastdirection[0] == 1:
				get_node("AnimatedSprite2D").flip_h = false
			elif lastdirection[0] == -1:
				get_node("AnimatedSprite2D").flip_h = true	


# This function runs 60 timer per second, calls (all of) the other functions
func _physics_process(delta):
	
	# Update the dash timer
	update_dash_timer(delta)
	
	
	# Get player direction
	get_player_direction()
	
	
	# Reset has_dashed when on the floor and reset coyote time
	reset_dash_and_coyote_time()
	
	
	# Add the gravity.
	enable_gravity(delta)


	# Is the player falling?
	is_falling()			


	# Handle jump.
	jump()
	
	
	# Wall Sliding		
	wallSlide()
	
	
	# Should the player start running?
	start_running()	


	# Should the player stop running?
	stop_running()


	# Crouching
	enable_crouch()
	
	
	# Handle dash	
	enable_dash()
	
	
	# Handle basic player movement
	basic_movement_with_smoothing()
	
	
	# Makes sure the player stays within the maximum allowed speed
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	
	
	move_and_slide()
