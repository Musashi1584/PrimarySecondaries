class X2AbilityCost_QuickdrawActionPointsPatched extends X2AbilityCost_ActionPoints;

simulated function bool ConsumeAllPoints(XComGameState_Ability AbilityState, XComGameState_Unit AbilityOwner)
{
	`LOG("X2AbilityCost_QuickdrawActionPointsPatched" @ AbilityState.GetMyTemplateName() @ AbilityOwner.HasSoldierAbility('Quickdraw') @ X2WeaponTemplate(AbilityState.GetSourceWeapon().GetMyTemplate()).WeaponCat,, 'PrimarySecondaries');
	if (AbilityOwner.HasSoldierAbility('Quickdraw') &&
		X2WeaponTemplate(AbilityState.GetSourceWeapon().GetMyTemplate()).WeaponCat == 'pistol')
	{
		return false;
	}
	return super.ConsumeAllPoints(AbilityState, AbilityOwner);
}