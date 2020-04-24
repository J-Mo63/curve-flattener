extends Control

var site_link = "jonathanmoallem.com/curve-flattener"
var current_share
var img_link

func _ready():
	add_child(SceneManager.graph)
	$Graph.anchor_left = 0.625
	$Graph.anchor_top = 0.2
	$Graph.anchor_right = 0.9
	$Graph.anchor_bottom = 0.49
	
	$PlayButton.connect("button_up", SceneManager, "start_game")
	$FacebookButton.connect("button_up", self, "share_result", ["https://www.facebook.com/sharer/sharer.php?u="])
	$TwitterButton.connect("button_up", self, "share_result", ["https://twitter.com/share?text=Check out my score in #CurveFlattener&url="])
	
	$StatsLabel.text = "Peak Infected: " + str($Graph.peak_infection_rate) + "%\nPopulation Uninfected: " + str($Graph.total_uninfected) + "%\nDays Since First Case: " + str($Graph.current_day)
	$LinkLabel.text = "play Curve Flattener now at:\n" + site_link
	
	yield(VisualServer, 'frame_post_draw')

func upload_image():
	var viewport_size = get_viewport().size
	var img = get_viewport().get_texture().get_data()
	img.crop($CapturePanel.rect_position.x + $CapturePanel.get_size().x, img.get_size().y - $CapturePanel.rect_position.y)
	img.flip_y()
	img.flip_x()
	img.crop(img.get_size().x - $CapturePanel.rect_position.x, $CapturePanel.get_size().y)
	img.flip_x()
	img.save_png("user://results.png")
	
	var file = File.new()
	file.open("user://results.png", File.READ)
	var base_64_data = Marshalls.raw_to_base64(file.get_buffer(file.get_len()))
	
	$HTTPRequest.connect("request_completed", self, "_http_request_completed")
	var body = JSON.print({"title": "My Latest Score on Curve Flattener", "image": base_64_data, "type": "base64", "description": "Play #CurveFlattener now at http://" + site_link})
	var error = $HTTPRequest.request("https://api.imgur.com/3/image", ["Authorization: Client-ID 41491c19309863b", "Content-Type: application/json"], false, HTTPClient.METHOD_POST, body)

func _http_request_completed(result, response_code, headers, body):
	print(parse_json(body.get_string_from_utf8()))
	img_link = parse_json(body.get_string_from_utf8())["data"]["link"]
	share_result(current_share)

func share_result(sharer_url):
	current_share = sharer_url
	if img_link:
		OS.shell_open(sharer_url + img_link)
	else:
		upload_image()
