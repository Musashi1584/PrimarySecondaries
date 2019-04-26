class AnimNotify_UnitHitCustomDeath extends AnimNotify_Scripted;

var() editinline name DeathAnimSequence <ToolTip="Sequence name of the death animation to play">;

event Notify(Actor Owner, AnimNodeSequence AnimSeqInstigator)
{
	local XComUnitPawn Pawn, TargetPawn;
	local XGUnitNativeBase OwnerUnit;
	local X2Action_Fire FireAction;
	local X2Action_CustomDeath DeathAction;
	local XComGameStateVisualizationMgr VisualizationManager;
	local CustomAnimParams AnimParams;
	local XGUnit TargetUnit;

	Pawn = XComUnitPawn(Owner);
	if (Pawn != none)
	{
		OwnerUnit = Pawn.GetGameUnit();
		if (OwnerUnit != none)
		{
			`LOG(default.class @ "Owner" @ String(OwnerUnit),, 'PrimarySecondaries');
			VisualizationManager = `XCOMVISUALIZATIONMGR;
			FireAction = X2Action_Fire(VisualizationManager.GetCurrentActionForVisualizer(OwnerUnit));
			if (FireAction != none)
			{
				TargetUnit = XGUnit(FireAction.PrimaryTarget);
				TargetPawn = TargetUnit.GetPawn();
				`LOG(default.class @ "Target" @ TargetUnit @ TargetPawn @ FireAction,, 'PrimarySecondaries');
				if (TargetPawn != none)
				{
					DeathAction = X2Action_CustomDeath(VisualizationManager.GetNodeOfType(VisualizationManager.VisualizationTree, class'X2Action_CustomDeath', TargetUnit));

					if (DeathAction != none)
					{
						DeathAction.DeathAnimSequence = DeathAnimSequence;
					}

					`XEVENTMGR.TriggerEvent('Visualizer_EffectApplied', self, FireAction);
					`XEVENTMGR.TriggerEvent('Visualizer_AbilityHit', self, FireAction);
					
					`LOG(default.class @ "triggered Visualizer_EffectApplied & Visualizer_AbilityHit" @ self @ FireAction @ DeathAction,, 'PrimarySecondaries');
					
				}
			}
		}
	}
	super.Notify(Owner, AnimSeqInstigator);
}

defaultproperties
{
	DeathAnimSequence = "HL_DeathDefault"
}