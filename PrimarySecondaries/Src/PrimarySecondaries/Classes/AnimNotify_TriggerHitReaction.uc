class AnimNotify_TriggerHitReaction extends AnimNotify_Scripted;

var() editinline name ReactionAnimSequence <ToolTip="Sequence name of the damage reaction to play">;
var() editinline bool RandomReactionAnimSequence <ToolTip="Play a random sequence of HL_HurtFront, HL_HurtLeft or HL_HurtRight Overides ReactionAnimSequence">;
var() editinline int BloodAmount <ToolTip="Virtual damage amount that calculates the amount of blood effect">;
var() name DamageTypeName  <ToolTip="Virtual damage type used in hit effect. Possible values are DefaultProjectile, Acid, Electrical, Poison, Psi and Fire">;
var() EAbilityHitResult HitResult <ToolTip="Virtual hit result used in the hit effect container">;

event Notify(Actor Owner, AnimNodeSequence AnimSeqInstigator)
{
	local XComUnitPawn Pawn, TargetPawn;
	local XGUnitNativeBase OwnerUnit;
	local X2Action_Fire FireAction;
	local XComGameStateVisualizationMgr VisualizationManager;
	local CustomAnimParams AnimParams;
	local XGUnit TargetUnit;
	local array<name> RandomSequences;

	RandomSequences.AddItem('HL_HurtFront');
	RandomSequences.AddItem('HL_HurtLeft');
	RandomSequences.AddItem('HL_HurtRight');

	Pawn = XComUnitPawn(Owner);
	if (Pawn != none)
	{
		OwnerUnit = Pawn.GetGameUnit();
		if (OwnerUnit != none)
		{
			`LOG("AnimNotify_TriggerHitReaction Owner" @ String(OwnerUnit),, 'PrimarySecondaries');
			VisualizationManager = `XCOMVISUALIZATIONMGR;
			FireAction = X2Action_Fire(VisualizationManager.GetCurrentActionForVisualizer(OwnerUnit));
			if (FireAction != none)
			{
				TargetUnit = XGUnit(FireAction.PrimaryTarget);
				TargetPawn = TargetUnit.GetPawn();
				`LOG("AnimNotify_TriggerHitReaction Target" @ TargetUnit @ TargetPawn @ FireAction,, 'PrimarySecondaries');
				if (TargetPawn != none)
				{
					
					if (RandomReactionAnimSequence)
					{
						AnimParams.AnimName = RandomSequences[`SYNC_RAND_STATIC(3)];
					}
					else
					{
						AnimParams.AnimName = ReactionAnimSequence;
					}

					if (!TargetPawn.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName))
					{
						AnimParams.AnimName = default.ReactionAnimSequence;
					}

					TargetPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
					TargetPawn.PlayHitEffects(
						BloodAmount,
						OwnerUnit,
						TargetPawn.GetHeadshotLocation(),
						DamageTypeName,
						Normal(TargetPawn.GetHeadshotLocation()) * 500.0f,
						false,
						HitResult
					);

					`LOG("AnimNotify_TriggerHitReaction triggered" @ AnimParams.AnimName @ DamageTypeName @ HitResult @ BloodAmount,, 'PrimarySecondaries');
					
				}
			}
		}
	}
	super.Notify(Owner, AnimSeqInstigator);
}

defaultproperties
{
	ReactionAnimSequence = "HL_HurtFront"
	DamageTypeName = "DefaultProjectile"
	RandomReactionAnimSequence = false
	BloodAmount = 1
	HitResult = eHit_Success
}