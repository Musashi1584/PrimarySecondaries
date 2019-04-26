class X2Action_CustomDeath extends X2Action_Death;

var name DeathAnimSequence;

function Init()
{
	`LOG(default.class @ GetFuncName() @ "triggerd",, 'PrimarySecondaries');
	super.Init();
}

function RespondToParentEventReceived(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	`LOG(default.class @ GetFuncName() @ "triggerd" @ Event @ EventData.Class @ EventSource.Class,, 'PrimarySecondaries');

	super.RespondToParentEventReceived(EventData, EventSource, GameState, Event, CallbackData);
}

simulated function Name ComputeAnimationToPlay()
{
	`LOG(default.class @ GetFuncName() @ DeathAnimSequence,, 'PrimarySecondaries');
	if (DeathAnimSequence != 'None' && UnitPawn.GetAnimTreeController().CanPlayAnimation(DeathAnimSequence))
	{
		return DeathAnimSequence;
	}
	
	return super.ComputeAnimationToPlay();
}


simulated state Executing
{	

Begin:
	StopAllPreviousRunningActions(Unit);

	Unit.SetForceVisibility(eForceVisible);

	//Ensure Time Dilation is full speed
	VisualizationMgr.SetInterruptionSloMoFactor(Metadata.VisualizeActor, 1.0f);

	Unit.PreDeathRotation = UnitPawn.Rotation;

	//Death might already have been played by X2Actions_Knockback.
	if (!UnitPawn.bPlayedDeath)
	{
		Unit.OnDeath(m_kDamageType, XGUnit(DamageDealer));

		AnimationName = ComputeAnimationToPlay();

		`LOG(default.class @ GetFuncName() @ AnimationName,, 'PrimarySecondaries');

		UnitPawn.SetFinalRagdoll(true);
		UnitPawn.TearOffMomentum = vHitDir; //Use archaic Unreal values for great justice	
		UnitPawn.PlayDying(none, UnitPawn.GetHeadshotLocation(), AnimationName, Destination);
	}

	//Since we have a unit dying, update the music if necessary
	`XTACTICALSOUNDMGR.EvaluateTacticalMusicState();

	Unit.GotoState('Dead');

	if( bDoOverrideAnim )
	{
		// Turn off new animation playing
		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
	}

	while( DoWaitUntilNotified() && !IsTimedOut() )
	{
		Sleep(0.0f);
	}

	CompleteAction();
}
