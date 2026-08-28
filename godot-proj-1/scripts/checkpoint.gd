extends Area2D

class_name Checkpoint

@onready var game_manager = %GameManager

var has_collected: bool = false

func _on_body_entered(_body: Node2D) -> void:
	if has_collected:
		pass
		
	has_collected = true
	game_manager.set_checkpoint(self)
