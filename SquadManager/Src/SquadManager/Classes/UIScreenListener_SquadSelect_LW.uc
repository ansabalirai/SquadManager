//---------------------------------------------------------------------------------------
//  FILE:    UIScreenListener
//  AUTHOR:  Amineri / Pavonis Interactive
//
//  PURPOSE: Adds additional functionality to SquadSelect_LW (from Toolbox)
//			 Provides support for squad-editting without launching mission
//--------------------------------------------------------------------------------------- 

class UIScreenListener_SquadSelect_LW extends UIScreenListener;

var localized string strSave;
var localized string strSquad;

var localized string strStart;
var localized string strInfiltration;

var localized string strAreaOfOperations;

//var config array<name> NonInfiltrationMissions;

var bool bInSquadEdit;
var GeneratedMissionData MissionData;

//var config float SquadInfo_DelayedInit;

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local UISquadSelect SquadSelect;
	local XComGameState_LWSquadManager SquadMgr;
	local XComGameState_Unit UnitState;
	//local UISquadSelect_InfiltrationPanel InfiltrationInfo;
	local UISquadContainer SquadContainer;
	local XComGameState_MissionSite MissionState;
	local StateObjectReference NullRef;
	local UITextContainer InfilRequirementText, MissionBriefText;
	local float RequiredInfiltrationPct;
	local string BriefingString;
	local int idx;

	if(!Screen.IsA('UISquadSelect')) return;

	//`LWTrace("UIScreenListener_SquadSelect_LW: Initializing");
	
	SquadSelect = UISquadSelect(Screen);
	if(SquadSelect == none) return;

	class'LWHelpTemplate'.static.AddHelpButton_Std('SquadSelect_Help', SquadSelect, 1057, 12);

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;
	SquadMgr = class'XComGameState_LWSquadManager'.static.GetSquadManager();
	SquadMgr.UpdateAllSquads();

	// pause and resume all headquarters projects in order to refresh state
	// this is needed because exiting squad select without going on mission can result in projects being resumed w/o being paused, and they may be stale
	XComHQ.PauseProjectsForFlight();
	XComHQ.ResumeProjectsPostFlight();

	XComHQ = `XCOMHQ;
	SquadSelect.XComHQ = XComHQ; // Refresh the squad select's XComHQ since it's been updated

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);

	//UpdateMissionDifficulty(SquadSelect);

	//check if we got here from the SquadBarracks
	bInSquadEdit = `SCREENSTACK.IsInStack(class'UIPersonnel_SquadBarracks');
	if(bInSquadEdit)
	{
		//`LWTrace("UIScreenListener_SquadSelect_LW: Arrived from SquadBarracks");
		if (`ISCONTROLLERACTIVE)
		{
			// KDM : Hide the 'Save Squad' button which appears while viewing a Long War squad's soldiers.
			// As an aside, I don't believe this functionality actually works.
			SquadSelect.LaunchButton.Hide();
		}
		else
		{
			SquadSelect.LaunchButton.OnClickedDelegate = OnSaveSquad;
			SquadSelect.LaunchButton.SetText(strSquad);
			SquadSelect.LaunchButton.SetTitle(strSave);
		}

		SquadSelect.m_kMissionInfo.Remove();
	} 
	else 
	{
		SquadContainer = SquadSelect.Spawn(class'UISquadContainer', SquadSelect);
		
		`Log("SquadBasedRoster: UIScreenListener_SquadSelect_LW: Arrived from mission");
		MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

		if (MissionState.GeneratedMission.MissionID != 0)
		{
			`Log("SquadBasedRoster: UIScreenListener_SquadSelect_LW: Setting up for an instant response mission");
			// This is an instant response mission or at least, not an infiltration or CA
			SquadContainer.CurrentSquadRef = SquadMgr.LaunchingMissionSquad;
			SquadContainer.CurrentSquadRef = SquadMgr.LastMissionSquad;
			
		}

		else
		{
			//Differentiate between CA and infiltration mission
			if (SquadSelect.SoldierSlotCount < 4) // Hacky check which assumes that we will not have more than 4 people on a CA
			{
				`Log("SquadBasedRoster: UIScreenListener_SquadSelect_LW: Likley Setting up for a CA");
				SquadContainer.CurrentSquadRef = SquadMgr.LaunchingMissionSquad;
				SquadContainer.CurrentSquadRef = SquadMgr.LastMissionSquad;
				// SquadContainer.CurrentSquadRef = NullRef;
				
				// for (idx = XComHQ.Squad.Length - 1; idx >= 0; idx--)
				// {					
				// 	XComHQ.Squad.Remove(idx, 1);	
				// }
				// SquadSelect.UpdateData();
			}
				
			else
			{
				`Log("SquadBasedRoster: UIScreenListener_SquadSelect_LW: Likely Setting up for a infiltration mission (CI)");
				SquadContainer.CurrentSquadRef = SquadMgr.LaunchingMissionSquad;
				SquadContainer.CurrentSquadRef = SquadMgr.LastMissionSquad;
			}
				

		}
		// LW : Create the SquadContainer on a timer, to avoid creation issues that can arise when creating it immediately, when no pawn loading is present
		SquadContainer.DelayedInit(0.75);
		
		
		
		SquadSelect.bDirty = true; // Workaround for bug in currently published version of squad select
		SquadSelect.UpdateData();
		SquadSelect.UpdateNavHelp();
	}
}

/* simulated function string RequiredInfiltrationString(float RequiredValue)
{
	local XGParamTag ParamTag;
	local string ReturnString;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.IntValue0 = Round(RequiredValue);
	ReturnString = `XEXPAND.ExpandString(class'UIMission_LWLaunchDelayedMission'.default.m_strInsuffientInfiltrationToLaunch);

	return "<p align='CENTER'><font face='$TitleFont' size='20' color='#000000'>" $ ReturnString $ "</font>";
}


function UpdateMissionDifficulty(UISquadSelect SquadSelect)
{
	local XComGameState_MissionSite MissionState;
	local string Text;
	
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(`XCOMHQ.MissionRef.ObjectID));
	Text = class'UIUtilities_Text_LW'.static.GetDifficultyString(MissionState);
	SquadSelect.m_kMissionInfo.MC.ChildSetString("difficultyValue", "htmlText", Caps(Text));
} */

// callback from clicking the rename squad button
function OnSquadManagerClicked(UIButton Button)
{
	local UIPersonnel_SquadBarracks kPersonnelList;
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPRES;

	if (HQPres.ScreenStack.IsNotInStack(class'UIPersonnel_SquadBarracks'))
	{
		kPersonnelList = HQPres.Spawn(class'UIPersonnel_SquadBarracks', HQPres);
		kPersonnelList.bSelectSquad = true;
		HQPres.ScreenStack.Push(kPersonnelList);
	}
}

simulated function OnSaveSquad(UIButton Button)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_LWSquadManager SquadMgr;
	local UIPersonnel_SquadBarracks Barracks;
	local UIScreenStack ScreenStack;

	XComHQ = `XCOMHQ;
	ScreenStack = `SCREENSTACK;
	SquadMgr = class'XComGameState_LWSquadManager'.static.GetSquadManager();
	Barracks = UIPersonnel_SquadBarracks(ScreenStack.GetScreen(class'UIPersonnel_SquadBarracks'));
	SquadMgr.GetSquad(Barracks.CurrentSquadSelection).SquadSoldiers = XComHQ.Squad;
	GetSquadSelect().CloseScreen();
	ScreenStack.PopUntil(Barracks);

}

simulated function UISquadSelect GetSquadSelect()
{
	local UIScreenStack ScreenStack;
	local int Index;
	ScreenStack = `SCREENSTACK;
	for( Index = 0; Index < ScreenStack.Screens.Length;  ++Index)
	{
		if(UISquadSelect(ScreenStack.Screens[Index]) != none )
			return UISquadSelect(ScreenStack.Screens[Index]);
	}
	return none; 
}

// This event is triggered after a screen receives focus
event OnReceiveFocus(UIScreen Screen)
{
	local UISquadSelect SquadSelect;
	//local UISquadSelect_InfiltrationPanel InfiltrationInfo;

	if(!Screen.IsA('UISquadSelect')) return;

	SquadSelect = UISquadSelect(Screen);
	if(SquadSelect == none) return;

	//`LWTrace("UIScreenListener_SquadSelect_LW: Received focus");
	
	SquadSelect.bDirty = true; // Workaround for bug in currently published version of squad select
	SquadSelect.UpdateData();
	SquadSelect.UpdateNavHelp();

	//UpdateMissionDifficulty(SquadSelect);

/* 	InfiltrationInfo = UISquadSelect_InfiltrationPanel(SquadSelect.GetChildByName('SquadSelect_InfiltrationInfo_LW', false));
	if (InfiltrationInfo != none)
	{
		`Log("UIScreenListener_SquadSelect_LW: Found infiltration panel");
		
		//remove and recreate infiltration info in order to prevent issues with Flash text updates not getting processed
		InfiltrationInfo.Remove();

		InfiltrationInfo = SquadSelect.Spawn(class'UISquadSelect_InfiltrationPanel', SquadSelect).InitInfiltrationPanel();
		InfiltrationInfo.MCName = 'SquadSelect_InfiltrationInfo_LW';
		InfiltrationInfo.MissionData = MissionData;
		InfiltrationInfo.Update(SquadSelect.XComHQ.Squad);
	} */
}

// This event is triggered after a screen loses focus
event OnLoseFocus(UIScreen Screen);

// This event is triggered when a screen is removed
event OnRemoved(UIScreen Screen)
{
	local XComGameState_LWSquadManager SquadMgr;
	local StateObjectReference SquadRef, NullRef;
	local XComGameState_LWPersistentSquad SquadState;
	local XComGameState NewGameState;
	local UISquadSelect SquadSelect;

	if(!Screen.IsA('UISquadSelect')) return;

	SquadSelect = UISquadSelect(Screen);

	//need to move camera back to the hangar, if was in SquadManagement
	if(bInSquadEdit)
	{
		`HQPRES.CAMLookAtRoom(`XCOMHQ.GetFacilityByName('Hangar').GetRoom(), `HQINTERPTIME);
	}

	SquadMgr = class'XComGameState_LWSquadManager'.static.GetSquadManager();
	SquadRef = SquadMgr.LaunchingMissionSquad;
	SquadRef = SquadMgr.LastMissionSquad;
	if (SquadRef.ObjectID != 0)
	{
		SquadState = XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(SquadRef.ObjectID));
		if (SquadState != none)
		{
			if (SquadState.bTemporary && !SquadSelect.bLaunched)
			{
				SquadMgr.RemoveSquadByRef(SquadRef);
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clearing LaunchingMissionSquad");
				SquadMgr = XComGameState_LWSquadManager(NewGameState.CreateStateObject(class'XComGameState_LWSquadManager', SquadMgr.ObjectID));
				NewGameState.AddStateObject(SquadMgr);
				SquadMgr.LaunchingMissionSquad = NullRef;
				SquadMgr.UpdateAllSquads();
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}
	}
}

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none;
}