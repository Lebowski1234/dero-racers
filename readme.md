# Dero Racers

Dero Racers is a Blockchain based game written for the Dero Stargate competition! The game involves buying and selling cars for (testnet) Dero, and racing for points and a hallowed position on the game leaderboard!

![title](https://github.com/Lebowski1234/dero-racers/raw/master/dero-racers-screenshot-50.png)


## Requirements

The game is designed to run on a 64 bit Windows or Linux PC, but it should also run on Mac (you will need to build from source, see below). 

All testing was done on Windows 7 and Ubuntu 16.04. 


## Binaries

* [Dero Racers Linux 64](https://github.com/Lebowski1234/dero-racers/raw/master/Binaries/DeroRacers-Linux64.tar.gz)
* [Dero Racers Windows 64](https://github.com/Lebowski1234/dero-racers/raw/master/Binaries/DeroRacers-Win64.rar)


## Quick Start

To run the game:

* The Dero Stargate daemon and wallet must be running and fully synched, with RPC ports open. The wallet must be unlocked and have minimum 50 testnet Dero available, preferably >200 as whenever a wallet transaction is made, part of the balance is locked for a short period, then released again. 

* Download the binaries for your platform (either Windows 64 or Linux 64). Or build from source / run from Godot (see below). 

* Extract the archive to an empty folder. 

* Double click on the executable file (Windows) or binary file (Linux).

* The game should run!

Note: Instructions are provided at the end of this readme for running the daemon and wallet.



## Playing the Game

Important note: After pressing any of the game buttons, if the debug message box comes up with 'Please try again' followed by an error message, keep trying every few seconds until it says 'Transaction sent to wallet'. This type of error is usually due to the daemon refusing the transaction due to a RCT error and is nothing to worry about (nothing to do with Dero Racers). 


To join the game for the first time:

* Enter a player name and press Join Game!

* The debug message box should say 'Transaction sent to wallet'. 

* Within a minute (depending on block time), the Player fields should come up and the debug box should display a message confirming you have joined the game! If after a few minutes and several blocks have passed this doesn't happen, just try again. It is likely due to too many calls to the contract by other players. 

* Press the 'Update Car Yard, Open races, My Garage' button. This should populate the game GUI.

The next time the game is run, just press the Start button! No need to join again. 



To play the game:

Buy a Car:

* First buy a car from the Car Yard! Select a car and press buy. The Price in Dero will be sent from your wallet. Note that there is a limit on how often a player can buy a car. This is set at one car every 50 blocks on the release of the game (the contract owner can change this any time). So choose carefully!

* Wait until the game status message confirms the purchase, or check the Smart Contract error message box for messages (for example, you have tried to buy two cars within 50 blocks). 

* Press the Update button again. The car should display in My Garage!


Enter a Race:

* Select a race you want to enter.

* Select a car from My Garage.

* Press Enter Race! The cost of entering a race is 0.01 testnet Dero. 


Start a Race:

* Races can be started by anyone when the blockchain height passes the race start block. Select a race, and press Start Race!


New Race:

* Enter a starting block height in the future. The height must be no more than 3600 higher than the current block height. 

* Press Create Race! The cost of creating a race is 0.01 testnet Dero. 

* The contract owner can limit the number of races a player can start to 1 at a time (the first race must finish before a new race can be created). This is not set right now, but can be changed any time by the contract owner. 

* A maximum of 50 open races can exist at once. 


Sell a Car:

* If you want to put a car up for sale, select the car from My Garage.

* Enter an Asking Price. This must be a whole integer number between 1 and 999.

* Press Sell Car!

* Another player can then buy the car.

* If you want to take a car off the market, select the car for sale in My Garage, and press Cancel Sale.  

 
## Important Notes and Limitations

The game was put together in a rushed timeframe over about 3 weeks in the evenings and weekends, to meet the competition entry deadline. It has the following limitations (and probably others I have not thought of right now):


* The game runs with a fixed screen resolution of 1600 x 900, which can't be adjusted. Older monitors may not display the game properly. The only fix is go and buy a new monitor! As the game is developed going forward, it will be re-written to work with multiple resolutions the same as most other apps. 

* Error catching is not 100% as I ran out of time to do a full review before release. Most common errors with daemon / wallet responses (including daemon / wallet not running) should be handled, however there is a chance that the game will crash when any errors occur that have not come up while testing the game. Please report any errors here on Github, or alternatively DM me in the Dero Discord channel where I can be found (thedudelebowski#1775). 

* The source code for the Godot app is very untidy and could be greatly simplified in some areas. I ran out of time to do this before the competition closed. So for any forkers, please consider that it is not a great base to build a different app. 

* The game was originally intended to let players gamble money on each race (the race starter could select the entry fee, and the winner takes all). An issue was found with the Dero Stargate DVM very late in the development which makes this impossible to implement reliably without causing serious issues with the game. So the game was quickly changed to let players win points only. 



## Building from Source

The app was written using Godot, an amazing piece of 100% free and open source indie game development software. All development was done in Godot 3.06 Mono version. It has not been tested with Godot 3.1, but I will do this some time soon. 

For those who want to run from source but don't want to go to the trouble of building binaries, you can simply download the source code and import as a Godot project. The game can then be run by pressing the Play button in the Godot editor! It is as simple as that.

To build / export binaries, you need to follow the instructions in the Godot documentation. It is not difficult, but beyond the scope of this readme. 



## Running the Dero Stargate Daemon and Wallet


Get the Dero Stargate binaries here:

[https://git.dero.io/DeroProject/Dero_Stargate_testnet_binaries](https://git.dero.io/DeroProject/Dero_Stargate_testnet_binaries)


To run the daemon in Linux:

```
./derod-linux-amd64 --testnet
```

To run the wallet in Linux:

```
./dero-wallet-cli-linux-amd64 --rpc-server --wallet-file testnetwallet.db --testnet
```



To run the daemon in Windows:

```
derod-windows-amd64 --testnet
```

To run the wallet in Windows:

```
dero-wallet-cli-windows-amd64 --rpc-server --wallet-file testnetwallet.db --testnet
```


 

