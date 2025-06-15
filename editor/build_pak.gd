extends Button

var pak_filename
var files_to_package = []

@export var tabcontroler: Node
@export var colorrect: Node
@export var iconfiledialog: Node
@export var videofiledialog: Node
@export var previewfiledialog: Node
@export var musicfiledialog: Node
@export var pakinfobox: Node
@export var paknamebox: Node
@export var reqpopup: Node
@export var confirmpopup: Node
@export var root: Node

func _ready() -> void:
	confirmpopup.connect("canceled", Callable(self, "_canceled"))
	confirmpopup.connect("confirmed", Callable(self, "_confirmed"))

func _on_pressed() -> void:
	reqpopup.dialog_text = "Please fill out all required fields!"
	if paknamebox.text == "":
		reqpopup.visible = true
		reqpopup.dialog_text += " PakName"
		print(root.selected_files)
		return
	if root.selected_files[3] == "":
		reqpopup.visible = true
		reqpopup.dialog_text += " Song"
		print(root.selected_files)
		return
	var generated_pak_config:String = str(
		"[PackInfo]\n",
		"pack_config=generated_pak_file.ini\n",
		"pack_name=", paknamebox.text, "\n",
		"icon=", root.selected_files[0], "\n",
		"[Resources]\n",
		"song=", root.selected_files[3], "\n",
		"video=", root.selected_files[1], "\n",
		"preview_img=", root.selected_files[2],"\n",
		"beat_map=","\n",
		"info=generated_info_file.txt\n"
	)
	# Store the config in a temporary file
	var generated_pak_file = FileAccess.open("res://temp/generated_pak_file.ini", FileAccess.WRITE)
	generated_pak_file.store_string(generated_pak_config)
	generated_pak_file.close()
	busy_screen()
	pack_pak()
	reset_busy_screen()
	DirAccess.remove_absolute("res://temp")
	DirAccess.make_dir_absolute("res://temp")

func pack_pak() -> void:
	# Define a dictionary to map prefixes to their actions
	var prefix_to_list = {
		"icon=": files_to_package,
		"pack_name=": files_to_package,
		"pack_config=": files_to_package,
		"song=": files_to_package,
		"video=": files_to_package,
		"preview_img=": files_to_package,
		"beat_map=": files_to_package,
		"info=": files_to_package
	}
	
	# Open the .ini file
	var config_file = FileAccess.open("res://temp/generated_pak_file.ini", FileAccess.READ)
	if not config_file:
		print("Failed to open .ini file")
		return

	var pack_name = ""
	files_to_package = []

	while not config_file.eof_reached():
		var line = config_file.get_line().strip_edges()
		
		# Skip section headers like [PackInfo]
		if line.begins_with("["):
			continue

		var processed = false
		for prefix in prefix_to_list.keys():
			if line.begins_with(prefix):
				if prefix == "pack_name=":
					pack_name = line.replace(prefix, "").strip_edges()
				else:
					var file_path = line.replace(prefix, "").strip_edges().replace("\\", "/")
					files_to_package.append(str("res://temp/",file_path))
					
				processed = true
				break

		if not processed:
			print("Unrecognized line: ", line)
	
	config_file.close()
	
	if pack_name == "":
		print("Pack name not found in config file")
		return
	
	pak_filename = "user://%s.minapak" % pack_name
	confirmpopup.dialog_text = str("Pak already exists at (", ProjectSettings.globalize_path(pak_filename), ") !")
	if FileAccess.file_exists(pak_filename):
		confirmpopup.visible = true
	else:
		create_zip(pak_filename, files_to_package)
		print("Pack successfully created as " + pak_filename)

func create_zip(zip_path: String, files: Array) -> void:
	var writer = ZIPPacker.new()
	
	# Open the ZIP file for writing
	var err = writer.open(zip_path)
	if err != OK:
		print("Failed to create ZIP file")
		return
	
	# Declare file_data variable at the start of the function
	var file_data: PackedByteArray

	# Include the generated config file in the pack
	var config_file = "res://temp/generated_pak_file.ini"
	var f = FileAccess.open(config_file, FileAccess.READ)
	if f:
		file_data = f.get_buffer(f.get_length())
		f.close()
		writer.start_file("generated_pak_file.ini")
		writer.write_file(file_data)
		writer.close_file()

	# Force include info.txt
	var info_file = "res://temp/generated_info_file.txt"
	f = FileAccess.open(info_file, FileAccess.READ)
	if f:
		file_data = f.get_buffer(f.get_length())
		f.close()
		writer.start_file("generated_info_file.txt")
		writer.write_file(file_data)
		writer.close_file()
	else:
		print("Failed to open file: " + info_file)

	# Add each file to the ZIP archive
	for file_path in files:
		var file_name = file_path.split("\\")[-1].replace("res://temp/", "")
		f = FileAccess.open(file_path, FileAccess.READ)
		if f:
			file_data = f.get_buffer(f.get_length())
			f.close()
			writer.start_file(file_name)
			writer.write_file(file_data)
			writer.close_file()
		else:
			print("Failed to open file: " + file_path)
	
	writer.close()
	print("Pack file created as " + zip_path)

func busy_screen():
	tabcontroler.visible = false
	colorrect.visible = false
	self.visible = false
	Input.set_default_cursor_shape(Input.CURSOR_BUSY)

func reset_busy_screen():
	tabcontroler.visible = true
	colorrect.visible = true
	self.visible = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _canceled(): pass

func _confirmed():
	create_zip(pak_filename, files_to_package)
	print("Pack successfully created as " + pak_filename)
