extends Node

class_name PakFileReader
const prefixes = ["icon=","pack_name=","song=","background=","preview_img=","beatmap=","info=","song_start=","song_end=","bottom_fade=","pak_creator=","credits=","desc="]

var supported_image_extensions := ["png","jpg","jpeg","bmp","tga","webp","tif","tiff","gif","hdr","exr","tex","stex","ctex"]

func parse_config(pak_path:String,unpacked:bool) -> PackedStringArray:
	var headers = ["[PackInfo]","[Resources]",""]
	var config_lines: Array
	var config:String
	match unpacked: 
		true:
			var confile = FileAccess.open(str(pak_path,"/pak_config.ini"),FileAccess.READ)
			if confile:
				config = confile.get_as_text()
			else:
				return []
		false:
			var reader = ZIPReader.new()
			reader.open(pak_path)
			config = reader.read_file("pak_config.ini").get_string_from_utf8()
	if config.is_empty():
		return []
	for index in config.get_slice_count("\n") - 1:
		config_lines.append(config.get_slice("\n",index))
	for line:String in config_lines:
		for prefix in prefixes:
			if line.trim_prefix(prefix) == "" && config_lines.find(line) != -1:
				config_lines.remove_at(config_lines.find(line))
	for header in headers:
		while config_lines.find(header) != -1:
			config_lines.remove_at(config_lines.find(header))
	return config_lines

func find_in_config(pak_path:String,unpacked:bool,key:String) -> String:
	if prefixes.find(key+"=") != -1:
		for value in parse_config(pak_path,unpacked):
			if value.begins_with(key+"="):
				return value.trim_prefix(key+"=")
		return ""
	else:
		push_error("ERROR: (",key,") is not a valid key!")
		return ""

func parse_beatmap(beatmap_path: String) -> Array:
	# Check if the file exists before attempting to open it.
	if not FileAccess.file_exists(beatmap_path):
		push_error("Beatmap file does not exist: " + beatmap_path)
		return []
	
	var notes = []
	var file = FileAccess.open(beatmap_path, FileAccess.READ)
	if not file:
		push_error("Failed to open beatmap file: " + beatmap_path)
		return notes
	
	var text = file.get_as_text()
	file.close()
	
	var lines = text.split("\n")
	for line in lines:
		line = line.strip_edges()
		if !line:
			continue
		if line.begins_with('##'):
			continue
		elif line.begins_with("[tap]"):
			var data = line.replace("[tap]", "").split("?")
			if data.size() != 2:
				push_warning("Malformed tap note line (expected 2 parameters): " + line)
				continue
			if not data[0].is_valid_int() or not data[1].is_valid_int():
				push_warning("Invalid integer in tap note line: " + line)
				continue
			if int(data[0]) > 3 or int(data[0]) < 0:
				push_warning("Invalid lane in tap note line: " + line)
				continue
			
			var note = {
				"type": "tap",
				"column": int(data[0]),
				"time": int(data[1])
			}
			notes.append(note)
		elif line.begins_with("[hold]"):
			var data = line.replace("[hold]", "").split("?")
			if data.size() != 3:
				push_warning("Malformed hold note line (expected 3 parameters): " + line)
				continue
			if not data[0].is_valid_int() or not data[1].is_valid_int() or not data[2].is_valid_int():
				push_warning("Invalid integer in hold note line: " + line)
				continue
			if int(data[0]) > 3 or int(data[0]) < 0:
				push_warning("Invalid lane in hold note line: " + line)
				continue
			
			var note = {
				"type": "hold",
				"column": int(data[0]),
				"start_time": int(data[1]),
				"end_time": int(data[2])
			}
			
			if note["end_time"] <= note["start_time"]:
				push_warning("Hold note with non-positive duration: " + line)
				continue
			notes.append(note)
		elif line.begins_with("[light]"):
			var data = line.replace("[light]", "").split("?")
			if data.size() != 2:
				push_warning("Malformed light note line (expected 2 parameters): " + line)
				continue
			if not data[0].is_valid_int() or not data[1].is_valid_int():
				push_warning("Invalid integer in light note line: " + line)
				continue
			if int(data[0]) > 3 or int(data[0]) < 0:
				push_warning("Invalid lane in light note line: " + line)
				continue
			
			var note = {
				"type": "light",
				"column": int(data[0]),
				"time": int(data[1])
			}
			notes.append(note)
		elif line.begins_with("[poly]"):
			var data = line.replace("[poly]", "").split("?")
			if data.size() != 4:
				push_warning("Malformed poly note line (expected 4 parameters): " + line)
				continue
			if not data[0].is_valid_int() or not data[1].is_valid_int() or not data[2].is_valid_int() or not data[3].is_valid_int():
				push_warning("Invalid integer in poly note line: " + line)
				continue
			if int(data[0]) > 3 or int(data[0]) < 0:
				push_warning("Invalid lane in poly note line: " + line)
				continue
			
			var note = {
				"type": "poly",
				"column": int(data[0]),
				"start_time": int(data[1]),
				"end_time": int(data[2]),
				"poly": int(data[3])
			}
			notes.append(note)
		else:
			push_warning("Unknown note type or format: " + line)
	
	return notes

func import_minapak(pak_path:String) -> String:
	var reader = ZIPReader.new() 
	reader.open(pak_path)
	var pak_name:String
	pak_name = find_in_config(pak_path,false,"pack_name")
	if !DirAccess.dir_exists_absolute(str("user://songs")):
		if DirAccess.make_dir_absolute(str("user://songs")) != OK:
			return str("failed: song directory")
	if !DirAccess.dir_exists_absolute(str("user://songs/",pak_name)):
		if DirAccess.make_dir_absolute(str("user://songs/",pak_name)) != OK:
			return str("failed: ",pak_name)
	else:
		print("pak already exists at: user://songs/",pak_name)
		return str("exists: ",pak_name)
	for file in reader.get_files():
		if FileAccess.file_exists(str("user://songs/",pak_name,"/",file)):
			push_error("error importing pak, file: ",file," already exists in user://songs/",pak_name)
		else:
			var writefile = FileAccess.open(str("user://songs/",pak_name,"/",file),FileAccess.WRITE)
			var contents = reader.read_file(file)
			writefile.store_buffer(contents)
			writefile.close()
	while not FileAccess.file_exists(str("user://songs/",pak_name,"/pak_config.ini")):
		await get_tree().process_frame
	if not FileAccess.get_file_as_bytes(str("user://songs/",pak_name,"/pak_config.ini")):
		while not FileAccess.get_file_as_bytes(str("user://songs/",pak_name,"/pak_config.ini")):
			await get_tree().process_frame
	return str("success: ",pak_name)

func is_song_background_image(pak_path:String,unpacked:bool) -> bool:
	var bg = find_in_config(pak_path,unpacked,"background")
	for extension in supported_image_extensions:
		if bg.ends_with(extension):
			return true
	return false

func import_osumania(path: String) -> String:
	var reader = ZIPReader.new()
	if reader.open(path) != OK:
		return str("failed: osz file may be corrupted")

	var beatmaps = []
	for file in reader.get_files():
		if file.ends_with(".osu"):
			var raw = reader.read_file(file).get_string_from_utf8()
			var lines = raw.split("\n")
			var section = ""
			
			var metadata = {
				"artist": "",
				"title": "",
				"creator": "",
				"version": "",
				"approach_rate": null,
				"overall_difficulty": null,
				"hp_drain_rate": null,
				"circle_size": null,
				"slider_multiplier": 1.4,
				"first_beat_length": 500.0,
				"hit_objects": [],
				"raw": raw
			}

			for line in lines:
				line = line.strip_edges()
				if line.begins_with("[") and line.ends_with("]"):
					section = line
					continue

				match section:
					"[Metadata]":
						if line.begins_with("Title:"):
							metadata.title = line.trim_prefix("Title:").strip_edges()
						elif line.begins_with("Artist:"):
							metadata.artist = line.trim_prefix("Artist:").strip_edges()
						elif line.begins_with("Creator:"):
							metadata.creator = line.trim_prefix("Creator:").strip_edges()
						elif line.begins_with("Version:"):
							metadata.version = line.trim_prefix("Version:").strip_edges()

					"[Difficulty]":
						if line.begins_with("ApproachRate:"):
							metadata.approach_rate = float(line.trim_prefix("ApproachRate:"))
						elif line.begins_with("OverallDifficulty:"):
							metadata.overall_difficulty = float(line.trim_prefix("OverallDifficulty:"))
						elif line.begins_with("HPDrainRate:"):
							metadata.hp_drain_rate = float(line.trim_prefix("HPDrainRate:"))
						elif line.begins_with("CircleSize:"):
							metadata.circle_size = int(line.trim_prefix("CircleSize:"))
						elif line.begins_with("SliderMultiplier:"):
							metadata.slider_multiplier = float(line.trim_prefix("SliderMultiplier:"))

					"[TimingPoints]":
						if metadata.first_beat_length == 500.0 and line != "":
							var parts = line.split(",")
							if parts.size() >= 2:
								var beat_len = float(parts[1])
								if beat_len > 0:
									metadata.first_beat_length = beat_len

					"[HitObjects]":
						if line != "":
							metadata.hit_objects.append(line)

			if metadata["CircleSize"] == 4:
				beatmaps.append(metadata)
	
	if !DirAccess.dir_exists_absolute(str("user://songs")):
		if DirAccess.make_dir_absolute(str("user://songs")) != OK:
			return str("failed: song directory")
	var song_name = path.get_file().get_basename()
	if !DirAccess.dir_exists_absolute(str("user://songs/",song_name)):
		if DirAccess.make_dir_absolute(str("user://songs/",song_name)) != OK:
			return str("failed: ",song_name)
	else:
		print("pak already exists at: user://songs/",song_name)
		return str("exists: ",song_name)
	return str("success: ",song_name)
	


func parse_osumania(hitobjects: Array, slider_multiplier: float = 1.4, beat_length: float = 500.0) -> Array:
	var parsed = []
	var lane_width = 128

	for line in hitobjects:
		if line.strip_edges() == "":
			continue

		var parts = line.split(",")
		if parts.size() < 5:
			continue

		var x = int(parts[0])
		var time = int(parts[2])
		var type = int(parts[3])
		var lane = int(float(x) / lane_width)

		if type & 1 != 0:
			parsed.append("[tap]%d?%d" % [lane, time])
		elif type & 2 != 0:
			var extras = line.split(",")
			var repeat = 1
			var pixel_length = 0.0

			if extras.size() >= 8:
				repeat = int(extras[6])
				pixel_length = float(extras[7])
			var duration = (pixel_length * repeat * beat_length) / (100.0 * slider_multiplier)
			var end_time = int(time + duration)
			parsed.append("[hold]%d?%d?%d" % [lane, time, end_time])
		else:
			continue

	return parsed
