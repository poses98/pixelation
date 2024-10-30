extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SideMenu/Sprite2D.scale = Vector2(2,2)
	$SideMenu/Sprite2D.position = Vector2(40,$SideMenu.offset.y)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_image_splitter_image_processed(processed_image: Image) -> void:	
	processed_image.resize(32,32)	
	var texture = ImageTexture.create_from_image(processed_image)
	$SideMenu/Sprite2D.texture = texture
