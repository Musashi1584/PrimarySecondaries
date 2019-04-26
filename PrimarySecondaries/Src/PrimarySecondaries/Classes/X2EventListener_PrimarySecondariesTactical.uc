class X2EventListener_PrimarySecondariesTactical extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListeners());

	return Templates;
}

static function X2EventListenerTemplate CreateListeners()
{
	local X2EventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'PSAbilityActivatedListener');
	Template.AddEvent('AbilityActivated', OnAbilityActivated);
	Template.RegisterInTactical = true;

	return Template;
}

static protected function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit SourceUnit, TargetUnit;
	local XComGameState NewGameState;

	SourceUnit = XComGameState_Unit(EventSource);
	if (!SourceUnit.IsSoldier()) {
		return ELR_NoInterrupt;
	}

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	AbilityState = XComGameState_Ability(EventData);
	AbilityTemplate = AbilityState.GetMyTemplate();

	if (AbilityContext != none && AbilityTemplate.IsMelee()) 
	{
		if (AbilityContext.InputContext.PrimaryTarget.ObjectID > 0)
		{
			`LOG(GetFuncName() @ "triggerd" @ AbilityTemplate.DataName,, 'PrimarySecondaries');

			 TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

			 `LOG(TargetUnit.GetFullName() @ TargetUnit.IsDead(),, 'PrimarySecondaries');

			 if (TargetUnit.IsDead())
			 {
				AbilityContext.PostBuildVisualizationFn.AddItem(CustomDeathVisualizationFn);
			 }
		}
	}

	return ELR_NoInterrupt;
}

function CustomDeathVisualizationFn(XComGameState VisualizeGameState)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local Array<X2Action>					arrFoundActions;
	local X2Action_Death					DeathAction;
	local X2Action_Fire						FireAction;
	local X2Action_CustomDeath				CustomDeathAction;
	local VisualizationActionMetadata		ActionMetadata;
	local XComGameStateHistory				History;
	local XComGameStateContext_Ability		Context;
	local StateObjectReference				InteractingUnitRef;
	local X2Action							FoundAction;

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.PrimaryTarget;

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	//	Find Death Action
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_Death', arrFoundActions);

	//	Should be only one Death Action since ability is single target
	DeathAction = X2Action_Death(arrFoundActions[0]);

	if (DeathAction != none) 
	{
		`LOG(GetFuncName() @ "triggerd" @ InteractingUnitRef.ObjectID @ DeathAction @ Context,, 'PrimarySecondaries');

		CustomDeathAction = X2Action_CustomDeath(class'X2Action_CustomDeath'.static.AddToVisualizationTree(ActionMetadata, Context));	//	create Dismemberment Action wherever

		VisMgr.DisconnectAction(CustomDeathAction);	//	Disconnect it from that wherever just in case

		//	Insert CustomDeathAction into Viz Tree so that it has same parents and children as Deaath Action
		foreach DeathAction.ParentActions(FoundAction)
		{
			VisMgr.ConnectAction(CustomDeathAction, VisMgr.BuildVisTree,, FoundAction);	// Found Action becomes parent of CustomDeathAction
		}

		foreach DeathAction.ChildActions(FoundAction)
		{
			VisMgr.ConnectAction(FoundAction, VisMgr.BuildVisTree,, CustomDeathAction);	//	CustomDeathAction becomes parent of Found Action
		}
		//	remove Death Action from the tree.
		VisMgr.DisconnectAction(DeathAction);
	}
	else `LOG("Could not find death action.",, 'PrimarySecondaries');
}