//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_SquadManager.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_SquadManager extends X2DownloadableContentInfo;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
// Called when mod is first installed in an ongoing campaign - Thanks to TeslaRage for providing this snippet
static event OnLoadedSavedGame()
{
    local XComGameState NewGameState;
    local XComGameState_LWSquadManager SquadMgrState;
    local bool bSquadManagerExist;

	bSquadManagerExist = FALSE;

    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_LWSquadManager', SquadMgrState)
    {
        bSquadManagerExist = true;
    }

    if (!bSquadManagerExist)
    {
        // Create new Game State
        NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SquadManager: Mid campaign install");
        SquadMgrState = XComGameState_LWSquadManager(NewGameState.CreateNewStateObject(class'XComGameState_LWSquadManager'));
        SquadMgrState.InitSquadManagerListeners();
        NewGameState.AddStateObject(SquadMgrState);
        `GAMERULES.SubmitGameState(NewGameState);
    }
}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{
	`Log("SquadManager: Installing a new campaign");
	//class'XComGameState_LWListenerManager'.static.CreateListenerManager(StartState);
	class'XComGameState_LWSquadManager'.static.CreateSquadManager(StartState);

	//class'XComGameState_LWSquadManager'.static.CreateFirstMissionSquad(StartState);
}






static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
{
	//class'XComGameState_LWSquadManager'.static.GetSquadManager().UpdateSquadPreMission(StartGameState); // completed mission
}

static event OnPostMission()
{
	//class'XComGameState_LWListenerManager'.static.RefreshListeners();

	class'XComGameState_LWSquadManager'.static.GetSquadManager().UpdateSquadPostMission(, true); // completed mission
	//`LWOUTPOSTMGR.UpdateOutpostsPostMission();
}
