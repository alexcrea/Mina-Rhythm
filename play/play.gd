extends CanvasLayer

var song_path: String = ""
var tap_scene = preload("res://play/single.tscn")
var hold_scene = preload("res://play/hold.tscn")
var light_scene = preload("res://play/light.tscn")
var poly_scene = preload("res://play/poly.tscn")
var judgement_scene = preload("res://play/judgement_text.tscn")
var current_time: float = 0.0
var scroll_speed: float = 0.5
var hit_line: float = 500
var lanes: Array[Panel]= []
var rating_ratios := [1.0,0.9,0.85,0.75,0.60,0.50,0.40,0.23,0.10]
var ratings := ["SP","SSS","SS","S","P","A","B","C",'D','F',"N/A"]
var timing_displays := ["Orbular!!", "Purrfect!", "Wan Wan!", "Wan!", "oh nyo...", "miss"]
var score: int = 0
@export var score_text:Label
var total_possible_score: int = 0
var total_notes: int = 0
var auto_play := false
var extra_info := true
var end_time
const HOLD_ACTIVATION_THRESHOLD = 100
const HOLD_RELEASE_THRESHOLD = 100
var max_combo := 0
var combo := 0
var ratio
var possible_combo:=0
var note_events: Array = []

var timing_windows = [2, 25, 50, 100, 250, 400]
var score_multipliers = [1000, 500, 250, 100, 50, -10]

func _ready() -> void:
	if song_path:
		for child in $hit_line.get_children():
			if child.has_meta("Lane"):
				lanes.append(child)
		var notes = Global.pak_reader.parse_beatmap(str(song_path, "/", Global.pak_reader.find_in_config(song_path,true,"beatmap")))
		for note in notes:
			total_notes += 1
			match note.type:
				"tap":
					var tap_note = tap_scene.instantiate()
					tap_note.position.y = get_note_position(note.time, current_time, hit_line, scroll_speed)
					total_possible_score += score_multipliers[0]
					tap_note.set_meta("type", note.type)
					tap_note.set_meta("is_note", true)
					tap_note.set_meta("lane", note.column)
					tap_note.set_meta("time", note.time)
					possible_combo+=1
					tap_note.set_meta("hit", false)
					tap_note.position.x = lanes[note.column].position.x
					add_child(tap_note)
					note_events.append(Vector2(note.time,score_multipliers[0]))
				"hold":
					var hold_note = hold_scene.instantiate()
					hold_note.size.y = (note.end_time - note.start_time) * scroll_speed
					hold_note.position.y = get_note_position(note.start_time, current_time, hit_line, scroll_speed) - hold_note.size.y
					hold_note.set_meta("is_note", true)
					hold_note.set_meta("type", note.type)
					hold_note.set_meta("time", note.start_time)
					hold_note.set_meta("end_time", note.end_time)
					hold_note.set_meta("lane", note.column)
					hold_note.set_meta("hit", false)
					possible_combo+=2
					total_possible_score += score_multipliers[0] * 2
					hold_note.position.x = lanes[note.column].position.x
					add_child(hold_note)
					note_events.append(Vector2(note.start_time,score_multipliers[0]))
					note_events.append(Vector2(note.end_time,score_multipliers[0]))
				"light":
					var light_note = light_scene.instantiate()
					light_note.position.y = get_note_position(note.time, current_time, hit_line, scroll_speed)
					light_note.set_meta("is_note", true)
					light_note.set_meta("type", note.type)
					light_note.set_meta("time", note.time)
					light_note.set_meta("lane", note.column)
					total_possible_score += score_multipliers[2]
					possible_combo+=1
					light_note.set_meta("hit", false)
					light_note.position.x = lanes[note.column].position.x
					add_child(light_note)
					note_events.append(Vector2(note.time,score_multipliers[2]))
				"poly":
					var poly_note = poly_scene.instantiate()
					poly_note.size.y = (note.end_time - note.start_time) * scroll_speed
					poly_note.position.y = get_note_position(note.start_time, current_time, hit_line, scroll_speed) - poly_note.size.y
					poly_note.set_meta("is_note", true)
					poly_note.set_meta("type", note.type)
					poly_note.set_meta("time", note.start_time)
					poly_note.set_meta("end_time", note.end_time)
					poly_note.set_meta("poly", note.poly)
					poly_note.set_meta("lane", note.column)
					poly_note.set_meta("hit_count",0)
					poly_note.set_meta("hit", false)
					total_possible_score += score_multipliers[1]
					possible_combo+=1
					poly_note.position.x = lanes[note.column].position.x
					var poly_count = Label.new()
					poly_count.text = str(note.poly)
					poly_count.z_index = 1
					poly_count.size.x = poly_note.size.x
					poly_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					poly_count.label_settings = LabelSettings.new()
					poly_count.label_settings.font_color = Color(1,1,1,1)
					poly_count.label_settings.shadow_color = Color(0,0,0,0.7)
					poly_count.label_settings.shadow_size = 20
					poly_count.label_settings.shadow_offset = Vector2(0,0)
					poly_count.label_settings.font = load("res://resources/Vividly-extended-Regular.ttf")
					poly_count.label_settings.font_size = 32
					poly_note.add_child(poly_count)
					add_child(poly_note)
					note_events.append(Vector2(note.end_time,score_multipliers[1]))
		score_text.text = str("Score: ",score," (",get_current_rating(),")")
		$TextureRect.visible = Global.pak_reader.find_in_config(song_path,true,"bottom_fade") == "true" if true else false
		var music_path = str(song_path, "/", Global.pak_reader.find_in_config(song_path,true,"song"))
		
		var loader := AudioLoader.new()
		var stream = loader.loadfile(music_path)
		if stream:
			$AudioStreamPlayer.stream = stream
		else:
			push_error("Failed to load music from " + music_path)
		var video_path = str(song_path, "/", Global.pak_reader.find_in_config(song_path,true,"background"))
		var is_image = Global.pak_reader.is_song_background_image(song_path,true)
		if video_path:
			if is_image:
				var img = Image.new()
				img.load(video_path)
				$BackgroundImage.texture = ImageTexture.create_from_image(img)
			else:
				$VideoPlayback.set_video_path(ProjectSettings.globalize_path(video_path))
		var time = Global.pak_reader.find_in_config(song_path,true,"song_start")
		end_time = Global.pak_reader.find_in_config(song_path,true,"song_end")
		if time.is_valid_float():
			time = float(time)
		else:
			time = 0.0
		if time < 0:
			time = 0.0
		$AudioStreamPlayer.play(time)
		if is_image:
			$BackgroundImage.show()
		else:
			$VideoPlayback.show()
			$VideoPlayback.enable_auto_play = true
	note_events.sort()


var _prev_score = null
var _prev_combo = null

func _process(delta: float) -> void:
	if auto_play:
		$auto_play_watermarks.show()
		$auto_play_watermarks.visible = true
	current_time += delta * 1000.0
	for note in get_children():
		if note.has_meta("is_note"):
			note.position.y += scroll_speed * delta * 1000.0
			if note.get_meta("type") == "poly":
				note.get_child(0).position.y = min(note.size.y - 50, hit_line - note.position.y - 50)
			var prev_y = note.position.y
			if auto_play:
				if note.get_meta("type") == "hold":
					if !note.has_meta("autodone"):
						var time = note.get_meta("time")
						if current_time < note.get_meta("end_time") and current_time >= time:
							if not note.has_meta("autoflag"):
								if (prev_y + note.size.y >= hit_line) or (note.position.y + note.size.y >= hit_line):
									score += score_multipliers[0]
									update_combo(combo+1)
									var alabel = judgement_scene.instantiate()
									alabel.text = timing_displays[0]
									alabel.position = Vector2(note.position.x + note.size.x, hit_line - 100)
									add_child(alabel)
									note.set_meta("autoflag", true)
							var max_height = hit_line - note.position.y
							note.size.y = max_height
						if note.has_meta("autoflag") and not note.has_meta("autodone") and (prev_y >= hit_line or note.position.y >= hit_line):
							score += score_multipliers[0]
							note.size.y = 0
							update_combo(combo+1)
							var alabel = judgement_scene.instantiate()
							alabel.text = timing_displays[0]
							alabel.position = Vector2(note.position.x + note.size.x, hit_line - 100)
							add_child(alabel)
							note.set_meta("autodone", true)
							note.queue_free()
				else:
					if note.get_meta("time") - current_time <= 1:
						if note.get_meta("type") == "light":
							score += score_multipliers[2]
							update_combo(combo+1)
						else:
							score += score_multipliers[0]
							update_combo(combo+1)
						var alabel = judgement_scene.instantiate()
						alabel.text = timing_displays[0]
						alabel.position = Vector2(note.position.x, note.position.y - 100)
						add_child(alabel)
						note.set_meta("hit", true)
						note.queue_free()
			else:
				if !note.get_meta("hit"):
					if note.get_meta("type") == "hold" || note.get_meta("type") == "poly":
						if note.get_meta("type") == "hold":
							if !note.has_meta("check_hold"):
								if note.position.y + note.size.y >= hit_line + timing_windows[3]:
									score += score_multipliers[5]
									update_combo(0)
									var alabel = judgement_scene.instantiate()
									alabel.text = timing_displays[5]
									miss_lane(note.get_meta("lane"))
									alabel.position = Vector2(note.position.x, hit_line - 100)
									add_child(alabel)
									note.self_modulate.v = 0.3
									note.set_meta("hit", true)
						if note.get_meta("type") == "poly":
							if note.get_meta("hit_count") >= note.get_meta("poly"):
								var score_to_add = score_multipliers[1]
								score += score_to_add
								if score_to_add > 0:
									update_combo(combo+1)
								else:
									update_combo(0)
								var judgement = timing_displays[1]
								score_text.text = str("Score: ",score," (",get_current_rating(),")")
								var judgement_label = judgement_scene.instantiate()
								judgement_label.text = judgement
								judgement_label.position.x = note.position.x
								judgement_label.position.y = hit_line - 50
								add_child(judgement_label)
								note.set_meta("hit", true)
								note.queue_free()
							if note.position.y >= hit_line:
								var score_index = clamp(ceil((1 - (float(note.get_meta("hit_count")) / max(note.get_meta("poly")+ 1, 1))) * 4) + 1, 1, 5)
								var score_to_add = score_multipliers[score_index]
								score += score_to_add
								if score_to_add > 0:
									update_combo(combo+1)
								else:
									update_combo(0)
								var judgement = timing_displays[score_index]
								score_text.text = str("Score: ",score," (",get_current_rating(),")")
								var judgement_label = judgement_scene.instantiate()
								judgement_label.text = judgement
								judgement_label.position.x = note.position.x
								judgement_label.position.y = hit_line - 50
								add_child(judgement_label)
								note.self_modulate.v = 0.3
								note.set_meta("hit", true)
								note.get_child(0).hide()
					else:
						if note.position.y >= hit_line + timing_windows[3]:
							score += score_multipliers[5]
							update_combo(0)
							var alabel = judgement_scene.instantiate()
							alabel.text = timing_displays[5]
							miss_lane(note.get_meta("lane"))
							alabel.position = Vector2(note.position.x, hit_line - 100)
							add_child(alabel)
							note.self_modulate.v = 0.3
							note.set_meta("hit", true)
					if note.get_meta("type") == "light":
						if Input.is_action_pressed("lane" + str(note.get_meta("lane"))):
							if note.get_meta("time") - current_time <= 1:
								score += score_multipliers[2]
								update_combo(combo+1)
								var alabel = judgement_scene.instantiate()
								alabel.text = timing_displays[1]
								alabel.position = Vector2(note.position.x, note.position.y - 100)
								add_child(alabel)
								note.set_meta("hit", true)
								note.queue_free()
				if note.get_meta("type") == "hold":
					if note.position.y + note.size.y <= timing_windows[4] or note.has_meta("check_hold"):
						if note.has_meta("check_hold"):
							if current_time < note.get_meta("end_time"):
								var remaining = note.get_meta("end_time") - current_time
								var new_height = remaining * scroll_speed
								var max_height = hit_line - note.position.y
								note.size.y = min(new_height, max_height)

							var lane_key = "lane" + str(note.get_meta("lane"))
							if Input.is_action_pressed(lane_key):
								if not note.has_meta("first_input_time"):
									note.set_meta("first_input_time", current_time)
									var first_offset = abs(current_time - note.get_meta("time"))
									note.set_meta("first_rating", get_rating(first_offset))
									note.set_meta("was_held", true)
								else:
									note.set_meta("last_pressed_time", current_time)
									if not note.has_meta("hold_started") and (current_time - note.get_meta("first_input_time") >= HOLD_ACTIVATION_THRESHOLD):
										note.set_meta("hold_started", true)
							else:
								if not note.has_meta("last_pressed_time"):
									note.set_meta("last_pressed_time", current_time)
								elif current_time - note.get_meta("last_pressed_time") >= HOLD_RELEASE_THRESHOLD:
									if not note.has_meta("hold_started"):
										score += score_multipliers[5]
										update_combo(0)
										var alabel = judgement_scene.instantiate()
										alabel.text = timing_displays[5]
										miss_lane(note.get_meta("lane"))
										alabel.position = Vector2(note.position.x, hit_line - 100)
										add_child(alabel)
										note.self_modulate.v = 0.3
										note.set_meta("hit", true)
										note.set_meta("hold_cancelled", true)
										note.set_meta("release_rating", timing_displays[5])
										note.set_meta("check_hold", false)
									elif not note.has_meta("release_time"):
										note.set_meta("release_time", current_time)
										var release_offset = abs(current_time - note.get_meta("end_time"))
										note.set_meta("release_rating", get_rating(release_offset))
										note.set_meta("check_hold", false)
						if current_time >= note.get_meta("end_time") and not note.has_meta("end_rating_shown"):
							var end_rating: String = ""
							if note.has_meta("hold_cancelled") or not note.has_meta("was_held"):
								end_rating = timing_displays[5]
								miss_lane(note.get_meta("lane"))
							else:
								var actual_release_time = note.get_meta("release_time") if note.has_meta("release_time") else current_time
								var end_offset = abs(note.get_meta("end_time") - actual_release_time)
								end_rating = get_rating(end_offset)
							
							score += score_multipliers[timing_displays.find(end_rating)]
							if !end_rating.is_empty() and timing_displays.find(end_rating) < 5:
								update_combo(combo+1)
							else:
								update_combo(0)
							var alabel = judgement_scene.instantiate()
							alabel.text = end_rating
							alabel.position = Vector2(note.position.x + note.size.x, hit_line - 100)
							add_child(alabel)
							note.set_meta("end_rating_shown", true)
							note.queue_free()
	if end_time:
		if float(end_time) != 0:
			if float(end_time) - current_time <= 1:
				$AudioStreamPlayer.stop()
				$VideoPlayback.queue_free()
	
	if _prev_score != score || _prev_combo != combo: #designed so it doesn't change text every frame and attempt to do it only when needed
		if score_text:
			score_text.text = str("Score: ",score," (",get_current_rating()," / ",get_overall_rating(),")\n","Biggest Combo: ",max_combo,"" if not extra_info else str("\nRating Ratio: ", round(ratio * 100.0) / 100.0, "\nPossible Score: ", total_possible_score, "\nTotal notes: ", total_notes,"\nPossible Combo: ",possible_combo))
		_prev_score = score
		_prev_combo = combo


func _input(event):
	if not auto_play and event is InputEventKey:
		if event.pressed:
			if event.is_action_pressed("lane0"):
				check_input(0)
				on_lane_pressed(0)
			elif event.is_action_pressed("lane1"):
				check_input(1)
				on_lane_pressed(1)
			elif event.is_action_pressed("lane2"):
				check_input(2)
				on_lane_pressed(2)
			elif event.is_action_pressed("lane3"):
				check_input(3)
				on_lane_pressed(3)
		else:
			if InputMap.event_is_action(event, "lane0"):
				on_lane_released(0)
			elif InputMap.event_is_action(event, "lane1"):
				on_lane_released(1)
			elif InputMap.event_is_action(event, "lane2"):
				on_lane_released(2)
			elif InputMap.event_is_action(event, "lane3"):
				on_lane_released(3)


func check_input(lane):
	for note in get_children():
		if note.has_meta("is_note"):
			#var true_note_pos = note.position.y + note.size.y
			var note_offset = note.get_meta("time") - current_time
			
			var note_scoring = score_note(note_offset)
			
			if note_scoring == null:
				continue
			else:
				if note.get_meta("lane") == lane:
					if note.get_meta("hit",""):
						continue
					if note.get_meta("type") == "hold":
						#var hit_offset = note.get_meta("time") - current_time
						
						var judgement = timing_displays[note_scoring]
						var score_to_add = score_multipliers[note_scoring]

						score += score_to_add
						if score_to_add > 0:
							update_combo(combo+1)
						else:
							update_combo(0)
						score_text.text = str("Score: ",score," (",get_current_rating(),")")
						
						spawn_judgement(judgement,note.get_meta("lane"))
						note.set_meta("check_hold", true)
						note.set_meta("held_since",current_time)
						return
					if note.get_meta("type") == "poly":
						note.set_meta("hit_count",note.get_meta("hit_count") + 1)
						note.get_child(0).text = str(note.get_meta("poly") - note.get_meta("hit_count"))
						return
					if note.get_meta("type") != "hold":
						#var hit_offset = note.get_meta("time") - current_time
						
						var judgement = timing_displays[note_scoring]
						var score_to_add = score_multipliers[note_scoring]

						if note.get_meta("type") == "light":
							score += score_multipliers[2] if score_to_add > score_multipliers[2] else score_to_add
						else:
							score += score_to_add
						if score_to_add > 0:
							update_combo(combo+1)
						else:
							update_combo(0)
						score_text.text = str("Score: ",score," (",get_current_rating(),")")
						
						spawn_judgement(judgement,note.get_meta("lane"))
						note.set_meta("hit", true)
						note.queue_free()
						return


func get_note_position(note_time: int, time: float, line: float, speed: float) -> float:
	var time_diff = note_time - time
	return line - time_diff * speed


func get_current_rating() -> String:
	var running_total := 0
	for event in note_events:
		if event.x <= current_time:
			running_total += int(event.y)
		else:
			break
	ratio = score / float(running_total)
	return rating_from_ratio(ratio)


func get_overall_rating() -> String:
	ratio = score / float(total_possible_score)
	return rating_from_ratio(ratio)


func rating_from_ratio(ratio_to_rate) -> String:
	if score == 0:
		return ratings[ratings.size()-1] #NA
	for i in ratings.size():
		if i >= rating_ratios.size()-2: #F
			return ratings[ratings.size()-2] #F
		if ratio_to_rate >= rating_ratios[i]:
			return ratings[i]
	return ratings[ratings.size()-1] #NA   this is for error prevention


func get_rating(hit_offset: float) -> String:
	for i in timing_windows.size():
		if hit_offset <= timing_windows[i]:
			return timing_displays[i]
	return ""


func update_combo(value):
	combo = value
	if combo > max_combo:
		max_combo = combo


func score_note(offset_):
	offset_ = abs(offset_)
	for i in timing_windows.size():
		if offset_ <= timing_windows[i]:
			return i


func spawn_judgement(judgement:String, lane:int):
	if lane != null:
		var judgement_label = judgement_scene.instantiate()
		judgement_label.text = judgement
		judgement_label.position.x = lanes[lane].position.x
		judgement_label.position.y = hit_line-50
		add_child(judgement_label)


func miss_lane(lane: int) -> void:
	if lane == null:
		return

	var highlight = lanes[lane].get_child(0)
	highlight.visible = true
	highlight.modulate.a = 0.0

	var tween := create_tween()

	tween.tween_property(highlight, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.05)
	tween.tween_property(highlight, "modulate:a", 0.0, 0.1)
	tween.tween_callback(Callable(highlight, "hide"))


var lane_tweens:Array[Tween] = [null, null, null, null]
func on_lane_pressed(lane:int) -> void:
	var laneNode := lanes[lane]
	var lane_tween := lane_tweens[lane]
	if lane_tween != null:
		lane_tween.kill()
	var stylebox = laneNode.get("theme_override_styles/panel")
	if stylebox and stylebox is StyleBoxFlat:
		var color = stylebox.bg_color
		color.v = 0.3
		stylebox.bg_color = Color.from_hsv(color.h, color.s, color.v, color.a)


func on_lane_released(lane: int) -> void:
	var lane_node := lanes[lane]
	var stylebox := lane_node.get("theme_override_styles/panel") as StyleBoxFlat
	if stylebox == null:
		return

	var hsv = stylebox.bg_color
	var start_v = hsv.v
	var target_v = 0.1
	
	var lane_tween := lane_tweens[lane]
	if lane_tween != null:
		lane_tween.kill()
	lane_tween = create_tween()
	lane_tweens[lane] = lane_tween
	lane_tween.tween_method(
		func(v):
			stylebox.bg_color = Color.from_hsv(hsv.h, hsv.s, v, hsv.a),
		start_v, target_v, 0.25
	)
