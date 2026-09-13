@tool
extends EditorPlugin

func _enter_tree() -> void:
	call_deferred("_apply_target_state")

func _apply_target_state() -> void:
	var filesystem: EditorFileSystem = get_editor_interface().get_resource_filesystem()
	while filesystem.is_scanning():
		await get_tree().process_frame
	var enabled: bool = OS.get_environment("GD_GESTURE_PLUGIN_ENABLED") == "true"
	if get_editor_interface().is_plugin_enabled("@aviorstudio_gd-gesture") != enabled:
		get_editor_interface().set_plugin_enabled("@aviorstudio_gd-gesture", enabled)
	await get_tree().process_frame
	if get_editor_interface().is_plugin_enabled("@aviorstudio_gd-gesture") != enabled:
		push_error("FAIL: editor plugin state did not change")
		get_tree().quit(1)
		return
	if enabled and not ProjectSettings.has_setting("autoload/GdGesture"):
		push_error("FAIL: enabled plugin did not install its autoload")
		get_tree().quit(1)
		return
	ProjectSettings.save()
	await get_tree().create_timer(0.5).timeout
	print("PASS gd-gesture set_plugin_enabled assertions=", 2 if enabled else 1)
	get_tree().quit(0)
