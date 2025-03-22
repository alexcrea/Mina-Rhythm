extends Button

@export var dialog: FileDialog
@export var musicdialog: Node
@export var previewdialog: Node
@export var videodialog: Node
@export var icondialog: Node
@export var paknamedialog:Node
@export var pakinfodialog:Node
@export var root:Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	root.connect("button_refresh",Callable(self,"_refresh"))
	dialog.connect("file_selected", Callable(self,"_file_selected"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _file_selected(path):
	generate_config()
	var generated_info_file = FileAccess.open("res://temp/generated_info_file.txt", FileAccess.WRITE)
	generated_info_file.store_string(pakinfodialog.text)
	generated_info_file.close()
	Global.IRLS.import_to_res(path, true, "res://editor/editor.tscn",str(root.selected_files))
func _on_pressed() -> void:
	dialog.visible = true
func _refresh():
	if FileAccess.file_exists("res://temp/generated_pak_file.ini"):
		var config = Global.pak_reader.parse_config("res://temp",true)
		for line in config:
			for prefix in Global.pak_reader.prefixes:
				if line.trim_prefix(prefix).strip_edges() != "" and line.trim_prefix(prefix).strip_edges() != "\n" and line.begins_with(prefix):
					match prefix:
						"icon=":
							if self.name == "iconsel":
								self.text = self.text.trim_suffix("(unset)")
								self.text.replace("(unset)","")
								self.icon = load(str("res://temp/",line.trim_prefix(prefix).strip_edges().strip_escapes()))
						"preview_img=":
							if self.name == "previewsel":
								self.text = self.text.trim_suffix("(unset)")
								self.icon = load(str("res://temp/",line.trim_prefix(prefix).strip_edges().strip_escapes()))
						"song=":
							if self.name == "musicsel":
								self.text = self.text.trim_suffix("(unset)")
						"video=":
							if self.name == "videosel":
								self.text = self.text.trim_suffix("(unset)")
						_:
							pass
func generate_config():
	var generated_pak_config:String = str(
		"[PackInfo]\n",
		"pack_config=generated_pak_file.ini\n",
		"pack_name=", paknamedialog.text, "\n",
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
	return generated_pak_config
