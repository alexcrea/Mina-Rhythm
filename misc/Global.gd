extends Node

# Singleton reference to PakFileReader
var pak_reader = preload("res://misc/pak_reader.gd").new()
# Singleton reference to IRLS System
var IRLS = preload("res://misc/IRLS.gd").new()

var settings_file = "user://user_data/settings.json"

var Settings = {}
var default_settings = {"master_volume":0,"music_volume":-12,"effects_volume":0,"target_fps":60,"vsync":DisplayServer.VSyncMode.VSYNC_ENABLED,"show_fps":false}

var fps_counter
func _ready():
	var fps_count = Label.new()
	fps_count.top_level = true
	fps_count.z_index = 500
	fps_count.position = Vector2(1000,10)
	fps_count.size.x = 142
	fps_count.name = "fps_counter"
	fps_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	fps_count.label_settings = LabelSettings.new()
	fps_count.label_settings.font_color = Color(1,1,1,0.7)
	fps_count.label_settings.shadow_color = Color(0,0,0,0.3)
	fps_count.label_settings.shadow_size = 20
	fps_count.label_settings.shadow_offset = Vector2(0,0)
	fps_count.label_settings.font = load("res://resources/Vividly-extended-Regular.ttf")
	fps_count.label_settings.font_size = 32
	fps_counter = fps_count
	get_tree().root.add_child.call_deferred(ui_layer,true)
	ui_layer.add_child(fps_count)
	DisplayServer.window_set_title(str(get_window().title.trim_suffix("(DEBUG)")," ",ProjectSettings.get_setting("application/config/version")))
	
	if !DirAccess.dir_exists_absolute("user://user_data"):
		DirAccess.make_dir_absolute("user://user_data")
	
	var temp_settings = load_json_dict(settings_file)
	if !temp_settings.is_empty():
		Settings = temp_settings
	else:
		save_json_dict(settings_file,default_settings)
		Settings = default_settings

func clear_temp():
	if DirAccess.dir_exists_absolute("user://temp"):
		DirAccess.remove_absolute("user://temp")
		DirAccess.make_dir_absolute("user://temp")

var last_target_fps
var last_vsync
var last_fps
func _process(_delta: float) -> void:
	for key in default_settings.keys():
		Settings.get_or_add(key, default_settings[key])

	if Settings.target_fps != last_target_fps:
		Engine.max_fps = 0 if Settings.target_fps < 10 else Settings.target_fps
		last_target_fps = Settings.target_fps

	if Settings.vsync != last_vsync:
		DisplayServer.window_set_vsync_mode(Settings.vsync)
		last_vsync = Settings.vsync

	if fps_counter:
		if Settings["show_fps"] != fps_counter.visible:
			fps_counter.visible = Settings["show_fps"]

		var current_fps = roundi(Engine.get_frames_per_second())
		if current_fps != last_fps:
			fps_counter.text = str(current_fps)+" FPS"
			last_fps = current_fps

const INDICATOR_CHR = '￼'

func sanitize_json(value):
	if typeof(value) == TYPE_DICTIONARY:
		var new_dict = {}
		for k in value.keys():
			new_dict[k] = sanitize_json(value[k])
		return new_dict
	elif typeof(value) == TYPE_ARRAY:
		var new_arr = []
		for v in value:
			new_arr.append(sanitize_json(v))
		return new_arr
	elif typeof(value) == TYPE_FLOAT:
		if is_nan(value):
			return INDICATOR_CHR + "NaN" + INDICATOR_CHR
		elif value == INF:
			return INDICATOR_CHR + "INF" + INDICATOR_CHR
		elif value == -INF:
			return INDICATOR_CHR + "-INF" + INDICATOR_CHR
		else:
			return value
	else:
		return value

func unsanitize_json(value):
	if typeof(value) == TYPE_DICTIONARY:
		var new_dict = {}
		for k in value.keys():
			new_dict[k] = unsanitize_json(value[k])
		return new_dict
	elif typeof(value) == TYPE_ARRAY:
		var new_arr = []
		for v in value:
			new_arr.append(unsanitize_json(v))
		return new_arr
	elif typeof(value) == TYPE_STRING and value.begins_with(INDICATOR_CHR) and value.ends_with(INDICATOR_CHR):
		var content = value.substr(1, value.length() - 2)
		match content:
			"NaN":
				return NAN
			"INF":
				return INF
			"-INF":
				return -INF
			_:
				return value
	else:
		return value

func load_json_dict(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + path)
		return {}

	var text = file.get_as_text()
	var result = JSON.parse_string(text)
	if result is Dictionary:
		return unsanitize_json(result)
	else:
		push_error("JSON file does not contain a dictionary: " + path)
		return {}

func save_json_dict(path: String, data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + path)
		return
	var sanitized_data = sanitize_json(data)
	var json_text = JSON.stringify(sanitized_data, "\t")
	file.store_string(json_text)
	file.flush()
	file.close()
