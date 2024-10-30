extends Node2D

signal game_ended(elapsed_time);
signal image_processed(processed_image)

@export var image: CompressedTexture2D;
@export var star_scene: PackedScene
@export var THRESHOLD_DISTANCE: int
@export var STAR_SOUNDS: Array[AudioStream]

# Enum to handle game state
enum GAME_STATE {
	LOADING,
	READY,
	PLAY,
	PAUSE,
	WIN,
	OVER
}

const FOREIGN_STAR_NUMBER = 50
var current_game_state = GAME_STATE.LOADING
var size: Vector2
var edgePoints = []
var left_edge_points = []
var right_edge_points = []
var draw_image: Image;
var rng = RandomNumberGenerator.new()
var constelation_node: Node2D
var constellation_list = []
var game_start_time = 0;
var canvas_size = Vector2.ZERO

# Called when instantiated
func _ready() -> void:
	if !image:
		print('No resource found')
	else:
		canvas_size = Vector2(get_viewport_rect().size.x - 40, get_viewport_rect().size.y)
		size = image.get_size()
		print('Image found.\nStarting to process a ', size.x, 'x', size.y, 'px\nTotal pixels to process:', size.x * size.y)
		draw_image = Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGB8)
		process_edges()
		instantiate_stars()
		printEdges()
		update_game_state(GAME_STATE.PLAY)
		$ConstellationLine.global_position = Vector2.ZERO
		game_start_time = Time.get_ticks_msec()
# Called once per frame
func _process(delta: float) -> void:
	$Label.text = get_stars_remaining()

# Updates game state
func update_game_state(game_state: GAME_STATE):
	current_game_state = game_state
	
# Fills the edges array depending of the given image
func process_edges():
	# Time measurement
	var start_time = Time.get_ticks_msec()
	# Create a list with the edge of the image
	for y in range(size.y): # y coordinate
		process_edge_line(y)
	var end_time = Time.get_ticks_msec()
	print("Execution time (ms): ", end_time - start_time)

# Process a whole line in an image
func process_edge_line(y: int):
	var l_found = false

	for x in range(size.x): # x coordinate
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
	$ConstelationContainer.position = Vector2(rng.randi_range(0 + canvas_size.x / 6, canvas_size.x - canvas_size.x / 6), rng.randi_range(0 + canvas_size.y / 4, canvas_size.y - canvas_size.y / 2))
	instantiate_stars_from_array(left_edge_points, false)
	instantiate_stars_from_array(right_edge_points, true)
	$ConstelationContainer.rotate(rng.randf_range(-3.14, 3.14))
	reallocate_constellation()
	instantiate_foreign_stars()

# Intantiates stars from an specific array. If reversed is passed then it does it in reverse order
func instantiate_stars_from_array(arr: Array, reversed: bool):
	var scale_factor_x = canvas_size.x / size.x / 4
	var scale_factor_y = canvas_size.x / size.x / 4
	var start = arr.size() - 1 if reversed else 0;
	var end = 0 if reversed else arr.size()
	var step = -1 if reversed else 1
	
	for i in range(start, end, step):
		var point = arr[i]
		if i == start or i == end - 1 or point.y == roundi(image.get_height() / 2) or point.y == roundi(image.get_height() / 2) + roundi(image.get_height() / 4) or point.y == roundi(image.get_height() / 2) - roundi(image.get_height() / 4):
			var star_instance = star_scene.instantiate()
			$ConstelationContainer.add_child(star_instance)
			star_instance.position = Vector2(point.x * scale_factor_x, point.y * scale_factor_y)
			star_instance.connect("select", _on_star_selectable_select)

# Instantiate the number of stars that you pass in respecting the threshold to contellation
func instantiate_foreign_stars():
	# Instantiate foreign stars
	for point in range(FOREIGN_STAR_NUMBER):
		var star_instance = star_scene.instantiate()
		$ForeignStars.add_child(star_instance)
		star_instance.connect("select", _on_star_selectable_select)
		
		var new_position = Vector2.ZERO
		var too_close = true
		while too_close:
			new_position = Vector2(rng.randi_range(0, canvas_size.x), rng.randi_range(0, canvas_size.y))
			too_close = false
			for edge_point in $ConstelationContainer.get_children():
				var distance_between = new_position.distance_to(edge_point.global_position)
				if distance_between < THRESHOLD_DISTANCE:
					too_close = true
					break
		star_instance.position = new_position

# In case any star of the constellation is out it reallocates the constellation until it is not
func reallocate_constellation():
	var star_out = true;
	# Reallocating the whole constelation in the canvas if a star is out of bounds
	while star_out:
		star_out = false
		$ConstelationContainer.position = Vector2(rng.randi_range(0 + canvas_size.x/12, canvas_size.x - canvas_size.x/12), rng.randi_range(0 + canvas_size.y/12, canvas_size.y - canvas_size.y/12))
		for edge_point in $ConstelationContainer.get_children():
			if edge_point.global_position.x > canvas_size.x - 20 or edge_point.global_position.x < 20 or edge_point.global_position.y > canvas_size.y - 20 or edge_point.global_position.y < 20:
				star_out = true				
				break

# Prints the edges of the image in the $Sprite2D
func printEdges():
	for i: Vector2i in edgePoints:
		draw_image.set_pixelv(i, '#FFFFFF')
	var texture = ImageTexture.create_from_image(draw_image)
	image_processed.emit(draw_image)
	$Sprite2D.texture = texture

# Gets how many stars are remaining
func get_stars_remaining() -> String:
	var count = 0
	for child in $ConstelationContainer.get_children():
		count = count + (1 if child.get_selected() else 0)
	return str(count) + '/' + str($ConstelationContainer.get_child_count())

# Draws the line between constellation points
func draw_constellation_line():
	$ConstellationLine.clear_points()
	for point in constellation_list:
		$ConstellationLine.add_point(point.g_position)

# Handler for the on selected star signal
func _on_star_selectable_select(star_id, selected, g_position) -> void:
	if current_game_state != GAME_STATE.PLAY:
		return
	if selected:
		$AudioStreamPlayer2D.stream = STAR_SOUNDS[min(constellation_list.size(), STAR_SOUNDS.size() - 1)]
		constellation_list.append({"star_id": star_id, "g_position": g_position})
	else:
		constellation_list.erase({"star_id": star_id, "g_position": g_position})
		$AudioStreamPlayer2D.stream = STAR_SOUNDS[min(constellation_list.size(), STAR_SOUNDS.size() - 1)]
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

	if selected_ids.size() == 0:
		return false

	for selected_id in selected_ids:
		if star_ids.find(selected_id) == -1:
			return false

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
		game_ended.emit(game_start_time - Time.get_ticks_msec())
		constellation_list.append(constellation_list[0])
		draw_constellation_line()
		update_game_state(GAME_STATE.WIN)
		return true
	else:
		return false
