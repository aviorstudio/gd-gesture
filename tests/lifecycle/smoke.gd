extends SceneTree

func _init() -> void:
	var recognizer_script: Script = load("res://addons/@aviorstudio_gd-gesture/src/gesture_recognizer_module.gd")
	if recognizer_script == null or recognizer_script.new() == null:
		push_error("FAIL: packaged gesture recognizer cannot be constructed")
		quit(1)
		return
	print("PASS gd-gesture packaged_smoke assertions=1")
	quit(0)
