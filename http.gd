#author https://github.com/AlexHolly
extends Node

var timeout_sec = 2

func headers():
	return {
				"User-Agent": "Pirulo/1.0 (Godot)",
				"Accept": "*/*"
			}

func dict_to_array(dict):
	var rs = []
	for key in dict:
		rs.append(key + ": " + str(dict[key]))
	return rs
	
var HTTP = "http://"
var HTTPS = "https://"
#TODO http request liefert die response, sollten die errors abgefangen werden?
#TODO Was machen mit players wie werden sie geupdated siehe board get players problem
#TODO Asynchrone anfragen einbauen? Etwas komplizierter für anfragenden, muss call back funktion mit geben?
#TODO ssl immer port 443???? nicht unbedingt oder?

func _init():
	pass
	
func _ready():
	pass

func get(adress):
	var headers = headers()
	var http = checkServerConnection(adress)
	
	if(typeof(http)==TYPE_OBJECT):
		var err = http.request(HTTPClient.METHOD_GET, adress.percent_encode(), dict_to_array(headers))
		if(err==OK):
			return getResponse(http)
	return null
	
func put(adress,body=[]):
	var headers = handle_body(body)
	
	if(headers== null):
		return null
		
	var http = checkServerConnection(adress)
	if(typeof(http)==TYPE_OBJECT):
		var err = http.request_raw(HTTPClient.METHOD_PUT, adress.percent_encode(), dict_to_array(headers), body)
		if(err==OK):
			return getResponse(http)
	return null
	
func delete(adress):
	var headers = headers()
		
	var http = checkServerConnection(adress)
	if(typeof(http)==TYPE_OBJECT):
		var err = http.request(HTTPClient.METHOD_DELETE, adress.percent_encode(), dict_to_array(headers))
		if(err==OK):
			return getResponse(http)
	return null
	
func post(adress, body=[]):
	var headers = handle_body(body)
	
	if( headers==null ):
		return null
		
	var http = checkServerConnection(adress)
	if(typeof(http)==TYPE_OBJECT):
		var err = http.request_raw(HTTPClient.METHOD_POST, adress.percent_encode(), dict_to_array(headers), body)
		if(err==OK):
			return getResponse(http)
	return null

func handle_body(body):
	var headers = headers()
	if(typeof(body)==TYPE_RAW_ARRAY):
		headers["Content-Length"] = body.size()
		headers["Content-Type"] =  "bytestream"
		print("ist raw array: " + str(body.size()))
	elif(typeof(body)==TYPE_STRING):
		headers["Content-Length: "] = body.length()
		headers["Content-Type"] = "application/json"
	else:
		print("unsupported type")
		return null

func get_link_address_port_path(uri):
	var ssl = false
	# TODO ssl immer port 443???? nicht unbedingt oder?
	var link = uri.replace(HTTP, "")
	if(uri.begins_with(HTTPS)):
		ssl = true
		link = uri.replace(HTTPS, "")
	var host = link.split("/", true)[0]
	
	var adress_port = host.split(":", true)
	var adress = adress_port[0]
	
	#kein port also "" führt zu einem freeze
	var port = "80"
	if(adress_port.size()>1):
		port = adress_port[1]
	
	var path = uri.replace(adress,"")
	
	if(ssl):
		path = uri.replace(HTTP+adress+":"+port,"")
	else:
		path = uri.replace(HTTPS+adress+":"+port,"")
	
	#print("request: " + path)
	return {
			"uri":uri, 
			"host":adress,
			"port":int(port),
			"path":path,
			"ssl":ssl
			#query missing
			#fragment missing
			}

func checkServerConnection(adress):
	var uri_dict = get_link_address_port_path(adress)
	
	var serverAdress = uri_dict["host"]
	var port = uri_dict["port"]
	var ssl = uri_dict["ssl"]
	
	var http = HTTPClient.new() # Create the Client
	
	http.set_blocking_mode( true ) #wait untl all data is available on response
	var err = http.connect(serverAdress,port,ssl) # Connect to host/port
	#print(err)
	
	if(!err):
		var start = OS.get_unix_time()
		while( http.get_status()==HTTPClient.STATUS_CONNECTING or http.get_status()==HTTPClient.STATUS_RESOLVING):
			if(OS.get_unix_time()-start>timeout_sec):
				return HTTPClient.STATUS_CANT_CONNECT
			else:
				http.poll()
		return http
	else:
		return HTTPClient.STATUS_CANT_CONNECT


func getResponse(http):

	var rs = {}
	
	rs["header"] = {}
	rs["body"] = {}
	rs["code"] = 404
	
	# Keep polling until the request is going on
	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		http.poll()
		#print("read header")
		#print("ich frage die datei an...")
	
	# If there is header content
	if (http.has_response()):
		# Get response headers
		var headers = http.get_response_headers_as_dictionary()
		for key in headers:
			rs["header"][key.to_lower()] = headers[key]

		#print(rs)
		var cache = headers
		rs["code"] = http.get_response_code()   
		#This method works for both anyway
		var rb = RawArray() #array that will hold the data
		
		while(http.get_status()==HTTPClient.STATUS_BODY):
			http.set_read_chunk_size( http.get_response_body_length() )
			rb += http.read_response_body_chunk()
			#print(rs)
			
		if("content-length" in rs["header"]):
			print(str("EMPFANGEN LENGHT:", rs["header"]["content-length"]))
			rs["body"] = parse_body_to_var(rb, rs["header"]["content-type"])
			#print(rs)
		else:
			rs["body"] = {}
			#print("maybe chunked or error? chunked transfer not supported")
		#print("http empfangen")
		return rs
	else:
		print("http.gd - no response")
		return null

func parse_body_to_var(body, content_type):
	
	if(content_type.find("application/json")!=-1):
		
		var bodyDict = {}
		body = body.get_string_from_ascii()
		
		#print(body)
		
		if( bodyDict.parse_json( body ) == 0 ):
			body = bodyDict
			print("make dict")
		else:
			print("Error beim body to dict json wandel")
		
	elif(content_type.find("bytestream")!=-1):
		
		pass#return body
	return body