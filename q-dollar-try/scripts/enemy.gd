extends CharacterBody2D

const SPEED = 300
@onready var player = %Player

func _physics_process(delta: float) -> void:
	velocity = global_position.direction_to(player.global_position) * SPEED
	move_and_slide()
