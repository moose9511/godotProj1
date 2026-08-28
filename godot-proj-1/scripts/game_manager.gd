extends Node

@onready var player = %player
var player_instance = preload("res://scenes/player.tscn")

var checkpoint: Checkpoint

func set_can_shoot() -> void:
	player.enable_gun()
	

func set_checkpoint(cckpnt: Checkpoint) -> void:
	self.checkpoint = cckpnt
	
func die() -> void:
	
	if checkpoint != null:
		player.queue_free()
		player = player_instance.instantiate()
		player.unique_name_in_owner = true
		call_deferred("add_sibling", player)
		player.position = checkpoint.position
	else: 
		get_tree().call_deferred("reload_current_scene")
