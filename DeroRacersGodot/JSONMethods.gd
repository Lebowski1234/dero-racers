extends Node


#Define general

var y = ""

#Define RPC calls as dictionaries, for conversion to JSON strings

var mainIndexes = {"txs_hashes":[""], "sc_keys": ["player_count", "VIN_count", "model_number_count", "race_count", "open_races", "player_", "token_"]} #player_ currently not used
var blankKeyList = {"txs_hashes":[""], "sc_keys": [""]}
var getAddress = {"jsonrpc": "2.0", "method": "getaddress", "id": 1}
var getBalance = {"jsonrpc": "2.0", "method": "getbalance", "id": 1}
var getBlockCount = {"jsonrpc": "2.0", "method": "getblockcount", "id": 1}
var join = {"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key": true , "sc_tx":{"entrypoint":"Player","scid":"", "params":{ "name":"" } } }}
var newRace = {"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key": true , "sc_tx":{"entrypoint":"NewRace","scid":"","value":0, "params":{ "blockheight":"", "VIN":"" } } }}
var buy = {"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key": true , "sc_tx":{"entrypoint":"Buy","scid":"","value":0, "params":{ "VIN":"" } } }}
var enterRace = {"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key": true , "sc_tx":{"entrypoint":"EnterRace","scid":"","value":0, "params":{ "raceNumber":"", "VIN":"" } } }}
var startRace = {"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key": true , "sc_tx":{"entrypoint":"StartRace","scid":"", "params":{ "raceNumber":"" } } }}
var sell = {"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key": true , "sc_tx":{"entrypoint":"Sell","scid":"", "params":{ "VIN":"", "price":"" } } }}
var getPlayerNumber = {"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key": true , "sc_tx":{"entrypoint":"GetPlayerNumber","scid":"", "params":{ "token":"" } } }}
var cancelSale = {"jsonrpc":"2.0","id":"0","method":"transfer_split","params":{"mixin":5,"get_tx_key": true , "sc_tx":{"entrypoint":"CancelSale","scid":"", "params":{ "VIN":"" } } }}


#Functions to convert dictionaries to JSON

func getPlayerNumberToJSON(SCID, token):
	#split up dictionary
	var params1 = getPlayerNumber["params"]
	var sc_tx = params1["sc_tx"]
	var params2 = sc_tx["params"]
	
	#assign new values to dictionaries
	sc_tx["scid"] = SCID
	params2["token"] = token
		
	#put dictionary back together
	sc_tx["params"] = params2
	params1["sc_tx"] = sc_tx
	getPlayerNumber["params"] = params1
		
	var j = to_json(getPlayerNumber)
	return j

func sellToJSON(SCID, VIN, price):
	#split up dictionary
	var params1 = sell["params"]
	var sc_tx = params1["sc_tx"]
	var params2 = sc_tx["params"]
	
	#assign new values to dictionaries
	sc_tx["scid"] = SCID
	params2["VIN"] = VIN
	params2["price"] = price
	
	#put dictionary back together
	sc_tx["params"] = params2
	params1["sc_tx"] = sc_tx
	sell["params"] = params1
		
	var j = to_json(sell)
	return j


func cancelSaleToJSON(SCID, VIN):
	#split up dictionary
	var params1 = cancelSale["params"]
	var sc_tx = params1["sc_tx"]
	var params2 = sc_tx["params"]
	
	#assign new values to dictionaries
	sc_tx["scid"] = SCID
	params2["VIN"] = VIN
		
	#put dictionary back together
	sc_tx["params"] = params2
	params1["sc_tx"] = sc_tx
	cancelSale["params"] = params1
		
	var j = to_json(cancelSale)
	return j


func startRaceToJSON(SCID, raceNumber):
	#split up dictionary
	var params1 = startRace["params"]
	var sc_tx = params1["sc_tx"]
	var params2 = sc_tx["params"]
	
	#assign new values to dictionaries
	sc_tx["scid"] = SCID
	params2["raceNumber"] = raceNumber	
	
	#put dictionary back together
	sc_tx["params"] = params2
	params1["sc_tx"] = sc_tx
	startRace["params"] = params1
		
	var j = to_json(startRace)
	return j

func enterRaceToJSON(SCID, VIN, value, raceNumber):
	#split up dictionary
	var params1 = enterRace["params"]
	var sc_tx = params1["sc_tx"]
	var params2 = sc_tx["params"]
	
	#assign new values to dictionaries
	sc_tx["scid"] = SCID
	sc_tx["value"] = value
	params2["VIN"] = VIN
	params2["raceNumber"] = raceNumber	
	
	#put dictionary back together
	sc_tx["params"] = params2
	params1["sc_tx"] = sc_tx
	enterRace["params"] = params1
		
	var j = to_json(enterRace)
	return j

func buyToJSON(SCID, VIN, value):
	#split up dictionary
	var params1 = buy["params"]
	var sc_tx = params1["sc_tx"]
	var params2 = sc_tx["params"]
	
	#assign new values to dictionaries
	sc_tx["scid"] = SCID
	sc_tx["value"] = value
	params2["VIN"] = VIN
		
	#put dictionary back together
	sc_tx["params"] = params2
	params1["sc_tx"] = sc_tx
	buy["params"] = params1
		
	var j = to_json(buy)
	return j

func newRaceToJSON(SCID, VIN, value, blockheight):
	#split up dictionary
	var params1 = newRace["params"]
	var sc_tx = params1["sc_tx"]
	var params2 = sc_tx["params"]
	
	#assign new values to dictionaries
	sc_tx["scid"] = SCID
	sc_tx["value"] = value
	params2["VIN"] = VIN
	params2["blockheight"] = blockheight
	
	#put dictionary back together
	sc_tx["params"] = params2
	params1["sc_tx"] = sc_tx
	newRace["params"] = params1
		
	var j = to_json(newRace)
	return j


func joinToJSON(SCID, name, token):
	#split up dictionary
	var params1 = join["params"]
	var sc_tx = params1["sc_tx"]
	var params2 = sc_tx["params"]
	
	#assign new values to dictionaries
	sc_tx["scid"] = SCID
	params2["name"] = name
	params2["token"] = token
	
	#put dictionary back together
	sc_tx["params"] = params2
	params1["sc_tx"] = sc_tx
	join["params"] = params1
		
	var j = to_json(join)
	return j

func getAddressToJSON():
	var j = to_json(getAddress)
	return j

func getBalanceToJSON():
	var j = to_json(getBalance)
	return j
	
func getBlockHeightToJSON():
	var j = to_json(getBlockCount)
	return j



#main DB indexes
func mainIndexesToJSON(SCID, token): 
	var txs_hashes = mainIndexes["txs_hashes"]
	var sc_keys = mainIndexes["sc_keys"]
	txs_hashes[0] = SCID
	#sc_keys[5] = "player_" + account #Keep for main net version
	sc_keys[6] = "token_" + token
	mainIndexes["txs_hashes"] = txs_hashes
	mainIndexes["sc_keys"] = sc_keys
	
	var j = to_json(mainIndexes)
	return j

#DB of VINs
func buildKeysVIN(SCID, total): #total is the number of VINs in the SC
	#Put SCID into dictionary:
	var txs_hashes = blankKeyList["txs_hashes"]
	txs_hashes[0] = SCID
	blankKeyList["txs_hashes"] = txs_hashes
	
	#Build list of keys for dictionary::
	var sc_keys = blankKeyList["sc_keys"] #create array
	var arraysize = total * 5 #There are 5 fields stored for each VIN
	var tempKey = ""
	var inc = 1
	sc_keys.resize(arraysize)
	
	for i in range(total): 
		inc = i + 1 #all SC databases in Dero Racers start with 1 when not empty
		tempKey = "VIN_" + str(inc) + "_model_number"
		sc_keys[i] = tempKey
		
	for i in range(total, total*2):
		inc = i+1 - total 
		tempKey = "VIN_" + str(inc) + "_owner"
		sc_keys[i] = tempKey
		
	for i in range(total*2, total*3):
		inc = i+1 - total*2 
		tempKey = "VIN_" + str(inc) + "_forsale"
		sc_keys[i] = tempKey
	
	for i in range(total*3, total*4):
		inc = i+1 - total*3 
		tempKey = "VIN_" + str(inc) + "_askingprice"
		sc_keys[i] = tempKey
	
	for i in range(total*4, total*5):
		inc = i+1 - total*4 
		tempKey = "VIN_" + str(inc) + "_soldprice"
		sc_keys[i] = tempKey
	
	blankKeyList["sc_keys"] = sc_keys
	
	var j = to_json(blankKeyList)
	return j 
	

#DB of Races
func buildKeysRace(SCID, total): #total is the number of races in the SC
	#Put SCID into dictionary:
	var txs_hashes = blankKeyList["txs_hashes"]
	txs_hashes[0] = SCID
	blankKeyList["txs_hashes"] = txs_hashes
	
	#Build list of keys for dictionary::
	var sc_keys = blankKeyList["sc_keys"] #create array
	var arraysize = total * 2 #There are 2 fields we need for each race
	var tempKey = ""
	var inc = 1
	sc_keys.resize(arraysize)
	
	for i in range(total): 
		inc = i + 1 #all SC databases in Dero Racers start with 1 when not empty
		tempKey = "race_" + str(inc) + "_status"
		sc_keys[i] = tempKey
		
	for i in range(total, total*2):
		inc = i+1 - total 
		tempKey = "race_" + str(inc) + "_entries"
		sc_keys[i] = tempKey
	
	
	
	#for i in range(total, total*2):
	#	inc = i+1 - total 
	#	tempKey = "race_" + str(inc) + "_fee"
	#	sc_keys[i] = tempKey
		
	#for i in range(total*2, total*3):
	#	inc = i+1 - total*2 
	#	tempKey = "race_" + str(inc) + "_stake"
	#	sc_keys[i] = tempKey
	
	#for i in range(total*3, total*4):
	#	inc = i+1 - total*3 
	#	tempKey = "race_" + str(inc) + "_startblock"
	#	sc_keys[i] = tempKey
		
		
			
	blankKeyList["sc_keys"] = sc_keys
	
	var j = to_json(blankKeyList)
	return j 


#DB of Open Races - first get DB of races
func buildKeysOpenRaces(SCID, total, raceDB): #total = qty races, raceDB = dictionary of races (status plus number of entries)
	#Put SCID into dictionary:
	var txs_hashes = blankKeyList["txs_hashes"]
	txs_hashes[0] = SCID
	blankKeyList["txs_hashes"] = txs_hashes
	
	#Build list of keys for dictionary::
	var sc_keys = blankKeyList["sc_keys"] #create array
	var tempArray = [] 
	
	#for each open race, we need:
		#_fee
		#_stake
		#_startblock
		#race_x_car_x * number of entries
		#_originator
		#array size = 4 x number of open races, plus sum of number of entries
	#var arraysize = open * 4 + sumofentries
	var tempKey1 = ""
	var tempKey2 = ""
	var tempKey3 = ""
	var tempKey4 = ""
	var tempVIN = ""
	var tempStatus = ""
	var tempNumberOfEntries = ""
	var isOpen = ""
	var raceNo = 1
	var entries = 0
	var car = 0
	#sc_keys.resize(arraysize)
	sc_keys.resize(0)
	
	for i in range(total):
		raceNo = i+1  
		tempKey1 = "race_" + str(raceNo) + "_fee"
		tempKey2 = "race_" + str(raceNo) + "_stake"
		tempKey3 = "race_" + str(raceNo) + "_startblock"
		tempKey4 = "race_" + str(raceNo) + "_originator"
		tempStatus = "race_" + str(raceNo) + "_status"
		tempNumberOfEntries = "race_" + str(raceNo) + "_entries"
		isOpen = raceDB[tempStatus]
		entries = int(raceDB[tempNumberOfEntries])
		if isOpen == "1" or isOpen == "2": #only add keys to array if race is open - 2 is not finished, but closed to new entries
			sc_keys.append(tempKey1) 
			sc_keys.append(tempKey2)
			sc_keys.append(tempKey3)
			sc_keys.append(tempKey4)
			#Get list of entries in each race
			for n in range(entries):
				car = n+1
				tempVIN = "race_" + str(raceNo) + "_car_" + str(car)
				sc_keys.append(tempVIN)
	
	blankKeyList["sc_keys"] = sc_keys
	
	
	var j = to_json(blankKeyList)
	return j 
	
	#for i in range(total):
	#	raceNo = i+1  
	#	tempKey = "race_" + str(raceNo) + "_fee"
	#	tempStatus = "race_" + str(raceNo) + "_status"
	#	isOpen = raceDB[tempStatus]
	#	if isOpen == "1":
	#		sc_keys[i] = tempKey #only add key to list if race is open
		
	#for i in range(total, total*2):
	#	raceNo = i+1 - total 
	#	tempKey = "race_" + str(raceNo) + "_stake"
	#	tempStatus = "race_" + str(raceNo) + "_status"
	#	isOpen = raceDB[tempStatus]
	#	if isOpen == "1":
	#		sc_keys[i] = tempKey #only add key to list if race is open
	
	#for i in range(total*2, total*3):
	#	raceNo = i+1 - total*2 
	#	tempKey = "race_" + str(raceNo) + "_startblock"
	#	tempStatus = "race_" + str(raceNo) + "_status"
	#	isOpen = raceDB[tempStatus]
	#	if isOpen == "1":
	#		sc_keys[i] = tempKey #only add key to list if race is open
	
	#for i in range(total*3, total*4):
	#	raceNo = i+1 - total*3 
	#	tempKey = "race_" + str(raceNo) + "_originator"
	#	tempStatus = "race_" + str(raceNo) + "_status"
	#	isOpen = raceDB[tempStatus]
	#	if isOpen == "1":
	#		sc_keys[i] = tempKey #only add key to list if race is open
					
	



#DB of Models
func buildKeysModels(SCID, total): #total is the number of model numbers in the SC
	#Put SCID into dictionary:
	var txs_hashes = blankKeyList["txs_hashes"]
	txs_hashes[0] = SCID
	blankKeyList["txs_hashes"] = txs_hashes
	
	#Build list of keys for dictionary::
	var sc_keys = blankKeyList["sc_keys"] #create array
	var arraysize = total * 6 #There are 6 fields we need for each model
	var tempKey = ""
	var inc = 1
	sc_keys.resize(arraysize)
	
	for i in range(total): 
		inc = i + 1 #all SC databases in Dero Racers start with 1 when not empty
		tempKey = "model_number_" + str(inc) + "_make"
		sc_keys[i] = tempKey
		
	for i in range(total, total*2):
		inc = i+1 - total 
		tempKey = "model_number_" + str(inc) + "_model"
		sc_keys[i] = tempKey
		
	for i in range(total*2, total*3):
		inc = i+1 - total*2 
		tempKey = "model_number_" + str(inc) + "_speed"
		sc_keys[i] = tempKey
	
	for i in range(total*3, total*4):
		inc = i+1 - total*3 
		tempKey = "model_number_" + str(inc) + "_acceleration"
		sc_keys[i] = tempKey
	
	for i in range(total*4, total*5):
		inc = i+1 - total*4 
		tempKey = "model_number_" + str(inc) + "_handling"
		sc_keys[i] = tempKey
	
	for i in range(total*5, total*6):
		inc = i+1 - total*5 
		tempKey = "model_number_" + str(inc) + "_productionrun"
		sc_keys[i] = tempKey
			
	blankKeyList["sc_keys"] = sc_keys
	
	var j = to_json(blankKeyList)
	return j 

#DB of Player points
func buildKeysPoints(SCID, total): #total is the number of players in the SC
	#Put SCID into dictionary:
	var txs_hashes = blankKeyList["txs_hashes"]
	txs_hashes[0] = SCID
	blankKeyList["txs_hashes"] = txs_hashes
	
	#Build list of keys for dictionary::
	var sc_keys = blankKeyList["sc_keys"] #create array
	#var arraysize = total * 2
	var tempName = ""
	var tempPoints = ""
	var inc = 1
	sc_keys.resize(0)
	
	for i in range(total): 
		inc = i + 1 #all SC databases in Dero Racers start with 1 when not empty
		tempPoints = "player_" + str(inc) + "_points"
		tempName = "player_" + str(inc) + "_name"
		sc_keys.append(tempPoints)
		sc_keys.append(tempName)
	
	blankKeyList["sc_keys"] = sc_keys
	
	var j = to_json(blankKeyList)
	return j 

func buildKeysPlayerStats(SCID, playerNumber): #total is the number of players in the SC
	#Put SCID into dictionary:
	var txs_hashes = blankKeyList["txs_hashes"]
	txs_hashes[0] = SCID
	blankKeyList["txs_hashes"] = txs_hashes
	
	#Build list of keys for dictionary::
	var sc_keys = blankKeyList["sc_keys"] #create array
	sc_keys.resize(6)
	sc_keys[0] = "player_" + playerNumber + "_points"
	sc_keys[1] = "player_" + playerNumber + "_name"
	sc_keys[2] = "player_" + playerNumber + "_numberofcars"
	sc_keys[3] = "player_" + playerNumber + "_message"
	sc_keys[4] = "player_" + playerNumber + "_error"
	sc_keys[5] = "player_" + playerNumber + "_last_race_won"
	
	blankKeyList["sc_keys"] = sc_keys
	
	var j = to_json(blankKeyList)
	return j 

#DB of Player cars
func buildKeysPlayerCars(SCID, playerNumber, numberOfCars): #total is the number of cars owned by the player
	#Put SCID into dictionary:
	var txs_hashes = blankKeyList["txs_hashes"]
	txs_hashes[0] = SCID
	blankKeyList["txs_hashes"] = txs_hashes
	
	#Build list of keys for dictionary::
	var sc_keys = blankKeyList["sc_keys"] #create array
	var arraysize = numberOfCars 
	var tempKey = ""
	var inc = 1
	sc_keys.resize(arraysize)
	
	for i in range(numberOfCars): 
		inc = i + 1 #all SC databases in Dero Racers start with 1 when not empty
		tempKey = "player_" + playerNumber + "_car_" +str(inc)
		sc_keys[i] = tempKey
	
	blankKeyList["sc_keys"] = sc_keys
	
	var j = to_json(blankKeyList)
	return j 


#DB of cars entered in a race
func buildKeysCarsEntered(SCID, raceNumber, numberOfEntries): #total is the number of cars owned by the player
	#Put SCID into dictionary:
	var txs_hashes = blankKeyList["txs_hashes"]
	txs_hashes[0] = SCID
	blankKeyList["txs_hashes"] = txs_hashes
	
	#Build list of keys for dictionary::
	var sc_keys = blankKeyList["sc_keys"] #create array
	var arraysize = numberOfEntries 
	var tempKey = ""
	var inc = 1
	sc_keys.resize(arraysize)
	
	for i in range(numberOfEntries): 
		inc = i + 1 #all SC databases in Dero Racers start with 1 when not empty
		tempKey = "race_" + raceNumber + "_car_" +str(inc)
		sc_keys[i] = tempKey
	
	blankKeyList["sc_keys"] = sc_keys
	
	var j = to_json(blankKeyList)
	return j 


#getKeys: pull sc_keys out of daemon response, return as dictionary. 
func getKeys(daemonResponse):
	var error = {"error": "new error"}
	var d = JSON.parse(daemonResponse) #JSON to JSONParseResult
	var d1 = d.result #JSONParseResult to dictionary
	
	#We must check SC exists, and for 'txs' and 'sc_keys' to catch errors. Any further checking is not required, as provided the key is included 
	#in the original message, the daemon will return the key but with a blank value even if it doesn't exist.
	if d1.has("txs"):
		var d2 = d1["txs"]
		if typeof(d2) != TYPE_ARRAY:
			error["error"] = "error, SC does not exist" 
			return error
		var a = d2[0]
		#var d4 = d3["VIN_count"]		
		if a.has("sc_keys"):
			var d3 = a["sc_keys"]
			return d3
		else:
			error["error"] = "error, no SC_keys" 
			return error
		
	else:
		error["error"] = "error, no txs" 
		return error


#Extract address from wallet response JSON string. For functions that return a single result in 'result' field. 
func getAddressFromResponse(walletResponse):
	var y = ""
	var d = JSON.parse(walletResponse) #JSON to JSONParseResult
	if d.error != OK:
		return "Error, please check that wallet is running!" 
	var d1 = d.result #JSONParseResult to dictionary
	if d1.has("error"): #if node returns error message
		var d2 = d1["error"]
		return d2["message"]
		
	if d1.has("result"):
		var d2 = d1["result"]
		return d2["address"]
				
	else:
		return "Error, unexpected JSON from wallet"
		

#Extract address from wallet response JSON string. For functions that return a single result in 'result' field. 
func getBlockHeightFromResponse(daemonResponse):
	var y = ""
	var d = JSON.parse(daemonResponse) #JSON to JSONParseResult
	var d1 = d.result #JSONParseResult to dictionary
	if d1.has("error"): #if node returns error message
		var d2 = d1["error"]
		return d2["message"]
		
	if d1.has("result"):
		var d2 = d1["result"]
		return str(d2["count"])
				
	else:
		return "Error, unexpected JSON from daemon!"


#Extract address from wallet response JSON string. For functions that return a single result in 'result' field. 
func getBalanceFromResponse(walletResponse):
	var y = ""
	var d = JSON.parse(walletResponse) #JSON to JSONParseResult
	
	return d.result #JSONParseResult to dictionary
	


#For SC related calls to wallet: return error or result. 
func getResultOrError(walletResponse):
	var y = ""
	var d = JSON.parse(walletResponse) #JSON to JSONParseResult
	if d.error != OK:
		return "Error, please check that wallet is running!" 
	var d1 = d.result #JSONParseResult to dictionary
	if d1.has("error"): #if node returns error message
		var d2 = d1["error"]
		return "Please try again, transaction failed, error received from wallet: " + d2["message"]
		#return "Error, transaction failed, error received from wallet!"
		
	if d1.has("result"):
		return "Transaction sent to wallet"
				
	else:
		return "Error, unexpected JSON from wallet!"

#For SC related calls to daemon: return error or result. 
func getResultOrErrorDaemon(daemonResponse):
	var y = ""
	var d = JSON.parse(daemonResponse) #JSON to JSONParseResult
	if d.error != OK:
		return "Error, please check that daemon is running!" 
	return "Daemon is running"
	






