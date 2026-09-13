@tool
extends EditorPlugin

const AUTOLOAD_NAME := "GdGesture"
const AUTOLOAD_PATH := "res://addons/@aviorstudio_gd-gesture/autoload.gd"
const OWNERSHIP_SETTING := "gd_gesture/internal/owns_autoload"

var _added_autoload: bool = false

func _enter_tree() -> void:
	var key: String = "autoload/" + AUTOLOAD_NAME
	if ProjectSettings.has_setting(key):
		_added_autoload = bool(ProjectSettings.get_setting(OWNERSHIP_SETTING, false)) and str(ProjectSettings.get_setting(key)) == _autoload_path()
		return

	add_autoload_singleton(AUTOLOAD_NAME, _autoload_path())
	ProjectSettings.set_setting(OWNERSHIP_SETTING, true)
	ProjectSettings.set_as_internal(OWNERSHIP_SETTING, true)
	ProjectSettings.save()
	_added_autoload = true

func _exit_tree() -> void:
	if _added_autoload:
		remove_autoload_singleton(AUTOLOAD_NAME)
		ProjectSettings.set_setting(OWNERSHIP_SETTING, null)
		ProjectSettings.save()

func _autoload_path() -> String:
	return AUTOLOAD_PATH
