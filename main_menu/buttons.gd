extends Control

@export var button_scene:= preload("res://main_menu/song_button.tscn")  # Exported variable to assign the button scene
@export var info_scene:= preload("res://main_menu/info_panel.tscn")
@export var play_scene:= preload("res://play/play.tscn")

var song_paths:Array = []
var songs : Array = []  # Array to store song information
var selected_index : int = -1  # Index of the currently selected song
var buttons : Array[Node]
var _trans_to_play = false
var _seperation_factor = 100
var _x_factor = -50
signal add_songs_pressed
@export var scroll_container : ScrollContainer
var audioplayer:AudioStreamPlayer
var curr_info_box:Node
var ignore_button:= false

func _ready():
	init_new_audioplayer()
	populate_song_list()
	append_song("",true)

func populate_song_list():
	var song_dir = DirAccess.open(ProjectSettings.globalize_path("user://songs"))
	if song_dir:
		for song in song_dir.get_directories():
			song_paths.append(str("user://songs/",song))
			songs.append(Global.pak_reader.find_in_config(str("user://songs/",song),true,"pack_name"))
		for i in songs.size():
			var song_name = songs[i]
			var button = button_scene.instantiate()  # Create a new button instance
			button.label.text = song_name  # Set the button text to the song name
			button.label.label_settings = button.label.label_settings.duplicate()
			button.label.label_settings.font_size = 21 * pow(24.0 / button.label.text.length(), 0.1)
			print(button.label.label_settings.font_size)
			button.id = i
			button.audioplayer = audioplayer
			button.connect("pressed", Callable(self, "_on_button_pressed"))
			button.connect("focus_entered", Callable(self, "_on_focus_entered"))
			button.position = Vector2(_x_factor, i * _seperation_factor)  # Position buttons vertically
			button.set_meta("original_x",button.position.x)
			button.set_meta("original_y",button.position.y)
			add_child(button)
			buttons.append(button)
	else:
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path("user://songs"))

func _on_button_pressed(index):
	var song 
	var button_node
	for button in get_children():
			var buttonfilter = button as Control
			if buttonfilter != null:
				if button.id == index:
					button_node = button
	if button_node.label.text != "add song":
		if index == selected_index:
			_trans_to_play = true
			apply_slide_back_effect(button_node)
		else:
			init_new_audioplayer()
			scroll_to_selected(button_node)
			if !audioplayer.playing:
				#tween.set_trans(Tween.TRANS_BOUNCE)
				print(song_paths[buttons.find(button_node)],"/",Global.pak_reader.find_in_config(song_paths[buttons.find(button_node)],true,"song"))
				if selected_index < 0:
					var music_path = str(song_paths[0], "/", Global.pak_reader.find_in_config(song_paths[0],true,"song"))
					var stream = AudioStreamOggVorbis.load_from_file(music_path)
					if stream:
						audioplayer.stop()
						audioplayer.stream = stream
						audioplayer.stream.loop = true
					else:
						push_error("Failed to load music from " + music_path)
					var start_time = Global.pak_reader.find_in_config(song_paths[0],true,"song_start")
					if start_time.is_valid_float():
						start_time = float(start_time)
					else:
						start_time = 0.0
					if start_time < 0:
						start_time = 0.0
					audioplayer.play(start_time)
					var videoplayer = get_node("/root/CanvasLayer/VideoStreamPlayer")
					videoplayer.stop()
					videoplayer.stream = null
					var video_path = Global.pak_reader.find_in_config(song_paths[0],true,"video")
					var video = VideoStreamTheora.new()
					if video_path:
						video.file = str(song_paths[0], "/", video_path)
						if video:
							videoplayer.stream = video
				else:
					var music_path = str(song_paths[buttons.find(button_node)], "/", Global.pak_reader.find_in_config(song_paths[buttons.find(button_node)],true,"song"))
					var stream = AudioStreamOggVorbis.load_from_file(music_path)
					if stream:
						audioplayer.stop()
						audioplayer.stream = stream
						audioplayer.stream.loop = true
					else:
						push_error("Failed to load music from " + music_path)
					var start_time = Global.pak_reader.find_in_config(song_paths[buttons.find(button_node)],true,"song_start")
					if start_time.is_valid_float():
						start_time = float(start_time)
					else:
						start_time = 0.0
					if start_time < 0:
						start_time = 0.0
					audioplayer.play(start_time)
					var videoplayer = get_node("/root/CanvasLayer/VideoStreamPlayer")
					videoplayer.stop()
					videoplayer.stream = null
					var video_path = Global.pak_reader.find_in_config(song_paths[buttons.find(button_node)],true,"video")
					var video = VideoStreamTheora.new()
					if video_path:
						video.file = str(song_paths[buttons.find(button_node)], "/", video_path)
						if video:
							videoplayer.stream = video
					audioplayer.play(start_time)
					videoplayer.play()
	else:
		if index == selected_index && !ignore_button:
			emit_signal("add_songs_pressed")
		ignore_button = false
	selected_index = index
	if button_node.label.text == "add song":
		song = "add song"
	else:
		if index <= songs.size()-1:
			song = songs[index]
		else:
			return
	print("Selected song: ", song)

func apply_slide_back_effect(else_button: Control):
	#emit_signal("button_slide_start")
	for button in buttons:
		var tween = create_tween()
		if button != else_button:
			# Slide other buttons off-screen
			tween.set_trans(Tween.TRANS_SINE)
			tween.tween_property(button, "position:x", button.get_meta("original_x") - button.size.x, 0.8).set_ease(Tween.EASE_IN)
		else: 
			tween.set_trans(Tween.TRANS_SINE)
			tween.tween_property(button, "position:x", button.get_meta("original_x") - button.size.x, 1.2).set_ease(Tween.EASE_IN)
			tween.connect("finished",Callable(self,"_trans_tween_finished"))
	var transition = get_node("/root/CanvasLayer/ColorRect")
	transition.visible = true
	var trantween = create_tween()
	trantween.set_trans(Tween.TRANS_QUINT)
	trantween.tween_property(transition,"position:x",0,1).set_ease(Tween.EASE_IN_OUT)
	await trantween.finished
	await Global.clear_temp()
	var play = play_scene.instantiate()
	play.song_path = song_paths[buttons.find(else_button)]
	get_tree().root.add_child(play)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = play

func apply_selected_effect(button,start_or_end):
	var tween = create_tween()
	if start_or_end:
		tween.tween_property(button, "position:x", button.get_meta("original_x") + 52, 0.1)
	else:
		tween.tween_property(button, "position:x", button.get_meta("original_x"), 0.1).set_ease(Tween.EASE_OUT)

func scroll_to_selected(button):
	# Ensure the button is visible
	if FileAccess.file_exists(str(song_paths[button.id],"/pak_config.ini")) || selected_index == -1:
		scroll_container.ensure_control_visible(button)
		var info_box = info_scene.instantiate()
		info_box.title = songs[button.id]
		info_box.desc = Global.pak_reader.find_in_config(song_paths[button.id],true,"desc")
		info_box.song = Global.pak_reader.find_in_config(song_paths[button.id],true,"credits")
		info_box.pak = Global.pak_reader.find_in_config(song_paths[button.id],true,"pak_creator")
		var icon_path = Global.pak_reader.find_in_config(song_paths[button.id],true,"icon")
		if icon_path:
			info_box.icon = ImageTexture.create_from_image(Image.load_from_file(str(song_paths[button.id],"/",icon_path)))
		else:
			info_box.icon = load("res://resources/minapak.svg")
		info_box.position.x = 1000
		info_box.position.y = 440
		if(curr_info_box):
			curr_info_box.queue_free()
		curr_info_box = info_box
		get_parent().get_parent().add_child.call_deferred(info_box)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(info_box, "position:x", 670, 0.3).set_ease(Tween.EASE_OUT)
	else:
		%AcceptDialog.title = "Oh noe!"
		%AcceptDialog.dialog_text = str("Song \"",songs[button.id],"\" could not be found! please make sure its installed correctly! wan wan!")
		%AcceptDialog.show()
		pop_song(button.id)

func _process(_delta: float) -> void:
	if !_trans_to_play:
		for button in get_children():
			var buttonfilter = button as Control
			if buttonfilter != null:
				if selected_index == buttonfilter.id:
					apply_selected_effect(buttonfilter,true)
				else:
					apply_selected_effect(buttonfilter,false)
	scroll_container.size.y = buttons.size() * _seperation_factor + 50

func append_song(_song_config_path,is_add_song_button: = false):
	var button = button_scene.instantiate()  # Create a new button instance
	var song_name
	if is_add_song_button:
		song_name = "add song"
	else:
		song_name = Global.pak_reader.find_in_config(_song_config_path,true,"pack_name")
		if song_name:
			songs.append(song_name)
			song_paths.append(_song_config_path)
	if song_name:
		if !is_add_song_button:
			for b in buttons:
				if b.label.text == "add song":
					buttons.remove_at(buttons.find(b))
					b.queue_free()
					break
		button.label.text = song_name  # Set the button text to the song name
		if buttons.size() > 0:
			button.id = buttons[buttons.size() - 1].id + 1
		else:
			button.id = 0
		button.audioplayer = audioplayer
		button.connect("pressed", Callable(self, "_on_button_pressed"))
		button.connect("focus_entered", Callable(self, "_on_focus_entered"))
		button.position = Vector2(_x_factor, buttons.size() * _seperation_factor)  # Position buttons vertically
		button.set_meta("original_x",button.position.x)
		button.set_meta("original_y",button.position.y)
		add_child(button)
		buttons.append(button)
		if !is_add_song_button:
			append_song("",true)
			selected_index+=1
		for i in buttons.size():
			var ibutton = buttons[i]
			ibutton.id = i
			ibutton.position = Vector2(_x_factor, i * _seperation_factor)  # Position buttons vertically
			ibutton.set_meta("original_x",ibutton.position.x)
			ibutton.set_meta("original_y",ibutton.position.y)

func pop_song(pop_index:= -1):
	if pop_index != -1:
		songs.pop_at(pop_index)
		song_paths.pop_at(pop_index)
		buttons[pop_index].queue_free()
		buttons.pop_at(pop_index)
		for i in buttons.size():
			var button = buttons[i]
			button.id = i
			button.position = Vector2(_x_factor, i * _seperation_factor)  # Position buttons vertically
			button.set_meta("original_x",button.position.x)
			button.set_meta("original_y",button.position.y)
		if selected_index >= buttons.size():
			selected_index = max(0, buttons.size() - 2)
		ignore_button = true
		await get_tree().process_frame

func _trans_tween_finished():
	emit_signal("button_slide_finished",)

func init_new_audioplayer():
	if audioplayer:
		audioplayer.queue_free()
		audioplayer = null
	audioplayer = AudioStreamPlayer.new()
	audioplayer.name = "MusicPlayer"
	audioplayer.volume_db = Global.Settings["music_volume"]
	add_child(audioplayer)


func _on_import(song_list: PackedStringArray) -> void:
	for song in song_list:
		append_song(str("user://songs/",song))
