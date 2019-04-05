/*
Dero Racers - Alpha Release - Version 1 - For Dero Stargate Competition

https://github.com/Lebowski1234/dero-racers

by thedudelebowski


*/


// This function is used to initialize parameters during install time
Function Initialize() Uint64
10 PRINTF "Contract initialized!"
20 setupIndexes()
30 setupBlockheights()
40 setupLimits()
50 STORE("owner", SIGNER())
60 player(SIGNER(), "The Boss", "12345") //setup contract owner as player 1!
70 RETURN 0
End Function


//setupIndexes: setup main database indexes
Function setupIndexes() Uint64
10 PRINTF "Setting up indexes..."
20 STORE("player_count", 0)
30 STORE("VIN_count", 0)
40 STORE("model_number_count", 0)
50 STORE("race_count", 0)
60 STORE("open_races", 0) //for enforcing limit on number of open races
70 RETURN 0
End Function


//setupBlockheights: hopefully this won't be required in main net implementation!
Function setupBlockheights() Uint64
10 STORE("scblockheightPlayer", BLOCK_HEIGHT()) 
20 STORE("sctopoheightPlayer", BLOCK_TOPOHEIGHT())
30 STORE("scblockheightNewModel", BLOCK_HEIGHT()) 
40 STORE("sctopoheightNewModel", BLOCK_TOPOHEIGHT())
50 STORE("scblockheightMint", BLOCK_HEIGHT()) 
60 STORE("sctopoheightMint", BLOCK_TOPOHEIGHT())
70 STORE("scblockheightNewRace", BLOCK_HEIGHT()) 
80 STORE("sctopoheightNewRace", BLOCK_TOPOHEIGHT())
90 STORE("scblockheightEnterRace", BLOCK_HEIGHT()) 
100 STORE("sctopoheightEnterRace", BLOCK_TOPOHEIGHT())
110 STORE("scblockheightStartRace", BLOCK_HEIGHT()) 
120 STORE("sctopoheightStartRace", BLOCK_TOPOHEIGHT())
130 STORE("scblockheightSell", BLOCK_HEIGHT()) 
140 STORE("sctopoheightSell", BLOCK_TOPOHEIGHT())
150 STORE("scblockheightBuy", BLOCK_HEIGHT()) 
160 STORE("sctopoheightBuy", BLOCK_TOPOHEIGHT())
170 STORE("scblockheightCancelSale", BLOCK_HEIGHT()) 
180 STORE("sctopoheightCancelSale", BLOCK_TOPOHEIGHT())
190 RETURN 0
End Function


//setupLimits: initial setup of hard limits. These can be changed by the owner later, to respond to abuse, changing game popularity etc. 
Function setupLimits() Uint64
10 STORE("minimumStake", 10000000000) //0.01 Dero nominal fee to start a race
20 STORE("blocksBetweenBuys", 1) //Player can only purchase a car once every 1 blocks
30 STORE("raceFutureStartLimit", 3600) //Race start time must be <3600 blocks into the future, approximately 12 hours
40 STORE("enforceRaceLimit", 0) //If set to 1, then a player can only start 1 race at a time. To start another, the first race must finish. Does not apply to contract owner.
50 STORE("maxEntrants", 10) //Maximum number of entries in one race.
60 STORE("maxRaces", 49) //Maximum number of open races -1, e.g. maxRaces = 19, maximum number of open races = 20.
70 STORE("raceFactor", 50000)//For calculating winner. 
80 STORE("noWinningsMode", 1)//When set to 1, players accumulate points, but do not win money. Due to DVM bug. Can be set to 0 to re-enable winning money in a future version. 
100 RETURN 0
End Function


//ChangeSettings: For owner to update game settings. Ideally would be called by owner UI that loads existing settings first, to prevent accidentally changing values when only one setting is being updated. 
Function ChangeSettings(minimumStake Uint64, blocksBetweenBuys Uint64, raceFutureStartLimit Uint64, enforceRaceLimit Uint64, maxEntrants Uint64, maxRaces Uint64, raceFactor Uint64, noWinningsMode Uint64) Uint64
10 IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 
20 RETURN 1 //signer is not the contract owner, exit
30 STORE("minimumStake", minimumStake) 
40 STORE("blocksBetweenBuys", blocksBetweenBuys) 
50 STORE("raceFutureStartLimit", raceFutureStartLimit) 
60 STORE("enforceRaceLimit", enforceRaceLimit) 
70 STORE("maxEntrants", maxEntrants) 
80 STORE("maxRaces", maxRaces) 
90 STORE("raceFactor", raceFactor)
100 STORE("noWinningsMode", noWinningsMode) 
110 RETURN 0
End Function


//Player: Public entrypoint for new player setup, excluding Player 1 (contract owner) initial setup. 
Function Player(name String, token String) Uint64
10 IF blockCheck("Player") == 0 THEN GOTO 30 //In this case, 0 = true, as blockCheck must return 0 to store values within function. 
20 RETURN 0
30 IF token != "" THEN GOTO 60 //Token value not defined, exit
40 PRINTF "Error, token blank!"
50 RETURN 1
60 IF EXISTS("token_"+token) THEN GOTO 80 //Token exists, we don't want to overwrite. Exit.
70 GOTO 100
80 PRINTF "Error, token exists already!"
90 RETURN 1
100 player(SIGNER(), name, token)
110 RETURN 0
End Function


//player: Set up new player. Check if exists already, if so update name. If not, store player id (player_+signer address), player number, player name, points (0), number of cars owned (0), last purchase block number (0). If name is "", return with error.  
Function player(signer String, name String, token String) Uint64
10 DIM player_count, player_number as Uint64 
20 IF name == "" THEN GOTO 230 //name is blank, exit
30 IF token == "null" THEN GOTO 50 //change name but don't update token
40 GOTO 80
50 IF EXISTS("player_"+signer) THEN GOTO 200 //change name but don't update token
60 PRINTF "Player not registered, name change not possible!" 
70 RETURN 1
80 IF EXISTS("player_"+signer) THEN GOTO 100 //Player exists, new token number received. So player GUI must want to save new token for verification.
90 GOTO 130 //Player does not exist, set up new player and token.
100 LET player_number = LOAD("player_"+signer) //load player number of signer
110 storeNewToken(token, player_number) 
120 RETURN 0
130 LET player_count = LOAD("player_count") +1 //increment player_count so we can store new player
140 STORE("player_"+signer, player_count) //allows cross referencing
150 STORE("player_number_"+player_count, signer) //for getting address from player number
160 STORE("player_"+player_count+"_name", name)
170 STORE("player_count", player_count)
175 storeNewToken(token, player_count)
180 setupPlayerParams(player_count) //setup empty data holders for new player
190 RETURN 0 //new player setup complete
200 LET player_number = LOAD("player_"+signer) //load player number of signer so we can change name
210 STORE("player_"+player_number+"_name", name) //change name
220 RETURN 0
230 IF EXISTS("player_"+signer) THEN GOTO 260 //If player exists, store error for GUI
240 PRINTF "Name cannot be blank"
250 RETURN 1
260 error("Error, name cannot be blank", signer)
270 RETURN 0
End Function


//storeNewToken: Used by GUI to store a random string (token) as a DB entry, with player number as data if exists. Gets around problem of automatic conversion of deto to dero address formats in SC, preventing lookup of stored testnet address by GUI. GUI can then lookup random number and get player number. Should not be required in main net version.
Function storeNewToken(token String, playerNumber Uint64) Uint64
10 STORE("token_"+token, playerNumber)
20 PRINTF "New token stored with player number!"
30 RETURN 0
End Function


//setupPlayerParams: setup empty data holders for new player
Function setupPlayerParams(x Uint64) Uint64
10 STORE("player_"+x+"_points", 0)
20 STORE("player_"+x+"_numberofcars", 0)
30 STORE("player_"+x+"_lastpurchaseblock", 0)
40 STORE("player_"+x+"_openraces", 0) //if enforceRaceLimit if set to 1, then this will be set to 1 whenever a player creates a race, and back to 0 when the race has finished. 
50 STORE("player_"+x+"_car_1", 0) //first garage space
60 STORE("player_"+x+"_message", "Joined the game!") //to be updated as races won, cars bought, etc
70 STORE("player_"+x+"_error", "") //to be updated with error messages whenever something goes wrong
80 STORE("player_"+x+"_last_race_won", 0) //to be updated after every race win
90 STORE("player_"+x+"_banned", 0) //player can be banned - up to contract owner to decide and publish rules! 
100 RETURN 0
End Function



//Warn: Player can be warned for bad behaviour by changing name, stripping points (the only bad behaviour likely is if a player posts offensive messages on leaderboard by changing name, hence delete points to remove from leaderboard). 
Function Warn(playerNumber Uint64, stripPoints Uint64, name String, message String) Uint64
10 IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 
20 RETURN 1 //signer is not the contract owner, exit
30 IF stripPoints == 0 THEN GOTO 50 //set stripPoints to >0 to reset player points to 0. No option for setting points to a particular number, as could be considered unfair. i.e. contract owner could manipulate points.
40 STORE("player_"+playerNumber+"_points", 0)
50 STORE("player_"+playerNumber+"_name", name)
60 STORE("player_"+playerNumber+"_message", message) //send a warning message
70 PRINTF "Warning complete!"
80 RETURN 0
End Function


//Ban: Contract owner can ban player to prevent from entering races. Player can still buy and sell cars (not fair to remove access to digital property). 
Function Ban(playerNumber Uint64, banned Uint64) Uint64
10 IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 
20 RETURN 1 //signer is not the contract owner, exit
30 STORE("player_"+playerNumber+"_banned", banned) //set to 1 for ban, 0 for unban
40 IF banned == 1 THEN GOTO 60
50 STORE("player_"+playerNumber+"_message", "Player ban lifted, you can resume racing") 
55 RETURN 0
60 STORE("player_"+playerNumber+"_message", "Player banned") 
70 PRINTF "Ban complete!"
80 RETURN 0
End Function


//NewModel: Call before minting new cars. Called by contract owner. Check owner is signer. Increments model number, stores data. Productionrun is a hard limit on how many can be minted. Prevents profiteering by contract owner!  
Function NewModel(make String, model String, speed Uint64, acceleration Uint64, handling Uint64, productionrun Uint64) Uint64
10 IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 21 
20 RETURN 1 //signer is not the contract owner, exit
21 IF blockCheck("NewModel") == 0 THEN GOTO 30 //In this case, 0 = true, as blockCheck must return 0 to store values within function. 
22 RETURN 0
30 DIM model_number_count as Uint64
40 LET model_number_count = LOAD("model_number_count")
80 LET model_number_count = model_number_count +1
90 setupNewModel(model_number_count, make, model, speed, acceleration, handling, productionrun)
100 STORE("model_number_count", model_number_count)
105 PRINTF "New model successful!"
110 RETURN 0
End Function


//setupNewModel: called after checks have passed. Store model details.
Function setupNewModel(model_number Uint64, make String, model String, speed Uint64, acceleration Uint64, handling Uint64, productionrun Uint64) Uint64
10 DIM score as Uint64
14 STORE("model_number_"+model_number, model_number)
15 STORE("model_number_"+model_number+"_make", make)
20 STORE("model_number_"+model_number+"_model", model)
30 STORE("model_number_"+model_number+"_speed", speed)
40 STORE("model_number_"+model_number+"_acceleration", acceleration)
50 STORE("model_number_"+model_number+"_handling", handling)
60 STORE("model_number_"+model_number+"_productionrun", productionrun)
70 STORE("model_number_"+model_number+"_qtyminted", 0)
80 LET score = speed * (100 - acceleration) * handling //do this total score calc here, to reduce LOAD calls when picking winner
90 STORE("model_number_"+model_number+"_score", score)
100 RETURN 0
End Function


//Mint: Mint new cars. Called by contract owner. Check owner is signer. Check quantity >0, <limit (TBC). Check modelno exists. Check production run for this model will not be exceeded. Start loop, increment VIN and assign to each car. Store model number, VIN, owner, sold price (0), for sale (yes or no), asking price (0 if not for sale). Update cars owned for owner. Need to restrict qty to limit evaluation etc.  
Function Mint(modelno Uint64, quantity Uint64, forsale Uint64, price Uint64) Uint64
10 IF ADDRESS_RAW(LOAD("owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 21 
20 RETURN 1 //signer is not the contract owner, exit
21 IF blockCheck("Mint") == 0 THEN GOTO 30 //In this case, 0 = true, as blockCheck must return 0 to store values within function. 
22 RETURN 0
30 IF mintChecks(modelno, quantity) == 1 THEN GOTO 50
40 RETURN 1 //checks failed
50 mintCars(SIGNER(), modelno, quantity, forsale, price) //checks passed, mint new cars
60 DIM existingqty, newqty as Uint64 //now we need to update modelno qty
70 LET existingqty = LOAD("model_number_"+modelno+"_qtyminted")
80 LET newqty = existingqty + quantity
90 STORE("model_number_"+modelno+"_qtyminted", newqty)
95 PRINTF "Mint successful!"
100 RETURN 0
End Function


//mintCars: mint new cars
Function mintCars(signer String, modelno Uint64, quantity Uint64, forsale Uint64, price Uint64) Uint64
10 DIM VIN_count, inc as Uint64
20 LET VIN_count = LOAD("VIN_count") +1 
25 LET inc = 1
30 STORE("VIN_"+VIN_count, VIN_count) //setup and store new VIN number
40 STORE("VIN_"+VIN_count+"_model_number", modelno) //store model number
50 STORE("VIN_"+VIN_count+"_forsale", forsale) //store forsale status: 1 = for sale, 0 = not for sale
60 STORE("VIN_"+VIN_count+"_askingprice", price)
70 STORE("VIN_"+VIN_count+"_soldprice", 0)
80 STORE("VIN_"+VIN_count+"_owner", signer)
90 updateCarsOwnedMint(VIN_count)
100 IF inc == quantity THEN GOTO 140 //////Finished minting new cars
110 LET VIN_count = VIN_count + 1
120 LET inc = inc + 1
130 GOTO 30
140 STORE("VIN_count", VIN_count)
150 RETURN 0
End Function


//updateCarsOwnedMint: update owner car list during minting process. Separate to other update function, as there is no buyer. Reason function exists is so that GUI does not have to search through entire list of VIN numbers (could be >10k in real game!) to display garage. 
Function updateCarsOwnedMint(VIN Uint64) Uint64
10 DIM numberofcars, garageSlot as Uint64
20 LET numberofcars = LOAD("player_1_numberofcars") +1 //Contract owner is always player1
30 STORE("player_1_car_"+numberofcars, VIN) //add new slot, store VIN number in garage
40 STORE("player_1_numberofcars", numberofcars) //update number of cars owned as we have added a new garage slot
50 STORE("VIN_"+VIN+"_owner_car_position", numberofcars) //store position to make removal easier when car is sold
60 RETURN 0
End Function


//mintChecks: Check mint quantity within limits, model number exists, and production run not exceeded. 
Function mintChecks(modelno Uint64, quantity Uint64) Uint64
10 IF quantity >0 THEN GOTO 40
20 PRINTF "Check failed, quantity must be greater than 0!"
30 RETURN 0 
40 IF quantity <51 THEN GOTO 70
50 PRINTF "Check failed, quantity must be 50 or less!"
60 RETURN 0
70 IF EXISTS("model_number_"+modelno) THEN GOTO 100
80 PRINTF "Check failed, model number does not exist!"
90 RETURN 0
100 DIM productionrun, qtyminted, checksum as Uint64
110 LET productionrun = LOAD("model_number_"+modelno+"_productionrun")
120 LET qtyminted = LOAD("model_number_"+modelno+"_qtyminted")
130 LET checksum = qtyminted + quantity
140 IF checksum > productionrun THEN GOTO 160
150 RETURN 1 //checks passed, we can mint new cars
160 PRINTF "Check failed, production run exceeded!"
170 RETURN 0  
End Function


//Function blockCheck: Used to prevent multiple function calls during one block, which cause unexpected behaviour on testnet. Hopefully this will not be required on mainnet implementation. Returns 0 if checks passed.
Function blockCheck(s String) Uint64
10 IF BLOCK_HEIGHT() > LOAD("scblockheight" + s) THEN GOTO 40
20 PRINTF "Multiple simultaneous function calls detected, exiting function!"
30 RETURN 1 
40 IF BLOCK_TOPOHEIGHT() > LOAD("sctopoheight" + s) THEN GOTO 70
50 PRINTF "Multiple simultaneous function calls detected, exiting function!"
60 RETURN 1 
70 STORE("scblockheight" + s, BLOCK_HEIGHT()) //store block and topo heights immediately after initial checks, to catch subsequent attempts to load function
80 STORE("sctopoheight" + s, BLOCK_TOPOHEIGHT())
90 RETURN 0
End Function


//Sell: Check signer is VIN owner. Change status of car to 'for sale', update asking price.
Function Sell(VIN Uint64, price Uint64) Uint64
10 IF ADDRESS_RAW(LOAD("VIN_"+VIN+"_owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 30 
20 RETURN 1 //signer is not the car owner, exit
30 IF blockCheck("Sell") == 0 THEN GOTO 50 //In this case, 0 = true, as blockCheck must return 0 to store values within function. 
31 IF EXISTS("player_"+SIGNER()) THEN GOTO 35
32 RETURN 0
35 DIM message as String 
36 LET message = "Error selling car (VIN "+VIN+"), too many function calls to smart contract, please try again later"
37 error(message, SIGNER())
40 RETURN 0 
50 STORE("VIN_"+VIN+"_forsale", 1) //store forsale status: 1 = for sale, 0 = not for sale
60 STORE("VIN_"+VIN+"_askingprice", price)
70 RETURN 0
End Function


//CancelSale: Check signer is VIN owner. Change status of car to 'not for sale', update asking price to 0.
Function CancelSale(VIN Uint64) Uint64
10 IF ADDRESS_RAW(LOAD("VIN_"+VIN+"_owner")) == ADDRESS_RAW(SIGNER()) THEN GOTO 21 
20 RETURN 1 //signer is not the car owner, exit
21 IF blockCheck("CancelSale") == 0 THEN GOTO 30 //In this case, 0 = true, as blockCheck must return 0 to store values within function. 
22 DIM message as String 
23 LET message = "Error cancelling sale (VIN "+VIN+"), too many function calls to smart contract, please try again later"
24 error(message, SIGNER())
25 RETURN 0
30 STORE("VIN_"+VIN+"_forsale", 0) //store forsale status: 1 = for sale, 0 = not for sale
40 STORE("VIN_"+VIN+"_askingprice", 0)
50 RETURN 0
End Function


//Buy: Check signer is registered player. Check car exists. Check car is for sale. Check value == asking price. Check player last purchase block number >x blocks behind current (limit on 1 car purchase per x blocks, keeps things fair when cars are released). If so, call transfer function, pay seller. Update VIN owner to signer. Change status of car to 'not for sale', update 'sold price' to value, update asking price to 0. Update cars owned for buyer and seller. Update player last purchase block number.
Function Buy(value Uint64, VIN Uint64) Uint64
10 DIM sellerAddress, message as String
15 DIM ownerCarPosition as Uint64
20 IF buyChecks(SIGNER(), value, VIN) == 1 THEN GOTO 40
25 sendDero(SIGNER(), value) //give money back
30 RETURN 0 //checks failed 
40 IF blockCheck("Buy") == 0 THEN GOTO 60 //In this case, 0 = true, as blockCheck must return 0 to store values within function. 
50 sendDero(SIGNER(), value) //give money back 
51 LET message = "Error buying car (VIN "+VIN+"), too many function calls to smart contract, please try again later"
52 error(message, SIGNER())
55 RETURN 0 
60 LET sellerAddress = LOAD("VIN_"+VIN+"_owner")
70 sendDero(sellerAddress, value)
80 LET ownerCarPosition = LOAD("VIN_"+VIN+"_owner_car_position")
90 completeTransfer(SIGNER(), sellerAddress, VIN, value, ownerCarPosition) 
100 RETURN 0
End Function


//completeTransfer: update VIN database after sale has happened. Call updateCarsOwned function.
Function completeTransfer(buyerAddress String, sellerAddress String, VIN Uint64, salePrice Uint64, ownerCarPosition Uint64) Uint64
10 DIM playerNumberBuyer, playerNumberSeller as Uint64
15 DIM message as String
20 STORE("VIN_"+VIN+"_forsale", 0) //store forsale status: 1 = for sale, 0 = not for sale
30 STORE("VIN_"+VIN+"_askingprice", 0)
40 STORE("VIN_"+VIN+"_soldprice", salePrice)
50 STORE("VIN_"+VIN+"_owner", buyerAddress)
60 LET playerNumberBuyer = LOAD("player_"+buyerAddress)
70 LET playerNumberSeller = LOAD("player_"+sellerAddress)
80 addCarsOwned(playerNumberBuyer, VIN) //add car to buyers list
90 STORE("player_"+playerNumberSeller+"_car_"+ownerCarPosition, 0) //delete car from sellers list
100 STORE("player_"+playerNumberBuyer+"_lastpurchaseblock", BLOCK_HEIGHT()) //Update buyer last purchase block number
105 LET message = "New car purchased! VIN Number: " + VIN
110 STORE("player_"+playerNumberBuyer+"_message", message)
115 LET message = "Car sold! VIN Number: " + VIN
120 STORE("player_"+playerNumberSeller+"_message", message)
130 RETURN 0
End Function


//addCarsOwned: add purchased car to player car list. 
Function addCarsOwned(playerNumber Uint64, VIN Uint64) Uint64
10 DIM numberofcars, inc as Uint64
20 LET numberofcars = LOAD("player_"+playerNumber+"_numberofcars") +1
30 STORE("player_"+playerNumber+"_car_"+numberofcars, VIN) //add new slot, store VIN number in garage
40 STORE("player_"+playerNumber+"_numberofcars", numberofcars)
50 STORE("VIN_"+VIN+"_owner_car_position", numberofcars) //store position to make removal easier when car is sold
60 RETURN 0
End Function


//buyChecks: all checks must pass before sale is authorized.
Function buyChecks(signer String, price Uint64, VIN Uint64) Uint64
10 DIM message as String
11 IF EXISTS("player_"+signer) THEN GOTO 40
20 PRINTF "Player not found!"  //don't store error, no player number!
30 RETURN 0
40 IF EXISTS("VIN_"+VIN) THEN GOTO 70
45 LET message = "Error buying car, VIN "+VIN+" not found"
50 error(message, signer)
60 RETURN 0
70 IF LOAD("VIN_"+VIN+"_forsale") == 1 THEN GOTO 100
75 LET message = "Error buying car, VIN "+VIN+" not for sale"
80 error(message, signer)
90 RETURN 0
100 IF price == LOAD("VIN_"+VIN+"_askingprice") THEN GOTO 130
105 LET message = "Error buying car (VIN "+VIN+"), value of funds received does not match car asking price"
110 error(message, signer)
120 RETURN 0
130 DIM playerNumber as Uint64
140 LET playerNumber = LOAD("player_"+signer)
150 IF BLOCK_HEIGHT() > LOAD("player_"+playerNumber+"_lastpurchaseblock") + LOAD("blocksBetweenBuys") THEN GOTO 180
155 LET message = "Error buying car (VIN "+VIN+"), car purchase frequency exceeded, try again later"
160 error(message, signer)
170 RETURN 0
180 RETURN 1 //All checks passed!
End Function

 
//sendDero: Do required checks (amount >1) then transfer Dero. 
Function sendDero(recipient String, amount Uint64) Uint64
10 DIM transferAmount as Uint64
20 IF amount >1 THEN GOTO 50
30 PRINTF "Value too small to send"
40 RETURN 1
50 LET transferAmount = amount -1 //there must always be at least 1 remaining in contract or send will panic.
60 SEND_DERO_TO_ADDRESS(recipient, transferAmount)
70 RETURN 0
End Function


//NewRace: Create new race. value is Dero, blockheight is start time, VIN is car id. Check VIN is owned by signer. Check start time is in the future. If not, return value to signer and exit (check value is greater than 1 Dero? - call sub function). Else, store race number, started status, number of racers (1), player who started the race, total stake (value), entry fee (value), racer 1 car (VIN), update player open races to 1, update total races by 1 (this will be decremented when a race finishes).
Function NewRace(value Uint64, blockheight Uint64, VIN Uint64) Uint64
10 IF newRaceChecks(SIGNER(), value, blockheight, VIN) == 1 THEN GOTO 30
20 RETURN 0 //checks have failed - rev1.4 changed 1 to 0, fix issue storing error message?
30 DIM race_count, open_races, playerNumber as Uint64
35 DIM message as String
40 LET race_count = LOAD("race_count") +1
50 LET open_races = LOAD("open_races") +1
60 LET playerNumber = LOAD("player_"+SIGNER())
80 STORE("race_count", race_count)
90 STORE("race_"+race_count, race_count) //race number
100 STORE("race_"+race_count+"_status", 1) //0 = race finished, 1 = race open, 2 = race closed to new entrants but not yet started
110 STORE("race_"+race_count+"_entries", 1) //1 entrant
120 STORE("race_"+race_count+"_originator", playerNumber) //player who created the race
125 IF LOAD("noWinningsMode") == 1 THEN GOTO 135 //we are playing for points only, not Dero. Set stake to 0.
130 STORE("race_"+race_count+"_stake", value) //stake, to be updated as more racers join
131 GOTO 140 
135 STORE("race_"+race_count+"_stake", 0)
140 STORE("race_"+race_count+"_fee", value) //entry fee, equal to first stake
150 STORE("race_"+race_count+"_car_1", VIN) //VIN of first car to join the race
155 STORE("race_"+race_count+"_startblock", blockheight) //race starting block height
170 STORE("player_"+playerNumber+"_openraces", 1) //to do in main net version: increment instead of set to 1?
175 LET message = "New race created! Race number: " + race_count
180 STORE("player_"+playerNumber+"_message", message)
200 STORE("open_races", open_races) //increment open races
210 RETURN 0
End Function


//newRaceChecks: Checks to be completed before race created. If fail, return funds to player. To do: Player exists check? May be no point. 
Function newRaceChecks(signer String, stake Uint64, blockheight Uint64, VIN Uint64) Uint64
10 DIM blocksToStart, playerNumber as Uint64
11 DIM message as String
12 IF EXISTS("player_"+signer) THEN GOTO 20
13 PRINTF "Player does not exist"
//--14 sendDero(signer, stake) 
15 RETURN 0
20 LET playerNumber = LOAD("player_"+signer)
30 IF ADDRESS_RAW(LOAD("VIN_"+VIN+"_owner")) != ADDRESS_RAW(signer) THEN GOTO 200 
40 IF blockCheck("NewRace") != 0 THEN GOTO 320 //In this case, 0 = true, as blockCheck must return 0 to store values within function. 
50 IF stake < LOAD("minimumStake") THEN GOTO 220
60 IF blockheight <= BLOCK_HEIGHT() THEN GOTO 240 //To do: race must start at least x number of blocks in future?
70 LET blocksToStart = blockheight - BLOCK_HEIGHT()
80 IF blocksToStart > LOAD("raceFutureStartLimit") THEN GOTO 260
90 IF LOAD("enforceRaceLimit") == 0 THEN GOTO 110 //1 = enforce race limit of 1 open race started per player
95 IF playerNumber == 1 THEN GOTO 110 //Contract owner can create multiple races
100 IF LOAD("player_"+playerNumber+"_openraces") == 1 THEN GOTO 280
110 IF LOAD("open_races") > LOAD("maxRaces") THEN GOTO 300
115 IF LOAD("player_"+playerNumber+"_banned") == 1 THEN GOTO 340
120 RETURN 1 //All checks passed!
200 LET message = "Error creating new race, player does not own this car (VIN "+VIN+")"
201 errorReturnFunds(message, signer, stake, playerNumber)
210 RETURN 0
220 errorReturnFunds("Error creating new race, stake below minimum stake", signer, stake, playerNumber)
230 RETURN 0
240 errorReturnFunds("Error creating new race, race can't start in the past", signer, stake, playerNumber)
250 RETURN 0
260 errorReturnFunds("Error creating new race, start time too far in the future", signer, stake, playerNumber)
270 RETURN 0
280 errorReturnFunds("Error creating new race, player already has one open race", signer, stake, playerNumber)
290 RETURN 0
300 errorReturnFunds("Error creating new race, too many races open", signer, stake, playerNumber)
310 RETURN 0
320 errorReturnFunds("Error creating new race, too many function calls to smart contract, please try again later", signer, stake, playerNumber)
330 RETURN 0
340 errorReturnFunds("Error creating new race, player is banned", signer, stake, playerNumber)
350 RETURN 0
End Function


//error: display error in daemon and store player error message for GUI
Function error(message String, signer String) Uint64
10 DIM playerNumber as Uint64
20 LET playerNumber = LOAD("player_"+signer)
30 PRINTF "%t" message
40 STORE("player_"+playerNumber+"_error", message) //store error, for display in GUI
50 RETURN 0
End Function


//errorReturnFunds: display error in daemon, store player error message for GUI, and return funds
Function errorReturnFunds(message String, signer String, amount Uint64, playerNumber Uint64) Uint64
10 PRINTF "%t" message
15 IF LOAD("noWinningsMode") == 1 THEN GOTO 30 //we are playing for points only, not Dero. Don't return funds, they are very small anyway (0.01 testnet Dero). 
20 sendDero(signer, amount) //return funds
30 STORE("player_"+playerNumber+"_error", message) //store error, for display on GUI
40 RETURN 0
End Function


//EnterRace: Enter car in race. Check raceno exists, race is open, value == entry fee, signer == VIN owner, number of entrants !> max limit (50?). If not, return value and exit. If ok, increment number of racers, store racer, add value to stake. 
Function EnterRace(value Uint64, raceNumber Uint64, VIN Uint64) Uint64
10 DIM playerNumber, numberOfEntries, stake as Uint64
15 DIM message as String
20 IF enterRaceChecks(SIGNER(), value, raceNumber, VIN) == 1 THEN GOTO 40
30 RETURN 0 //checks failed 
40 LET playerNumber = LOAD("player_"+SIGNER())
45 IF checkDoubleEntry(SIGNER(), value, raceNumber, VIN, playerNumber) == 1 THEN GOTO 50 
46 RETURN 0 //player attempted to enter car twice 
50 LET numberOfEntries = LOAD("race_"+raceNumber+"_entries") + 1
60 LET stake = LOAD("race_"+raceNumber+"_stake") + value
70 STORE("race_"+raceNumber+"_entries", numberOfEntries)
75 IF LOAD("noWinningsMode") == 1 THEN GOTO 90 //we are playing for points only, not Dero. Don't update stake.
80 STORE("race_"+raceNumber+"_stake", stake) 
90 STORE("race_"+raceNumber+"_car_"+numberOfEntries, VIN)
95 LET message = "Entered race! Race number: " + raceNumber
100 STORE("player_"+playerNumber+"_message", message)
110 RETURN 0
End Function


//checkDoubleEntry: make sure same car is not entered twice.
Function checkDoubleEntry(signer String, stake Uint64, raceNumber Uint64, VIN Uint64, playerNumber Uint64) Uint64
10 DIM numberOfEntries, inc as Uint64
15 DIM message as String
20 LET numberOfEntries = LOAD("race_"+raceNumber+"_entries")
30 LET inc = 1
40 IF VIN == LOAD("race_"+raceNumber+"_car_"+inc) THEN GOTO 80
50 IF inc == numberOfEntries THEN GOTO 70
55 LET inc = inc + 1
60 GOTO 40
70 RETURN 1 //checks have passed
80 LET message = "Error entering race, car (VIN "+VIN+") already entered!" 
90 errorReturnFunds(message, signer, stake, playerNumber)
100 RETURN 0
End Function


//enterRaceChecks: Checks to be completed before race created. If fail, return funds to player. To do: Player exists check? May be no point. 
Function enterRaceChecks(signer String, stake Uint64, raceNumber Uint64, VIN Uint64) Uint64
10 DIM playerNumber, numberOfEntries, status as Uint64
11 DIM message as String
12 IF EXISTS("player_"+signer) THEN GOTO 20
13 PRINTF "Player does not exist"
//--14 sendDero(signer, stake) //return funds 
15 RETURN 0
20 LET playerNumber = LOAD("player_"+signer)
30 IF ADDRESS_RAW(LOAD("VIN_"+VIN+"_owner")) != ADDRESS_RAW(signer) THEN GOTO 200 
40 IF EXISTS("race_"+raceNumber) THEN GOTO 60 //does race number exist?
50 GOTO 280 
60 IF blockCheck("EnterRace") != 0 THEN GOTO 320 //In this case, 0 = true, as blockCheck must return 0 to store values within function. 
70 IF stake != LOAD("race_"+raceNumber+"_fee") THEN GOTO 220
75 LET status = LOAD("race_"+raceNumber+"_status")
80 IF status == 0 THEN GOTO 300 //race has finished
85 IF status == 2 THEN GOTO 240 //race has finished
90 LET numberOfEntries = LOAD("race_"+raceNumber+"_entries")
100 IF numberOfEntries >= LOAD("maxEntrants") THEN GOTO 260
105 IF LOAD("player_"+playerNumber+"_banned") == 1 THEN GOTO 340
110 RETURN 1 //All checks passed!
200 LET message = "Error entering race "+raceNumber+", player does not own this car (VIN "+VIN+")"
201 errorReturnFunds(message, signer, stake, playerNumber) //could happen if car just sold
210 RETURN 0
220 errorReturnFunds("Error entering race, payment sent does not equal entry fee", signer, stake, playerNumber) //should not happen in GUI
230 RETURN 0
240 LET message = "Error entering race "+raceNumber+", maximum number of entries reached"
241 errorReturnFunds(message, signer, stake, playerNumber)
250 RETURN 0
260 STORE("race_"+raceNumber+"_status", 2) //Close the race to new entries
270 GOTO 240
280 errorReturnFunds("Error entering race, race number does not exist", signer, stake, playerNumber) //should not happen in GUI
290 RETURN 0
300 LET message = "Error entering race "+raceNumber+", race has finished"
301 errorReturnFunds(message, signer, stake, playerNumber) //could happen if last minute entry attempt
310 RETURN 0
320 LET message = "Error entering race "+raceNumber+", too many function calls to smart contract, please try again later"
321 errorReturnFunds(message, signer, stake, playerNumber)
330 RETURN 0
340 errorReturnFunds("Error entering race, player is banned", signer, stake, playerNumber) //rev 1.6
350 RETURN 0
End Function


//StartRace: Start race (raceno). Check raceno exists, if not return. Check block height >= start time. Then call race. Anyone can start a race, even if not a registered player (e.g. a bot). 
Function StartRace(raceNumber Uint64) Uint64
10 IF blockCheck("NewRace") == 0 THEN GOTO 30 //same block check as NewRace, because we are incrementing / decrementing number of open races!
11 IF EXISTS("player_"+SIGNER()) THEN GOTO 25
20 RETURN 0 //
25 DIM message as String
26 LET message = "Error starting race "+raceNumber+", too many function calls to smart contract, please try again later" 
27 error(message, SIGNER())
28 RETURN 0
30 IF EXISTS("race_"+raceNumber) THEN GOTO 60
40 PRINTF "Race number does not exist"
50 RETURN 0 
60 IF BLOCK_HEIGHT() >= LOAD("race_"+raceNumber+"_startblock") THEN GOTO 90
70 PRINTF "Race not scheduled to start yet"
80 RETURN 0 
90 race(raceNumber) //all checks passed, start race!
100 RETURN 0
End Function


//race: If only one entrant, return stake to sole entrant. Exit. Else, do maths to pick winner, lookup winner from VIN, call transfer function. Increment player points (number of points = number of entrants -1). Call leaderboard function. Set race to finished. Set race winner to player number. update player1 open races to 0, decrease total races by 1 . //60 sendWinnings(playerNumber, raceNumber) moved to closeRace().
Function race(raceNumber Uint64) Uint64
10 DIM playerNumber, playerPoints, winningVIN as Uint64
20 IF enoughEntrants(raceNumber) == 1 THEN GOTO 40 //1 == OK, more than one entrant
30 RETURN 0 
40 LET winningVIN = pickWinner(raceNumber) 
50 LET playerNumber = getPlayerNumber(winningVIN)
70 closeRace(playerNumber, raceNumber)
80 STORE("player_"+playerNumber+"_last_race_won", raceNumber)
90 RETURN 0
End Function


//enoughEntrants: Check if only one entrant after race started. If so, return stake to player, set player open races to 0, set race to finished (0).
Function enoughEntrants(raceNumber Uint64) Uint64
10 DIM VIN, playerNumber, stake as Uint64
15 DIM playerAddress, message as String
20 IF LOAD("race_"+raceNumber+"_entries") == 1 THEN GOTO 40 //Only one entry, cancel race
30 RETURN 1 //More than 1 entry, race can proceed
40 LET VIN = LOAD("race_"+raceNumber+"_car_1") //First entrant will always be car_1
50 LET stake = LOAD("race_"+raceNumber+"_stake")
60 LET playerAddress = LOAD("VIN_"+VIN+"_owner")
70 LET playerNumber = LOAD("player_"+playerAddress)
75 IF LOAD("noWinningsMode") == 1 THEN GOTO 90 //we are playing for points only, not Dero. 
80 sendDero(playerAddress, stake) //refund player
90 STORE("race_"+raceNumber+"_status", 0) //close race
100 STORE("player_"+playerNumber+"_openraces", 0)//set player open races to 0, so player can start a new race
110 LET message = "Race number "+raceNumber+" canceled due to only one entrant at race start time"
120 STORE("player_"+playerNumber+"_message", message)
130 RETURN 0
End Function


//pickWinner: Do maths to pick winner, lookup winner from VIN, return winning player number
Function pickWinner(raceNumber Uint64) Uint64
10 DIM numberOfEntries, score, factor, model, highestScore, VIN, raceLeader, inc as Uint64
20 LET numberOfEntries = LOAD("race_"+raceNumber+"_entries")
25 LET factor = LOAD("raceFactor") 
30 LET inc = 1
35 LET highestScore = 0
40 LET VIN = LOAD("race_"+raceNumber+"_car_"+inc) //get VIN
50 LET model = LOAD("VIN_"+VIN+"_model_number") //get model
70 LET score = LOAD("model_number_"+model+"_score") + RANDOM(factor) //assign a score
80 IF score > highestScore THEN GOTO 100 //highest score beaten, new leader
90 GOTO 120 //highest score stands, no new leader
100 LET highestScore = score
110 LET raceLeader = VIN
120 IF inc == numberOfEntries THEN GOTO 150
130 LET inc = inc +1
140 GOTO 40
150 RETURN raceLeader //we have a winner!
End Function


//To do: update all functions to use this function where player number required from VIN
//getPlayerNumber: returns playerNumber from VIN
Function getPlayerNumber(VIN Uint64) Uint64
10 DIM playerNumber as Uint64
20 DIM playerAddress as String
30 LET playerAddress = LOAD("VIN_"+VIN+"_owner")
40 LET playerNumber = LOAD("player_"+playerAddress)
50 RETURN playerNumber
End Function


//closeRace: update various DB's 
Function closeRace(playerNumber Uint64, raceNumber Uint64) Uint64
10 DIM newPoints, playerPoints, raceStarterPlayer, raceStarterVIN, open_races as Uint64
15 DIM message as String
20 LET newPoints = LOAD("race_"+raceNumber+"_entries") -1 //To do: review points allocation philosophy?
30 LET playerPoints = LOAD("player_"+playerNumber+"_points") + newPoints
40 STORE("player_"+playerNumber+"_points", playerPoints)
50 STORE("race_"+raceNumber+"_winner", playerNumber)
60 STORE("race_"+raceNumber+"_status", 0) //close race
70 LET raceStarterVIN = LOAD("race_"+raceNumber+"_car_1") //First entrant will always be car_1
90 LET raceStarterPlayer = getPlayerNumber(raceStarterVIN)
100 STORE("player_"+raceStarterPlayer+"_openraces", 0)//set race starter open races to 0, so player can start a new race
110 LET open_races = LOAD("open_races") - 1
120 STORE("open_races", open_races) //decrement open races
130 LET message = "Race number "+raceNumber+" won!" //to do: update message to include winnings and points?
140 STORE("player_"+playerNumber+"_message", message)
145 IF LOAD("noWinningsMode") == 1 THEN GOTO 160 //we are playing for points only, not Dero. 
150 sendWinnings(playerNumber, raceNumber) 
160 RETURN 0
End Function

//not used for initial release
//sendWinnings: send winnings to player
Function sendWinnings(playerNumber Uint64, raceNumber Uint64) Uint64
10 DIM stake as Uint64
20 DIM playerAddress as String
30 LET stake = LOAD("race_"+raceNumber+"_stake")
40 LET playerAddress = LOAD("player_number_"+playerNumber)
50 sendDero(playerAddress, stake)
60 RETURN 0
End Function




