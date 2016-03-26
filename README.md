#TODO:

 - HTTPS not supported
 - sending raw_array not supported by godot master
 - change default transformation not supported
 - changing timeout and pass headers not supported

#Errors:

code on internal errors is always 404

##body contains description

	"Parse Error unsupported body type"
	"Connection error, can't reach host"
	"Request failed, invalid params?"


#How to use

var http = load("res://http.gd").new()

var response = http.get(uri)

var response = http.put(uri, body) # body can be String or RawArray

var response = http.post(uri, body) # body can be String or RawArray

var response = http.delete(uri)

#Response is a Dictionary and contains the following fields

response["code"]

response["headers"]

response["body"]

#The body is automatically transformed to an var there are 3 types supported as default

	"application/json" - A Json String, will return a Dictionary 
	"text/plain" - Simple text, will return a String
	"bytestream" - A bytestream, that can contain any data(files,images,..), will return a RawArray()

Headers don't need the Content-Length header, this is beeing added by godot HTTPClient.


