#To do before main net release: simplification to significantly reduce number of functions, make use of timers instead of multiple similar RPC functions!
#To do: much tidying up...

extends Panel

#Variables for RPC calls:

var daemonURL = "127.0.0.1"
var walletURL = "127.0.0.1"
var daemonPort = 30306
var walletPort = 30309
var daemonPage = "/gettransactions" #daemon URL entrypoint to get SC transactions
var walletPage = "/json_rpc"

#for testing only
var walletMessage = "{\"jsonrpc\":\"2.0\",\"id\":\"0\",\"method\":\"transfer_split\",\"params\":{\"mixin\":5,\"get_tx_key\": true , \"sc_tx\":{\"entrypoint\":\"UpdateIP\",\"scid\":\"9caa493a0167238cef5ec0394558a2bd9127c82f8bf0e90ea572aaf3703e819f\", \"params\":{ \"Data\":\"123.4.5.6\" } } }}"
var sendMessage = "{\"txs_hashes\":[\"641dfb8f5072de300c27d66d7887d51397d85dd3b501ce4a294e95f3b6255475\"], \"sc_keys\": [\"model_number_1_make\"]}"
var timerinc = 0

#General variables:
var y = "" #y is used as a general variable for temporary strings
var SCID = "d938d2a66d27bd66791a11f983d7b36ba2bdc0fb833fbeb81cf4bab26351cdfc" 
var token = "" #for getting player number from SC 
var thread = Thread.new()
var thread2 = Thread.new() #used for main sequence


#Variables for timers and sequencing
var main_timer = null
var is_joined_timer = null
#send_token_timer = null
var wait_to_start_timer = null
var wait_to_update_timer = null
var wait_for_address_timer = null
#var sendTokenTimerStartedBlock = 0
var waitToStartTimerStartedBlock = 0
var walletRunning = false
var daemonRunning = false
var updating = false #set to true when update button pressed, back to false when sequence finished. To avoid DB clashes. 
var mainSequeceActive = false #set to true when main sequence active. Locks out update function to prevent errors if main indexes get updated while updating.
var newName = "" #to store new name in memory when join or change name buttons pressed
var pressStartMessageDisplayed = false #set to true once player stats retrieved from SC, i.e. game started, so we stop displaying debug message

#Variables of keys pulled from SC via daemon:
#Main indexes
var player_count = 0
var VIN_count = 0
var model_number_count = 0
var race_count = 0
var open_races = 0
var playerNumber = ""

#Player stats
var playerPoints = 0
var playerName = ""
var playerNumberOfCars = 0
var playerMessage = ""
var playerErrorMessage = ""
var playerLastRaceWon = ""
var currentSCErrorMessage = ""


#Databases pulled from daemon - all dictionary format
var VINDB = {}
var modelDB = {}
var playerCarsDB = {}
var raceDB = {}
var openRaceDB = {}
var pointsDB = {} ##for leaderboard

#Status of databases - changed to true when populated
var VINDBStatus = false
var modelDBStatus = false
var playerCarsDBStatus = false
var raceDBStatus = false
var openRaceDBStatus = false
var pointsDBStatus = false

var playerStatsStatus = false #not actually a database, but a list of variables

#Variables pulled from wallet
var playerAccount = ""
var balance = 0
var unlockedBalance = 0
var blockHeight = 0
var playerJoined = false

#Variables for car yard
var carYardVINArray = []
var carYardPriceArray = []
var carYardModelNumberArray = []
var carYardModelArray = []
var carYardMakeArray = []
var carYardItemListArray = []
var carYardSpeedArray = []
var carYardAccelArray = []
var carYardHandlingArray = []
var carYardProductionRunArray = []
var selectedCarYardVIN = ""
var selectedCarYardMake = ""
var selectedCarYardModel = ""
var selectedCarYardModelNumber = ""
#var selectedCarYardSpeed = ""
#var selectedCarYardAccel = ""
#var selectedCarYardHandling = ""
var selectedCarYardPrice = ""
#var selectedCarYardProductionRun = ""

#Variables for garage
var garageVINArray = []
var garagePriceArray = []
var garagePricePaidArray = []
var garageModelNumberArray = []
var garageModelArray = []
var garageMakeArray = []
var garageItemListArray = []
var garageSpeedArray = []
var garageAccelArray = []
var garageHandlingArray = []
var garageProductionRunArray = []
var garageForSaleArray = []
var selectedGarageVIN = ""
var selectedGarageMake = ""
var selectedGarageModel = ""
var selectedGarageModelNumber = ""
var selectedGaragePrice = ""

#Variables for race
var raceNumberArray = []
var raceStartingArray = []
var raceEntryFeeArray = []
var racePrizePotArray = []
var raceEnteredArray = []
var raceEntryCountArray = []
var raceItemListArray = []
var selectedRaceNumber = ""
var selectedRaceFee = ""

#Variables for leaderboard
var nameArray = []
var pointsArray = []
var leaderboardNameArray = []
var leaderboardPointsArray = []



func _ready():
	#randomize internal number generator seed in case we need to generate a token
	randomize()
	
	#connect buttons
	get_node("StartPanel/StartRect/UpdateButton").connect("pressed", self, "_on_UpdateButton_pressed")
	get_node("StartPanel/StartRect/StartButton").connect("pressed", self, "_on_StartButton_pressed")
	
	
	
	#open SC error message file
	currentSCErrorMessage = openSCErrorFile()
	playerErrorMessage = currentSCErrorMessage
	
	#for testing only
	#get_node("StartPanel/StartRect/TestButton").connect("pressed", self, "_on_TestButton_pressed")
	#get_node("StartPanel/StartRect/IndexesButton").connect("pressed", self, "_on_IndexesButton_pressed")
	#get_node("StartPanel/StartRect/TestTokenButton").connect("pressed", self, "_on_TestTokenButton_pressed")
	
	#setup timers
	#main_timer: to update balance, block height, indexes, player stats, player cars
	main_timer = Timer.new()
	add_child(main_timer)
	main_timer.connect("timeout", self, "_on_MainTimer_timeout")
	main_timer.set_wait_time(12.0)
	main_timer.set_one_shot(false) # Make sure it loops
	main_timer.start()
	
	#start main sequence
	mainSequence()

func _on_MainTimer_timeout():
	mainSequence()

#Continuous loop, getting balance, block height, indexes, player stats, player cars
func mainSequence():
	#if update button has been pressed, we don't want to update the main indexes and DB's in the middle of an update otherwise unexpected behaviour might occur
	if updating == true:
		return
	mainSequeceActive = true #lock out update functions until finished
	getIndexes()

func _on_StartButton_pressed():
	startGame()

func startGame():
	if playerJoined == true:
		return #Nothing more to do, perhaps player pressed button accidentally
	
	#check if we already have a token saved
	get_node("StartPanel/StartRect/StartButton").text = "Starting..."
	var save_token = File.new()
	if save_token.file_exists("user://deroracers.dat"):
		save_token.open("user://deroracers.dat", File.READ)
		var contents = save_token.get_line()
		save_token.close()
		if contents != "": #make sure nobody has changed the data for some reason
			token = contents
			get_node("StatsPanel/PlayerRect/Joined2").text = "Checking..."
			
			#call daemon, see if token exists in SC
			isPlayerJoined()
			
			#start a timer, if token is valid then main sequence should pick up player number from token
			is_joined_timer = Timer.new()
			add_child(is_joined_timer)
			is_joined_timer.connect("timeout", self, "_on_IsJoinedTimer_timeout")
			is_joined_timer.set_wait_time(13.0)
			is_joined_timer.set_one_shot(true) # Make sure it loops
			is_joined_timer.start()
			return
	get_node("DebugTextEdit").text = "You have not joined the game, enter name and press 'Join Game'"
	get_node("StartPanel/StartRect/StartButton").text = "Start Game!"

func _on_IsJoinedTimer_timeout():
	#we did not get a player number from our token, player has not joined, or some other error has occured (e.g. not synched)
	if playerNumber == "":
		get_node("StatsPanel/PlayerRect/Joined2").text = "No"
		get_node("DebugTextEdit").text = "You have not joined the game, enter name and press 'Join Game'"
		get_node("StartPanel/StartRect/StartButton").text = "Start Game!"
		return
	
	#All good! We have joined the game
	get_node("StatsPanel/PlayerRect/Joined2").text = "Yes"
	playerJoined = true
	get_node("DebugTextEdit").text = "Joined! Press 'Update...' button to get car yard, garage and race details!"
	get_node("StartPanel/StartRect/StartButton").text = "Game Started!"
	#update all panels
	#getVIN()


func waitToStart():
	if waitToStartTimerStartedBlock == 0: #we are at the start of the loop
		waitToStartTimerStartedBlock = blockHeight
	
	wait_to_start_timer = Timer.new()
	add_child(wait_to_start_timer)
	wait_to_start_timer.connect("timeout", self, "_on_WaitToStartTimer_timeout")
	wait_to_start_timer.set_wait_time(12.0)
	wait_to_start_timer.set_one_shot(true) # Make sure it loops
	wait_to_start_timer.start()

func _on_WaitToStartTimer_timeout():
	#2 blocks have elapsed since we sent a token request to the SC, we should now be able to start the game
	if (blockHeight >= waitToStartTimerStartedBlock + 2):
		waitToStartTimerStartedBlock = 0
		startGame()
		return
	
	#2 blocks have not elapsed, start timer again and wait for blockheight to increase
	waitToStart()
	

func _on_ClearErrorButton_pressed():
	get_node("SCErrorTextEdit").text = ""

#Buy the selected car
func _on_BuyButton_pressed():
	if get_node("CarYardPanel/CarYardRect/VIN2").text == "-":
		return
	if get_node("CarYardPanel/CarYardRect/Price2").text == "-":
		return
	#get_node("DebugTextEdit").text = selectedCarYardPrice
	var priceInt = get_node("BigMath").StrToInt64(selectedCarYardPrice) #convert string to int64 dero value
	#get_node("DebugTextEdit").text = str(priceInt)
	buyCar(selectedCarYardVIN, priceInt)


#Sell the selected car
func _on_SellButton_pressed():
	if get_node("GaragePanel/MyGarageRect/VIN2").text == "-":
		return
	if get_node("GaragePanel/MyGarageRect/AskingPriceEdit").text == "-":
		return
	#prevent accidentally selling a car, i.e. seller must enter a price greater than 0, or 0.0 to give away for free
	if get_node("GaragePanel/MyGarageRect/AskingPriceEdit").text == "0":
		return
	#get_node("DebugTextEdit").text = selectedCarYardPrice
	#var priceFloat = float(get_node("GaragePanel/MyGarageRect/AskingPriceEdit").text)
	#if priceFloat > 9999999:
	#	get_node("DebugTextEdit").text = "Error, value cannot exceed 9,999,999"
	#	return
	
	#var priceDero = str(priceFloat * 1000000000000)
	if int(get_node("GaragePanel/MyGarageRect/AskingPriceEdit").text) == 0:
		get_node("DebugTextEdit").text = "Error, please enter integer value between 1 and 999"
		return
	
	var boxContents = get_node("GaragePanel/MyGarageRect/AskingPriceEdit").text
	var isFloat = -1 
	
	isFloat = boxContents.find(".")
	if (isFloat >-1):  
		get_node("DebugTextEdit").text = "Error, please enter integer value between 1 and 999"
		return
	
	var enteredInt = int(get_node("GaragePanel/MyGarageRect/AskingPriceEdit").text)
	var priceDero = str(enteredInt * 1000000000000)
	#get_node("DebugTextEdit").text = priceDero
	
	sellCar(selectedGarageVIN, priceDero)



func _on_CancelSaleButton_pressed():
	if get_node("GaragePanel/MyGarageRect/VIN2").text == "-":
		return
	if get_node("GaragePanel/MyGarageRect/ForSale2").text == "No":
		return
	#get_node("DebugTextEdit").text = selectedCarYardPrice
	
	cancelSale(selectedGarageVIN)
	#sellCar(selectedGarageVIN, priceDero)



func _on_EnterRaceButton_pressed():
	if get_node("RacePanel/RaceRect/RaceNo2").text == "-":
		return
	if selectedGarageVIN == "":
		return
	
	var priceInt = get_node("BigMath").StrToInt64(selectedRaceFee) #convert string to int64 dero value
	enterRace(selectedGarageVIN, priceInt, selectedRaceNumber)



func _on_StartRaceButton_pressed():
	if get_node("RacePanel/RaceRect/RaceNo2").text == "-":
		return
	#Add check to make sure current block number > starting block before start function can be called, saves gas!
	startRace(selectedRaceNumber)
	



func _on_NewRaceButton_pressed():
	if get_node("RacePanel/NewRaceRect/StartEdit").text == "":
		return
	
	if selectedGarageVIN == "":
		return
		
	var startBlock = get_node("RacePanel/NewRaceRect/StartEdit").text
	if int(startBlock) == 0:
		return
	#to do: add check that start block falls within SC rules: in future and not too far ahead. Need to get raceFutureStartLimit from SC.
	
	#For testnet, fixed fee of 0.01 Dero to start or enter a race
	newRace(selectedGarageVIN, 10000000000, startBlock)


func _on_JoinButton_pressed():
	newName = get_node("StatsPanel/PlayerRect/NameEdit").text
	if newName == "":
		return
	if newName =="Enter Name":
		return
	if newName =="enter name":
		return
	getAddress() #so we can use in token generating function
	waitForAddress() #wait for the wallet to return address, start timer


func waitForAddress():
	wait_for_address_timer = Timer.new()
	add_child(wait_for_address_timer)
	wait_for_address_timer.connect("timeout", self, "_on_WaitForAddressTimer_timeout")
	wait_for_address_timer.set_wait_time(1.0)
	wait_for_address_timer.set_one_shot(true) # Make sure it loops
	wait_for_address_timer.start()

func _on_WaitForAddressTimer_timeout():
	if playerAccount != "": #we have an address, generate token then send join request
		generateToken()
		get_node("StatsPanel/PlayerRect/Joined2").text = "Joining..."
		var newToken = token
		joinGame(newToken)
		return
	waitForAddress() #still waiting, restart timer



func _on_ChangeNameButton_pressed():
	newName = get_node("StatsPanel/PlayerRect/NameEdit").text
	if newName == "":
		return
	if newName =="Enter Name":
		return
	if newName =="enter name":
		return
	joinGame("null") #'null' argument in SC 'Player' function just changes name, no new token storage


func _on_IndexesButton_pressed(): #Process RPC request
	getIndexes()
	

func _on_UpdateButton_pressed():
	
	get_node("StartPanel/StartRect/UpdateButton").text = "Updating..."
	get_node("DebugTextEdit").text = "Updating..."
	
	if mainSequeceActive == false: 
		#get_node("DebugTextEdit").text = "Updating - main sequence not active"
		updating = true #lock out main sequence until we are finished
		getVIN()
	
	#if main sequence is updating, wait one second and try again
	if mainSequeceActive == true:
		#get_node("DebugTextEdit").text = "Main sequence active, can't update"
		wait_to_update_timer = Timer.new()
		add_child(wait_to_update_timer)
		wait_to_update_timer.connect("timeout", self, "_on_WaitToUpdateTimer_timeout")
		wait_to_update_timer.set_wait_time(1.0)
		wait_to_update_timer.set_one_shot(true) # Make sure it loops
		wait_to_update_timer.start()

func _on_WaitToUpdateTimer_timeout():
	#try again!
	_on_UpdateButton_pressed()




func _on_TestTokenButton_pressed():
	saveToken()
	openToken()


func _on_TestButton_pressed(): #Process RPC request
	
		
	getVIN()
	
	
	
	
	
	#getIndexes()
	#getBig()
	#getRaces()
	#getModels()
	#getAddress()
	#getBlockHeight()
	#joinGame()
	#newRace()
	#buyCar()
	#enterRace()
	#startRace()
	#sellCar()
	#getPlayerNumber()
	#getPoints()
	#playerStats()
	#getCarsEntered()
	
	#playerNumberOfCars = 2
	#getPlayerCars()

func _on_GarageItemList_item_selected(index):
	var f = 0.0
	var f2 = 0.0
	var forSale = "No"
	
	#Update global VIN and price in case we want to buy
	selectedGarageVIN = garageVINArray[index]
	selectedGaragePrice = garagePriceArray[index]
	selectedGarageModelNumber = garageModelNumberArray[index]
	
	get_node("GaragePanel/MyGarageRect/Make2").text = garageMakeArray[index]
	get_node("GaragePanel/MyGarageRect/Model2").text = garageModelArray[index]
	get_node("GaragePanel/MyGarageRect/TopSpeed2").text = garageSpeedArray[index]
	f = float(garageAccelArray[index]) / 10
	get_node("GaragePanel/MyGarageRect/Acceleration2").text = str(f)
	get_node("GaragePanel/MyGarageRect/Handling2").text = garageHandlingArray[index]
	get_node("GaragePanel/MyGarageRect/VIN2").text = garageVINArray[index]
	f = float(garagePriceArray[index]) / 1000000000000
	f2 = stepify(f, 0.0001)
	get_node("GaragePanel/MyGarageRect/AskingPriceEdit").text = str(f2)
	f = float(garagePricePaidArray[index]) / 1000000000000
	f2 = stepify(f, 0.0001)
	get_node("GaragePanel/MyGarageRect/PricePaid2").text = str(f2)
	if garageForSaleArray[index] == "1":
		forSale = "Yes"
	get_node("GaragePanel/MyGarageRect/ForSale2").text = forSale 
	
	#Model number 1: Subaru Impreza STI GC8
	if selectedGarageModelNumber == "1":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://subaru-sti.png")
	if selectedGarageModelNumber == "2":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://nissan-gtr.png")
	if selectedGarageModelNumber == "3":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://lambo-huracan.png")
	if selectedGarageModelNumber == "4":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://ferrari-488.png")
	if selectedGarageModelNumber == "5":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://porche-gt3.png")
	if selectedGarageModelNumber == "6":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://dodge-hellcat.png")
	if selectedGarageModelNumber == "7":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://mclaren-p1.png")
	if selectedGarageModelNumber == "8":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://pagani-zonda.png")
	if selectedGarageModelNumber == "9":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://koenigsegg-ccxr.png")
	if selectedGarageModelNumber == "10":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://bugatti-veyron.png")
	if selectedGarageModelNumber == "11":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://ariel-atom.png")
	if selectedGarageModelNumber == "12":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://audi-r8.png")
	if selectedGarageModelNumber == "13":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://aston-dbs.png")
	if selectedGarageModelNumber == "14":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://lambo-aventador-s.png")
	if selectedGarageModelNumber == "15":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://ford-gt.png")
	if selectedGarageModelNumber == "16":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://ferrari-812.png")
	if selectedGarageModelNumber == "17":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://honda-nsx.png")
	if selectedGarageModelNumber == "18":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://dodge-viper.png")
	if selectedGarageModelNumber == "19":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://mercedes-amg-gtr.png")
	if selectedGarageModelNumber == "20":
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://corvette-zr1.png")
	if int(selectedGarageModelNumber) >20:
		get_node("GaragePanel/MyGarageRect/TextureRect").texture = load("res://not-available.png")
	
	

#Update GUI fields when car is selected on list
func _on_CarYardItemList_item_selected(index):
	var f = 0.0
	var f2 = 0.0
	
	#Update global VIN and price in case we want to buy
	selectedCarYardVIN = carYardVINArray[index]
	selectedCarYardPrice = carYardPriceArray[index]
	selectedCarYardModelNumber = carYardModelNumberArray[index]
	
	get_node("CarYardPanel/CarYardRect/Make2").text = carYardMakeArray[index]
	get_node("CarYardPanel/CarYardRect/Model2").text = carYardModelArray[index]
	get_node("CarYardPanel/CarYardRect/TopSpeed2").text = carYardSpeedArray[index]
	f = float(carYardAccelArray[index]) / 10
	get_node("CarYardPanel/CarYardRect/Acceleration2").text = str(f)
	get_node("CarYardPanel/CarYardRect/Handling2").text = carYardHandlingArray[index]
	get_node("CarYardPanel/CarYardRect/VIN2").text = carYardVINArray[index]
	f = float(carYardPriceArray[index]) / 1000000000000
	f2 = stepify(f, 0.0001)
	get_node("CarYardPanel/CarYardRect/Price2").text = str(f2)

	#Model number 1: Subaru Impreza STI GC8
	if selectedCarYardModelNumber == "1":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://subaru-sti.png")
	if selectedCarYardModelNumber == "2":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://nissan-gtr.png")
	if selectedCarYardModelNumber == "3":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://lambo-huracan.png")
	if selectedCarYardModelNumber == "4":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://ferrari-488.png")
	if selectedCarYardModelNumber == "5":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://porche-gt3.png")
	if selectedCarYardModelNumber == "6":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://dodge-hellcat.png")
	if selectedCarYardModelNumber == "7":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://mclaren-p1.png")
	if selectedCarYardModelNumber == "8":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://pagani-zonda.png")
	if selectedCarYardModelNumber == "9":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://koenigsegg-ccxr.png")
	if selectedCarYardModelNumber == "10":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://bugatti-veyron.png")
	if selectedCarYardModelNumber == "11":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://ariel-atom.png")
	if selectedCarYardModelNumber == "12":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://audi-r8.png")
	if selectedCarYardModelNumber == "13":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://aston-dbs.png")
	if selectedCarYardModelNumber == "14":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://lambo-aventador-s.png")
	if selectedCarYardModelNumber == "15":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://ford-gt.png")
	if selectedCarYardModelNumber == "16":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://ferrari-812.png")
	if selectedCarYardModelNumber == "17":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://honda-nsx.png")
	if selectedCarYardModelNumber == "18":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://dodge-viper.png")
	if selectedCarYardModelNumber == "19":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://mercedes-amg-gtr.png")
	if selectedCarYardModelNumber == "20":
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://corvette-zr1.png")
	if int(selectedCarYardModelNumber) >20:
		get_node("CarYardPanel/CarYardRect/TextureRect").texture = load("res://not-available.png")

func _on_RaceItemList_item_selected(index):
	var f = 0.0
	var f2 = 0.0
	
	#Update global race number and fee in case we want to enter
	
	selectedRaceFee = raceEntryFeeArray[index]
	selectedRaceNumber = raceNumberArray[index]
	
	get_node("RacePanel/RaceRect/RaceNo2").text = raceNumberArray[index]
	get_node("RacePanel/RaceRect/StartingIn2").text = raceStartingArray[index]
	f = float(raceEntryFeeArray[index]) / 1000000000000
	f2 = stepify(f, 0.0001)
	get_node("RacePanel/RaceRect/EntryFee2").text = str(f2)
	f = float(racePrizePotArray[index]) / 1000000000000
	f2 = stepify(f, 0.0001)
	#get_node("RacePanel/RaceRect/PrizePot2").text = str(f2)
	get_node("RacePanel/RaceRect/NumberOfRacers2").text = str(raceEntryCountArray[index])
	get_node("RacePanel/RaceRect/Entered2").text = raceEnteredArray[index]
	

#-----------------------------------------------Sequencing and saving functions------------------------------------

func generateToken():
	randomize()
	var i1 = randi() #generates random Uint32
	var accountComponent = ""
	if playerAccount != "": #use part of dero address to minimise chances of two identical tokens existing. Further checks in SC.
		accountComponent = playerAccount.right(80)
	
	token = str(i1) + accountComponent
	
	#save token number to disk, will be required every time game starts
	var save_token = File.new()
	save_token.open("user://deroracers.dat", File.WRITE)
	save_token.store_line(token) 
	save_token.close()


func saveSCError(SCError):
	var save_error = File.new()
	save_error.open("user://deroracerserror.dat", File.WRITE)
	save_error.store_line(SCError) 
	save_error.close()

func openSCErrorFile():
	var save_error = File.new()
	if not save_error.file_exists("user://deroracerserror.dat"):
		#get_node("DebugTextEdit").text = "Error, can't find saved application data!"
		saveSCError("")
		return ""
	save_error.open("user://deroracerserror.dat", File.READ)
	var contents = save_error.get_line()
	save_error.close()
	#get_node("DebugTextEdit").text = contents
	return contents
	
#-----------------------------------------------Game database functions-----------------------------------------

func updateGarage():
	#make sure DB's are populated
	if VINDBStatus == false:
		return
	if modelDBStatus == false:
		return
	if playerCarsDBStatus == false:
		return
	
	#clear list box
	get_node("GaragePanel/MyGarageRect/ItemList").clear()
	
	#clear all arrays
	garageVINArray.resize(0)
	garagePriceArray.resize(0)
	garagePricePaidArray.resize(0)
	garageModelNumberArray.resize(0)
	garageModelArray.resize(0)
	garageMakeArray.resize(0)
	garageSpeedArray.resize(0)
	garageAccelArray.resize(0)
	garageHandlingArray.resize(0)
	garageProductionRunArray.resize(0)
	garageForSaleArray.resize(0)
	garageItemListArray.resize(0)
	
	#declare temp variables
	var inc = 0
	var tempDBfield = ""
	var tempStatus = ""
	var tempVIN = ""
	var tempModelNo = ""
	var tempModel = ""
	var tempMake = ""
	var tempPrice = ""
	var tempPricePaid = ""
	var tempSpeed = ""
	var tempAccel = ""
	var tempHandling = ""
	var tempProductionRun = ""
	var tempForSale = ""
	var tempListDescription = ""
	var f = 0.0
	var f2 = 0.0
	var arrayLength = 0
	
	#Extract data from DB's into arrays for item list	
	for i in range(playerNumberOfCars): 
		inc = i + 1 #all SC databases in Dero Racers start with 1 when not empty
		#get the VIN
		tempDBfield = "player_" + playerNumber + "_car_" + str(inc)
		tempVIN = playerCarsDB[tempDBfield]
		
		if tempVIN != "0": #prevents crash if player has sold a car and has a 0 entry against player_x_car_x
			#make temporary strings for getting dictionary items:
			tempForSale = "VIN_" + tempVIN + "_forsale"
			tempModelNo = "VIN_" + tempVIN + "_model_number"
			tempPrice = "VIN_" + tempVIN + "_askingprice"
			tempPricePaid = "VIN_" + tempVIN + "_soldprice"
			tempModel = "model_number_" + VINDB[tempModelNo] + "_model"
			tempMake = "model_number_" + VINDB[tempModelNo] + "_make"
			tempSpeed = "model_number_" + VINDB[tempModelNo] + "_speed"
			tempAccel = "model_number_" + VINDB[tempModelNo] + "_acceleration"
			tempHandling = "model_number_" + VINDB[tempModelNo] + "_handling"
			tempProductionRun = "model_number_" + VINDB[tempModelNo] + "_productionrun"
			
			#extract from dictionaries (DB's) to arrays:			
			garageVINArray.append(tempVIN) #add VIN to array
			garageModelNumberArray.append(VINDB[tempModelNo]) #add model number to array
			garagePriceArray.append(VINDB[tempPrice]) #add price to array
			garagePricePaidArray.append(VINDB[tempPricePaid])
			garageModelArray.append(modelDB[tempModel])
			garageMakeArray.append(modelDB[tempMake])
			garageSpeedArray.append(modelDB[tempSpeed])
			garageAccelArray.append(modelDB[tempAccel])
			garageHandlingArray.append(modelDB[tempHandling])
			garageProductionRunArray.append(modelDB[tempProductionRun])
			garageForSaleArray.append(VINDB[tempForSale])
			
			#make description string for item list:
		
			tempListDescription = modelDB[tempMake] + " " + modelDB[tempModel] 
			
			garageItemListArray.append(tempListDescription)
			
	#get_node("DebugTextEdit").text = carYardItemListArray[0]
	
	#Display cars in item list
	arrayLength = garageItemListArray.size()
	for i in range(arrayLength):
		get_node("GaragePanel/MyGarageRect/ItemList").add_item(garageItemListArray[i],null,true)
		
	#get_node("GaragePanel/MyGarageRect/ItemList").select(0,true)
	
	updateRace()


func updateCarYard():
	#make sure DB's are populated
	if VINDBStatus == false:
		return
	if modelDBStatus == false:
		return
	
	#clear list box
	get_node("CarYardPanel/CarYardRect/ItemList").clear()
	
	#clear all arrays
	carYardVINArray.resize(0)
	carYardPriceArray.resize(0)
	carYardModelNumberArray.resize(0)
	carYardModelArray.resize(0)
	carYardMakeArray.resize(0)
	carYardSpeedArray.resize(0)
	carYardAccelArray.resize(0)
	carYardHandlingArray.resize(0)
	carYardProductionRunArray.resize(0)
	carYardItemListArray.resize(0)
	
	#declare temp variables
	var inc = 0
	var tempStatus = ""
	var tempModelNo = ""
	var tempModel = ""
	var tempMake = ""
	var tempPrice = ""
	var tempSpeed = ""
	var tempAccel = ""
	var tempHandling = ""
	var tempProductionRun = ""
	var tempListDescription = ""
	var f = 0.0
	var f2 = 0.0
	var arrayLength = 0
	
	#Extract data from DB's into arrays for item list	
	for i in range(VIN_count): 
		inc = i + 1 #all SC databases in Dero Racers start with 1 when not empty
		tempStatus = "VIN_" + str(inc) + "_forsale"
		if VINDB[tempStatus] == "1": #car is for sale, add to car yard
			#make temporary strings for getting dictionary items:
			tempModelNo = "VIN_" + str(inc) + "_model_number"
			tempPrice = "VIN_" + str(inc) + "_askingprice"
			tempModel = "model_number_" + VINDB[tempModelNo] + "_model"
			tempMake = "model_number_" + VINDB[tempModelNo] + "_make"
			tempSpeed = "model_number_" + VINDB[tempModelNo] + "_speed"
			tempAccel = "model_number_" + VINDB[tempModelNo] + "_acceleration"
			tempHandling = "model_number_" + VINDB[tempModelNo] + "_handling"
			tempProductionRun = "model_number_" + VINDB[tempModelNo] + "_productionrun"
			
			#extract from dictionaries (DB's) to arrays:			
			carYardVINArray.append(str(inc)) #add VIN to array
			carYardModelNumberArray.append(VINDB[tempModelNo]) #add model number to array
			carYardPriceArray.append(VINDB[tempPrice]) #add price to array
			carYardMakeArray.append(modelDB[tempMake])
			carYardModelArray.append(modelDB[tempModel])
			carYardSpeedArray.append(modelDB[tempSpeed])
			carYardAccelArray.append(modelDB[tempAccel])
			carYardHandlingArray.append(modelDB[tempHandling])
			carYardProductionRunArray.append(modelDB[tempProductionRun])
			
			#make description string for item list:
			f = float(VINDB[tempPrice]) / 1000000000000
			f2 = stepify(f, 0.01)
			tempListDescription = modelDB[tempMake] + " " + modelDB[tempModel] + " - Price: " + str(f2) + " Dero"
			
			carYardItemListArray.append(tempListDescription)
			
	#get_node("DebugTextEdit").text = carYardItemListArray[0]
	
	#Display cars in item list
	arrayLength = carYardItemListArray.size()
	for i in range(arrayLength):
		get_node("CarYardPanel/CarYardRect/ItemList").add_item(carYardItemListArray[i],null,true)
		
	#get_node("CarYardPanel/CarYardRect/ItemList").select(0,true)
	
	updateGarage()


func updateRace():
	#make sure DB's are populated
	if raceDBStatus == false:
		return
	if openRaceDBStatus == false:
		return
	
	#clear list box
	get_node("RacePanel/RaceRect/ItemList").clear()
	
	#clear all arrays
	raceNumberArray.resize(0)
	raceStartingArray.resize(0)
	raceEntryFeeArray.resize(0)
	racePrizePotArray.resize(0)
	raceEnteredArray.resize(0)
	raceEntryCountArray.resize(0)
	raceItemListArray.resize(0)
	
	#declare temp variables
	var inc = 0
	var tempStatus = ""
	var tempStarting = ""
	var tempFee = ""
	var tempStake = ""
	var tempEntries = ""
	var tempEntered = "No"
	var tempVIN = ""
	var carNum = 0
	var tempListDescription = ""
	var f = 0.0
	var f2 = 0.0
	var arrayLength = 0
	var entryCount = 0
	var entriesArray = []
	
	#Extract data from DB's into arrays for item list	
	for i in range(race_count): 
		tempEntered = "No" 
		inc = i + 1 #all SC databases in Dero Racers start with 1 when not empty
		tempStatus = "race_" + str(inc) + "_status"
		if raceDB[tempStatus] == "1" or raceDB[tempStatus] == "2": #race is open
			#make temporary strings for getting dictionary items:
			tempStarting = "race_" + str(inc) + "_startblock"
			tempFee = "race_" + str(inc) + "_fee"
			tempStake = "race_" + str(inc) + "_stake"
			tempEntries = "race_" + str(inc) + "_entries"
			
			#read entries (VINs) for this race into array for comparison with garage VINs
			entryCount = int(raceDB[tempEntries])
			entriesArray.resize(0)
			for n in range(entryCount):
				carNum = n + 1
				tempVIN = "race_" + str(inc) + "_car_" + str(carNum)
				entriesArray.append(openRaceDB[tempVIN])
			
			#make sure we own at least one car and garage DB is polulated:
			if playerNumberOfCars > 0:
				if playerCarsDBStatus == true:
					#compare VINs in garage with VINs entered in race
					for x in range(garageVINArray.size()):
						for y in range(entriesArray.size()):
							if garageVINArray[x] == entriesArray[y]:
								tempEntered = "Yes"
			
			
			#extract from dictionaries (DB's) to arrays:			
			raceNumberArray.append(str(inc))
			raceStartingArray.append(openRaceDB[tempStarting])
			raceEntryFeeArray.append(openRaceDB[tempFee])
			racePrizePotArray.append(openRaceDB[tempStake])
			raceEnteredArray.append(tempEntered)
			raceEntryCountArray.append(entryCount)
			
			
			#make description string for item list:
			f = float(openRaceDB[tempFee]) / 1000000000000
			f2 = stepify(f, 0.01)
			tempListDescription = "Race " + str(inc) + " - Fee: " +  str(f2) + " Dero - Starting block: " + openRaceDB[tempStarting]
			
			raceItemListArray.append(tempListDescription)
			
	
	#Display cars in item list
	arrayLength = raceItemListArray.size()
	for i in range(arrayLength):
		get_node("RacePanel/RaceRect/ItemList").add_item(raceItemListArray[i],null,true)
		
	#get_node("CarYardPanel/CarYardRect/ItemList").select(0,true)

	updateLeaderboard()
	

func updateLeaderboard():
	#make sure DB's are populated
	if pointsDBStatus == false:
		return
	
	#clear all arrays
	nameArray.resize(0)
	pointsArray.resize(0)
	leaderboardNameArray.resize(0)
	leaderboardPointsArray.resize(0)
		
	#declare temp variables
	var inc = 0
	var tempPoints = ""
	var tempName = ""
	var name1 = ""
	var name2 = ""
	var shortName = ""
	var points1 = 0
	var points2 = 0
	var arrayLength = 0
	
	#Extract data from DB into arrays 
	for i in range(player_count): 
		inc = i + 1 #all SC databases in Dero Racers start with 1 when not empty
		tempName = "player_" + str(inc) + "_name"
		tempPoints = "player_" + str(inc) + "_points"
		nameArray.append(pointsDB[tempName])
		pointsArray.append(int(pointsDB[tempPoints]))
	
	#sort arrays into order of points, high to low
	arrayLength = nameArray.size()
	inc = arrayLength - 1
	while inc >= 0:
		for i in range(inc):
			if pointsArray[i] < pointsArray[i+1]:
				points1 = pointsArray[i]
				points2 = pointsArray[i+1]
				name1 = nameArray[i]
				name2 = nameArray[i+1]
				pointsArray[i] = points2
				pointsArray[i+1] = points1
				nameArray[i] = name2
				nameArray[i+1] = name1
		inc -=1	
	
	
	if player_count <=10:
		for i in range(pointsArray.size()):
			shortName = nameArray[i].substr(0, 15) #limit displayed name length to xx characters
			leaderboardNameArray.append(shortName)
			leaderboardPointsArray.append(pointsArray[i])
	if player_count >10:
		for i in range(10):
			shortName = nameArray[i].substr(0, 15)
			leaderboardNameArray.append(shortName)
			leaderboardPointsArray.append(pointsArray[i])	
	
	if leaderboardNameArray.size() >0:
		get_node("StatsPanel/LeaderBoardRect/Position1").text = "1 - " + leaderboardNameArray[0]
		get_node("StatsPanel/LeaderBoardRect/Points1").text = str(leaderboardPointsArray[0]) + " Pts"
	if leaderboardNameArray.size() >1:
		get_node("StatsPanel/LeaderBoardRect/Position2").text = "2 - " + leaderboardNameArray[1] 
		get_node("StatsPanel/LeaderBoardRect/Points2").text = str(leaderboardPointsArray[1]) + " Pts"
	if leaderboardNameArray.size() >2:
		get_node("StatsPanel/LeaderBoardRect/Position3").text = "3 - " + leaderboardNameArray[2] 
		get_node("StatsPanel/LeaderBoardRect/Points3").text = str(leaderboardPointsArray[2]) + " Pts"
	if leaderboardNameArray.size() >3:
		get_node("StatsPanel/LeaderBoardRect/Position4").text = "4 - " + leaderboardNameArray[3] 
		get_node("StatsPanel/LeaderBoardRect/Points4").text = str(leaderboardPointsArray[3]) + " Pts"
	if leaderboardNameArray.size() >4:
		get_node("StatsPanel/LeaderBoardRect/Position5").text = "5 - " + leaderboardNameArray[4] 
		get_node("StatsPanel/LeaderBoardRect/Points5").text = str(leaderboardPointsArray[4]) + " Pts"
	if leaderboardNameArray.size() >5:
		get_node("StatsPanel/LeaderBoardRect/Position6").text = "6 - " + leaderboardNameArray[5] 
		get_node("StatsPanel/LeaderBoardRect/Points6").text = str(leaderboardPointsArray[5]) + " Pts"
	if leaderboardNameArray.size() >6:
		get_node("StatsPanel/LeaderBoardRect/Position7").text = "7 - " + leaderboardNameArray[6] 
		get_node("StatsPanel/LeaderBoardRect/Points7").text = str(leaderboardPointsArray[6]) + " Pts"
	if leaderboardNameArray.size() >7:
		get_node("StatsPanel/LeaderBoardRect/Position8").text = "8 - " + leaderboardNameArray[7] 
		get_node("StatsPanel/LeaderBoardRect/Points8").text = str(leaderboardPointsArray[7]) + " Pts"
	if leaderboardNameArray.size() >8:
		get_node("StatsPanel/LeaderBoardRect/Position9").text = "9 - " + leaderboardNameArray[8] 
		get_node("StatsPanel/LeaderBoardRect/Points9").text = str(leaderboardPointsArray[8]) + " Pts"
	if leaderboardNameArray.size() >9:
		get_node("StatsPanel/LeaderBoardRect/Position10").text = "10 - " + leaderboardNameArray[9] 
		get_node("StatsPanel/LeaderBoardRect/Points10").text = str(leaderboardPointsArray[9]) + " Pts"		
	
	get_node("DebugTextEdit").text = "Finished updating!"	
	#get_node("DebugTextEdit").text = "Arrays sorted"
	#for i in range(nameArray.size()):
	#	get_node("DebugTextEdit").text = get_node("DebugTextEdit").text + " " + str(pointsArray[i])


func updatePlayer():
	if playerStatsStatus == false:
		updateBalance()
		updateBlockHeight()
		return
	get_node("StatsPanel/PlayerRect/Points2").text = str(playerPoints)
	get_node("StatsPanel/PlayerRect/Name2").text = playerName
	get_node("StatsPanel/PlayerRect/LastRaceWon2").text = playerLastRaceWon
	get_node("StatsPanel/MessageRect/StatusMessage").text = playerMessage
		
	#we have a new error message, save to disk, print in error text edit
	if not playerErrorMessage == currentSCErrorMessage:
		currentSCErrorMessage = playerErrorMessage
		saveSCError(currentSCErrorMessage)
		get_node("SCErrorTextEdit").text = currentSCErrorMessage
	
		
	updateBalance()
	updateBlockHeight()

func updateBalance():
	var f = 0.0
	var f2 = 0.0
	#if balance == 0:
	#	get_node("StatsPanel/PlayerRect/Balance2").text = "0"
	#	get_node("StatsPanel/PlayerRect/Unlocked2").text = "0"
	#	return
	f = balance / 1000000000000
	f2 = stepify(f, 0.01)
	get_node("StatsPanel/PlayerRect/Balance2").text = str(f2)
	f = unlockedBalance / 1000000000000
	f2 = stepify(f, 0.01)
	get_node("StatsPanel/PlayerRect/Unlocked2").text = str(f2)


func updateBlockHeight():
	if blockHeight == 0:
		get_node("StatsPanel/PlayerRect/BlockHeight2").text = "0"
		mainSequeceActive = false #main sequence finished! Update functions now enabled.
		return
	get_node("StatsPanel/PlayerRect/BlockHeight2").text = str(blockHeight)
	mainSequeceActive = false #main sequence finished! Update functions now enabled.

#-----------------------------------------------Wallet RPC calls to SC-----------------------------------------


#-----------------------------------------------Get Player Number-----------------------------------------------
#Generates random number (token) and sends to SC. SC stores player number against this token. Token can then be looked up to
#get the player number, without issues converting deto / dero addresses etc. 

#NOT USED!!!!!!!!!!!!!!! FOR DELETION
func getPlayerNumber(): #Process RPC request
	#Generate random token string based on Godot internal generator, plus part of Dero address. 
	randomize()
	var i1 = randi() #generates random Uint32
	var accountComponent = ""
	if playerAccount != "":
		accountComponent = playerAccount.right(80)
	
	token = str(i1) + accountComponent
	
	#save token number to disk, will be required every time game starts
	var save_token = File.new()
	save_token.open("user://deroracers.dat", File.WRITE)
	save_token.store_line(token) 
	save_token.close()
		
	var message = get_node("JSONMethods").getPlayerNumberToJSON(SCID, token)
	getPlayerNumberToWallet(message)

#Called as thread to prevent game locking up during RPC call
func getPlayerNumberToWallet(message): #message must be a JSON string
	thread.start(self, "startGetPlayerNumberToWallet", message)
			 
func startGetPlayerNumberToWallet(message):
	y = get_node("RPC").RPCSend(message, walletURL, walletPort, walletPage)
	call_deferred("returnGetPlayerNumberToWallet")
	return y  #this value will be passed to ending_function

func returnGetPlayerNumberToWallet():
	var error = ""
	var RPCErrorFound = -1 
	var JSONErrorFound = -1
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
	#get_node("DebugTextEdit").text = result
	
	var transactionStatus = get_node("JSONMethods").getResultOrError(result)
	get_node("DebugTextEdit").text = transactionStatus + " Token number: " +token




#-----------------------------------------------Sell Car-----------------------------------------------

func sellCar(VIN, price): #Process RPC request
	var message = get_node("JSONMethods").sellToJSON(SCID, VIN, price)
	sellToWallet(message)

#Called as thread to prevent game locking up during RPC call
func sellToWallet(message): #message must be a JSON string
	thread.start(self, "startSellToWallet", message)
			 
func startSellToWallet(message):
	y = get_node("RPC").RPCSend(message, walletURL, walletPort, walletPage)
	call_deferred("returnSellToWallet")
	return y  #this value will be passed to ending_function

func returnSellToWallet():
	var error = ""
	var RPCErrorFound = -1 
	var JSONErrorFound = -1
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
	#get_node("DebugTextEdit").text = result	
	
	var transactionStatus = get_node("JSONMethods").getResultOrError(result)
	get_node("DebugTextEdit").text = transactionStatus




#-----------------------------------------------Cancel Sale-----------------------------------------------

func cancelSale(VIN): #Process RPC request
	var message = get_node("JSONMethods").cancelSaleToJSON(SCID, VIN)
	cancelSaleToWallet(message)

#Called as thread to prevent game locking up during RPC call
func cancelSaleToWallet(message): #message must be a JSON string
	thread.start(self, "startCancelSaleToWallet", message)
			 
func startCancelSaleToWallet(message):
	y = get_node("RPC").RPCSend(message, walletURL, walletPort, walletPage)
	call_deferred("returnCancelSaleToWallet")
	return y  #this value will be passed to ending_function

func returnCancelSaleToWallet():
	var error = ""
	var RPCErrorFound = -1 
	var JSONErrorFound = -1
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
	#get_node("DebugTextEdit").text = result	
	
	var transactionStatus = get_node("JSONMethods").getResultOrError(result)
	get_node("DebugTextEdit").text = transactionStatus




#-----------------------------------------------Start Race-----------------------------------------------

func startRace(raceNumber): #Process RPC request
	var message = get_node("JSONMethods").startRaceToJSON(SCID, raceNumber)
	startRaceToWallet(message)

#Called as thread to prevent game locking up during RPC call
func startRaceToWallet(message): #message must be a JSON string
	thread.start(self, "startStartRaceToWallet", message)
			 
func startStartRaceToWallet(message):
	y = get_node("RPC").RPCSend(message, walletURL, walletPort, walletPage)
	call_deferred("returnStartRaceToWallet")
	return y  #this value will be passed to ending_function

func returnStartRaceToWallet():
	var error = ""
	var RPCErrorFound = -1 
	var JSONErrorFound = -1
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
	#get_node("DebugTextEdit").text = result	
	
	var transactionStatus = get_node("JSONMethods").getResultOrError(result)
	get_node("DebugTextEdit").text = transactionStatus



#-----------------------------------------------Enter Race-----------------------------------------------

func enterRace(VIN, value, raceNumber): #Process RPC request
	var message = get_node("JSONMethods").enterRaceToJSON(SCID, VIN, value, raceNumber)
	enterRaceToWallet(message)

#Called as thread to prevent game locking up during RPC call
func enterRaceToWallet(message): #message must be a JSON string
	thread.start(self, "startEnterRaceToWallet", message)
			 
func startEnterRaceToWallet(message):
	y = get_node("RPC").RPCSend(message, walletURL, walletPort, walletPage)
	call_deferred("returnEnterRaceToWallet")
	return y  #this value will be passed to ending_function

func returnEnterRaceToWallet():
	var error = ""
	var RPCErrorFound = -1 
	var JSONErrorFound = -1
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
	#get_node("DebugTextEdit").text = result	
	
	var transactionStatus = get_node("JSONMethods").getResultOrError(result)
	get_node("DebugTextEdit").text = transactionStatus



#-----------------------------------------------Buy Car-----------------------------------------------

func buyCar(VIN, price): #Process RPC request
	var message = get_node("JSONMethods").buyToJSON(SCID, VIN, price)
	buyToWallet(message)

#Called as thread to prevent game locking up during RPC call
func buyToWallet(message): #message must be a JSON string
	thread.start(self, "startBuyToWallet", message)
			 
func startBuyToWallet(message):
	y = get_node("RPC").RPCSend(message, walletURL, walletPort, walletPage)
	call_deferred("returnBuyToWallet")
	return y  #this value will be passed to ending_function

func returnBuyToWallet():
	var error = ""
	var RPCErrorFound = -1 
	var JSONErrorFound = -1
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
	#get_node("DebugTextEdit").text = result	
	
	var transactionStatus = get_node("JSONMethods").getResultOrError(result)
	get_node("DebugTextEdit").text = transactionStatus


#-----------------------------------------------New Race-----------------------------------------------

func newRace(VIN, value, block): #Process RPC request
	var message = get_node("JSONMethods").newRaceToJSON(SCID, VIN, value, block)
	newRaceToWallet(message)

#Called as thread to prevent game locking up during RPC call
func newRaceToWallet(message): #message must be a JSON string
	thread.start(self, "startNewRaceToWallet", message)
			 
func startNewRaceToWallet(message):
	y = get_node("RPC").RPCSend(message, walletURL, walletPort, walletPage)
	call_deferred("returnNewRaceToWallet")
	return y  #this value will be passed to ending_function

func returnNewRaceToWallet():
	var error = ""
	var RPCErrorFound = -1 
	var JSONErrorFound = -1
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
	#get_node("DebugTextEdit").text = result	
	
	var transactionStatus = get_node("JSONMethods").getResultOrError(result)
	get_node("DebugTextEdit").text = transactionStatus


#-----------------------------------------------Join game / update name-----------------------------------------------

func joinGame(newToken): #Process RPC request
	var message = get_node("JSONMethods").joinToJSON(SCID, newName, newToken)
	joinToWallet(message)

#Called as thread to prevent game locking up during RPC call
func joinToWallet(message): #message must be a JSON string
	thread.start(self, "startJoinToWallet", message)
			 
func startJoinToWallet(message):
	y = get_node("RPC").RPCSend(message, walletURL, walletPort, walletPage)
	call_deferred("returnJoinToWallet")
	return y  #this value will be passed to ending_function

func returnJoinToWallet():
	var error = ""
	var RPCErrorFound = -1 
	var JSONErrorFound = -1
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
	#get_node("DebugTextEdit").text = result	
	
	var transactionStatus = get_node("JSONMethods").getResultOrError(result)
	get_node("DebugTextEdit").text = transactionStatus


#-----------------------------------------------Wallet RPC calls (non-SC)-----------------------------------------

#-----------------------------------------------Get account address-----------------------------------------------

func getAddress(): #Process RPC request
	var message = get_node("JSONMethods").getAddressToJSON()
	getAddressFromWallet(message)

#Called as thread to prevent game locking up during RPC call
func getAddressFromWallet(message): #message must be a JSON string
	thread.start(self, "startGetAddressFromWallet", message)
			 
func startGetAddressFromWallet(message):
	y = get_node("RPC").RPCSend(message, walletURL, walletPort, walletPage)
	call_deferred("returnGetAddressFromWallet")
	return y  #this value will be passed to ending_function

func returnGetAddressFromWallet():
	var error = ""
	var RPCErrorFound = -1 
	var JSONErrorFound = -1
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
	#get_node("DebugTextEdit").text = result	
	var address = get_node("JSONMethods").getAddressFromResponse(result)
	JSONErrorFound = address.find("error")
	
	if (JSONErrorFound >-1):  
		get_node("DebugTextEdit").text = address
		return
		
	else:
		#No errors, update address variable
		#get_node("DebugTextEdit").text = address
		playerAccount = address

	#getPlayerNumber()
	

#-----------------------------------------------Get account balance-----------------------------------------------

func getBalance(): #Process RPC request
	var message = get_node("JSONMethods").getBalanceToJSON()
	getBalanceFromWallet(message)

#Called as thread to prevent game locking up during RPC call
func getBalanceFromWallet(message): #message must be a JSON string
	thread2.start(self, "startGetBalanceFromWallet", message)
			 
func startGetBalanceFromWallet(message):
	y = get_node("RPC").RPCSend(message, walletURL, walletPort, walletPage)
	call_deferred("returnGetBalanceFromWallet")
	return y  #this value will be passed to ending_function

func returnGetBalanceFromWallet():
	var error = ""
	var RPCErrorFound = -1 
	var walletErrorFound = -1
	var JSONErrorFound = -1
	var result=thread2.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		walletRunning = false
		mainSequeceActive = false #so we don't lock out update functions
		return
	#get_node("DebugTextEdit").text = result	
	walletRunning = true
	#another check that wallet is running, the above does not always catch errors:
	var transactionStatus = get_node("JSONMethods").getResultOrError(result)
	walletErrorFound = transactionStatus.find("Error")
	if walletErrorFound >-1:
		get_node("DebugTextEdit").text = transactionStatus
		walletRunning = false
		mainSequeceActive = false #so we don't lock out update functions
		return
	walletRunning = true
	var d1 = get_node("JSONMethods").getBalanceFromResponse(result)
	
	if d1.has("error"): #if node returns error message
		var d2 = d1["error"]
		get_node("DebugTextEdit").text = d2["message"]
		mainSequeceActive = false #so we don't lock out update functions
		return
		
	if d1.has("result"):
		var d2 = d1["result"]
		#get_node("DebugTextEdit").text = "Balance: " + str(d2["balance"]) + "   Unlocked Balance: " + str(d2["unlocked_balance"])
		balance = d2["balance"]
		unlockedBalance = d2["unlocked_balance"]
		
		
	else:
		get_node("DebugTextEdit").text =  "Error, unexpected JSON from wallet"
		mainSequeceActive = false #so we don't lock out update functions
		return
	
	updatePlayer()



#-----------------------------------------------Daemon RPC calls---------------------------------------------


#-----------------------------------------------Get block height-----------------------------------------------

func getBlockHeight(): #Process RPC request
	var message = get_node("JSONMethods").getBlockHeightToJSON()
	getBlockHeightFromDaemon(message)

#Called as thread to prevent game locking up during RPC call
func getBlockHeightFromDaemon(message): #message must be a JSON string
	thread2.start(self, "startGetBlockHeightFromDaemon", message)
			 
func startGetBlockHeightFromDaemon(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, walletPage) #walletPage used as we are using json_rpc
	call_deferred("returnGetBlockHeightFromDaemon")
	return y  #this value will be passed to ending_function

func returnGetBlockHeightFromDaemon():
	var error = ""
	var RPCErrorFound = -1 
	var JSONErrorFound = -1
	var result=thread2.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		mainSequeceActive = false #so we don't lock out update functions
		return
	#get_node("DebugTextEdit").text = result	
	var height = get_node("JSONMethods").getBlockHeightFromResponse(result)
	JSONErrorFound = height.find("error")
	
	if (JSONErrorFound >-1):  
		#get_node("DebugTextEdit").text = height
		mainSequeceActive = false #so we don't lock out update functions
		return
		
	else:
		#No errors, update address variable
		#get_node("DebugTextEdit").text = height
		blockHeight = int(height)
		getBalance()


#-----------------------------------------------Is player joined-----------------------------------------------
#This function will need to be called before any game play can take place. 
func isPlayerJoined(): #Process RPC request
	
	var message = get_node("JSONMethods").mainIndexesToJSON(SCID, token)
	getIsPlayerJoined(message)

#Called as thread to prevent game locking up during RPC call
func getIsPlayerJoined(message): #message must be a JSON string
	thread.start(self, "startIsPlayerJoined", message)
			 
func startIsPlayerJoined(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, daemonPage)
	call_deferred("returnIsPlayerJoined")
	return y  #this value will be passed to ending_function

func returnIsPlayerJoined():
	var error = ""
	var RPCErrorFound = -1 
	var daemonErrorFound = -1
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
	
	#daemon not running, or token number invalid:
	var transactionStatus = get_node("JSONMethods").getResultOrErrorDaemon(result)
	daemonErrorFound = transactionStatus.find("Error")
	if daemonErrorFound >-1:
		get_node("DebugTextEdit").text = "Token not valid"
		return
		
	var sc_keys = get_node("JSONMethods").getKeys(result)
	if sc_keys.has("error"):
		get_node("DebugTextEdit").text = sc_keys["error"] #error during key extraction / JSON parsing etc
	else:
		#No errors, update main index variables so we can dig further into SC
		player_count = int(sc_keys["player_count"])
		VIN_count = int(sc_keys["VIN_count"])
		model_number_count = int(sc_keys["model_number_count"])
		race_count = int(sc_keys["race_count"])
		open_races = int(sc_keys["open_races"])
		var tokenNumber = "token_" + token
		if sc_keys.has(tokenNumber):
			playerNumber = sc_keys[tokenNumber]
			#get_node("DebugTextEdit").text = "Got indexes! Player Number = " + playerNumber
		



#-----------------------------------------------Get SC indexes-----------------------------------------------
#This function will need to be called before any game play can take place. 
func getIndexes(): #Process RPC request
	
	var message = get_node("JSONMethods").mainIndexesToJSON(SCID, token)
	getSCIndexes(message)

#Called as thread to prevent game locking up during RPC call
func getSCIndexes(message): #message must be a JSON string
	thread2.start(self, "startSCIndexes", message)
			 
func startSCIndexes(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, daemonPage)
	call_deferred("returnSCIndexes")
	return y  #this value will be passed to ending_function

func returnSCIndexes():
	var error = ""
	var RPCErrorFound = -1 
	var daemonErrorFound = -1
	var result=thread2.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		mainSequeceActive = false #so we don't lock out update functions
		return
	
	#another check that daemon is running, the above does not always catch errors:
	var transactionStatus = get_node("JSONMethods").getResultOrErrorDaemon(result)
	daemonErrorFound = transactionStatus.find("Error")
	if daemonErrorFound >-1:
		get_node("DebugTextEdit").text = transactionStatus
		daemonRunning = false
		mainSequeceActive = false #so we don't lock out update functions
		return
	daemonRunning = true
	
	var sc_keys = get_node("JSONMethods").getKeys(result)
	if sc_keys.has("error"):
		get_node("DebugTextEdit").text = sc_keys["error"] #error during key extraction / JSON parsing etc
		mainSequeceActive = false #so we don't lock out update functions
		return
	else:
		#No errors, update main index variables so we can dig further into SC
		player_count = int(sc_keys["player_count"])
		VIN_count = int(sc_keys["VIN_count"])
		model_number_count = int(sc_keys["model_number_count"])
		race_count = int(sc_keys["race_count"])
		open_races = int(sc_keys["open_races"])
		var tokenNumber = "token_" + token
		if sc_keys.has(tokenNumber):
			playerNumber = sc_keys[tokenNumber]
			#get_node("DebugTextEdit").text = "Got indexes! Player Number = " + playerNumber
			#Now get player stats
			playerStats()
		
		if not sc_keys.has(tokenNumber):
			#playerNumber = sc_keys[tokenNumber]
			get_node("DebugTextEdit").text = "Error, player number not found"
			playerStats()
			
		#DO NOT DELETE! The following can be used on main net, when deto / dero address conversion not an issue
		#var player_address = "player_" + playerAccount
		#if playerAccount != "":
		#	if sc_keys.has(player_address):
		#		if sc_keys[player_address] != "":
		#			get_node("DebugTextEdit").text = sc_keys[player_address]
		#			playerJoined = true
		#		else:
		#			get_node("DebugTextEdit").text = "Player has not joined game"
		#			playerJoined = false
		#else:
		#	get_node("DebugTextEdit").text = "Player has not joined game"
		#	playerJoined = false


#-----------------------------------------------Get Player Stats-----------------------------------------------
#This function will need to be called before any game play can take place. 
func playerStats(): #Process RPC request
	if playerNumber == "":
		if pressStartMessageDisplayed == false:
			get_node("DebugTextEdit").text = "Please press Start button to start game"
			pressStartMessageDisplayed = true #so we don't keep displaying the message
		getBlockHeight()
		mainSequeceActive = false #so we don't lock out update functions
		return
	var message = get_node("JSONMethods").buildKeysPlayerStats(SCID, playerNumber)
	getPlayerStats(message)

#Called as thread to prevent game locking up during RPC call
func getPlayerStats(message): #message must be a JSON string
	thread2.start(self, "startPlayerStats", message)
			 
func startPlayerStats(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, daemonPage)
	call_deferred("returnPlayerStats")
	return y  #this value will be passed to ending_function

func returnPlayerStats():
	var error = ""
	var RPCErrorFound = -1 
	var result=thread2.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		mainSequeceActive = false #so we don't lock out update functions
		return
		
	var sc_keys = get_node("JSONMethods").getKeys(result)
	if sc_keys.has("error"):
		get_node("DebugTextEdit").text = sc_keys["error"] #error during key extraction / JSON parsing etc
		mainSequeceActive = false #so we don't lock out update functions
		return
	else:
		#No errors, update main index variables so we can dig further into SC
		var points = "player_" + playerNumber + "_points"
		var name = "player_" + playerNumber + "_name"
		var numberofcars = "player_" + playerNumber + "_numberofcars"
		var playermessage = "player_" + playerNumber + "_message"
		var playererror = "player_" + playerNumber + "_error"
		var lastracewon = "player_" + playerNumber + "_last_race_won"
		
		playerPoints = int(sc_keys[points])
		playerName = sc_keys[name] 
		playerNumberOfCars = int(sc_keys[numberofcars])
		playerMessage = sc_keys[playermessage]
		playerErrorMessage = sc_keys[playererror]
		playerLastRaceWon = sc_keys[lastracewon]
		
		playerStatsStatus = true
		if playerName != "":
			get_node("StatsPanel/PlayerRect/Joined2").text = "Yes"
			playerJoined = true
		
		var printMessage = "Points: " + str(playerPoints) + " Name: " + playerName + " Num. Cars: " + str(playerNumberOfCars) + " Message: " + playerMessage + " Error message: " + playerErrorMessage + "Last race won: " + playerLastRaceWon
		#get_node("DebugTextEdit").text = printMessage
		
		
		getPlayerCars()


#-----------------------------------------------Get VIN DB-----------------------------------------------
#Get all VIN fields. May not all be required?
#Called as thread to prevent game locking up during RPC call

func getVIN(): #Process RPC request
	#TO DO: CATCH ERROR (VIN_count ==0 etc)
	var message = get_node("JSONMethods").buildKeysVIN(SCID, VIN_count)
	getVINDB(message)

func getVINDB(message): #message must be a JSON string
	thread.start(self, "startGetVIN", message)
			 
func startGetVIN(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, daemonPage)
	call_deferred("returnGetVIN")
	return y  #this value will be passed to ending_function

func returnGetVIN():
	var error = ""
	var RPCErrorFound = -1 
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
		
	var sc_keys = get_node("JSONMethods").getKeys(result)
	if sc_keys.has("error"):
		get_node("DebugTextEdit").text = sc_keys["error"] #error during key extraction / JSON parsing etc
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
	else:
		#No errors, we now have a dictionary of all VIN details
		#get_node("DebugTextEdit").text = sc_keys["VIN_1_owner"]
		VINDB = sc_keys
		VINDBStatus = true
		get_node("DebugTextEdit").text = "Success, retrieved VIN database from daemon, now getting models..."
		
		getModels()

#-----------------------------------------------Get Race DB; this is made up of two RPC calls------------------------------
#Called as thread to prevent game locking up during RPC call

func getRaces(): #Process RPC request
	var message = get_node("JSONMethods").buildKeysRace(SCID, race_count)
	getRaceDB(message)

func getRaceDB(message): #message must be a JSON string
	thread.start(self, "startGetRace", message)
			 
func startGetRace(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, daemonPage)
	call_deferred("returnGetRace")
	return y  #this value will be passed to ending_function

func returnGetRace():
	var error = ""
	var RPCErrorFound = -1 
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
		
	var sc_keys = get_node("JSONMethods").getKeys(result)
	if sc_keys.has("error"):
		get_node("DebugTextEdit").text = sc_keys["error"] #error during key extraction / JSON parsing etc
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
	else:
		#No errors, we now have a dictionary of all race details
		#get_node("DebugTextEdit").text = sc_keys["race_5_status"]
		get_node("DebugTextEdit").text = "Got DB of all race status and number of entries! Now getting details for open races..."
		raceDB = sc_keys
		raceDBStatus = true
		
		getOpenRaces()

func getOpenRaces(): #Process RPC request
	if raceDBStatus == false:
		return
	var message = get_node("JSONMethods").buildKeysOpenRaces(SCID, race_count, raceDB)
	getOpenRaceDB(message)

func getOpenRaceDB(message): #message must be a JSON string
	thread.start(self, "startGetOpenRace", message)
			 
func startGetOpenRace(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, daemonPage)
	call_deferred("returnGetOpenRace")
	return y  #this value will be passed to ending_function

func returnGetOpenRace():
	var error = ""
	var RPCErrorFound = -1 
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
		
	var sc_keys = get_node("JSONMethods").getKeys(result)
	if sc_keys.has("error"):
		get_node("DebugTextEdit").text = sc_keys["error"] #error during key extraction / JSON parsing etc
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
	else:
		#No errors, we now have a dictionary of all race details
		#get_node("DebugTextEdit").text = sc_keys["race_2_car_1"]
		get_node("DebugTextEdit").text = "Got DB of all details for open races!"
		openRaceDB = sc_keys
		openRaceDBStatus = true
		
		#var testArray = openRaceDB.keys()
		#for i in range (testArray.size()):
		#	get_node("DebugTextEdit").text = get_node("DebugTextEdit").text + testArray[i]
		
		#get_node("DebugTextEdit").text = openRaceDB["race_5_car_1"] #openRaceDB["race_5_stake"] 
		#updateRace()
		getPoints()
#-----------------------------------------------Get Model DB-----------------------------------------------
#Called as thread to prevent game locking up during RPC call

func getModels(): #Process RPC request
	var message = get_node("JSONMethods").buildKeysModels(SCID, model_number_count)
	getModelDB(message)

func getModelDB(message): #message must be a JSON string
	thread.start(self, "startGetModel", message)
			 
func startGetModel(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, daemonPage)
	call_deferred("returnGetModel")
	return y  #this value will be passed to ending_function

func returnGetModel():
	var error = ""
	var RPCErrorFound = -1 
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
		
	var sc_keys = get_node("JSONMethods").getKeys(result)
	if sc_keys.has("error"):
		get_node("DebugTextEdit").text = sc_keys["error"] #error during key extraction / JSON parsing etc
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
	else:
		#No errors, we now have a dictionary of all VIN details
		#get_node("DebugTextEdit").text = sc_keys["model_number_1_model"]
		modelDB = sc_keys
		modelDBStatus = true
		get_node("DebugTextEdit").text = "Success, retrieved model database from daemon, now updating car yard..."

		#updateCarYard()
		getRaces()
#-----------------------------------------------Get Player Points DB-----------------------------------------------
#Called as thread to prevent game locking up during RPC call

func getPoints(): #Process RPC request
	if player_count == 0:
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
	var message = get_node("JSONMethods").buildKeysPoints(SCID, player_count)
	getPointsDB(message)

func getPointsDB(message): #message must be a JSON string
	thread.start(self, "startGetPoints", message)
			 
func startGetPoints(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, daemonPage)
	call_deferred("returnGetPoints")
	return y  #this value will be passed to ending_function

func returnGetPoints():
	var error = ""
	var RPCErrorFound = -1 
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
		
	var sc_keys = get_node("JSONMethods").getKeys(result)
	if sc_keys.has("error"):
		get_node("DebugTextEdit").text = sc_keys["error"] #error during key extraction / JSON parsing etc
		updating = false #set updating to false, so main sequence is not locked out
		get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
		return
	else:
		#No errors, we now have a dictionary of all points and names
		
		get_node("DebugTextEdit").text = "Got player points DB!"
		#var tempArray = sc_keys.keys()
		#for i in range(tempArray.size()):
		#	get_node("DebugTextEdit").text = get_node("DebugTextEdit").text + tempArray[i]
		#get_node("DebugTextEdit").text = get_node("DebugTextEdit").text + "player_5_points: " + sc_keys["player_5_points"]
		pointsDB = sc_keys
		pointsDBStatus = true
	updating = false #updating sequence has finished, set updating to false, so main sequence is not locked out
	get_node("StartPanel/StartRect/UpdateButton").text = "Update Car Yard, Open Races, My Garage!"
	updateCarYard()
	
	

#-----------------------------------------------Get Player Cars DB-----------------------------------------------
#Called as thread to prevent game locking up during RPC call

func getPlayerCars(): #Process RPC request
	#if playerNumberOfCars == 0:
	#	mainSequeceActive = false #so we don't lock out update functions
	#	return
	var message = get_node("JSONMethods").buildKeysPlayerCars(SCID, playerNumber, playerNumberOfCars)
	getPlayerCarsDB(message)

func getPlayerCarsDB(message): #message must be a JSON string
	thread2.start(self, "startGetPlayerCars", message)
			 
func startGetPlayerCars(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, daemonPage)
	call_deferred("returnGetPlayerCars")
	return y  #this value will be passed to ending_function

func returnGetPlayerCars():
	var error = ""
	var RPCErrorFound = -1 
	var result=thread2.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		mainSequeceActive = false #so we don't lock out update functions
		return
		
	var sc_keys = get_node("JSONMethods").getKeys(result)
	if sc_keys.has("error"):
		get_node("DebugTextEdit").text = sc_keys["error"] #error during key extraction / JSON parsing etc
		mainSequeceActive = false #so we don't lock out update functions
		return
	else:
		#No errors, we now have a dictionary of all VIN details
		#get_node("DebugTextEdit").text = sc_keys["player_5_car_1"]
		#get_node("DebugTextEdit").text = "Got DB of player cars!"
		playerCarsDB = sc_keys
		playerCarsDBStatus = true
	
	getBlockHeight()

#-----------------------------------------------Get DB of Cars Entered in Race-----------------------------------------------
#Called as thread to prevent game locking up during RPC call

func getCarsEntered(): #Process RPC request
	var message = get_node("JSONMethods").buildKeysCarsEntered(SCID, "4", "2") #race number, number of entries
	getCarsEnteredDB(message)

func getCarsEnteredDB(message): #message must be a JSON string
	thread.start(self, "startGetCarsEntered", message)
			 
func startGetCarsEntered(message):
	y = get_node("RPC").RPCSend(message, daemonURL, daemonPort, daemonPage)
	call_deferred("returnGetCarsEntered")
	return y  #this value will be passed to ending_function

func returnGetCarsEntered():
	var error = ""
	var RPCErrorFound = -1 
	var result=thread.wait_to_finish()  #result is the response returned from the RPC function, either JSON string or error
	
	#First check for a RPC error (e.g. wallet / daemon not running)
	RPCErrorFound = result.find("RPC Error")
	if (RPCErrorFound >-1):  
		get_node("DebugTextEdit").text = result
		return
		
	var sc_keys = get_node("JSONMethods").getKeys(result)
	if sc_keys.has("error"):
		get_node("DebugTextEdit").text = sc_keys["error"] #error during key extraction / JSON parsing etc
	else:
		#No errors, we now have a dictionary of all VIN details
		get_node("DebugTextEdit").text = sc_keys["race_4_car_2"]



