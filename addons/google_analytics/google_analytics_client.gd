extends Node

class_name GoogleAnalyticsClient

const GA4_ENDPOINT = "https://www.google-analytics.com/mp/collect"

var _measurement_id: String
var _api_secret: String
var _client_id: String
var _http_request: HTTPRequest
var _session_id: String

# Current page tracking
var _current_page_title: String = "Game"
var _current_page_location: String = "app://game"

var _last_event_time: float = 0.0
const EVENT_COOLDOWN: float = 1.0 # Minimum seconds between any events
var _event_queue: Array[Dictionary] = []
var _is_processing_queue: bool = false

func _init(measurement_id: String, api_secret: String, client_id: String) -> void:
	_debug_log("Initializing client with measurement_id: %s" % measurement_id)
	_measurement_id = measurement_id
	_api_secret = api_secret
	_client_id = client_id
	_session_id = str(Time.get_unix_time_from_system())
	if not OS.has_feature("web"):
		_http_request = HTTPRequest.new()
		add_child(_http_request)
		_http_request.request_completed.connect(_on_request_completed)

func track_page_view(page_title: String, page_location: String = "") -> void:
	_debug_log("Setting current page to: %s at %s" % [page_title, page_location if not page_location.is_empty() else "auto-generated"])

	# Update current page tracking
	var referrer = _current_page_location
	_current_page_title = page_title
	_current_page_location = page_location if not page_location.is_empty() else "app://game/" + page_title.to_lower().replace(" ", "_")
	
	var params = {
		"page_title": _current_page_title,
		"page_location": _current_page_location,
		"engagement_time_msec": "100",
		"page_referrer": referrer,
		"screen_resolution": "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"session_id": _session_id,
		"session_engaged": "1"
	}
	
	# Queue the event
	_queue_event("page_view", params)

func send_event(event_name: String, params: Dictionary = {}) -> void:
	_debug_log("Preparing to send event: %s with initial params: %s" % [event_name, params])
	
	var event_params = params.duplicate()
	
	# Add required GA4 parameters
	event_params["engagement_time_msec"] = "100"
	event_params["screen_resolution"] = "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]
	event_params["session_id"] = _session_id
	event_params["session_engaged"] = "1"
	
	# Add current page context only if not already present
	if not event_params.has("page_title"):
		event_params["page_title"] = _current_page_title
	if not event_params.has("page_location"):
		event_params["page_location"] = _current_page_location
	
	# Convert numeric values to strings as GA4 expects
	for key in event_params.keys():
		if event_params[key] is float or event_params[key] is int:
			event_params[key] = str(event_params[key])
	
	# Queue the event
	_queue_event(event_name, event_params)

func _queue_event(event_name: String, params: Dictionary) -> void:
	_event_queue.push_back({"name": event_name, "params": params})
	_process_queue()

func _process_queue() -> void:
	if _is_processing_queue:
		return
	
	_is_processing_queue = true
	
	while _event_queue.size() > 0:
		var current_time = Time.get_unix_time_from_system()
		var time_since_last_event = current_time - _last_event_time
		
		if time_since_last_event < EVENT_COOLDOWN:
			await get_tree().create_timer(EVENT_COOLDOWN - time_since_last_event).timeout
		
		var event = _event_queue.pop_front()
		_last_event_time = Time.get_unix_time_from_system()
		_send_event(event.name, event.params)
	
	_is_processing_queue = false

func _send_event(event_name: String, params: Dictionary) -> void:
	if OS.has_feature("web"):
		_send_event_web(event_name, params)
	else:
		_send_event_server(event_name, params)

func _send_event_web(event_name: String, params: Dictionary) -> void:
	# Call gtag.js function in JavaScript
	var code = """
	if (typeof gtag === 'undefined') {
		throw new Error('gtag not found');
	}
	gtag('event', '%s', %s);
	""" % [event_name, JSON.stringify(params)]
	
	# Use a try-catch in JavaScript to handle errors
	var wrapped_code = """
	try {
		%s
	} catch (error) {
		console.error('[GA] ' + error.message);
	}
	""" % code
	
	JavaScriptBridge.eval(wrapped_code)

func _send_event_server(event_name: String, params: Dictionary) -> void:
	var url = "%s?measurement_id=%s&api_secret=%s" % [GA4_ENDPOINT, _measurement_id, _api_secret]
	
	var data = {
		"client_id": _client_id,
		"user_id": _client_id,
		"events": [ {
			"name": event_name,
			"params": params
		}],
		"non_personalized_ads": true
	}
	
	var headers = [
		"Content-Type: application/json",
		"User-Agent: Godot-Game/1.0"
	]
	var body = JSON.stringify(data)
	
	_debug_log("Making request to: %s" % url)
	_debug_log("Request body: %s" % body)
	
	var error = _http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("[GA] Failed to send request: %s" % error)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_debug_log("Request completed with response code: %d" % response_code)
	if response_code != 204:
		push_error("[GA] Request failed with code: %d" % response_code)
		if body.size() > 0:
			var response = body.get_string_from_utf8()
			push_error("[GA] Response: %s" % response)
	else:
		_debug_log("Event sent successfully")

func _debug_log(message: String) -> void:
	if OS.is_stdout_verbose():
		print("[GA] %s" % message)
