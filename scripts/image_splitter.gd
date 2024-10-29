extends Node2D


@export var image:CompressedTexture2D;
@export var star_scene:PackedScene
@export var threshold_distance:int
@export var star_sounds:Array[AudioStream]


var size:Vector2
var edgePoints = []
var left_edge_points = []
var right_edge_points = []
var draw_image: Image;
var rng = RandomNumberGenerator.new()
var constelation_node:Node2D
var constellation_list=[]

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

# Fills the edges array depending of the given image
func process_edges():
	# Time measurement
	var start_time = Time.get_ticks_msec()
	# Create a list with the edge of the image
	for y in range(size.y):  # y coordinate
		process_edge_line(y)
	var end_time = Time.get_ticks_msec()
	print("Execution time (ms): ", end_time - start_time)

# Process a whole line in an image
func process_edge_line(y: int):
	var l_found = false

	for x in range(size.x):  # x coordinate
		if !l_found and (x - 1 >= 0 or x == 0):
			if (x == 0 and !is_empty_pixel(Vector2i(x, y))) or (is_empty_pixel(Vector2i(x - 1, y)) and !is_empty_pixel(Vector2i(x, y))):
				l_found = true
				edgePoints.append(Vector2(x, y))
				left_edge_points.append(Vector2(x, y))
				find_opposite_edge(x, y)
				break
	l_found = false

# Find the opposite edge of the image
func find_opposite_edge(start_x: int, y: int):
	for x in range(size.x - 1, start_x, -1):
		if x + 1 < size.x and !is_empty_pixel(Vector2i(x, y)) and is_empty_pixel(Vector2i(x + 1, y)):
			right_edge_points.append(Vector2(x, y))
			edgePoints.append(Vector2(x, y))
			break
		elif x == size.x - 1 and !is_empty_pixel(Vector2i(x, y)):
			right_edge_points.append(Vector2(x, y))
			edgePoints.append(Vector2(x, y))
			break

# Checks is a pixel is transparent
func is_empty_pixel(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.y >= size.y:
		return -1
	else:
		return image.get_image().get_pixel(pos.x, pos.y).a == 0 

# Instantiates every star depending on the edgePoints array and the foreign stars.
func instantiate_stars():
	var canvas_size = get_viewport_rect().size
	$ConstelationContainer.position= Vector2(rng.randi_range(0+canvas_size.x/6, canvas_size.x-canvas_size.x/6), rng.randi_range(0+canvas_size.y/4, canvas_size.y-canvas_size.y/2))
	instantiate_stars_from_array(left_edge_points, false)
	instantiate_stars_from_array(right_edge_points, true)
	$ConstelationContainer.rotate(rng.randf_range(-3.14,3.14))
	reallocate_constellation()
	instantiate_foreign_stars(50)

func instantiate_stars_from_array(arr:Array, reversed:bool):
	var canvas_size = get_viewport_rect().size
	var scale_factor_x = canvas_size.x / size.x / 4
	var scale_factor_y = canvas_size.x / size.x / 4
	var start = arr.size() - 1 if reversed  else 0;
	var end = 0 if reversed else arr.size()
	var step = -1 if reversed else 1
	
	for i in range(start, end, step):
		var point = arr[i]
		if i == start or i == end-1 or point.y == roundi(image.get_height()/2) or point.y == roundi(image.get_height()/2) + roundi(image.get_height()/4) or point.y == roundi(image.get_height()/2) - roundi(image.get_height()/4):
			var star_instance = star_scene.instantiate()
			print('Point:',point,'\tPosition in array:', i,'\tGlobal pos:',$ConstelationContainer.get_child_count(),'\tStar instance id:',star_instance.get_instance_id(),'\tStart:',start)
			$ConstelationContainer.add_child(star_instance)
			star_instance.position = Vector2(point.x * scale_factor_x, point.y * scale_factor_y)
			star_instance.connect("select", _on_star_selectable_select)

func instantiate_foreign_stars(star_number:int):
	var canvas_size = get_viewport_rect().size
	# Instantiate foreign stars
	for point in range(star_number):
		var star_instance = star_scene.instantiate()
		add_child(star_instance)
		star_instance.connect("select", _on_star_selectable_select)
		
		var new_position = Vector2.ZERO
		var too_close = true
		while too_close:
			new_position = Vector2(rng.randi_range(0, canvas_size.x), rng.randi_range(0, canvas_size.y))
			too_close = false 
			for edge_point in $ConstelationContainer.get_children():
				var distance_between = new_position.distance_to(edge_point.global_position)
				if  distance_between < threshold_distance:
					too_close = true
					break 
		star_instance.position = new_position

func reallocate_constellation():
	var canvas_size = get_viewport_rect().size
	var star_out = true;
	# Reallocating the whole constelation in the canvas if a star is out of bounds
	while star_out:
		star_out = false
		$ConstelationContainer.position= Vector2(rng.randi_range(0+canvas_size.x/10, canvas_size.x-canvas_size.x/10), rng.randi_range(0+canvas_size.y/10, canvas_size.y-canvas_size.y/10))
		for edge_point in $ConstelationContainer.get_children():
			if edge_point.global_position.x > canvas_size.x - 20 or edge_point.global_position.x < 20 or edge_point.global_position.y > canvas_size.y - 20 or edge_point.global_position.y < 20:
				star_out = true
				break

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

func draw_constellation_line():
	$ConstellationLine.clear_points()
	for point in constellation_list:
		$ConstellationLine.add_point(point.g_position)

func _on_star_selectable_select(star_id, selected, g_position) -> void:
	if selected:
		$AudioStreamPlayer2D.stream = star_sounds[min(constellation_list.size(),star_sounds.size()-1)]
		constellation_list.append({"star_id":star_id,"g_position":g_position})
		print(star_id)
	else:
		constellation_list.erase({"star_id":star_id,"g_position":g_position})
		$AudioStreamPlayer2D.stream = star_sounds[min(constellation_list.size(),star_sounds.size()-1)]
	$AudioStreamPlayer2D.play()
	draw_constellation_line()
	# Check if constellation is over
	check_solution()

# Check if the user has got a valid solution
func check_solution():
	var star_ids = []
	var selected_ids = []
	
	if constellation_list.size() != $ConstelationContainer.get_child_count():
		return false

	for selected in constellation_list:
		selected_ids.append(selected.star_id)

	for star_instance in $ConstelationContainer.get_children():
		star_ids.append(star_instance.get_instance_id())

	# Caso donde no hay estrellas seleccionadas
	if selected_ids.size() == 0:
		return false

	# Verificar que todos los seleccionados estén en star_ids
	for selected_id in selected_ids:
		if star_ids.find(selected_id) == -1:
			return false

	# Verificar el orden circular
	var previous_index = star_ids.find(selected_ids[0])
	if previous_index == -1:
		return false

	var is_valid = true
	var total_stars = star_ids.size()

	for i in range(1, selected_ids.size()):
		var current_index = star_ids.find(selected_ids[i])
		if current_index == -1:
			return false

		var difference = current_index - previous_index
		if difference != 1 and difference != -1 and not (previous_index == total_stars - 1 and current_index == 0) and not (previous_index == 0 and current_index == total_stars - 1):
			is_valid = false
			break

		previous_index = current_index

	if is_valid:
		constellation_list.append(constellation_list[0])
		draw_constellation_line()
		return true
	else:
		return false
