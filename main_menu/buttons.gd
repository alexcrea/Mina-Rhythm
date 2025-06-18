extends Control

@export var button_scene:= preload("res://main_menu/song_button.tscn")
@export var info_scene:= preload("res://main_menu/info_panel.tscn")
@export var play_scene:= preload("res://play/play.tscn")

var song_paths:Array = []
var songs : Array = []  # Array to store song information
var selected_index : int = 0  # Index of the currently selected song
var buttons : Array[Node]
var _trans_to_play = false
var _seperation_factor = 100
var _x_factor = -50
signal add_songs_pressed
@export var scroll_container : ScrollContainer
var audioplayer:AudioStreamPlayer
var videoplayer:VideoPlayback
var backgroundimage:TextureRect
var curr_info_box:Node
var ignore_button:= false

func _ready():
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
			var button = button_scene.instantiate()
			button.label.text = song_name
			button.label.label_settings = button.label.label_settings.duplicate()
			button.label.label_settings.font_size = 21 * pow(24.0 / button.label.text.length(), 0.1)
			button.id = i
			button.audioplayer = audioplayer
			button.connect("pressed", Callable(self, "_on_button_pressed"))
			button.connect("focus_entered", Callable(self, "_on_focus_entered"))
			button.position = Vector2(_x_factor, i * _seperation_factor)
			button.set_meta("original_x",button.position.x)
			button.set_meta("original_y",button.position.y)
			button.set_meta("selected_once",false)
			add_child(button)
			buttons.append(button)
	else:
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path("user://songs"))
	scroll_container.size.y = buttons.size() * _seperation_factor + 50

func _on_button_pressed(index: int):
	var button_node: Control = null

	for button in get_children():
		if button is Control and button.has_method("get_id") and button.id == index:
			button_node = button
			break

	if button_node == null:
		return

	if button_node.get_meta("selected_once") == true:
		if button_node.has_meta("add_song_button"):
			emit_signal("add_songs_pressed")
			return
		_trans_to_play = true
		apply_slide_back_effect(button_node)
	else:
		for button in buttons:
			button.set_meta("selected_once", false)
		button_node.set_meta("selected_once", true)
		selected_index = index
		init_new_audioplayer()
		init_new_videoplayer()
		init_new_backgroundimage()
		scroll_to_selected(button_node)
		play_preview(index)
		await get_tree().process_frame
		await get_tree().process_frame
		for button in buttons:
			apply_selected_effect(button,false)
		apply_selected_effect(button_node,true)

func apply_slide_back_effect(else_button: Control):
	for button in buttons:
		var tween = create_tween()
		if button != else_button:
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

func apply_selected_effect(button,start_or_end:bool):
	var tween = create_tween()
	if start_or_end:
		tween.tween_property(button, "position:x", button.get_meta("original_x") + 52, 0.1)
	else:
		tween.tween_property(button, "position:x", button.get_meta("original_x"), 0.1).set_ease(Tween.EASE_OUT)

func scroll_to_selected(button):
	var is_add_song_button = button.has_meta("add_song_button")
	if button.has_meta("add_song_button") || FileAccess.file_exists(str(song_paths[button.id],"/pak_config.ini")) || selected_index == 0:
		scroll_container.ensure_control_visible(button)
		var info_box = info_scene.instantiate()
		if is_add_song_button:
			info_box.title = "Import a song!"
			info_box.icon = load("res://resources/add.svg")
			info_box.desc = "Import a song from an .osz or .minapak!"
			info_box.song = ""
			info_box.pak = ""
		else:
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

func play_preview(index):
	if index < song_paths.size():
		var song_path = song_paths[index]
		var song_file = Global.pak_reader.find_in_config(song_path, true, "song")
		var music_path = song_path + "/" + song_file

		var loader := AudioLoader.new()
		var stream = loader.loadfile(music_path,true)
		#if music_path.ends_with(".ogg"):
			#stream = AudioStreamOggVorbis.load_from_file(music_path)
		#elif music_path.ends_with(".mp3"):
			#var file = FileAccess.open(music_path, FileAccess.READ)
			#if file:
				#var mp3 = AudioStreamMP3.new()
				#mp3.data = file.get_buffer(file.get_length())
				#stream = mp3
		if stream:
			audioplayer.stop()
			audioplayer.stream = stream
		else:
			push_error("Failed to load music from %s" % music_path)
			return

		var start_time = Global.pak_reader.find_in_config(song_path, true, "song_start")
		start_time = float(start_time) if start_time.is_valid_float() and float(start_time) >= 0 else 0.0

		videoplayer.hide()
		backgroundimage.hide()

		var video_path = Global.pak_reader.find_in_config(song_path, true, "background")
		var is_image = Global.pak_reader.is_song_background_image(song_path, true)

		if video_path:
			var full_path = "user://songs/%s/%s" % [songs[index], video_path]
			if is_image:
				var img = Image.new()
				if img.load(full_path) == OK:
					backgroundimage.texture = ImageTexture.create_from_image(img)
			else:
				videoplayer.set_video_path(ProjectSettings.globalize_path(full_path))
		audioplayer.play(start_time)
		if is_image:
			backgroundimage.show()
		else:
			videoplayer.show()
			videoplayer.enable_auto_play = true

#func _process(_delta: float) -> void:
	#scroll_container.size.y = buttons.size() * _seperation_factor + 50

func append_song(_song_config_path,is_add_song_button: = false):
	var button = button_scene.instantiate()
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
		button.label.text = song_name
		if buttons.size() > 0:
			button.id = buttons[buttons.size() - 1].id + 1
		else:
			button.id = 0
		button.audioplayer = audioplayer
		button.connect("pressed", Callable(self, "_on_button_pressed"))
		button.connect("focus_entered", Callable(self, "_on_focus_entered"))
		button.position = Vector2(_x_factor, buttons.size() * _seperation_factor)
		button.set_meta("original_x",button.position.x)
		button.set_meta("original_y",button.position.y)
		button.set_meta("selected_once",false)
		if is_add_song_button:
			button.set_meta("add_song_button","")
		add_child(button)
		buttons.append(button)
		if !is_add_song_button:
			append_song("",true)
			#selected_index+=1
		for i in buttons.size():
			var ibutton = buttons[i]
			ibutton.id = i
			ibutton.position = Vector2(_x_factor, i * _seperation_factor)
			ibutton.set_meta("original_x",ibutton.position.x)
			ibutton.set_meta("original_y",ibutton.position.y)
	scroll_container.size.y = buttons.size() * _seperation_factor + 50

func pop_song(pop_index:= -1):
	if pop_index != -1:
		songs.pop_at(pop_index)
		song_paths.pop_at(pop_index)
		buttons[pop_index].queue_free()
		buttons.pop_at(pop_index)
		for i in buttons.size():
			var button = buttons[i]
			button.id = i
			button.position = Vector2(_x_factor, i * _seperation_factor)
			button.set_meta("original_x",button.position.x)
			button.set_meta("original_y",button.position.y)
		if selected_index >= buttons.size():
			selected_index = max(0, buttons.size() - 2)
		ignore_button = true
		await get_tree().process_frame
	scroll_container.size.y = buttons.size() * _seperation_factor + 50

func _trans_tween_finished():
	emit_signal("button_slide_finished",)

func init_new_audioplayer():
	if audioplayer:
		audioplayer.playing = false
		audioplayer.stop()
		audioplayer.queue_free()
		audioplayer = null
	audioplayer = AudioStreamPlayer.new()
	audioplayer.name = "MusicPlayer"
	audioplayer.bus = "Music"
	audioplayer.volume_db = -12
	add_child(audioplayer)

func init_new_videoplayer():
	if videoplayer:
		videoplayer.is_playing = false
		videoplayer.close()
		videoplayer.queue_free()
		videoplayer = null
	videoplayer = VideoPlayback.new()
	videoplayer.name = "VideoPlayback"
	videoplayer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	videoplayer.enable_audio = false
	videoplayer.loop = true
	videoplayer.visible = false
	videoplayer.set_anchors_preset(PRESET_FULL_RECT)
	get_parent().get_parent().add_child.call_deferred(videoplayer)
	get_parent().get_parent().move_child.call_deferred(videoplayer,0)

func init_new_backgroundimage():
	if backgroundimage:
		backgroundimage.queue_free()
		backgroundimage = null
	backgroundimage = TextureRect.new()
	backgroundimage.name = "BackgroundImage"
	backgroundimage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backgroundimage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backgroundimage.visible = false
	backgroundimage.set_anchors_preset(PRESET_FULL_RECT)
	get_parent().get_parent().add_child.call_deferred(backgroundimage)
	get_parent().get_parent().move_child.call_deferred(backgroundimage,0)

func _on_import(song_list: PackedStringArray) -> void:
	for song in song_list:
		append_song(str("user://songs/",song))

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.is_action_pressed("lane1",true):
				if selected_index-1 >= 0:
					_on_button_pressed(selected_index-1)
			elif event.is_action_pressed("lane2",true):
				if selected_index+1 < buttons.size():
					_on_button_pressed(selected_index+1)
			elif event.is_action_pressed("ui_accept"):
				_on_button_pressed(selected_index)
