extends Node2D

var rng = RandomNumberGenerator.new()
signal select(star_id,selected, g_position);
var selected:bool
var idle_animation_frame:int
var is_clicking = false

func _ready() -> void:
	
	if $AnimatedSprite2D.sprite_frames.get_frame_count('idle') > 0:
		$AnimatedSprite2D.animation = 'idle'
		idle_animation_frame = rng.randi_range(0,$AnimatedSprite2D.sprite_frames.get_frame_count('idle'))
		$AnimatedSprite2D.frame = idle_animation_frame
	else:
		print('Please add animation frames to idle animation!')


func get_selected() -> bool:
	return selected
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not is_clicking:
		if (event.position - global_position).length() < 5:
			is_clicking = true
			selected = !selected
			if selected:
				select.emit($".".get_instance_id(), true, global_position)
				$AnimatedSprite2D.animation = 'selected'
				$AnimatedSprite2D.play()
			else:
				select.emit($".".get_instance_id(), false, global_position)
				$AnimatedSprite2D.stop()
				$AnimatedSprite2D.animation = 'idle'
				$AnimatedSprite2D.frame = idle_animation_frame
				
			await get_tree().create_timer(0.2).timeout
			is_clicking = false
	
