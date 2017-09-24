class XGWeaponPatched extends XGWeapon;

simulated function Actor CreateEntity(optional XComGameState_Item ItemState=none)
{
	super.CreateEntity(ItemState);

	XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
	//if (X2WeaponTemplate(ItemState.GetMyTemplate()).WeaponCat == 'sidearm')
	//{
	//	XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimaryPistols_ANIM.Anims.AS_TemplarAutoPistol")));
	//}
	//else if (X2WeaponTemplate(ItemState.GetMyTemplate()).WeaponCat == 'pistol')
	//{
	//	XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("Soldier_ANIM.Anims.AS_Pistol")));
	//}

	`LOG(Class.Name @ "Spawn" @ m_kEntity @ ItemState.GetMyTemplateName() @ X2WeaponTemplate(ItemState.GetMyTemplate()).WeaponCat @ XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length,, 'PrimarySecondaries');

	return m_kEntity;
}
