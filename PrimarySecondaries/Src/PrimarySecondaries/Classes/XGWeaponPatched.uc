class XGWeaponPatched extends XGWeapon;

simulated function Actor CreateEntity(optional XComGameState_Item ItemState=none)
{
	local X2WeaponTemplate WeaponTemplate, PrimaryWeaponTemplate, SecondaryWeaponTemplate;
	local XComGameState_Unit UnitState;
	//local XComGameState_Item PrivateWeaponState;

	super.CreateEntity(ItemState);

	//PrivateWeaponState = XComGameState_Item(History.GetGameStateForObjectID(ObjectID));
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));
	PrimaryWeaponTemplate = X2WeaponTemplate(UnitState.GetPrimaryWeapon().GetMyTemplate());
	SecondaryWeaponTemplate = X2WeaponTemplate(UnitState.GetSecondaryWeapon().GetMyTemplate());
	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

	`LOG(Class.Name @ UnitState.GetFullName() @ "Primary Weapon" @ PrimaryWeaponTemplate.DataName,, 'PrimarySecondaries');

	// Dual Pistols
	if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.HasDualPistolEquipped(UnitState))
	{
		if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsPrimaryPistolWeaponTemplate(WeaponTemplate))
		{
			XComWeapon(m_kEntity).DefaultSocket = 'R_Hand';
			`LOG(Class.Name @ "Patching socket to R_Hand",, 'PrimarySecondaries');
		}

		if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsSecondaryPistolWeaponTemplate(WeaponTemplate))
		{
			XComWeapon(m_kEntity).DefaultSocket = 'L_Hand';
			`LOG(Class.Name @ "Patching socket to L_Hand",, 'PrimarySecondaries');
		}

		if(class'X2DownloadableContentInfo_PrimarySecondaries'.default.PistolCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE)
		{
			//XComWeapon(m_kEntity).WeaponAimProfileType = WAP_DualPistol;

			XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
			XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("WP_OffhandPistol_CV.Anims.AS_OffhandPistol")));
			`LOG(Class.Name @ "Adding AS_OffhandPistol",, 'PrimarySecondaries');
		}
	}
	// Shields
	else if (SecondaryWeaponTemplate.WeaponCat == 'shield')
	{
		if (WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon && (WeaponTemplate.WeaponCat == 'sidearm' || WeaponTemplate.WeaponCat == 'pistol'))
		{
			XComWeapon(m_kEntity).DefaultSocket = 'R_Hand';
		}
	}
	// Primary secondaries
	else
	{
		// We are patching also secondary pistols here if the primary is a sword
		if (WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon || InStr(string(PrimaryWeaponTemplate.DataName), "_Primary") != INDEX_NONE)
		{
			if (WeaponTemplate.WeaponCat == 'sidearm')
			{
				//XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
				XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_ANIM.Anims.AS_AutoPistol")));
				`LOG(Class.Name @ "Adding AS_AutoPistol",, 'PrimarySecondaries');
			}
			else if (WeaponTemplate.WeaponCat == 'pistol')
			{
				//XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
				XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_ANIM.Anims.AS_PrimaryPistol")));
				`LOG(Class.Name @ "Adding AS_PrimaryPistol",, 'PrimarySecondaries');
			}
		}

		// Reset the socket
		if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsPrimaryPistolWeaponTemplate(WeaponTemplate) ||
			class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsSecondaryPistolWeaponTemplate(WeaponTemplate))
		{
			if (WeaponTemplate.WeaponCat != 'sawedoffshotgun')
			{
				XComWeapon(m_kEntity).DefaultSocket = 'PistolHolster';
				`LOG(Class.Name @ "Patching socket to PistolHolster",, 'PrimarySecondaries');
			}
		}
	}

	`LOG(Class.Name @ "Spawn" @ m_kEntity @ ItemState.GetMyTemplateName() @ WeaponTemplate.WeaponCat @ XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length @ XComWeapon(m_kEntity).CustomUnitPawnAnimsets[0],, 'PrimarySecondaries');

	return m_kEntity;
}
