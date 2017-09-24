class XGWeaponMeleePatched extends XGWeapon;

simulated function Actor CreateEntity(optional XComGameState_Item ItemState=none)
{
	super.CreateEntity(ItemState);
	
	XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
	XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimaryPistols_ANIM.Anims.AS_Melee")));
	// Reload the animsets
	//UnitPawn.UpdateAnimations();
	`LOG(Class.Name @ "Spawn" @ m_kEntity @ ItemState.GetMyTemplateName() @ XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length,, 'PrimarySecondaries');

	return m_kEntity;
}
