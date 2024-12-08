@tool
extends EditorPlugin

const SETTINGS_PATH = "google_analytics"
const AUTOLOAD_NAME = "Analytics"
const ANALYTICS_SINGLETON_PATH = "res://addons/google_analytics/analytics_singleton.gd"

func _enter_tree() -> void:
	print("Google Analytics plugin entered tree")
	# Add project settings for Google Analytics configuration
	add_project_setting("measurement_id", "", TYPE_STRING)
	add_project_setting("api_secret", "", TYPE_STRING)
	
	# Add Analytics singleton
	add_autoload_singleton(AUTOLOAD_NAME, ANALYTICS_SINGLETON_PATH)

func _exit_tree() -> void:
	# Remove Analytics singleton
	remove_autoload_singleton(AUTOLOAD_NAME)

func add_project_setting(name: String, default_value, type: int) -> void:
	var setting_path = SETTINGS_PATH + "/" + name
	if not ProjectSettings.has_setting(setting_path):
		ProjectSettings.set_setting(setting_path, default_value)
		ProjectSettings.set_initial_value(setting_path, default_value)
		ProjectSettings.add_property_info({
			"name": setting_path,
			"type": type,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "",
		})

		ProjectSettings.save()
