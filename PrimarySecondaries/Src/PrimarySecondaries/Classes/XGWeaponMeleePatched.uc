class XGWeaponMeleePatched extends XGWeapon;

simulated function Actor CreateEntity(optional XComGameState_Item ItemState=none)
{
	local XComWeapon Template;
	
	super.CreateEntity(ItemState);
	
	if (m_kEntity != none)
	{
		Template = XComWeapon(m_kEntity);
		m_kEntity = Spawn(Template.Class, Template.Owner,,,,Template);
		XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
		XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimaryPistols_ANIM.Anims.AS_Melee")));
		// Reload the animsets
		//UnitPawn.UpdateAnimations();
		`LOG(Class.Name @ "Spawn" @ m_kEntity @ ItemState.GetMyTemplateName() @ Template.CustomUnitPawnAnimsets.Length,, 'PrimarySecondaries');
	}
	else
	{
		`LOG(Class.Name @ "Could not spawn entity for" @ ItemState.GetMyTemplateName(),, 'PrimarySecondaries');
	}
	return m_kEntity;
}
