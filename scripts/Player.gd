extends CharacterBody2D

@export var move_speed := 260.0
@export var acceleration := 960.0
@export var friction := 1100.0

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity := input_vector * move_speed

	if input_vector == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)

	move_and_slide()

	if input_vector.x != 0.0:
		scale.x = -1.0 if input_vector.x < 0.0 else 1.0
