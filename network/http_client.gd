extends Node

var connection_status:= false

func fetch(url: String, method: int = HTTPClient.METHOD_GET, headers: Array = [], body:="", timeout: int = 10,download_file:="") -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = timeout
	http_request.download_file = download_file
	var err: int = http_request.request(url, headers, method, body)
	if err != OK:
		http_request.queue_free()
		push_error("Error initiating HTTP request: %s" % str(err))
		return {"error": err}

	var result: Array = await http_request.request_completed
	http_request.queue_free()
	
	return {
		"result": result[0],
		"response_code": result[1],
		"headers": result[2],
		"body": result[3]
	}

func check_connection():
	var response = await fetch("https://clients3.google.com/generate_204")
	if response:
		return true if response.result == OK && response.response_code == 204 else false
	return false
