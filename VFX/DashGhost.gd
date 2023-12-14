extends Sprite2D

#func _ready():
#
	#randomize()
#
	#var tween = create_tween()
#
	#tween.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
#
	#tween.tween_interval(0.6)
#
	#tween.tween_callback(tween_all_completed)
#
 #
#
#func tween_all_completed():
	#self.queue_free()

func _ready():
	ghosting()

func set_property(tx_pos, tx_scale, ghost_texture, flip_horizontal):
	position = tx_pos
	scale = tx_scale
	texture = ghost_texture
	flip_h = flip_horizontal

func ghosting():
	var tween_fade = get_tree().create_tween()
	
	tween_fade.tween_property(self, "self_modulate", Color(1, 1, 1, 0), 0.3)
	
	await tween_fade.finished
	
	queue_free()
