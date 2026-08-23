extends Node

@onready var player = %player

func set_can_shoot(state: bool) -> void:
	player.enable_gun()
	
	
