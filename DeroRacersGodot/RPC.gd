#For SSL certs served by Nginx, the local (Godot folder) .crt file referenced in project settings
#must contain both certificates in the chain, in the correct order. If it freezes during polling,
#try changing the order of the certificates. 

#TO DO: add error handling for SSL certificate issues. 

extends Node



func RPCSend(args, url, port, pageAddress):
	var err = 0
	var http = HTTPClient.new() # Create the Client
	err = http.connect_to_host(url,port) # Connect to host/port "http://127.0.0.1/gettransactions",30306 or 127.0.0.1/json_rpc",30309
	assert(err == OK) # Make sure connection was OK
	
	#Wait until resolved
	while http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("Resolving..")
		OS.delay_msec(100) #was 500
	
	if (http.get_status() == HTTPClient.STATUS_CANT_RESOLVE):
		return "RPC Error, could not resolve HTTP address!"
	
	#assert(http.get_status() != HTTPClient.STATUS_CANT_RESOLVE) # Could not resolve
	
	#Wait until connected
	while http.get_status() == HTTPClient.STATUS_CONNECTING:
		http.poll()
		print("Connecting..")
		OS.delay_msec(100) #was 500
	
	if (http.get_status() != HTTPClient.STATUS_CONNECTED):
		return "Error, could not connect to HTTP server! Check that Dero wallet and daemon are running!"
	#assert(http.get_status() == HTTPClient.STATUS_CONNECTED) # Could not connect
	
	# Some headers
	var headers = [
		"Content-Type: application/json",
	]
	
	#var args = "{\"jsonrpc\":\"2.0\",\"method\":\"web3_clientVersion\",\"params\":[],\"id\":67}"
	
	err = http.request(HTTPClient.METHOD_POST, pageAddress, headers, args) # Request a page from the site (this one was chunked..)
	
	if (err != OK):
		return "RPC Error, could not POST to HTTP server!"
	
	#assert(err == OK) # Make sure all is OK
	
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling until the request is going on
		http.poll()
		print("Requesting..")
		OS.delay_msec(500) #was 500
	
	# The following code returns an error, probably not necessary. 
	#if (http.get_status() != HTTPClient.STATUS_BODY or http.get_status() != HTTPClient.STATUS_CONNECTED): # Make sure request finished well.
	#	return "Error request didnt work"
		
	print("response? ", http.has_response()) # Site might not have a response.
	
	if http.has_response():
		# If there is a response..
		headers = http.get_response_headers_as_dictionary() # Get response headers
		print("code: ", http.get_response_code()) # Show response code
		print("**headers:\\n", headers) # Show headers
		
		# Getting the HTTP Body
		if http.is_response_chunked():
			# Does it use chunks?
			print("Response is Chunked!")
		else:
			# Or just plain Content-Length
			var bl = http.get_response_body_length()
			print("Response Length: ",bl)
		
		# This method works for both anyway
		var rb = PoolByteArray() # Array that will hold the data
		
		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			var chunk = http.read_response_body_chunk() # Get a chunk
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit
				OS.delay_usec(10) #was 1000
			else:
				rb = rb + chunk # Append to read buffer
		# Done!
		
		print("bytes got: ", rb.size())
		var text = rb.get_string_from_ascii()
		print("Text: ", text)
		return text
	
	
	

