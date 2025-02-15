extends Label

#var min_font_size: int = 1
#var max_font_size: int = 24
#var font_step: float = 0.2  # Step to reduce font size
#var max_text_length: int = 40

#func _ready():
	#adjust_font_size()
	##label_settings.font_size = 640 / text.length()
#
#func adjust_font_size():
	#var label_settings = self.label_settings
	#if not label_settings:
		#return
#
	##if text.length() > max_text_length:
		##text = text.substr(0, max_text_length - 3) + "..."
#
	#var font_size = max_font_size
	#
	#while font_size >= min_font_size:
		#self.label_settings.font_size = font_size
		#
		#var text_width = 
		#if text_width <= size.x:
			#break
		#font_size -= font_step
#
	#self.label_settings.font_size = font_size - 3
