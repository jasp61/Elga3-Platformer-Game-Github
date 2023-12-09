extends Control

@onready var main_menu_buttons = $main_menu_buttons as MarginContainer
@onready var main = get_parent()
@onready var level_selector = main.get_node("level_selector") as Control

func _on_play_pressed():
	main_menu_buttons.visible = false
	level_selector.visible = true
	


func _on_settings_pressed():
	pass # Replace with function body.


func _on_quit_pressed():
	get_tree().quit()
