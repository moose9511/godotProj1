extends Sprite2D

var mouse_position: Vector2
@export var player_position: CharacterBody2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	mouse_position = get_global_mouse_position() - player_position.position + Vector2(0, 10)
	rotation = atan2(mouse_position.y, mouse_position.x) + (PI / 2)
