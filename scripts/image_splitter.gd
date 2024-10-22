extends Node2D

@export var image:CompressedTexture2D;

var size:Vector2
var edgePoints = []
var draw_image: Image;
var rng = RandomNumberGenerator.new()
var constelation_node:Node2D

func _ready() -> void:
	if !image:
		print('No resource found')
	else:
		size = image.get_size()
		draw_image = Image.create(image.get_width(),image.get_height(), false,Image.FORMAT_RGB8)
		process_edges()
		printEdges()
		


func _process(delta: float) -> void:
	pass
	
	
func process_edges():
	# Create a list with the edge of the image
	for i in range(size.y):
		for j in range(size.x):
			if j-1 >= 0:
				# Left edge = pixel before must be empty pixel
				if isEmptyPixel(Vector2i(j-1,i)) and !isEmptyPixel(Vector2i(j,i)):
					edgePoints.append(Vector2(j,i))
					
			if j+1 <= size.y:	
				# Right edge = pixel after must be empty pixel
				if !isEmptyPixel(Vector2i(j,i)) and isEmptyPixel(Vector2i(j+1,i)):
					edgePoints.append(Vector2i(j,i))

func isEmptyPixel(position:Vector2i):
	return image.get_image().get_pixel(position.x,position.y).a == 0


func printEdges():
	var count = 0
	var modulus = 1
	for i:Vector2i in edgePoints:
		if count % modulus == 0 || i.y == 0 || i.y == image.get_height()-1:
			draw_image.set_pixelv(i,Color.AQUA)
		count = count + 1
	var texture = ImageTexture.create_from_image(draw_image)
	$Sprite2D.texture = texture

	
