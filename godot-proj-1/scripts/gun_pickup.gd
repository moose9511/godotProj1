extends Area2D

@onready var game_manager = %GameManager

func _on_body_entered(body: Node2D) -> void:
	game_manager.set_can_shoot(true)
	queue_free()
