extends CanvasLayer

@export var lanes: Array[Node]
signal button_refresh
var selected_files:= ["","","",""]
var single = preload("res://play/single.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DirAccess.dir_exists_absolute("res://temp") && FileAccess.open("res://reload_file",FileAccess.READ).get_length() < 3:
		Global.clear_temp()
	if !FileAccess.file_exists("res://temp/generated_pak_file.ini"):
		$ColorRect2.visible = true
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUINT)
		tween.tween_property($ColorRect2,"position:x",1152,1).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		OS.alert("the game will restart to load resources\nthis is normal.","Notice")
	else:
		var config = Global.pak_reader.parse_config("res://temp",true)
		for i in config.size() - 1:
			for prefix in Global.pak_reader.prefixes:
				if config[i].begins_with(prefix) && config[i].trim_prefix(prefix).strip_edges().strip_escapes() != "":
					match prefix:
						"pack_name=":
							$TabContainer/PakInfo/Panel3/LineEdit.text = config[i].trim_prefix(prefix)
						"icon=":
							$TabContainer/PakInfo/Panel2/icondialog.current_file = str("res://temp/",config[i].trim_prefix(prefix)).strip_edges().strip_escapes()
						"preview_img=":
							$TabContainer/PakInfo/Panel2/previewdialog.current_file = str("res://temp/",config[i].trim_prefix(prefix)).strip_edges().strip_escapes()
		var info = FileAccess.open("res://temp/generated_info_file.txt",FileAccess.READ)
		$TabContainer/PakInfo/Panel/TextEdit.text = info.get_as_text()
	if FileAccess.file_exists("res://temp/generated_pak_file.ini"):
			# Clean up the data
		var config = Global.pak_reader.parse_config("res://temp",true)
		for each in config:
			for prefix in Global.pak_reader.prefixes:
				if each.begins_with(prefix):
					match prefix:
						"icon=":
							selected_files[0] = each.trim_prefix(prefix).strip_edges().strip_escapes()
						"video=":
							selected_files[1] = each.trim_prefix(prefix).strip_edges().strip_escapes()
						"preview_img=":
							selected_files[2] = each.trim_prefix(prefix).strip_edges().strip_escapes()
						"song=":
							selected_files[3] = each.trim_prefix(prefix).strip_edges().strip_escapes()
						_:
							pass
				else: continue
		
		#var data = Global.data.replace("IRLS_IMPORT","")
		#data = data.replace("\"\"", "")  # Remove doubled quotes
		#data = data.strip_edges()  # Remove any surrounding whitespace
#
		## Remove brackets if they exist
		#if data.begins_with("[") and data.ends_with("]"):
			#data = data.substr(1, data.length() - 2)
#
		## Split the data into slices
		#var slices = data.split(",")
#
		## Process each slice
		#for i in range(slices.size()):
			#var slice = slices[i].strip_edges()  # Trim whitespace from each slice
			#if slice.strip_edges().strip_escapes() != "":
				#selected_files.insert(0,slice.replace("\"", ""))  # Update selected_files
			#else:
				#continue
			#print(selected_files)
	emit_signal("button_refresh")
func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_point_in_lane(get_viewport().get_mouse_position())[0]:
				print("mouse menu open")
				$ContextMenu.show()
				$ContextMenu.position = get_viewport().get_mouse_position()

func _on_context_menu_id_pressed(id: int) -> void:
	if is_point_in_lane(get_viewport().get_mouse_position()).size() > 1:
		var lane = is_point_in_lane(get_viewport().get_mouse_position())[1]
		if lane != null:
			match id:
				0:
					var new = single.instantiate()
					new.position = Vector2(lane.position.x - 270,get_viewport().get_mouse_position().y)
					lane.add_child(new)
					print("CMD: create note")
				1:
					print("CMD: create trigger")
func _process(_delta: float) -> void:
	$Area2D.position = get_viewport().get_mouse_position()
func _on_icondialog_file_selected(path: String) -> void: 
	selected_files.pop_at(0)
	selected_files.insert(0,path.replace("\\", "/").split("/")[path.replace("\\", "/").split("/").size() - 1])
	print("file selected: ", selected_files[0])

func _on_videodialog_file_selected(path: String) -> void: 
	selected_files.pop_at(1)
	selected_files.insert(1,path.replace("\\", "/").split("/")[path.replace("\\", "/").split("/").size() - 1])
	print("file selected: ", selected_files[1])

func _on_previewdialog_file_selected(path: String) -> void:
	selected_files.pop_at(2)
	selected_files.insert(2,path.replace("\\", "/").split("/")[path.replace("\\", "/").split("/").size() - 1])
	print("file selected: ", selected_files[2])

func _on_musicdialog_file_selected(path: String) -> void: 
	selected_files.pop_at(3)
	selected_files.insert(3,path.replace("\\", "/").split("/")[path.replace("\\", "/").split("/").size() - 1])
	print("file selected: ", selected_files[3])


func _on_musicsel_pressed() -> void:
	$FileDialog.show()

func _on_file_dialog_file_selected(path: String) -> void:
	await Global.clear_temp()
	Global.pak_reader.import_minapak(path)
	#Global.restart_game("res://editor/editor.tscn","")

func generate_config_relay():
	return $TabContainer/PakInfo/Panel2/musicdialog.generate_config()

func is_point_in_lane(point: Vector2) -> Array:
	var returns:Array 
	var margin = 20  # Adjust this value as needed for leniency

	for lane in lanes:
		if (point.x > lane.position.x - margin and point.x < lane.position.x + lane.size.x + margin) and \
			(point.y > lane.position.y - margin and point.y < lane.position.y + lane.size.y + margin):
			returns.append(true)
			returns.append(lane)
			return returns
	returns.append(false)
	returns.append(null)
	return returns
