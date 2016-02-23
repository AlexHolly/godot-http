#by alexholly

extends Node2D

var headers=[
	"User-Agent: Pirulo/1.0 (Godot)",
	"Accept: */*"
]

#TODO http request liefert die response, sollten die errors abgefangen werden?
#TODO Was machen mit players wie werden sie geupdated siehe board get players problem
#TODO Asynchrone anfragen einbauen? Etwas komplizierter für anfragenden, muss call back funktion mit geben?

var http = HTTPClient.new() # Create the Client
#var serverAdress
#var port 

func _init():
	pass
	
func _ready():
	#serverAdress = get_node("/root/global").get_ha_proxy()
	#port = get_node("/root/global").get_ha_proxy_port()
	#http.set_blocking_mode( true )
	pass

func get(adress):
	#print(adress)
	var uri_dict = get_link_address_port_path(adress)
	print("SENDING NEW REQUEST")
	checkServerConnection(uri_dict["host"], uri_dict["port"])
	http.request(HTTPClient.METHOD_GET, adress.percent_encode(), headers)
	return getResponse()
	
func put(adress):
	
	var uri_dict = get_link_address_port_path(adress)
	
	checkServerConnection(uri_dict["host"], uri_dict["port"])
	http.request(HTTPClient.METHOD_PUT, adress.percent_encode(), headers)
	
	return getResponse()
	
func delete(adress):
	var uri_dict = get_link_address_port_path(adress)
	
	checkServerConnection(uri_dict["host"], uri_dict["port"])
	http.request(HTTPClient.METHOD_DELETE, adress.percent_encode(), headers)
	
	return getResponse()
	
func post(adress, body):
	var uri_dict = get_link_address_port_path(adress)
	
	checkServerConnection(uri_dict["host"], uri_dict["port"])
	http.request(HTTPClient.METHOD_POST, adress.percent_encode(), headers, body)
	
	return getResponse()
	
func get_link_address_port_path(uri):
	var link = uri.replace("http://", "")
	var host = link.split("/", true)[0]
	
	var adress_port = host.split(":", true)
	var adress = adress_port[0]
	
	#kein port also "" führt zu einem freeze
	var port = "80"
	if(adress_port.size()>1):
		port = adress_port[1]
	
	var path = uri.replace(adress,"")
	#print(adress)
	path = uri.replace("http://"+adress+":"+port,"")
	#print(str("REQUEST:", path))
	
	#print(str("REQUEST:", path))
	#print("request: " + path)
	return {
			"uri":uri, 
			"host":adress,
			"port":int(port),
			"path":path
			#query missing
			#fragment missing
			}

func checkServerConnection(serverAdress,port):
	var err = http.connect(serverAdress,port) # Connect to host/port

	while( http.get_status()==HTTPClient.STATUS_CONNECTING or http.get_status()==HTTPClient.STATUS_RESOLVING):
		http.poll()
	

func getResponse():

	var rs = {}
	rs["header"] = {}
	# Keep polling until the request is going on
	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		http.poll()
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
		
		if(http.get_status()==HTTPClient.STATUS_BODY):
			http.set_read_chunk_size( http.get_response_body_length() )
			var rb = http.read_response_body_chunk()
			#print(rs)
			if("content-length" in rs["header"]):
				rs["body"] = parse_body_to_var(rb, rs["header"]["content-type"])
				#print(rs)
			else:
				rs["body"] = null
			return rs
		else:
			print("chunked transfer not supported")
			#while(http.get_status()==HTTPClient.STATUS_BODY):
			#	# While there is body left to be read
			#	http.poll()
			#	# Get a chunk
			#	var chunk = http.read_response_body_chunk()
			#	rb = rb + chunk # append to read bufer
	else:
		print("no response")

func parse_body_to_var(body, content_type):
	
	if(content_type.find("application/json")!=-1):
		
		var bodyDict = {}
		body = body.get_string_from_utf8()
		
		if( bodyDict.parse_json( body ) == 0 ):
			body = bodyDict
			
	elif(content_type.find("bytestream")!=-1):
		
		pass#return body
	return body
