extends Control



##coyote timing for clicks(duh)
#display for "late" and "early" note hits
#display for level rating(P,S,A+,A,B,C,D) [U : unplayed]
#display for accuracy(in percentage)
#display for note timings(
#)
#
##"action line" is refering to the line where notes have to be clicked(or such) on the line with accuracy based off the line
#RGM will be used for a short of "Rhythm Game Mode", the usual run of the mill rhythm game type gameplay
#map mode is the official term for the "legally distinct osu type mode"
#
##triggers: (triggers can be used in the editor to change gameplay, and only visible in editor)
#action line pos(change the note line position on the screen, with tween capabilities) RGM ONLY
#action line rot(change the note line's rotation on the screen, with tween capabilities) RGM ONLY
#
##map mode:
#notes fade into existence
#notes are set to max and min sizes
#notes are required to be fully on screen
#notes should display a slight effect to show their timings
#
##note types:
#tap(just a click on time)
#multi-tap(tap but requires more than 1 tap(config in menu), display number of clicks remaining or other visual)
#
##RGM:
#notes slide into view(depending on action line orientation)
#click(or other respective action) notes on the action line
#
##note types:
#tap(simple click)
#hold(simple hold note)
#light notes(they are simply hold notes but without the click, so for example you click a tap note and hold the button down to hit these)
var tween 


func _on_area_2d_area_entered(area: Area2D) -> void:
	$Panel/VBoxContainer/CheckButton.grab_focus()
	if tween == null:
		tween = create_tween()
		tween.set_trans(Tween.TRANS_QUART)
		tween.tween_property($Panel,"position:x",0,0.82).set_ease(Tween.EASE_OUT)
		tween = null


func _on_area_2d_area_exited(area: Area2D) -> void:
	$Panel/VBoxContainer/CheckButton.release_focus()
	$Panel/VBoxContainer/CheckButton2.release_focus()
	if tween == null:
		tween = create_tween()
		tween.set_trans(Tween.TRANS_QUART)
		tween.tween_property($Panel,"position:x",-144,0.82).set_ease(Tween.EASE_OUT)
		tween = null
