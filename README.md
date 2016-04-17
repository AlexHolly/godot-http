##TODO:

 - HTTPS not supported.
 - sending raw_array not supported by godot master.
 - change default transformation not supported.
 - changing timeout and pass headers not supported.
 - headers are static inside the script.

##Errors:

The error code on internal errors is always 404.

The response["body"] contains an error description

	"Parse Error unsupported body type"
	"Connection error, can't reach host"
	"Request failed, invalid params?"


##How to use

There are two versions.

http.gd - Is creating a connection for each request.
	
	var http = load("res://http.gd").new()

	var response = http.get(url)

	var response = http.put(url, body) # body can be String or RawArray

	var response = http.post(url, body) # body can be String or RawArray

	var response = http.delete(url)


http_single.gd - Is using one connection that is kept alive to gain some speed.Create one instance for each server.

	var http = load("res://services/http/http_single.gd").new()

	http.connect(server_url)
	
	# To make a requests checkout http.gd example



##Response

The response is a Dictionary and contains the following fields.

	response["code"]

	response["headers"]

	response["body"]

##Body

The body is automatically transformed to an var. Following types are supported as default

	"application/json" - A Json String, will return a Dictionary 
	"text/plain" - Simple text, will return a String
	"text/html" - Simple text, will return a String
	"bytestream" - A bytestream, that can contain any data(files,images,..), will return a RawArray()

Headers don't need the Content-Length header, this is beeing added by godot HTTPClient.

