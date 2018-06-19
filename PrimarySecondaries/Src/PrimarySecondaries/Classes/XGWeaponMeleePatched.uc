class XGWeaponMeleePatched extends XGWeapon;

simulated function Actor CreateEntity(optional XComGameState_Item ItemState=none)
{
	local X2WeaponTemplate WeaponTemplate, PrimaryWeaponTemplate, SecondaryWeaponTemplate;
	local XComGameState_Unit UnitState;

	super.CreateEntity(ItemState);

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));
	PrimaryWeaponTemplate = X2WeaponTemplate(UnitState.GetPrimaryWeapon().GetMyTemplate());
	SecondaryWeaponTemplate = X2WeaponTemplate(UnitState.GetSecondaryWeapon().GetMyTemplate());
	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
	
	// Dual Melee
	if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.HasDualSwordsEquipped(UnitState))
	{
		if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsPrimarySwordWeaponTemplate(WeaponTemplate))
		{
			XComWeapon(m_kEntity).DefaultSocket = 'R_Hand';
			`LOG(Class.Name @ "Patching socket to R_Hand",, 'PrimarySecondaries');
		}

		if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsSecondarySwordWeaponTemplate(WeaponTemplate))
		{
			XComWeapon(m_kEntity).DefaultSocket = 'L_Hand';
			`LOG(Class.Name @ "Patching socket to L_Hand",, 'PrimarySecondaries');
		}

		if(class'X2DownloadableContentInfo_PrimarySecondaries'.default.MeleeCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE)
		{
			XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
			XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("DualSword.Anims.AS_Sword")));
			`LOG(Class.Name @ "Adding DualSword.Anims.AS_Sword",, 'PrimarySecondaries');
		}
	}
	// Shields
	else if (SecondaryWeaponTemplate.WeaponCat == 'shield')
	{
		if (class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsPrimarySwordWeaponTemplate(WeaponTemplate))
		{
			XComWeapon(m_kEntity).DefaultSocket = 'R_Hand';
		}
	}
	// Primary Melee
	else
	{
		// We are patching also secondary swords here if the primary is a pistol
		if (WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon || InStr(string(PrimaryWeaponTemplate.DataName), "_Primary") != INDEX_NONE)
		{
			XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
			XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimaryPistols_ANIM.Anims.AS_Melee")));
		}

		if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsPrimarySwordWeaponTemplate(WeaponTemplate) ||
			class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsSecondarySwordWeaponTemplate(WeaponTemplate))
		{
			XComWeapon(m_kEntity).DefaultSocket = 'SwordSheath';
			`LOG(Class.Name @ "Patching socket to SwordSheath",, 'PrimarySecondaries');
		}
	}

	`LOG(Class.Name @ "Spawn" @ m_kEntity @ ItemState.GetMyTemplateName() @ XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length,, 'PrimarySecondaries');

	return m_kEntity;
}

// Make sheats tintable and use patterns
simulated function UpdateWeaponMaterial(MeshComponent MeshComp, MaterialInstanceConstant MIC)
{
	local int i, a;
	local MaterialInterface Mat;
	local MaterialInstanceConstant AttachmentMIC;
	
	super.UpdateWeaponMaterial(MeshComp, MIC);

	MIC.SetScalarParameterValue('PatternUse', 0);
	
	for (i = 0; i < PawnAttachments.Length; ++i)
	{
		if (PawnAttachments.Find(MeshComp) == INDEX_NONE)
		{
			for (a = 0; a < SkeletalMeshComponent(PawnAttachments[i]).GetNumElements(); ++a)
			{
				Mat = SkeletalMeshComponent(PawnAttachments[i]).GetMaterial(a);
				AttachmentMIC = MaterialInstanceConstant(Mat);

				if (AttachmentMIC != none)
				{
					//`LOG("Apply tint and pattern to" @ SkeletalMeshComponent(PawnAttachments[i]).Name @ AttachmentMIC @ InStr(String(AttachmentMIC), "Katana3Saya"),, 'KatanaMod');
					super.UpdateWeaponMaterial(SkeletalMeshComponent(PawnAttachments[i]), AttachmentMIC);
				}
			}
		}
	}
}