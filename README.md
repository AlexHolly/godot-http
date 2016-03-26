TODO:

 - HTTPS not supported
 - sending raw_array not supported by godot master
 - change default transformation not supported
 - changing timeout and pass headers not supported

Errors:

code is always 404

body contains description

 - "Parse Error unsupported body type"
 - "Connection error, can't reach host"
 - "Request failed, invalid params?"


var response = http.get(uri)
var response = http.put(uri, chunk)
var response = http.post(uri, chunk)
var response = http.delete(uri)

Response is a Dictionary and contains the following fields

response["code"]
response["headers"]
response["body"]

The body is automatically transformed to an var there are 3 types supported as default

"application/json" - A Json String, will return a Dictionary 
"text/plain" - Simple text, will return a String
"bytestream" - A bytestream, that can contain any data(files,images,..), will return a RawArray()

You can overwrite the default transformation. This is the default tranformation, it also adds the header.
You could also just change the default function handle_body.

var default_body_parser = ["handle_body",self]

func handle_body(body):
	var headers = headers()
	if(typeof(body)==TYPE_RAW_ARRAY):
		if(body.size()>0):
			headers["Content-Type"] = "bytestream"
		return [headers,body]
	elif(typeof(body)==TYPE_DICTIONARY):
		if(!body.empty()):
			headers["Content-Type"] = "application/json"
			body = body.to_json()
		return [headers,body]
	elif(typeof(body)==TYPE_STRING):
		if(body.length()>0):
			headers["Content-Type"] = "text/plain"
		return [headers,body]
	else:
		print("unsupported type")
		return [ERR_BODY,ERR_BODY]

EXAMPLE that only supports json strings:

http.default_body_parser = ["my_body_tranformation",self]

func my_custom_headers():
	return {
		"User-Agent": "Pirulo/1.0 (Godot)",
		"Accept": "*/*"
		}

func my_body_tranformation(body):
	var headers = my_custom_headers()
	if(typeof(body)==TYPE_DICTIONARY):
		if(!body.empty()):
			headers["Content-Type"] = "application/json"
			body = body.to_json()
		return [headers,body]
	else:
		print("unsupported type")
		return [http.ERR_BODY,http.ERR_BODY]

Headers don't need the Content-Length header, this is beeing added by godot HTTPClient.


