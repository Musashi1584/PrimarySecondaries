class X2DownloadableContentInfo_PrimarySecondaries extends X2DownloadableContentInfo
	config (PrimarySecondaries);


struct AmmoCost
{
	var name Ability;
	var int Ammo;
};

struct PistolWeaponAttachment {
	var string Type;
	var name AttachSocket;
	var name UIArmoryCameraPointTag;
	var string MeshName;
	var string ProjectileName;
	var name MatchWeaponTemplate;
	var bool AttachToPawn;
	var string IconName;
	var string InventoryIconName;
	var string InventoryCategoryIcon;
	var name AttachmentFn;
};

struct ArchetypeReplacement {
	var() name TemplateName;
	var() string GameArchetype;
	var() int NumUpgradeSlots;
};

var config array<AmmoCost> AmmoCosts;
var config array<ArchetypeReplacement> ArchetypeReplacements;
var config array<PistolWeaponAttachment> PistolAttachements;
var config array<name> PistolCategories;
var config int PRIMARY_PISTOLS_CLIP_SIZE;
var config int PRIMARY_SAWEDOFF_CLIP_SIZE;
var config int PRIMARY_PISTOLS_DAMAGE_MODIFER;
var config bool bPrimaryPistolsInfiniteAmmo;
var config bool bUseVisualPistolUpgrades;

var delegate<OnEquippedDelegate> OnOldEquippedFn;
var delegate<OnEquippedDelegate> OnOldUnequippedFn;

delegate OnEquippedDelegate(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState);

static function bool IsLW2Installed()
{
	return IsModInstalled('X2DownloadableContentInfo_LW_Overhaul');
}

static function bool IsModInstalled(name X2DCLName)
{
	local X2DownloadableContentInfo Mod;
	foreach `ONLINEEVENTMGR.m_cachedDLCInfos (Mod)
	{
		if (Mod.Class.Name == X2DCLName)
		{
			`Log("Mod installed:" @ Mod.Class);
			return true;
		}
	}

	return false;
}

static function MatineeGetPawnFromSaveData(XComUnitPawn UnitPawn, XComGameState_Unit UnitState, XComGameState SearchState)
{
	class'ShellMapMatinee'.static.PatchAllLoadedMatinees(UnitPawn, UnitState, SearchState);
}

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{
	UpdateStorage();
}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{
	UpdateStorage();
}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	PatchAbilityTemplates();
	AddAttachments();
	AddPrimarySecondaries();
	CheckUniqueWeaponCategories();
	if (default.bUseVisualPistolUpgrades)
	{
		ReplacePistolArchetypes();
	}
	//AddEqippDelegates();
}

static function UpdateStorage()
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemTemplateMgr;
	local X2DataTemplate ItemTemplate;
	local array<X2ItemTemplate> ItemTemplates;
	local name TemplateName;
	local XComGameState_Item NewItemState;
	local array<name> AllTemplateNames;
	local int i;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(" Updating HQ Storage to add primary pistol variants");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));


	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplateMgr.GetTemplateNames(AllTemplateNames);

	foreach AllTemplateNames(TemplateName)
	{
		ItemTemplate = ItemTemplateMgr.FindItemTemplate(TemplateName);
		if (!IsPistolWeaponTemplate(X2WeaponTemplate(ItemTemplate)) && !IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate(ItemTemplate)))
			continue;

		if (XComHQ.HasItem(X2ItemTemplate(ItemTemplate)))
		{
			ItemTemplate = ItemTemplateMgr.FindItemTemplate(name(ItemTemplate.DataName $ "_Primary"));
			if (!XComHQ.HasItem(X2ItemTemplate(ItemTemplate)))
			{
				`LOG("Adding to HQ" @ ItemTemplate.DataName,, 'PrimarySecondaries');
				NewItemState = X2ItemTemplate(ItemTemplate).CreateInstanceFromTemplate(NewGameState);
				NewGameState.AddStateObject(NewItemState);
				XComHQ.AddItemToHQInventory(NewItemState);
			}
		}
	}

	ItemTemplates.AddItem(ItemTemplateMgr.FindItemTemplate('EmptySecondary'));
	for (i = 0; i < ItemTemplates.Length; ++i)
	{
		if(ItemTemplates[i] != none)
		{
			if (!XComHQ.HasItem(ItemTemplates[i]))
			{
				`Log(ItemTemplates[i].GetItemFriendlyName() @ " not found, adding to inventory",, 'PrimarySecondaries');
				NewItemState = ItemTemplates[i].CreateInstanceFromTemplate(NewGameState);
				NewGameState.AddStateObject(NewItemState);
				XComHQ.AddItemToHQInventory(NewItemState);
			}
		}
	}

	History.AddGameStateToHistory(NewGameState);
	History.CleanupPendingGameState(NewGameState);
}


static function AddAttachments()
{
	local array<name> AttachmentTypes;
	local name AttachmentType;
	
	AttachmentTypes.AddItem('CritUpgrade_Bsc');
	AttachmentTypes.AddItem('CritUpgrade_Adv');
	AttachmentTypes.AddItem('CritUpgrade_Sup');
	AttachmentTypes.AddItem('AimUpgrade_Bsc');
	AttachmentTypes.AddItem('AimUpgrade_Adv');
	AttachmentTypes.AddItem('AimUpgrade_Sup');
	AttachmentTypes.AddItem('ClipSizeUpgrade_Bsc');
	AttachmentTypes.AddItem('ClipSizeUpgrade_Adv');
	AttachmentTypes.AddItem('ClipSizeUpgrade_Sup');
	AttachmentTypes.AddItem('FreeFireUpgrade_Bsc');
	AttachmentTypes.AddItem('FreeFireUpgrade_Adv');
	AttachmentTypes.AddItem('FreeFireUpgrade_Sup');
	AttachmentTypes.AddItem('ReloadUpgrade_Bsc');
	AttachmentTypes.AddItem('ReloadUpgrade_Adv');
	AttachmentTypes.AddItem('ReloadUpgrade_Sup');
	AttachmentTypes.AddItem('MissDamageUpgrade_Bsc');
	AttachmentTypes.AddItem('MissDamageUpgrade_Adv');
	AttachmentTypes.AddItem('MissDamageUpgrade_Sup');
	AttachmentTypes.AddItem('FreeKillUpgrade_Bsc');
	AttachmentTypes.AddItem('FreeKillUpgrade_Adv');
	AttachmentTypes.AddItem('FreeKillUpgrade_Sup');

	foreach AttachmentTypes(AttachmentType)
	{
		AddAttachment(AttachmentType, default.PistolAttachements);
	}
}


static function AddAttachment(name TemplateName, array<PistolWeaponAttachment> Attachments) 
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2WeaponUpgradeTemplate Template;
	local PistolWeaponAttachment Attachment;
	local delegate<X2TacticalGameRulesetDataStructures.CheckUpgradeStatus> CheckFN;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	Template = X2WeaponUpgradeTemplate(ItemTemplateManager.FindItemTemplate(TemplateName));
	
	foreach Attachments(Attachment)
	{
		if (InStr(string(TemplateName), Attachment.Type) != INDEX_NONE)
		{
			switch(Attachment.AttachmentFn) 
			{
				case ('NoReloadUpgradePresent'): 
					CheckFN = class'X2Item_DefaultUpgrades'.static.NoReloadUpgradePresent; 
					break;
				case ('ReloadUpgradePresent'): 
					CheckFN = class'X2Item_DefaultUpgrades'.static.ReloadUpgradePresent; 
					break;
				case ('NoClipSizeUpgradePresent'): 
					CheckFN = class'X2Item_DefaultUpgrades'.static.NoClipSizeUpgradePresent; 
					break;
				case ('ClipSizeUpgradePresent'): 
					CheckFN = class'X2Item_DefaultUpgrades'.static.ClipSizeUpgradePresent; 
					break;
				case ('NoFreeFireUpgradePresent'): 
					CheckFN = class'X2Item_DefaultUpgrades'.static.NoFreeFireUpgradePresent; 
					break;
				case ('FreeFireUpgradePresent'): 
					CheckFN = class'X2Item_DefaultUpgrades'.static.FreeFireUpgradePresent; 
					break;
				default:
					CheckFN = none;
					break;
			}
			Template.AddUpgradeAttachment(Attachment.AttachSocket, Attachment.UIArmoryCameraPointTag, Attachment.MeshName, Attachment.ProjectileName, Attachment.MatchWeaponTemplate, Attachment.AttachToPawn, Attachment.IconName, Attachment.InventoryIconName, Attachment.InventoryCategoryIcon, CheckFN);
			//`LOG("Attachment for "@TemplateName @Attachment.AttachSocket @Attachment.UIArmoryCameraPointTag @Attachment.MeshName @Attachment.ProjectileName @Attachment.MatchWeaponTemplate @Attachment.AttachToPawn @Attachment.IconName @Attachment.InventoryIconName @Attachment.InventoryCategoryIcon,, 'PrimarySecondaries');
		}
	}
}



static function CheckUniqueWeaponCategories()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local name Category;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach ItemTemplateManager.UniqueEquipCategories(Category)
	{
		`LOG('UniqueEquipCategories' @ Category,, 'PrimarySecondaries');
	}
}

// Unused
//
static function AddEqippDelegates()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficultyVariants;
	local X2DataTemplate ItemTemplate;
	local array<X2WeaponTemplate> WeaponTemplates;
	local X2WeaponTemplate IterateTemplate, WeaponTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	
	WeaponTemplates = ItemTemplateManager.GetAllWeaponTemplates();
	foreach WeaponTemplates(IterateTemplate)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DifficultyVariants);
		// Iterate over all variants
		foreach DifficultyVariants(ItemTemplate)
		{
			WeaponTemplate = X2WeaponTemplate(ItemTemplate);
			if (WeaponTemplate != none)
			{
				//OnOldEquippedFn = WeaponTemplate.OnEquippedFn;
				//OnOldUnequippedFn = WeaponTemplate.OnUnequippedFn;

				//WeaponTemplate.OnEquippedFn = PistolEquipped;
				//WeaponTemplate.OnUnequippedFn = PistolUnEquipped;
			}
		}
	}
}

static function ReplacePistolArchetypes()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficultyVariants;
	local X2DataTemplate ItemTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local ArchetypeReplacement Replacement;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	
	foreach default.ArchetypeReplacements(Replacement)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(Replacement.TemplateName, DifficultyVariants);
		// Iterate over all variants
		foreach DifficultyVariants(ItemTemplate)
		{
			WeaponTemplate = X2WeaponTemplate(ItemTemplate);
			if (WeaponTemplate != none)
			{
				WeaponTemplate.GameArchetype = Replacement.GameArchetype;
				WeaponTemplate.NumUpgradeSlots = Replacement.NumUpgradeSlots;
				WeaponTemplate.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Shotgun';

				ItemTemplateManager.AddItemTemplate(WeaponTemplate, true);
				`Log("Patching " @ ItemTemplate.DataName @ "with" @ Replacement.GameArchetype @ "and" @ Replacement.NumUpgradeSlots @ "upgrade slots",, 'PrimarySecondaries');
			}
		}
	}

	ItemTemplateManager.LoadAllContent();
}

static function PatchAbilityTemplates()
{
	local X2AbilityTemplateManager						TemplateManager;
	local X2AbilityTemplate								Template;
	local X2AbilityCost_Ammo							NewAmmoCosts;
	local X2AbilityCost									CurrentAbilityCosts;
	local AmmoCost										AbilityAmmoCost;
	local bool											bHasAmmoCost;
	local array<X2AbilityTemplate>						AbilityTemplates;
	local array<name>									TemplateNames;
	local name											TemplateName;
	local X2AbilityCost_ActionPoints					ActionPointCost;
	
	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach default.AmmoCosts(AbilityAmmoCost)
	{
		TemplateManager.FindAbilityTemplateAllDifficulties(AbilityAmmoCost.Ability, AbilityTemplates);
		foreach AbilityTemplates(Template)
		{
			if (Template != none)
			{
				bHasAmmoCost = false;
				foreach Template.AbilityCosts(CurrentAbilityCosts)
				{
					if (X2AbilityCost_Ammo(CurrentAbilityCosts) != none)
					{
						X2AbilityCost_Ammo(CurrentAbilityCosts).iAmmo =  AbilityAmmoCost.Ammo;
						bHasAmmoCost = true;
						break;
					}
				}
				if (!bHasAmmoCost)
				{
					NewAmmoCosts = new class'X2AbilityCost_Ammo';
					NewAmmoCosts.iAmmo = AbilityAmmoCost.Ammo;
					Template.AbilityCosts.AddItem(NewAmmoCosts);
				}
				`LOG("Patching Template" @ AbilityAmmoCost.Ability @ "adding" @ AbilityAmmoCost.Ammo @ "ammo cost",, 'PrimarySecondaries');
			}
		}
	}

	TemplateNames.AddItem('PistolStandardShot');
	
	foreach TemplateNames(TemplateName)
	{
		Template = TemplateManager.FindAbilityTemplate(TemplateName);
		if (Template != none)
		{
			ActionPointCost = X2AbilityCost_ActionPoints(Template.AbilityCosts[0]);
			if (ActionPointCost != none && ActionPointCost.DoNotConsumeAllSoldierAbilities.Find('QuickDrawPrimary') == INDEX_NONE)
			{
				ActionPointCost.DoNotConsumeAllSoldierAbilities.AddItem('QuickDrawPrimary');
				ActionPointCost.DoNotConsumeAllSoldierAbilities.AddItem('Quickdraw');
				`LOG("Patching Template" @ TemplateName @ "adding QuickDrawPrimary and Quickdraw to DoNotConsumeAllSoldierAbilities",, 'PrimarySecondaries');
			}
		}
	}
}

static function AddPrimarySecondaries()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficultyVariants;
	local array<name> TemplateNames;
	local name TemplateName;
	local X2DataTemplate ItemTemplate;
	local X2WeaponTemplate WeaponTemplate, ClonedTemplate;
	local array<X2WeaponUpgradeTemplate> UpgradeTemplates;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local WeaponAttachment UpgradeAttachment;
	local array<WeaponAttachment> UpgradeAttachmentsToAdd;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	UpgradeTemplates = ItemTemplateManager.GetAllUpgradeTemplates();

	ItemTemplateManager.GetTemplateNames(TemplateNames);

	foreach TemplateNames(TemplateName)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(TemplateName, DifficultyVariants);
		// Iterate over all variants
		
		foreach DifficultyVariants(ItemTemplate)
		{
			ClonedTemplate = none;
			WeaponTemplate = X2WeaponTemplate(ItemTemplate);

			if (WeaponTemplate == none)
				continue;

			//`Log(WeaponTemplate.DataName @ WeaponTemplate.StowedLocation @ WeaponTemplate.WeaponCat, , 'PrimaryMeleeWeapons');

			if (IsPistolWeaponTemplate(WeaponTemplate))
			{
				ClonedTemplate = new class'X2WeaponTemplate' (WeaponTemplate);
				ClonedTemplate.SetTemplateName(name(TemplateName $ "_Primary"));
				ClonedTemplate.InventorySlot =  eInvSlot_PrimaryWeapon;
				ClonedTemplate.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Shotgun';

				ClonedTemplate.Abilities.AddItem('DualShotPrimary');
				ClonedTemplate.Abilities.AddItem('DualPistolOverwatch');
				
				if (ClonedTemplate.Abilities.Find('PistolStandardShot') == INDEX_NONE)
				{
					ClonedTemplate.Abilities.AddItem('PistolStandardShot');
				}
				ClonedTemplate.Abilities.AddItem('PrimaryPistolsBonus');
				//ClonedTemplate.Abilities.AddItem('PrimaryAnimSet');

				if (ClonedTemplate.WeaponCat == 'sawedoffshotgun')
				{
					ClonedTemplate.iClipSize = default.PRIMARY_SAWEDOFF_CLIP_SIZE;
				}
				else
				{
					ClonedTemplate.iClipSize = default.PRIMARY_PISTOLS_CLIP_SIZE;
				}
				ClonedTemplate.InfiniteAmmo = default.bPrimaryPistolsInfiniteAmmo;
				ClonedTemplate.BaseDamage.Damage += default.PRIMARY_PISTOLS_DAMAGE_MODIFER;
				
				ClonedTemplate.GameplayInstanceClass = class'XGWeaponPatched';
				WeaponTemplate.GameplayInstanceClass = class'XGWeaponPatched';
				
				`LOG(WeaponTemplate.DataName @ WeaponTemplate.GameplayInstanceClass,, 'PrimarySecondaries');
			}

			if (IsSecondaryMeleeWeaponTemplate(WeaponTemplate))
			{
				ClonedTemplate = new class'X2WeaponTemplate' (WeaponTemplate);
				ClonedTemplate.SetTemplateName(name(TemplateName $ "_Primary"));
				ClonedTemplate.InventorySlot =  eInvSlot_PrimaryWeapon;
				if (ClonedTemplate.Abilities.Find('SwordSlice') == INDEX_NONE)
				{
					ClonedTemplate.Abilities.AddItem('SwordSlice');
				}

				WeaponTemplate.Abilities.AddItem('DualSlashSecondary');

				ClonedTemplate.GameplayInstanceClass = class'XGWeaponMeleePatched';
				WeaponTemplate.GameplayInstanceClass = class'XGWeaponMeleePatched';
			}

			if (ClonedTemplate != none)
			{
				// Generic attachments
				foreach UpgradeTemplates(UpgradeTemplate)
				{
					UpgradeAttachmentsToAdd.Length = 0;

					foreach UpgradeTemplate.UpgradeAttachments(UpgradeAttachment)
					{
						if (UpgradeAttachment.ApplyToWeaponTemplate == TemplateName)
						{
							UpgradeAttachment.ApplyToWeaponTemplate = name(TemplateName $ "_Primary");
							UpgradeAttachmentsToAdd.AddItem(UpgradeAttachment);
						}
					}

					foreach UpgradeAttachmentsToAdd(UpgradeAttachment)
					{
						//`Log("Adding Attachment" @ UpgradeAttachment.ApplyToWeaponTemplate @ UpgradeAttachment.AttachMeshName,, 'PrimarySecondaries');
						UpgradeTemplate.UpgradeAttachments.AddItem(UpgradeAttachment);
					}
				}

				// Make sure the templates get added to the bottom if the list
				ClonedTemplate.Tier -= 1;

				ItemTemplateManager.AddItemTemplate(ClonedTemplate, true);
			}

		}

		if (ClonedTemplate != none)
		{
			`Log("Generating Template" @ TemplateName $ "_Primary with" @ ClonedTemplate.DefaultAttachments.Length @ "default attachments",, 'PrimarySecondaries');
		}
	}

	ItemTemplateManager.LoadAllContent();
}

static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
	local AnimSet IterateAnimSet;
	local bool bLog;

	bLog = true;
	
	if (HasPrimaryMeleeOrPistolEquipped(UnitState))
	{
		// Force Personality_ByTheBook
		UnitState.kAppearance.iAttitude = 0;
		UnitState.UpdatePersonalityTemplate();
		AddAnimSet(Pawn, AnimSet(`CONTENT.RequestGameArchetype("HQ_ANIM.Anims.AS_Armory_Unarmed")), 3);
		AddAnimSet(Pawn, AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_ANIM.Anims.AS_Primary")), 4);
		
		Pawn.Mesh.UpdateAnimations();

		foreach Pawn.Mesh.AnimSets(IterateAnimSet)
		{
			`LOG(GetFuncName() @ UnitState.GetFullName() @ "current animsets: " @ IterateAnimSet, bLog, 'PrimarySecondaries');
		}
		`LOG(GetFuncName() @ UnitState.GetFullName() @ "------------------", bLog, 'PrimarySecondaries');
	}
}

static function AddAnimSet(XComUnitPawn Pawn, AnimSet AnimSetToAdd, optional int Index = -1)
{
	if (Pawn.Mesh.AnimSets.Find(AnimSetToAdd) == INDEX_NONE)
	{
		if (Index != INDEX_NONE)
		{
			Pawn.Mesh.AnimSets.InsertItem(Index, AnimSetToAdd);
		}
		else
		{
			Pawn.Mesh.AnimSets.AddItem(AnimSetToAdd);
		}
		//`LOG(GetFuncName() @ "adding" @ AnimSetToAdd,, 'PrimarySecondaries');
	}
}

static function bool HasPrimaryMeleeOrPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return HasPrimaryMeleeEquipped(UnitState, CheckGameState) || HasPrimaryPistolEquipped(UnitState, CheckGameState);
}

static function bool HasPrimaryMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate())) &&
		!HasDualPistolEquipped(UnitState, CheckGameState) &&
		!HasDualMeleeEquipped(UnitState, CheckGameState) &&
		!HasShieldEquipped(UnitState, CheckGameState);
}

static function bool HasPrimaryPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsPrimaryPistolWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate())) &&
		!HasDualPistolEquipped(UnitState, CheckGameState) &&
		!HasDualMeleeEquipped(UnitState, CheckGameState) &&
		!HasShieldEquipped(UnitState, CheckGameState);
}

static function bool HasShieldEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	local X2WeaponTemplate SecondaryWeaponTemplate;
	SecondaryWeaponTemplate = X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate());
	return SecondaryWeaponTemplate.WeaponCat == 'shield';
}

static function bool HasDualPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsPrimaryPistolWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate())) &&
		IsSecondaryPistolWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate()));
}

static function bool CheckDualPistolGetsEquipped(XComGameState_Unit UnitState, XComGameState_Item ItemState, optional XComGameState CheckGameState)
{
	return (IsPrimaryPistolWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate())) &&
		IsSecondaryPistolWeaponTemplate(X2WeaponTemplate(ItemState.GetMyTemplate())))
		||
		(IsPrimaryPistolWeaponTemplate(X2WeaponTemplate(ItemState.GetMyTemplate())) &&
		IsSecondaryPistolWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate())));
}

static function bool HasDualMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate())) &&
		IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate()));
}

static function bool IsPistolWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.StowedLocation == eSlot_None &&
		WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon &&
		default.PistolCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE &&
		InStr(WeaponTemplate.DataName, "_TMP_") == INDEX_NONE; // Filter RF Templar Weapons
}

static function bool IsPrimaryPistolWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.StowedLocation == eSlot_None &&
		WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon &&
		default.PistolCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE;
}

static function bool IsSecondaryPistolWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.StowedLocation == eSlot_None &&
		WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon &&
		default.PistolCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE;
}

static function bool IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon &&
		WeaponTemplate.iRange == 0;
}

static function bool IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon &&
		WeaponTemplate.iRange == 0 &&
		WeaponTemplate.WeaponCat != 'wristblade' &&
		WeaponTemplate.WeaponCat != 'shield' &&
		WeaponTemplate.WeaponCat != 'gauntlet';
}