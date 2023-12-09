extends Camera2D

# Member Variables
@onready var player = get_parent()
@onready var playerCamera = self
@onready var animatedSprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D

# The _process(delta) function runs 60 times per second
var cameraTimerDefaultValue = 30 # 30 = 0.5 seconds of constant movement in the same direction before the camera is panned
var cameraTimer = cameraTimerDefaultValue
var panSpeed = 0.05

# Constants
enum Direction { LEFT, RIGHT }


# Functions
func determineLookAhead():
	if cameraTimer > 0:
		cameraTimer -= 1
	else:
		var direction = null
		if Input.is_action_pressed("ui_left"):
			direction = Direction.LEFT
		elif Input.is_action_pressed("ui_right"):
			direction = Direction.RIGHT

		if direction != null:
			panCamera(direction)

	if Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right"):
		cameraTimer = cameraTimerDefaultValue


func panCamera(direction: Direction):
	var targetOffset = 0.0

	if (direction == Direction.LEFT and animatedSprite.flip_h) or (direction == Direction.RIGHT and not animatedSprite.flip_h):
		targetOffset = lerp(playerCamera.drag_horizontal_offset, -1.0 if direction == Direction.LEFT else 1.0, panSpeed)
		playerCamera.drag_horizontal_offset = targetOffset


func _process(delta):
	determineLookAhead()



