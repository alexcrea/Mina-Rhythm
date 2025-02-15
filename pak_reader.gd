extends Node

class_name PakFileReader
const prefixes = ["pack_config=","icon=","pack_name=","song=","video=","preview_img=","beat_map=","info="]
const info_prefixes = ["pak_creator=","credits=","desc="]

func get_unpacked_pak_song(pak_path:String) -> String:
	var config = parse_config(pak_path,true,false)
	var path: = ""
	for value in config:
		if value.begins_with("song="):
			path = value.trim_prefix("song=")
	return path

func get_pak_song_raw(pak_path: String) -> PackedByteArray:
	var reader = ZIPReader.new()
	if reader.open(pak_path) != OK:
		print("Failed to open ZIP file")
		return PackedByteArray()
	
	if not reader.file_exists("generated_pak_file.ini"):
		print("Config file not found in pak!")
		reader.close()
		return PackedByteArray()
	
	print("Successfully found pak config")
	var config_data = reader.read_file("generated_pak_file.ini").get_string_from_utf8()
	
	var song_file_name = ""
	for line in config_data.split("\n"):
		if line.begins_with("song="):
			song_file_name = line.substr(5).strip_edges()
			break
	
	if song_file_name == "":
		print("Song path not found in config file!")
		reader.close()
		return PackedByteArray()
	
	print("Found song name(path)")
	var song_data = reader.read_file(song_file_name)
	reader.close()
	return song_data

func get_file_data(pak_path: String, file_path: String) -> PackedByteArray:
	var reader = ZIPReader.new()
	if reader.open(pak_path) != OK:
		print("Failed to open ZIP file")
		return PackedByteArray()
	
	if reader.file_exists(file_path):
		var file_data = reader.read_file(file_path)
		reader.close()
		return file_data
	else:
		print("File does not exist in the pak: ", file_path)
		reader.close()
		return PackedByteArray()

func parse_config(pak_path:String,unpacked:bool,Include_pak_name:bool) -> PackedStringArray:
	var headers = ["[PackInfo]","[Resources]",""]
	var config_lines: Array
	var config:String
	match unpacked: 
		true:
			var confile = FileAccess.open(str(pak_path,"/generated_pak_file.ini"),FileAccess.READ)
			config = confile.get_as_text()
		false:
			var reader = ZIPReader.new()
			reader.open(pak_path)
			config = reader.read_file("generated_pak_file.ini").get_string_from_utf8()
	for index in config.get_slice_count("\n") - 1:
		config_lines.append(config.get_slice("\n",index))
	for line:String in config_lines:
		if line.begins_with("pack_name=") && !Include_pak_name:
			config_lines.remove_at(config_lines.find(line))
		for prefix in prefixes:
			if line.trim_prefix(prefix) == "" && config_lines.find(line) != -1:
				config_lines.remove_at(config_lines.find(line))
	for header in headers:
		while config_lines.find(header) != -1:
			config_lines.remove_at(config_lines.find(header))
	return config_lines

func parse_info(info_path:String) -> PackedStringArray:
	var info_lines: Array
	var info:String
	var inffile = FileAccess.open(str(info_path,"/generated_info_file.txt"),FileAccess.READ)
	info = inffile.get_as_text()
	for index in info.get_slice_count("\n") - 1:
		info_lines.append(info.get_slice("\n",index))
	for line:String in info_lines:
		for prefix in info_prefixes:
			if line.trim_prefix(prefix) == "" && info_lines.find(line) != -1:
				info_lines.remove_at(info_lines.find(line))
	return info_lines

func get_pak_name(pak_path:String,unpacked:bool) -> String:
	for value in parse_config(pak_path,unpacked,true):
		if value.begins_with("pack_name="):
			return value.trim_prefix("pack_name=")
	return ""

func get_pak_icon(pak_path:String,unpacked:bool) -> String:
	for value in parse_config(pak_path,unpacked,true):
		if value.begins_with("icon="):
			return value.trim_prefix("icon=")
	return ""

func get_pak_desc(pak_path:String) -> String:
	for value in parse_info(pak_path):
		if value.begins_with("desc="):
			return value.trim_prefix("desc=")
	return ""

func import_minapak(pak_path:String,to_path:String,create_folder:=true) -> String:
	var reader = ZIPReader.new() 
	reader.open(pak_path)
	var config = parse_config(pak_path,false,false)
	var files_to_import: Array
	var pak_name:String
	if get_pak_name(pak_path,false) != "":
		pak_name = get_pak_name(pak_path,false)
	if !DirAccess.dir_exists_absolute(str(to_path)):
		if DirAccess.make_dir_absolute(str(to_path)) != OK:
			return str("failed: song directory")
	if create_folder:
		if !DirAccess.dir_exists_absolute(str(to_path,pak_name)):
			if DirAccess.make_dir_absolute(str(to_path,pak_name)) != OK:
				return str("failed: ",pak_name)
		else:
			print("pak already exists at: ",to_path,pak_name)
			return str("exists: ",pak_name)
	for value in config:
		for prefix in prefixes:
			config[config.find(value)] = value.trim_prefix(prefix)
			config[(config.find(value))].strip_edges()
	for path in config.size() - 1:
		files_to_import.append(config[path])
	for file in files_to_import:
		if file.length() < 2:
			files_to_import.remove_at(files_to_import.find(file))
	files_to_import.append("generated_info_file.txt")
	print(files_to_import)
	if create_folder:
		for file_name in files_to_import:
			var new_file = FileAccess.open(str(to_path,pak_name,"/",file_name),FileAccess.WRITE)
			new_file.store_buffer(reader.read_file(file_name))
			new_file.close()
	else:
		for file_name in files_to_import:
			var new_file = FileAccess.open(str(to_path,"/",file_name),FileAccess.WRITE)
			new_file.store_buffer(reader.read_file(file_name))
			new_file.close()
	return str("success: ",pak_name)
