#author https://github.com/AlexHolly 
#v0.4
extends Node

var timeout_sec = 1

var ERR_ADRESS = "Invalid http request, maybe adress is empty?"
var ERR_BODY = "Parse Error unsupported body"
var ERR_CONN = "Connection error, can't reach host"
var ERR_REQUEST = "Request failed, invalid params?"

var connections = {}

func error(code):
	var rs = {}
	
	rs["header"] = {}
	rs["body"] = str(code)
	rs["code"] = 404
	return rs

func headers():
	return {
				"User-Agent": "Pirulo/1.0 (Godot)",
				"Accept": "*/*",
				"connection": "keep-alive"
			}

func dict_to_array(dict):
	var rs = []
	
	for key in dict:
		rs.append(key + ": " + str(dict[key]))
	return rs
	
var HTTP = "http://"
var HTTPS = "https://"

# TODO Was machen mit players wie werden sie geupdated siehe board get players problem
# TODO Asynchrone anfragen einbauen? Etwas komplizierter für anfragenden, muss call back funktion mit geben?
# TODO ssl immer port 443???? nicht unbedingt oder?

func _init():
	pass
	
func _ready():
	pass

func test(adress, body=""):
	var headers = handle_body(body)
	
	if( headers==ERR_BODY ):
		return error(ERR_BODY)
		
	var http_fullhost = checkServerConnection(adress)
	var http = http_fullhost[0]
	var fullhost = http_fullhost[1]
	
	if(typeof(http)==TYPE_OBJECT):
		var url = http_fullhost[2]
		var err = http.request(HTTPClient.METHOD_GET, url, dict_to_array(headers), body)
		if(err==OK):
			return getResponse(http)
		else:
			return error(ERR_REQUEST)
	return error(ERR_CONN)

func get(adress):
	if(adress==""):
		return error(ERR_ADRESS)
		
	var headers = headers()
	
	var http_fullhost = checkServerConnection(adress)
	var http = http_fullhost[0]
	var fullhost = http_fullhost[1]
	
	#print(adress)
	if(typeof(http)==TYPE_OBJECT):
		var url = http_fullhost[2]
		print(url)
		var err = http.request(HTTPClient.METHOD_GET, url, dict_to_array(headers))
		if(err==OK):
			return getResponse(http)
		else:
			connections.erase(fullhost)
			return error(ERR_REQUEST)
	connections.erase(fullhost)
	return error(ERR_CONN)
	
func put(adress,body1=RawArray()):
	if(adress==""):
		return error(ERR_ADRESS)
		
	var headers_body = handle_body(body1)
	var headers = headers_body[0]
	var body = headers_body[1]

	if( headers==ERR_BODY ):
		return error(ERR_BODY)
		
	var http_fullhost = checkServerConnection(adress)
	var http = http_fullhost[0]
	var fullhost = http_fullhost[1]
	
	if(typeof(http)==TYPE_OBJECT):
		var url = http_fullhost[2]
		var err = http.request_raw(HTTPClient.METHOD_PUT, url, dict_to_array(headers), body)
		if(err==OK):
			return getResponse(http)
		else:
			connections.erase(fullhost)
			return error(ERR_REQUEST)
	connections.erase(fullhost)
	return error(ERR_CONN)
	
func post(adress, body1=RawArray()):
	if(adress==""):
		return error(ERR_ADRESS)
		
	var headers_body = handle_body(body1)
	var headers = headers_body[0]
	var body = headers_body[1]

	if( headers==ERR_BODY ):
		return error(ERR_BODY)
		
	var http_fullhost = checkServerConnection(adress)
	var http = http_fullhost[0]
	var fullhost = http_fullhost[1]
	
	if(typeof(http)==TYPE_OBJECT):
		var url = http_fullhost[2]
		var err = http.request_raw(HTTPClient.METHOD_POST, url, dict_to_array(headers), body)
		if(err==OK):
			return getResponse(http)
		else:
			connections.erase(fullhost)
			return error(ERR_REQUEST)
	connections.erase(fullhost)
	return error(ERR_CONN)
	
func delete(adress):
	if(adress==""):
		return error(ERR_ADRESS)
		
	var headers = headers()
		
	var http_fullhost = checkServerConnection(adress)
	var http = http_fullhost[0]
	var fullhost = http_fullhost[1]
	
	if(typeof(http)==TYPE_OBJECT):
		var url = http_fullhost[2]
		var err = http.request(HTTPClient.METHOD_DELETE, url, dict_to_array(headers))
		if(err==OK):
			return getResponse(http)
		else:
			connections.erase(fullhost)
			return error(ERR_REQUEST)
	connections.erase(fullhost)
	return error(ERR_CONN)

func handle_body(body):
	var headers = headers()
	if(typeof(body)==TYPE_RAW_ARRAY):
		if(body.size()>0):
			headers["Content-Type"] = "bytestream"
		return [headers,body]
	elif(typeof(body)==TYPE_DICTIONARY):
		if(!body.empty()):
			headers["Content-Type"] = "application/json"
			body = body.to_json().to_utf8()
		return [headers,body]
	elif(typeof(body)==TYPE_STRING):
		if(body.length()>0):
			headers["Content-Type"] = "text/plain"
			body = body.to_utf8()
		return [headers,body]
	else:
		print("unsupported type")
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
	
	# TODO ssl immer port 443???? nicht unbedingt oder?
	# TEST Falls kein port angegeben "" -> führt zu einem freeze 
	# TODO check if https -> ssl/tls 443
	var port = "80"
	if(host_port.size()>1):
		port = host_port[1]
	
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
	
	if(connections.has(fullhost)):
		return [connections[fullhost],fullhost]
		
	var ssl = uri_dict["ssl"]
	
	var http = HTTPClient.new() # Create the Client
	
	http.set_blocking_mode( true ) #wait untl all data is available on response
	var err = http.connect(serverAdress,port,ssl) # Connect to host/port
	#print(err)
	
	if(!err):
		var start = OS.get_unix_time()
		while( http.get_status()==HTTPClient.STATUS_CONNECTING or http.get_status()==HTTPClient.STATUS_RESOLVING):
			if(OS.get_unix_time()-start>timeout_sec):
				return [HTTPClient.STATUS_CANT_CONNECT,fullhost]
			else:
				http.poll()
		connections[fullhost] = http
		return [http,fullhost,path]
	else:
		return [HTTPClient.STATUS_CANT_CONNECT,fullhost]


# IF there is no body "" is returned else body
func getResponse(http):

	var rs = {}
	
	rs["header"] = {}
	rs["body"] = ""
	rs["code"] = 404
	
	# Keep polling until the request is going on
	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		http.poll()
		#print("read header")
		#print("ich frage die datei an...")
	
	rs["code"] = http.get_response_code()
	# If there is header content(more than first line)
	if (http.has_response()):
		# Get response headers
		var headers = http.get_response_headers_as_dictionary()
		for key in headers:
			rs["header"][key.to_lower()] = headers[key]

		#print(rs)
		var cache = headers
		#This method works for both anyway
		var rb = RawArray() #array that will hold the data
		
		while(http.get_status()==HTTPClient.STATUS_BODY):
			http.set_read_chunk_size( http.get_response_body_length() )
			rb += http.read_response_body_chunk()
		#print(rs)
		#print(rb.get_string_from_utf8())
		if("content-length" in rs["header"]):
			#print(str("EMPFANGEN LENGHT:", rs["header"]["content-length"]))
			rs["body"] = parse_body_to_var(rb, rs["header"]["content-type"])
			#print(rs)
		else:
			rs["body"] = ""
			#print("maybe chunked or error? chunked transfer not supported")
		#print("http empfangen")
		return rs
	else:
		return rs

func parse_body_to_var(body, content_type):
	
	if(content_type.find("application/json")!=-1):
		
		var bodyDict = {}
		body = body.get_string_from_utf8()
		
		#print(body)
		
		if( bodyDict.parse_json( body ) == 0 ):
			body = bodyDict
			print("make dict")
		else:
			print("Error beim body to dict json wandel")
		
	elif(content_type.find("text/plain")!=-1||content_type.find("text/html")!=-1):
		body = body.get_string_from_utf8()
	elif(content_type.find("bytestream")!=-1):
		pass#return body
	return body
