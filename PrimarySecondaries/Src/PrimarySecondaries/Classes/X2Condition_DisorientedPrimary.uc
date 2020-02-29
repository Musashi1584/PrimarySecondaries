class X2Condition_DisorientedPrimary extends X2Condition;

//	This condition fails if the source unit is disoriented and the ability is not attached to a primary weapon

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget) 
{
	local XComGameState_Unit SourceUnit;
	local XComGameState_Item SourceWeapon;

	SourceWeapon = kAbility.GetSourceWeapon();
	if (SourceWeapon == none) return 'AA_WeaponIncompatible';

	if (SourceWeapon.InventorySlot == eInvSlot_PrimaryWeapon)
	{
		return 'AA_Success'; 
	}
	else
	{
		SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
		if (SourceUnit == none) return 'AA_NotAUnit';

		if (SourceUnit.IsUnitAffectedByEffectName(class'X2AbilityTemplateManager'.default.DisorientedName))
		{
			return 'AA_UnitIsDisoriented';
		}
		else return 'AA_Success'; 
	}
	return 'AA_Success'; 
}