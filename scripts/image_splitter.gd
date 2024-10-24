extends Node2D


@export var image:CompressedTexture2D;
@export var star_scene:PackedScene
@export var threshold_distance:int

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
		print('Image found.\nStarting to process a ',size.x,'x',size.y,'px\nTotal pixels to process:',size.x*size.y)
		draw_image = Image.create(image.get_width(),image.get_height(), false,Image.FORMAT_RGB8)
		process_edges()
		instantiate_stars()
		printEdges()
		


func _process(delta: float) -> void:
	$Label.text = get_stars_remaining()
	
	
func process_edges():
	var start_time = Time.get_ticks_msec()  # Tiempo de inicio
	var l_found = false
	var r_found = false
	var reverse_adjustment = 0;
	var pixels_saved=0
	# Create a list with the edge of the image
	for i in range(size.y):
		for j in range(size.x):
			if !l_found and j - 1 >= 0:
				if isEmptyPixel(Vector2i(j-1, i)) and !isEmptyPixel(Vector2i(j, i)):
					l_found = true
					edgePoints.append(Vector2(j, i))
					for k in range(size.x - 1, j, -1):
						if k + 1 < size.x and !isEmptyPixel(Vector2i(k, i)) and isEmptyPixel(Vector2i(k+1, i)):
							r_found = true
							pixels_saved += k - j 
							edgePoints.append(Vector2(k, i))
							break
						elif k == size.x-1:
							if !isEmptyPixel(Vector2i(k,i)):
								r_found = true
								pixels_saved += k - j 
								edgePoints.append(Vector2(k, i))
								break	
					break 
			elif j == 0:
				if !isEmptyPixel(Vector2i(j,i)):
					edgePoints.append(Vector2(j,i))
					l_found=true
		l_found = false
		r_found = false
	var end_time = Time.get_ticks_msec()  # Tiempo de finalización
	print("Tiempo de ejecución optimizado (ms): ", end_time - start_time)
	print("Píxeles ahorrados: ", pixels_saved)


func isEmptyPixel(position:Vector2i):
	return image.get_image().get_pixel(position.x,position.y).a == 0

func instantiate_stars():
	var canvas_size = get_viewport_rect().size
	var scale_factor_x = canvas_size.x / size.x / 4
	var scale_factor_y = canvas_size.x / size.y / 4
	var modulus = 1
	var count = 0
	$ConstelationContainer.position= Vector2(rng.randi_range(0+canvas_size.x/6, canvas_size.x-canvas_size.x/6), rng.randi_range(0+canvas_size.y/4, canvas_size.y-canvas_size.y/2))
	for point in edgePoints:
		if count % modulus == 0 || point.y == 0 || point.y == image.get_height()-rng.randi_range(1,1) || point.y == image.get_height()/2 + rng.randi_range(-3,3) :
			var star_instance = star_scene.instantiate()
			$ConstelationContainer.add_child(star_instance)
			star_instance.position = Vector2(point.x * scale_factor_x, point.y * scale_factor_y)
		count = count + 1
	
	var start_out = true;
	#TODO check if there are any stars out of the canvas, if so rng the $ConstelationContainer.position again
	while start_out:
		for edge_point in $ConstelationContainer.get_children():
			pass
	for point in range(edgePoints.size()):
		var star_instance = star_scene.instantiate()
		add_child(star_instance)
		var new_position = Vector2.ZERO
		var too_close = true
		while too_close:
			new_position = Vector2(rng.randi_range(0, canvas_size.x), rng.randi_range(0, canvas_size.y))
			too_close = false 
			for edge_point in $ConstelationContainer.get_children():
				var distance_between = new_position.distance_to(edge_point.global_position)
				if  distance_between < threshold_distance:
					print(new_position.distance_to(edge_point.position))
					too_close = true
					print("Too close to an edge star")
					break 
		star_instance.position = new_position
		

func printEdges():
	var count = 0
	var modulus = 1
	for i:Vector2i in edgePoints:
		if count % modulus == 0 || i.y == 0 || i.y == image.get_height()-1:
			draw_image.set_pixelv(i,Color.AQUA)
		count = count + 1
	var texture = ImageTexture.create_from_image(draw_image)
	$Sprite2D.texture = texture
	
func get_stars_remaining() -> String:
	var count = 0
	for child in $ConstelationContainer.get_children():
		count = count + (1 if child.get_selected() else 0)
	return str(count) + '/' + str($ConstelationContainer.get_child_count())
	
