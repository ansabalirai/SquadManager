@echo off
SET "SDKLocation=D:\SteamLibrary\steamapps\common\XCOM 2 War of the Chosen SDK"
SET "GameLocation=G:\SteamLibrary\steamapps\common\XCOM 2\XCom2-WarOfTheChosen"
SET "SRCLocation=D:\Github\SquadManager"
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted  -file "D:\Github\SquadManager\.scripts\build.ps1" -srcDirectory "%SRCLocation%" -sdkPath "%SDKLocation%" -gamePath "%GameLocation%" -config "default"


