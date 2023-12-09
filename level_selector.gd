extends Control

@onready var level_selector_buttons = $level_selector_buttons as MarginContainer
@onready var main = get_parent()
@onready var main_menu = main.get_node("Menu") as Control
@onready var main_menu_buttons = main_menu.get_node("main_menu_buttons") as MarginContainer

func _on_level_one_pressed():
	get_tree().change_scene_to_file("res://Levels/level_one.tscn")


func _on_level_two_pressed():
	get_tree().change_scene_to_file("res://Levels/level_two.tscn")


func _on_level_three_pressed():
	get_tree().change_scene_to_file("res://Levels/level_three.tscn")


func _on_back_pressed():
	self.visible = false
	#level_selector_buttons.visible = false
	main_menu_buttons.visible = true



