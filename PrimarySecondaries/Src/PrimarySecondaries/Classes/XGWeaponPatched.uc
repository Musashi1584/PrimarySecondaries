class XGWeaponPatched extends XGWeapon;

simulated function Actor CreateEntity(optional XComGameState_Item ItemState=none)
{
	local XComWeapon Template;
	
	super.CreateEntity(ItemState);
	
	if (m_kEntity != none)
	{
		Template = XComWeapon(m_kEntity);
		m_kEntity = Spawn(Template.Class, Template.Owner,,,,Template);
		
		//XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
		//if (X2WeaponTemplate(ItemState.GetMyTemplate()).WeaponCat == 'sidearm')
		//{
		//	XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimaryPistols_ANIM.Anims.AS_TemplarAutoPistol")));
		//}
		//else
		//{
		//	XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Soldier_ANIM.Anims.AS_Pistol")));
		//}

		`LOG(Class.Name @ "Spawn" @ m_kEntity @ ItemState.GetMyTemplateName() @ Template.CustomUnitPawnAnimsets.Length,, 'PrimarySecondaries');
	}
	else
	{
		`LOG(Class.Name @ "Could not spawn entity for" @ ItemState.GetMyTemplateName(),, 'PrimarySecondaries');
	}
	return m_kEntity;
}
