extends Control

@export var _icon:Node
@export var _title:Node
@export var _desc:Node
@export var _song:Node
@export var _pak:Node


var icon:Texture2D: 
	set(value):
		_icon.texture = value
var title:String:
	set(value):
		_title.text = value
var desc:String:
	set(value):
		_desc.text = value
var song:String:
	set(value):
		_song.text = value
var pak:String:
	set(value):
		_pak.text = value
