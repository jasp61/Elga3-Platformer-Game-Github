extends CharacterBody2D

var player = self

# Walking and Running Speed
const MAX_SPEED = 1200.0
@export var WALKING_SPEED = 150.0
@export var RUNNING_SPEED = 300.0
@export var SPEED = 150.0  # Default speed, can be modified by dash or other abilities
@export var DASH_SPEED = 600.0  # Speed for the dash ability
@onready var footstep_particle = $FootstepParticle

# Jumping
@export var JUMP_VELOCITY = -400.0
@export var jump_buffer_time = 15
var jump_buffer_counter = 0
@export var coyote_time = 15
var coyote_counter = 0
#var jump_counter = 0
var max_fall_speed = 2000.0
var on_ground = true
@onready var landing_burst = $LandingBurst

# Double Jump
var has_jumped = false
var double_jump_intensity = 0.85  # Change this variable to jump higher on the second jump

# Wall Jumping
@export var wall_jump = -800.0
@export var jump_wall = 60

# Wall Sliding
@export var wall_slide_speed = 120.0

# Dashing
var dashed = false
var dash_timer = -0.1  # seconds between each key press for a dash ability to take activated
var dash_direction = Vector2.ZERO
var ghost_scene = preload("res://dash_ghost.tscn")
@onready var ghost_timer = $GhostTimer
@export var ghost_node : PackedScene
@onready var dust_trail = $DustTrail
@onready var dust_burst = $DustBurst

# Crouching
var crouching = false
	
# Gravity
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Last Direction
var direction : Vector2
var lastdirection : Vector2  # Used for determining whether the idle animation should be flipped horizontally or not

@onready var anim = get_node("AnimationPlayer")
@onready var animsprite = get_node("AnimatedSprite2D")
@onready var shader_material: ShaderMaterial = animsprite.material


func spawn_footstep_particle():
	if animsprite.animation == "Run":
		if direction.x != 0 and is_on_floor() and !next_to_wall():
			if !footstep_particle.emitting:
				footstep_particle.restart()
				footstep_particle.emitting = true
	
	# Landing from jump or fall-VFX
	if is_on_floor():
		if not on_ground:
			landing_burst.restart()
			landing_burst.emitting = true
			on_ground = true


# Dash Ghosts
func instance_ghost():
	var ghost = ghost_node.instantiate()
	var animation_name = animsprite.animation
	var animation_frame = animsprite.frame
	var animation_texture = animsprite.sprite_frames.get_frame_texture(animation_name, animation_frame)
	ghost.set_property(position, animsprite.scale, animation_texture, animsprite.flip_h)
	get_tree().current_scene.add_child(ghost)


func start_ghost_timer():
	# Start creating dash ghosts by starting the ghost_timer.
	ghost_timer.start()
	shader_material.set_shader_parameter("mix_weight", 0.7)
	shader_material.set_shader_parameter("whiten", true)


func stop_ghost_timer():
	ghost_timer.stop()
	shader_material.set_shader_parameter("whiten", false)


func dash_particle_effect():
	# Enable dash particle effect
	dust_trail.restart()
	dust_trail.emitting = true
	dust_burst.rotation = (direction * -1).angle()
	dust_burst.restart()
	dust_burst.emitting = true


# When the ghost timer runs out, create a new dash ghost
func _on_ghost_timer_timeout():
	instance_ghost()


# Is the player next to a wall?
func next_to_wall():
	return next_to_right_wall() or next_to_left_wall()


# Is the player next to a wall on the player's right?
func next_to_right_wall():
	return $RightWall.is_colliding()


# Is the player next to a wall on the player's left?
func next_to_left_wall():
	return $LeftWall.is_colliding()


func handle_crouch():
	if Input.is_action_pressed("CrouchControl"):
		crouching = true
		SPEED = 0.0
	else:
		crouching = false


# 8-directional dash movement
func get_dash_direction():
	if !dashed:
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		input_vector = input_vector.normalized()
		return input_vector
	return Vector2.ZERO


# 8-directional dashing
func handle_dash():
	if Input.is_action_just_pressed("ui_dash") and !dashed and !crouching:
		dash_direction = get_dash_direction()
		if dash_direction != Vector2.ZERO:  # Check if there's a valid dash direction
			dashed = true
			
			start_ghost_timer()
			
			dash_particle_effect()
			
			# Different dash durations depending on the direction of the dash
			if dash_direction[1] == 0:
				dash_timer = 0.25
				print("horizontal dash")
			elif dash_direction[1] == -1 or dash_direction[1] == 1:
				dash_timer = 0.01
				print("vertical dash")
			elif is_equal_approx(abs(direction[1]), 0.70710676908493):
				dash_timer = 0.15
				print("diagonal dash")	

	if dashed:
		if dash_timer > 0:
			SPEED = DASH_SPEED
			# Set player's velocity based on the dash direction
			velocity = dash_direction * SPEED
		else:
			dashed = !is_on_floor()
			stop_ghost_timer()


# 2-directional dashing (regular dashing)
#func handle_dash():
	#dash_direction = Vector2.ZERO
	#if Input.is_action_just_pressed("ui_dash") and !dashed and !crouching:
			#if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
				#dashed = true
				#dash_timer = 0.25
	#if dashed:
		#if dash_timer > 0:
			#SPEED = DASH_SPEED
		#else:
			#dashed = !is_on_floor()


func handle_jump():
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_counter = jump_buffer_time
	
	if jump_buffer_counter > 0:
		jump_buffer_counter -= 1
	
	if jump_buffer_counter > 0:
		if coyote_counter > 0 or dashed and !has_jumped or next_to_right_wall() or next_to_left_wall():
			has_jumped = true
			velocity.y = JUMP_VELOCITY
			jump_buffer_counter = 0
			coyote_counter = 0
			anim.play("Jump")
		
		# Wall Jump from wall on the player's right side	
		if next_to_right_wall(): # Wall Jumping
			velocity.x = lerp(velocity.x, (velocity.x + wall_jump), 1.0)
			velocity.y -= jump_wall
			animsprite.flip_h = true
		
		# Wall Jump from wall on the player's left side
		if next_to_left_wall():
			velocity.x = lerp(velocity.x, (velocity.x - wall_jump), 1.0)
			velocity.y -= jump_wall
			animsprite.flip_h = false
	
	# Different jump heights based on how long you hold the space bar
	if Input.is_action_just_released("ui_accept"):
		if velocity.y < 0:
			velocity.y += 150


func handle_animation():
	if lastdirection[0] == 1 or (next_to_left_wall() and velocity.y == wall_slide_speed):
		get_node("AnimatedSprite2D").flip_h = false
	elif lastdirection[0] == -1 or (next_to_right_wall() and velocity.y == wall_slide_speed):
		get_node("AnimatedSprite2D").flip_h = true
	lastdirection = direction
	
	if crouching:
		anim.play("Crouch")
	elif velocity.y > 0 and !next_to_wall():
			anim.play("Fall")
	elif velocity.y == wall_slide_speed and next_to_wall():
		anim.play("Fall") #TODO: make wall sliding animations
	elif direction and (direction[1] == 0):
		if velocity.y == 0: #If the player is not jumping or falling
			anim.play("Run")
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		anim.play("Idle")


func handle_wall_slide():	
	if next_to_wall() and velocity.y > 0:
		velocity.y = wall_slide_speed
		#if next_to_right_wall():
			#animsprite.flip_h = true
		#if next_to_left_wall():
			#animsprite.flip_h = false


func handle_falling(delta):
	if is_on_floor():
		coyote_counter = coyote_time
		has_jumped = false
	
	else:
		on_ground = false
		if coyote_counter > 0:
			coyote_counter -= 1

		if dash_timer > 0:
			velocity.y = 0
		else:
			velocity.y += gravity * delta

# This function runs 60 timer per second, calls (all of) the other functions
func _physics_process(delta):
	# Get player direction
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Reset has_dashed when on the floor and reset coyote time
	if dash_timer > 0:
		dash_timer -= delta
	
	handle_falling(delta)
	
	handle_jump()
	
	handle_wall_slide()
	
	# Should the player start running?
	if not crouching:
		SPEED = WALKING_SPEED if !Input.is_action_pressed("ShiftRun") else RUNNING_SPEED
	
	handle_dash()
	
	handle_crouch()
	
	handle_animation()
	
	spawn_footstep_particle()
	
	# Makes sure the player stays within the maximum allowed speed
	velocity.x = lerp(velocity[0], (direction[0] * SPEED), 0.1) # Movement smoothing
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	velocity.y = clamp(velocity.y, -max_fall_speed, max_fall_speed)
	
	if direction[1] == 0 or dashed or !is_on_floor(): # This kinda fixes bug [003] in bugtracker.gd
		move_and_slide()

