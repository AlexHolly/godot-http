# author https://github.com/AlexHolly 
# v0.8
extends Node

var RESPONSE_TIMEOUT_IN_MS = 30 * 1000 * 60 

var ERR_ADRESS = "Invalid http request, maybe adress is empty?"
var ERR_BODY = "Parse Error unsupported body"
var ERR_CONN = "Connection error, can't reach host"
var ERR_REQUEST = "Request failed, invalid params?"

#func _init():
	# Init SSL Certificates - Is broken in master
	# Add manually in Menu Project->Network->ssl
	# ProjectSettings.set("network/ssl/certificates", get_script().get_path().get_base_dir()+"/ca-certificates.crt")
	
func error(code):
	var rs = {}
	
	rs["header"] = {}
	rs["body"] = str(code)
	rs["code"] = 404
	
	print(rs)
	
	return rs

var _headers = {
	"User-Agent": "Pirulo/1.0 (Godot)",
	"Accept": "*/*"
}

func headers():
	return _headers

func dict_to_array(dict):
	var rs = []
	
	for key in dict:
		rs.append(key + ": " + str(dict[key]))
	return rs
	
var HTTP = "http://"
var HTTPS = "https://"

func req(verb, adress, body1):
	
	if(adress==""):
		return error(ERR_ADRESS)
		
	var headers_body = handle_body(body1)
	var headers = headers_body[0]
	var body = headers_body[1]

	if( typeof(headers)==TYPE_STRING ):
		return error(ERR_BODY)
	
	var http_fullhost = checkServerConnection(adress)
	var _http = http_fullhost[0]
	
	if(TYPE_INT != typeof(_http) && _http.get_status()==HTTPClient.STATUS_CONNECTED):
		# var fullhost = http_fullhost[1]
		var url = http_fullhost[2]
		var err = _http.request_raw(verb, url, dict_to_array(headers), body)
		
		if(!err):
			return getResponse(_http)
		else:
			return error(ERR_REQUEST)
	return error(ERR_CONN)

#var http # sync can only have one / blocks
# TODO all requests should be async
# 1. The ui will block and multiple sync http connections are not possbile anyway
# 2. The multiple http connections are useless, and returning the http connection to close it is not possible
func get(adress):
	return req(HTTPClient.METHOD_GET, adress, PoolByteArray())

func put(adress, body=PoolByteArray([])):
	return req(HTTPClient.METHOD_PUT, adress, body)

func post(adress, body=PoolByteArray([])):
	return req(HTTPClient.METHOD_POST, adress, body)

func delete(adress):
	return req(HTTPClient.METHOD_DELETE, adress, PoolByteArray())

func thread(verb, adress, function, body1):
	var thread = Thread.new()
	var args = [verb, adress, body1, function, thread]
	thread.start(self, "reqAsync", args)
	return thread

var requests = {}
func stop_async(thread):
	if(requests.has(thread)):
		requests[thread].close()

func reqAsync(args):
	var verb = args[0]
	var adress = args[1]
	var body1 = args[2]
	var function = args[3]
	var thread = args[4]
	
	function.call_func(req( verb, adress, body1))
	requests.erase(thread)

func getAsync(adress, function):
	return thread(HTTPClient.METHOD_GET, adress, function, PoolByteArray())
	
func putAsync(adress, function, body=PoolByteArray([])):
	return thread(HTTPClient.METHOD_PUT, adress, function, body)
	
func postAsync(adress, function, body=PoolByteArray([])):
	return thread(HTTPClient.METHOD_POST, adress, function, body)
	
func deleteAsync(adress, function):
	return thread(HTTPClient.METHOD_DELETE, adress, function, PoolByteArray())

func handle_body(body):
	var headers = headers()
	var type = typeof(body)
	if(type==TYPE_RAW_ARRAY):
		if(body.size()>0):
			headers["Content-Type"] = "bytestream"
		return [headers,body]
	elif(type==TYPE_DICTIONARY):
		if(!body.empty()):
			headers["Content-Type"] = "application/json"
			body = to_json(body).to_utf8()
		return [headers,body]
	elif(type==TYPE_STRING):
		if(body.length()>0):
			headers["Content-Type"] = "text/plain"
			body = body.to_utf8()
		return [headers,body]
	elif(type==TYPE_NIL):
		return [headers, "".to_utf8()]
	else:
		print("unsupported type:" + str(type))
		return [ERR_BODY,ERR_BODY]

func get_link_address_port_path(uri):
	var left = ""
	var link = ""
	var ssl = false
	
	if(uri.begins_with(HTTPS)):
		ssl = true
		link = uri.replace(HTTPS, "")
		left+=HTTPS
	else:
		link = uri.replace(HTTP, "")
		left+=HTTP
		
	var hostport = link.split("/", true)[0]
	
	left+=hostport
	
	var host_port = hostport.split(":", true)
	var host = host_port[0]
		
	var port = "80"
	if(host_port.size()>1):
		port = host_port[1]
	if(uri.begins_with(HTTPS)):# check if https -> ssl/tls 443
		port = "443"

	var path = uri.replace(left,"")
	
	return {
			"uri":uri, 
			"host":host,
			"port":int(port),
			"path":path,
			"ssl":ssl,
			"fullhost":hostport
			#query missing
			#fragment missing
		}

func checkServerConnection(adress):

	var uri_dict = get_link_address_port_path(adress)
	
	var serverAdress = uri_dict["host"]
	var port = uri_dict["port"]
	var path = uri_dict["path"]
	var fullhost = uri_dict["fullhost"]
	
	var ssl = uri_dict["ssl"]
	
	var _http = HTTPClient.new()
	_http.set_blocking_mode( true ) #wait until all data is available on response
	
	var err = _http.connect_to_host(serverAdress, port, ssl)
	
	if(!err):
		var start_time_in_ms = OS.get_ticks_msec()
		while( (_http.get_status()==HTTPClient.STATUS_CONNECTING or
				_http.get_status()==HTTPClient.STATUS_RESOLVING) &&
				(OS.get_ticks_msec()-start_time_in_ms)<RESPONSE_TIMEOUT_IN_MS):
			_http.poll()

		if((OS.get_ticks_msec()-start_time_in_ms)>=RESPONSE_TIMEOUT_IN_MS): # TIMEOUT
			return [HTTPClient.STATUS_CANT_CONNECT, fullhost]
		else:
			return [_http, fullhost, path]
	else:
		return [HTTPClient.STATUS_CANT_CONNECT, fullhost]

func getResponse(_http):
	
	var rs = {}
	
	rs["header"] = {}
	rs["body"] = ""
	rs["code"] = 404
	
	# Keep polling until the request is going on - in some cases the server will not respond I will add a timeout
	var start_time_in_ms = OS.get_ticks_msec()
	while ((_http.get_status() != HTTPClient.STATUS_DISCONNECTED) && 
		(_http.get_status() == HTTPClient.STATUS_REQUESTING) &&
		((OS.get_ticks_msec()-start_time_in_ms)<RESPONSE_TIMEOUT_IN_MS)):
		_http.poll()
	
	if(_http.get_status() == HTTPClient.STATUS_DISCONNECTED):
		return error("HTTP DC")
	
	if((OS.get_ticks_msec()-start_time_in_ms)>=RESPONSE_TIMEOUT_IN_MS):
		return error("TIMEOUT")
	
	rs["code"] = _http.get_response_code()

	if (_http.has_response()):
		# Get response headers
		var headers = _http.get_response_headers_as_dictionary()
		
		for key in headers:
			rs["header"][key.to_lower()] = headers[key]
		
		# var cache = headers
		
		var rb = PoolByteArray() #array that will hold the data
		
		while(_http.get_status()==HTTPClient.STATUS_BODY):
			#_http.set_read_chunk_size( _http.get_response_body_length() )
			rb += _http.read_response_body_chunk()
		
		if("content-length" in rs["header"] && rs["header"]["content-length"]!="0"):
			rs["body"] = parse_body_to_var(rb, rs["header"]["content-type"])
		else:
			rs["body"] = ""
		
		return rs
	else:
		if _http.get_status()==HTTPClient.STATUS_CONNECTION_ERROR:
			print("Maybe Certificates no set in project_settings/network/ssl/")
			breakpoint
		return rs

func parse_body_to_var(body, content_type):
	if(content_type.find("application/json")!=-1):
		body = body.get_string_from_utf8()
		#print(body)
		var bodyDict = parse_json( body )
		#print(bodyDict)
		if( typeof(bodyDict) == TYPE_DICTIONARY):
			body = bodyDict
		elif( typeof(bodyDict) == TYPE_ARRAY):
			body = bodyDict
		elif(body=="null"):
			body = {}
		else:
			print("Error body incompatible content_type: " + str(typeof(bodyDict)))
		
	elif(content_type.find("text/plain")!=-1||content_type.find("text/html")!=-1):
		body = body.get_string_from_utf8()
	elif(content_type.find("bytestream")!=-1):
		pass #return body
	return body

