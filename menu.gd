extends CanvasLayer

func _on_control_button_slide_start() -> void:
	pass # Replace with function body.

func _on_control_button_slide_finished() -> void:
	pass # Replace with function body.

func _on_control_add_songs_pressed() -> void:
	OS.alert("the game will restart to load songs\nthis is not a crash or error","Notice")
	$FileDialog.visible = true

func _ready() -> void:
	pass

func _on_file_dialog_files_selected(paths: PackedStringArray) -> void:
	print("Attempting to load minapaks")

	for path in paths:
		var pass_code = Global.pak_reader.import_minapak(path,"res://songs/")
		var name = pass_code.substr(pass_code.find(": ") + 2, pass_code.length())  # Extract the name after ": "
		var err_code = pass_code.substr(0, pass_code.find(": "))  # Extract the error code before ": "
	
		match err_code:
			"failed":
				Global.import_dialog += str("Failed: ", name, "\n")
			"exists":
				Global.import_dialog += str("Already exists: ", name, "\n")
			"success":
				Global.import_dialog += str("Success: ", name, "\n")
	Global.restart_game("res://menu.tscn","")

func _process(_delta: float) -> void:
	if Global.import_dialog.length() > 2 && Global.show_import_dialog:
		$AcceptDialog.dialog_text = Global.import_dialog
		$AcceptDialog.visible = true
		Global.import_dialog = ""
		Global.show_import_dialog = false


func _on_button_pressed() -> void:
	$ColorRect.visible = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($ColorRect,"position:x",0,1).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	await Global.clear_temp()
	get_tree().change_scene_to_file("res://editor.tscn")
