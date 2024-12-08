extends Node

var _client: GoogleAnalyticsClient = null
const CLIENT_ID_FILE = "user://analytics_client_id.txt"

func _ready() -> void:
	var measurement_id = ProjectSettings.get_setting("google_analytics/measurement_id")
	var api_secret = ProjectSettings.get_setting("google_analytics/api_secret")
	var client_id = _get_or_create_client_id()
	
	if measurement_id == null or api_secret == null or measurement_id.is_empty() or api_secret.is_empty():
		push_warning("[GA] Google Analytics settings are not configured. Events will not be tracked.")
		return
		
	_client = GoogleAnalyticsClient.new(measurement_id, api_secret, client_id)
	add_child(_client)
	
	# Set initial page to main game
	_client.track_page_view("Game Start")

func _get_or_create_client_id() -> String:
	if FileAccess.file_exists(CLIENT_ID_FILE):
		var file = FileAccess.open(CLIENT_ID_FILE, FileAccess.READ)
		var existing_id = file.get_as_text()
		file.close()
		if not existing_id.is_empty():
			return existing_id
	
	# Generate new UUID v4
	var new_id = _generate_uuid_v4()
	var file = FileAccess.open(CLIENT_ID_FILE, FileAccess.WRITE)
	file.store_string(new_id)
	file.close()
	return new_id

func _generate_uuid_v4() -> String:
	# Simple UUID v4 generation
	var chars = "0123456789abcdef"
	var uuid = ""
	for i in range(36):
		if i == 8 or i == 13 or i == 18 or i == 23:
			uuid += "-"
		elif i == 14:
			uuid += "4"
		elif i == 19:
			uuid += chars[randi() & 0x3 | 0x8]
		else:
			uuid += chars[randi() & 0xf]
	return uuid

func track_page_view(page_title: String, page_location: String = "") -> void:
	if _client:
		_client.track_page_view(page_title, page_location)
	else:
		push_warning("[GA] Attempted to track page view '%s' but Google Analytics is not initialized." % page_title)

func track_event(event_name: String, params: Dictionary = {}) -> void:
	if _client:
		_client.send_event(event_name, params)
	else:
		push_warning("[GA] Attempted to track event '%s' but Google Analytics is not initialized." % event_name)
