extends Timer

@export var time_scale : float

func _process(delta):
	if not is_stopped() and not paused:
		var store_wait_time = wait_time
		var new_time_left = time_left + delta - delta * time_scale
		if new_time_left <= 0:
			if one_shot:
				stop()
			else:
				start(store_wait_time)
			emit_signal("timeout")
		else:
			start(new_time_left)
			wait_time = store_wait_time
