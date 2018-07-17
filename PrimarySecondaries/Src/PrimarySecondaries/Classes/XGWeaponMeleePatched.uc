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
	
	`LOG(Class.Name @ "Spawn" @ m_kEntity @ ItemState.GetMyTemplateName() @ XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length,, 'PrimarySecondaries');

	// Shields
	if (class'X2DownloadableContentInfo_PrimarySecondaries'.static.HasShieldEquipped(UnitState))
	{
		if (class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsPrimaryMeleeWeaponTemplate(WeaponTemplate))
		{
			XComWeapon(m_kEntity).DefaultSocket = 'R_Hand';
		}
	}
	// Dual Melee
	else if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.HasDualMeleeEquipped(UnitState))
	{
		if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsPrimaryMeleeWeaponTemplate(WeaponTemplate))
		{
			XComWeapon(m_kEntity).DefaultSocket = 'R_Hand';
			`LOG(Class.Name @ "Patching socket to R_Hand",, 'PrimarySecondaries');

			// Patching the sequence name from FF_MeleeA to FF_Melee to support random sets via prefixes A,B,C etc
			XComWeapon(m_kEntity).WeaponFireAnimSequenceName = 'FF_Melee';
			XComWeapon(m_kEntity).WeaponFireKillAnimSequenceName = 'FF_MeleeKill';
		}

		if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsSecondaryMeleeWeaponTemplate(WeaponTemplate))
		{
			XComWeapon(m_kEntity).DefaultSocket = 'L_Hand';
			`LOG(Class.Name @ "Patching socket to L_Hand",, 'PrimarySecondaries');
		}

		if(WeaponTemplate.iRange == 0)
		{
			XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
			XComWeapon(m_kEntity).CustomUnitPawnAnimsetsFemale.Length = 0;
			XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("DualSword.Anims.AS_Sword")));
			`LOG(Class.Name @ "Adding DualSword.Anims.AS_Sword",, 'PrimarySecondaries');
		}
	}
	// Primary Melee (We are patching also secondary swords here if the primary is a pistol)
	else if (class'X2DownloadableContentInfo_PrimarySecondaries'.static.HasPrimaryMeleeOrPistolEquipped(UnitState))
	{
		// 
		if (
			(WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon || InStr(string(PrimaryWeaponTemplate.DataName), "_Primary") != INDEX_NONE) &&
			class'X2DownloadableContentInfo_PrimarySecondaries'.default.PatchMeleeCategoriesAnimBlackList.Find(WeaponTemplate.WeaponCat) == INDEX_NONE
		)
		{
			if (InStr(WeaponTemplate.DataName, "SpecOpsKnife") == INDEX_NONE)
			{
				XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
				XComWeapon(m_kEntity).CustomUnitPawnAnimsetsFemale.Length = 0;
				XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_ANIM.Anims.AS_Melee")));
			}
			else
			{
				XComWeapon(m_kEntity).CustomUnitPawnAnimsets.Length = 0;
				XComWeapon(m_kEntity).CustomUnitPawnAnimsetsFemale.Length = 0;
				XComWeapon(m_kEntity).CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_ANIM.Anims.AS_KnifeMelee")));
			}
		}

		//if(class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsPrimaryMeleeWeaponTemplate(WeaponTemplate) ||
		//	class'X2DownloadableContentInfo_PrimarySecondaries'.static.IsSecondaryMeleeWeaponTemplate(WeaponTemplate))
		//{
		//	XComWeapon(m_kEntity).DefaultSocket = 'SwordSheath';
		//	`LOG(Class.Name @ "Patching socket to SwordSheath",, 'PrimarySecondaries');
		//}
	}


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