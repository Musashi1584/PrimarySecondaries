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
var config array<name> PatchMeleeCategoriesAnimBlackList;
var config int PRIMARY_PISTOLS_CLIP_SIZE;
var config int PRIMARY_SAWEDOFF_CLIP_SIZE;
var config int PRIMARY_PISTOLS_DAMAGE_MODIFER;
var config bool bPrimaryPistolsInfiniteAmmo;
var config bool bUseVisualPistolUpgrades;
var config bool bLog;


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
			`Log("Mod installed:" @ Mod.Class, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog);
			return true;
		}
	}

	return false;
}

static function MatineeGetPawnFromSaveData(XComUnitPawn UnitPawn, XComGameState_Unit UnitState, XComGameState SearchState)
{
	class'ShellMapMatinee'.static.PatchAllLoadedMatinees(UnitPawn, UnitState, SearchState);
}

static event InstallNewCampaign(XComGameState StartState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetNewXComHQState(StartState);
	AddPrimaryVariants(XComHQ, StartState);
}

static event OnLoadedSavedGame()
{
	UpdateStorage();
}

static event OnLoadedSavedGameToStrategy()
{
	UpdateStorage();
}

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

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(" Updating HQ Storage to add primary pistol variants");
	XComHQ = GetNewXComHQState(NewGameState);

	AddPrimaryVariants(XComHQ, NewGameState);

	History.AddGameStateToHistory(NewGameState);
	History.CleanupPendingGameState(NewGameState);
}

static function UpdateStorageForItem(X2DataTemplate ItemTemplate)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(" Updating HQ Storage to add primary pistol variants");
	XComHQ = GetNewXComHQState(NewGameState);

	AddPrimaryVariantToHQ(ItemTemplate, XComHQ, NewGameState);

	History.AddGameStateToHistory(NewGameState);
	History.CleanupPendingGameState(NewGameState);
}

static function AddPrimaryVariants(XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local X2ItemTemplateManager ItemTemplateMgr;
	local array<X2ItemTemplate> ItemTemplates;
	local X2DataTemplate ItemTemplate;
	local XComGameState_Item NewItemState;
	local array<name> AllTemplateNames;
	local name TemplateName;
	local int i;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Updating HQ Storage to add primary secondary variants");
	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplateMgr.GetTemplateNames(AllTemplateNames);

	foreach AllTemplateNames(TemplateName)
	{
		ItemTemplate = ItemTemplateMgr.FindItemTemplate(TemplateName);

		AddPrimaryVariantToHQ(ItemTemplate, XComHQ, NewGameState);
	}

	ItemTemplates.AddItem(ItemTemplateMgr.FindItemTemplate('EmptySecondary'));
	for (i = 0; i < ItemTemplates.Length; ++i)
	{
		if(ItemTemplates[i] != none)
		{
			if (!XComHQ.HasItem(ItemTemplates[i]))
			{
				`Log(GetFuncName() @ ItemTemplates[i].GetItemFriendlyName() @ " not found, adding to inventory", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
				NewItemState = ItemTemplates[i].CreateInstanceFromTemplate(NewGameState);
				NewGameState.ModifyStateObject(XComHQ.Class, XComHQ.ObjectID);
				XComHQ.AddItemToHQInventory(NewItemState);
			}
		}
	}
}

static function AddPrimaryVariantToHQ(X2DataTemplate ItemTemplate, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local X2ItemTemplateManager ItemTemplateMgr;
	local XComGameState_Item NewItemState;

	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	if (!IsSecondaryPistolWeaponTemplate(X2WeaponTemplate(ItemTemplate)) && !IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate(ItemTemplate)))
	{
		return;
	}

	`LOG(GetFuncName() @ "Checking" @ ItemTemplate.DataName, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');

	if (XComHQ.HasItem(X2ItemTemplate(ItemTemplate)))
	{
		ItemTemplate = ItemTemplateMgr.FindItemTemplate(name(ItemTemplate.DataName $ "_Primary"));
		if (!XComHQ.HasItem(X2ItemTemplate(ItemTemplate)) && (XComHQ.EverAcquiredInventoryTypes.Find(ItemTemplate.DataName) == INDEX_NONE || (!X2WeaponTemplate(ItemTemplate).bInfiniteItem && X2WeaponTemplate(ItemTemplate).CanBeBuilt)))
		{
			`LOG(GetFuncName() @ "-->Adding to HQ" @ ItemTemplate.DataName, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
			NewItemState = X2ItemTemplate(ItemTemplate).CreateInstanceFromTemplate(NewGameState);
			NewItemState.Quantity = 1;
			//XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.Class, XComHQ.ObjectID));
			XComHQ.AddItemToHQInventory(NewItemState);
		}
		else
		{
			`LOG(GetFuncName() @ "Primary variant of" @ ItemTemplate.DataName @ "is already present", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		}
	}
	else
	{
		`LOG(GetFuncName() @ ItemTemplate.DataName @ "is not in inventory", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
	}
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
			`LOG("Attachment for "@TemplateName @Attachment.AttachSocket @Attachment.UIArmoryCameraPointTag @Attachment.MeshName @Attachment.ProjectileName @Attachment.MatchWeaponTemplate @Attachment.AttachToPawn @Attachment.IconName @Attachment.InventoryIconName @Attachment.InventoryCategoryIcon, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
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
		`LOG('UniqueEquipCategories' @ Category, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
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
				`Log("Patching " @ ItemTemplate.DataName @ "with" @ Replacement.GameArchetype @ "and" @ Replacement.NumUpgradeSlots @ "upgrade slots", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
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
				`LOG("Patching Template" @ AbilityAmmoCost.Ability @ "adding" @ AbilityAmmoCost.Ammo @ "ammo cost", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
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
				`LOG("Patching Template" @ TemplateName @ "adding QuickDrawPrimary and Quickdraw to DoNotConsumeAllSoldierAbilities", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
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

			`Log(WeaponTemplate.DataName @ WeaponTemplate.StowedLocation @ WeaponTemplate.WeaponCat, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimaryMeleeWeapons');

			if (IsSecondaryPistolWeaponTemplate(WeaponTemplate))
			{
				ClonedTemplate = new class'X2WeaponTemplate' (WeaponTemplate);
				ClonedTemplate.SetTemplateName(name(TemplateName $ "_Primary"));
				ClonedTemplate.InventorySlot =  eInvSlot_PrimaryWeapon;
				ClonedTemplate.UIArmoryCameraPointTag = 'UIPawnLocation_WeaponUpgrade_Shotgun';

				//ClonedTemplate.Abilities.AddItem('DualShotPrimary');
				//ClonedTemplate.Abilities.AddItem('DualPistolOverwatch');
				
				if (ClonedTemplate.Abilities.Find('PistolStandardShot') == INDEX_NONE)
				{
					ClonedTemplate.Abilities.AddItem('PistolStandardShot');
				}
				ClonedTemplate.Abilities.AddItem('PrimaryPistolsBonus');
				//ClonedTemplate.Abilities.AddItem('PrimaryAnimSet');

				if (ClonedTemplate.WeaponCat == 'sawedoffshotgun')
				{
					ClonedTemplate.iClipSize = default.PRIMARY_SAWEDOFF_CLIP_SIZE;
					ClonedTemplate.Abilities.AddItem('Reload');
				}
				else
				{
					ClonedTemplate.iClipSize = default.PRIMARY_PISTOLS_CLIP_SIZE;
				}
				ClonedTemplate.InfiniteAmmo = default.bPrimaryPistolsInfiniteAmmo;
				
				`LOG(WeaponTemplate.DataName @ WeaponTemplate.GameplayInstanceClass, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
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
						`Log("Adding Attachment" @ UpgradeAttachment.ApplyToWeaponTemplate @ UpgradeAttachment.AttachMeshName, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
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
			`Log("Generating Template" @ TemplateName $ "_Primary with" @ ClonedTemplate.DefaultAttachments.Length @ "default attachments", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		}
	}

	ItemTemplateManager.LoadAllContent();
}

static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item ItemState=none)
{
	local X2WeaponTemplate WeaponTemplate;
	local XComGameState_Unit UnitState;
	local array<string> AnimSetPaths;
	local string AnimSetPath;
	local AnimSet Anim;

	if (ItemState == none)
	{
		return;
	}
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));

	if (UnitState == none || !UnitState.IsSoldier())
	{
		return;
	}

	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

	if (!HasPrimaryMeleeOrPistolEquipped(UnitState))
	{
		return;
	}

	if (default.PatchMeleeCategoriesAnimBlackList.Find(WeaponTemplate.WeaponCat) != INDEX_NONE)
	// Primary Melee (We are patching also secondary swords/pistol here if the primary is a sword/pistol)
	if (HasPrimaryMeleeOrPistolEquipped(UnitState))
	{
		return;
	}

	`LOG(GetFuncName() @ "Spawn" @ WeaponArchetype @ ItemState.GetMyTemplateName() @ Weapon.CustomUnitPawnAnimsets.Length, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');

	if (HasMeleeAndPistolEquipped(UnitState))
	{
		if (IsPrimaryPistolWeaponTemplate(WeaponTemplate) || IsSecondaryPistolWeaponTemplate(WeaponTemplate))
		{
			Weapon.DefaultSocket = 'R_Hand';
		}
		if (IsPrimaryMeleeWeaponTemplate(WeaponTemplate) || IsSecondaryMeleeWeaponTemplate(WeaponTemplate))
		{
			Weapon.DefaultSocket = 'L_Hand';
		}

		if (WeaponTemplate.WeaponCat == 'sidearm')
		{
			AnimSetPaths.AddItem("PrimarySecondaries_SwordAndPistol.Anims.AS_AutoPistol");
		}
		else if (WeaponTemplate.WeaponCat == 'pistol')
		{
			AnimSetPaths.AddItem("PrimarySecondaries_SwordAndPistol.Anims.AS_Pistol");
			if (WeaponTemplate.DataName == 'AlienHunterPistol_CV' || WeaponTemplate.DataName == 'AlienHunterPistol_MG')
			{
				AnimSetPaths.AddItem("PrimarySecondaries_SwordAndPistol.Anims.AS_Shadowkeeper");
			}

			if (WeaponTemplate.DataName == 'AlienHunterPistol_BM')
			{
				AnimSetPaths.AddItem("PrimarySecondaries_SwordAndPistol.Anims.AS_Shadowkeeper_BM");
			}

			if (WeaponTemplate.DataName == 'TLE_Pistol_BM')
			{
				AnimSetPaths.AddItem("PrimarySecondaries_SwordAndPistol.Anims.AS_PlasmaPistol");
			}
		}
		else if (WeaponTemplate.WeaponCat == 'sword')
		{
			
		}
	}
	else if (IsPrimaryMeleeWeaponTemplate(WeaponTemplate))
	{
		if (InStr(WeaponTemplate.DataName, "SpecOpsKnife") == INDEX_NONE)
		{
			AnimSetPaths.AddItem("PrimarySecondaries_ANIM.Anims.AS_Melee");
		}
		else
		{
			AnimSetPaths.AddItem("PrimarySecondaries_ANIM.Anims.AS_KnifeMelee");
		}
	}
	else if (IsPrimaryPistolWeaponTemplate(WeaponTemplate) && HasPrimaryPistolEquipped(UnitState))
	{
		Weapon.DefaultSocket = 'R_Hand';

		if (WeaponTemplate.WeaponCat == 'sidearm')
		{
			AnimSetPaths.AddItem("PrimarySecondaries_AutoPistol.Anims.AS_AutoPistol_Primary");
		}
		else if (WeaponTemplate.WeaponCat == 'pistol')
		{
			AnimSetPaths.AddItem("PrimarySecondaries_Pistol.Anims.AS_Pistol");

			if (WeaponTemplate.DataName == 'AlienHunterPistol_CV' || WeaponTemplate.DataName == 'AlienHunterPistol_MG')
			{
				AnimSetPaths.AddItem("PrimarySecondaries_Pistol.Anims.AS_Shadowkeeper");
			}

			if (WeaponTemplate.DataName == 'AlienHunterPistol_BM')
			{
				AnimSetPaths.AddItem("PrimarySecondaries_Pistol.Anims.AS_Shadowkeeper_BM");
			}

			if (WeaponTemplate.DataName == 'TLE_Pistol_BM')
			{
				AnimSetPaths.AddItem("PrimarySecondaries_Pistol.Anims.AS_PlasmaPistol");
			}
		}
	}
	else if (IsSecondaryPistolWeaponTemplate(WeaponTemplate) && WeaponTemplate.WeaponCat == 'sidearm')
	{
		// Patching the default autopistol template here so other soldiers than templars can use it
		AnimSetPaths.AddItem("PrimarySecondaries_AutoPistol.Anims.AS_AutoPistol_Secondary");
	}

	if (AnimSetPaths.Length > 0)
	{
		Weapon.CustomUnitPawnAnimsets.Length = 0;
		Weapon.CustomUnitPawnAnimsetsFemale.Length = 0;

		foreach AnimSetPaths(AnimSetPath)
		{
			Weapon.CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype(AnimSetPath)));
			`LOG("----> Adding" @ AnimSetPath @ "to CustomUnitPawnAnimsets of" @ WeaponTemplate.DataName, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		}
		

		//foreach Weapon.CustomUnitPawnAnimsets(Anim)
		//{
		//	`LOG(Pathname(Anim), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		//}
	}
}


static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
	local string AnimSetPath;
	local AnimSet Anim;
	local int Index;

	if (!UnitState.IsSoldier())
	{
		return;
	}
	
	if (HasPrimaryMeleeOrPistolEquipped(UnitState))
	{
		// Force Personality_ByTheBook
		UnitState.kAppearance.iAttitude = 0;
		UnitState.UpdatePersonalityTemplate();
		//AddAnimSet(Pawn, AnimSet(`CONTENT.RequestGameArchetype("HQ_ANIM.Anims.AS_Armory_Unarmed")), 3);
		//AddAnimSet(Pawn, AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_ANIM.Anims.AS_Primary")), 4);
		if (HasMeleeAndPistolEquipped(UnitState))
		{
			AnimSetPath = "PrimarySecondaries_SwordAndPistol.Anims.AS_Soldier";
		}
		else if (HasPrimaryPistolEquipped(UnitState))
		{
			if (X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate()).WeaponCat == 'sidearm')
			{
				AnimSetPath = "PrimarySecondaries_AutoPistol.Anims.AS_Soldier";
			}
			else
			{
				AnimSetPath = "PrimarySecondaries_Pistol.Anims.AS_Soldier";
				
			}
		}
		

		if (AnimSetPath != "")
		{
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype(AnimSetPath)));
			`LOG(GetFuncName() @ "Adding" @ AnimSetPath @ "to" @ UnitState.GetFullName(), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		}
		
		Index = 0;
		foreach Pawn.Mesh.AnimSets(Anim)
		{
			`LOG(GetFuncName() @ "Pawn.Mesh.AnimSets" @ Index @ Pathname(Anim), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
			Index++;
		}

		//Index = 0;
		//foreach Pawn.DefaultUnitPawnAnimsets(Anim)
		//{
		//	`LOG(GetFuncName() @ "DefaultUnitPawnAnimsets" @ Index @ Pathname(Anim), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		//	Index++;
		//}

		`LOG(GetFuncName() @ "--------------------------------------------------------------", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');

		//Pawn.Mesh.UpdateAnimations();
	}
}

static function DLCAppendWeaponSockets(out array<SkeletalMeshSocket> NewSockets, XComWeapon Weapon, XComGameState_Item ItemState)
{
    local vector					RelativeLocation;
	local rotator					RelativeRotation;
    local SkeletalMeshSocket		Socket;
	local X2WeaponTemplate			Template;

	Template = X2WeaponTemplate(ItemState.GetMyTemplate());
	
	if (IsPrimaryPistolWeaponTemplate(Template))
	{
		if (Template.WeaponCat == 'pistol')
		{
			RelativeLocation.X = -6;
			RelativeLocation.Y = -3;
			RelativeLocation.Z = -6;
		
			RelativeRotation.Roll = int(-90 * DegToUnrRot);
			RelativeRotation.Pitch = int(0 * DegToUnrRot);
			RelativeRotation.Yaw = int(45 * DegToUnrRot);

			Socket = new class'SkeletalMeshSocket';
			Socket.SocketName = 'left_hand';
			Socket.BoneName = 'root';
			Socket.RelativeLocation = RelativeLocation;
			Socket.RelativeRotation = RelativeRotation;
			NewSockets.AddItem(Socket);

			`LOG(GetFuncName() @ "Overriding" @ Socket.SocketName @ "socket" @ `showvar(RelativeLocation) @ `showvar(RelativeRotation),, 'PrimarySecondaries');
		}

		if (Template.WeaponCat == 'sidearm')
		{
			RelativeLocation.X = -6.5;
			RelativeLocation.Y = -2.5;
			RelativeLocation.Z = -8;
		
			RelativeRotation.Roll = int(0 * DegToUnrRot);
			RelativeRotation.Pitch = int(0 * DegToUnrRot);
			RelativeRotation.Yaw = int(0 * DegToUnrRot);

			Socket = new class'SkeletalMeshSocket';
			Socket.SocketName = 'left_hand';
			Socket.BoneName = 'root';
			Socket.RelativeLocation = RelativeLocation;
			Socket.RelativeRotation = RelativeRotation;
			NewSockets.AddItem(Socket);

			`LOG(GetFuncName() @ "Overriding" @ Socket.SocketName @ "socket" @ `showvar(RelativeLocation) @ `showvar(RelativeRotation),, 'PrimarySecondaries');
		}
	}
}

static function bool HasPrimaryMeleeOrPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return HasPrimaryMeleeEquipped(UnitState, CheckGameState) || HasPrimaryPistolEquipped(UnitState, CheckGameState);
}

static function bool HasMeleeAndPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return (HasPrimaryMeleeEquipped(UnitState, CheckGameState) && HasSecondaryPistolEquipped(UnitState, CheckGameState)) ||
		   (HasPrimaryPistolEquipped(UnitState, CheckGameState) && HasSecondaryMeleeEquipped(UnitState, CheckGameState));
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

static function bool HasSecondaryMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate()));
}

static function bool HasSecondaryPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsSecondaryPistolWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate()));
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
		default.PistolCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE &&
		InStr(WeaponTemplate.DataName, "_TMP_") == INDEX_NONE; // Filter RF Templar Weapons
}

static function bool IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon &&
		WeaponTemplate.iRange == 0 &&
		WeaponTemplate.WeaponCat != 'wristblade' &&
		WeaponTemplate.WeaponCat != 'shield' &&
		WeaponTemplate.WeaponCat != 'gauntlet';
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


exec function PS_DebugAnimSetList()
{
	local XComTacticalController TacticalController;
	local XComUnitPawn Pawn;
	local AnimSet Anim;
	local int Index;

	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	if (TacticalController != none)
	{
		Pawn = TacticalController.GetActivePawn();
		Index = 0;
		foreach Pawn.Mesh.AnimSets(Anim)
		{
			`LOG(GetFuncName() @ "Pawn.Mesh.AnimSets" @ Index @ Pathname(Anim), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
			Index++;
		}
	}
}

exec function DebugLeftHandSocket(
	float X,
	float Y,
	float Z,
	int Roll,
	int Pitch,
	int Yaw
)
{
	local XComGameStateHistory History;
	local XComTacticalController TacticalController;
	local XComGameState_Unit UnitState;
	local XGWeapon WeaponVisualizer;
	local array<SkeletalMeshSocket> NewSockets;
	local vector					RelativeLocation;
	local rotator					RelativeRotation;
	local SkeletalMeshSocket		Socket;

	History = `XCOMHISTORY;

	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	if (TacticalController != none)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(TacticalController.GetActiveUnitStateRef().ObjectID));
		WeaponVisualizer = XGWeapon(UnitState.GetPrimaryWeapon().GetVisualizer());

		RelativeLocation.X = X;
		RelativeLocation.Y = Y;
		RelativeLocation.Z = Z;
		
		RelativeRotation.Roll = int(Roll * DegToUnrRot);
		RelativeRotation.Pitch = int(Pitch * DegToUnrRot);
		RelativeRotation.Yaw = int(Yaw * DegToUnrRot);

		Socket = new class'SkeletalMeshSocket';
		Socket.SocketName = 'left_hand';
		Socket.BoneName = 'root';
		Socket.RelativeLocation = RelativeLocation;
		Socket.RelativeRotation = RelativeRotation;
		NewSockets.AddItem(Socket);

		SkeletalMeshComponent(XComWeapon(WeaponVisualizer.m_kEntity).Mesh).AppendSockets(NewSockets, true);
	}
}

static function XComGameState_HeadquartersXCom GetNewXComHQState(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom NewXComHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', NewXComHQ)
	{
		break;
	}

	if(NewXComHQ == none)
	{
		NewXComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', NewXComHQ.ObjectID));
	}

	return NewXComHQ;
}