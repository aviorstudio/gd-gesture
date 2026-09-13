extends SceneTree

func _init() -> void:
	push_error("FAIL: assertion negative control")
	quit(1)
	print("PASS gd-gesture runner_success assertions=1")
	quit(0)
