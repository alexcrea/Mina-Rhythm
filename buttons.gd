extends Control

@export var button_scene:= preload("res://song_button.tscn")  # Exported variable to assign the button scene
@export var info_scene:= preload("res://info_panel.tscn")

#TODO 
# add name append from pak config for append song
# make songs list dynamic based on songs folder and configs
var song_paths:Array = []
var songs : Array = []  # Array to store song information
var selected_index : int = -1  # Index of the currently selected song
var buttons : Array[Node]
var _trans_to_play = false
var _seperation_factor = 100
var _x_factor = -50
signal button_slide_finished
signal button_slide_start(path_to_song)
signal add_songs_pressed
@export var scroll_container : ScrollContainer
var audioplayer:AudioStreamPlayer
var curr_info_box:Node

func _ready():
	init_new_audioplayer()
	populate_song_list()
	append_song("",true)

func populate_song_list():
	var song_dir = DirAccess.open(ProjectSettings.globalize_path("res://songs"))
	for song in song_dir.get_directories():
		song_paths.append(str("res://songs/",song))
		songs.append(Global.pak_reader.get_pak_name(str("res://songs/",song),true))
	for i in songs.size():
		var song_name = songs[i]
		var button = button_scene.instantiate()  # Create a new button instance
		button.label.text = song_name  # Set the button text to the song name
		button.label.label_settings = button.label.label_settings.duplicate()
		button.label.label_settings.font_size = 21 * pow(24.0 / button.label.text.length(), 0.1)#max( 16, 21 * (24.0 / button.label.text.length()) )
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
				print(song_paths[buttons.find(button_node)],"/",Global.pak_reader.get_unpacked_pak_song(song_paths[buttons.find(button_node)]))
				print(load(str(song_paths[buttons.find(button_node)],"/",Global.pak_reader.get_unpacked_pak_song(song_paths[buttons.find(button_node)]))))
				if selected_index < 0:
					audioplayer.stream = load(str(song_paths[0],"/",Global.pak_reader.get_unpacked_pak_song(song_paths[0])))
					audioplayer.play()
					audioplayer.stream.loop = true
				else:
					audioplayer.stream = load(str(song_paths[buttons.find(button_node)],"/",Global.pak_reader.get_unpacked_pak_song(song_paths[buttons.find(button_node)])))
					audioplayer.play()
					audioplayer.stream.loop = true
				#breakpoint
				#var voltween = create_tween()
				#audioplayer.volume_db = -50
				#voltween.set_trans(Tween.TRANS_QUINT)
				#voltween.tween_property(audioplayer,"volume_db",Global.Settings["music_volume"],0.4).set_ease(Tween.EASE_IN)
	else:
		if index == selected_index:
			emit_signal("add_songs_pressed")
	selected_index = index
	if button_node.label.text == "add song":
		song = "add song"
	else:
		song = songs[index]
	print("Selected song: ", song)

func apply_slide_back_effect(else_button: Control):
	emit_signal("button_slide_start")
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

func apply_selected_effect(button,start_or_end):
	var tween = create_tween()
	if start_or_end:
		tween.tween_property(button, "position:x", button.get_meta("original_x") + 52, 0.1)
	else:
		tween.tween_property(button, "position:x", button.get_meta("original_x"), 0.1).set_ease(Tween.EASE_OUT)

func scroll_to_selected(button):
	# Ensure the button is visible
	scroll_container.ensure_control_visible(button)
	var info_box = info_scene.instantiate()
	info_box.title = songs[button.id]
	info_box.desc = Global.pak_reader.get_pak_desc(song_paths[button.id])
	info_box.icon = load(str(song_paths[button.id],"/",Global.pak_reader.get_pak_icon(song_paths[button.id],true)))
	info_box.position.x = 1000
	info_box.position.y = 440
	if(curr_info_box):
		curr_info_box.queue_free()
	curr_info_box = info_box
	get_parent().get_parent().add_child.call_deferred(info_box)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(info_box, "position:x", 670, 0.3).set_ease(Tween.EASE_OUT)

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

func append_song(song_config_path,is_add_song_button: = false):
	var button = button_scene.instantiate()  # Create a new button instance
	var song_name
	if is_add_song_button:
		song_name = "add song"
	else:
		song_name = "test"
		songs.append(song_name)
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

func pop_song(song_config_path:="default",pop_index:= -1):
	if pop_index != -1:
		songs.pop_at(pop_index)
		remove_child(buttons[pop_index])
		buttons.pop_at(pop_index)
		for i in buttons.size():
			var button = buttons[i]
			button.id = i
			button.position = Vector2(_x_factor, i * _seperation_factor)  # Position buttons vertically
			button.set_meta("original_x",button.position.x)
			button.set_meta("original_y",button.position.y)
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
