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

Struct WeaponConfig {
	var name TemplateName;
	var bool bKeepPawnWeaponAnimation;
	var bool bUseSideSheaths;
	var bool bUseEmptyHandSoldierAnimations;
	var name CustomFireAnim;
	var string CustomWeaponPawnAnimset;

	structdefaultproperties
	{
		bKeepPawnWeaponAnimation = false
		bUseSideSheaths = true
		bUseEmptyHandSoldierAnimations = false
	}
};

struct DLCAnimSetAdditions
{
	var Name CharacterGroup;
	var String AnimSet;
	var String FemaleAnimSet;
};

var config array<DLCAnimSetAdditions> AnimSetAdditions;
var config array<AmmoCost> AmmoCosts;
var config array<ArchetypeReplacement> ArchetypeReplacements;
var config array<PistolWeaponAttachment> PistolAttachements;
var config array<name> PistolCategories;
var config array<name> WeaponCategoryBlacklist;
var config array<name> DontOverrideMeleeCategories;
var config array<WeaponConfig> IndividualWeaponConfig;

var array<name> SkipWeapons;

var config array<int> MIDSHORT_CONVENTIONAL_RANGE;
var config int PRIMARY_PISTOLS_CLIP_SIZE;
var config int PRIMARY_SAWEDOFF_CLIP_SIZE;
var config int PRIMARY_PISTOLS_DAMAGE_MODIFER;
var config bool bPrimaryPistolsInfiniteAmmo;
var config bool bUseVisualPistolUpgrades;
var config bool bLog;
var config bool bLogAnimations;

delegate OnEquippedDelegate(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState);

static function MatineeGetPawnFromSaveData(XComUnitPawn UnitPawn, XComGameState_Unit UnitState, XComGameState SearchState)
{
	class'ShellMapMatinee'.static.PatchAllLoadedMatinees(UnitPawn, UnitState, SearchState);
}

static event OnLoadedSavedGameToStrategy()
{
	`LOG(GetFuncName(), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
	UpdateStorage();
}

exec function UpdatePrimarySecondaries() {
	`LOG(GetFuncName(), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
	UpdateStorage();
}

static event OnPostTemplatesCreated()
{
	`LOG(default.class @ GetFuncName(),, 'DLCSort');
	ScriptTrace();
	PatchAbilityTemplates();
	AddAttachments();
	AddPrimarySecondaries();
	CheckUniqueWeaponCategories();
	if (default.bUseVisualPistolUpgrades)
	{
		ReplacePistolArchetypes();
	}
	OnPostCharacterTemplatesCreated();
}

static function OnPostCharacterTemplatesCreated()
{
	local X2CharacterTemplateManager CharacterTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local array<X2DataTemplate> DataTemplates;
	local int ScanTemplates, ScanAdditions;
	local array<name> AllTemplateNames;
	local name TemplateName;

	CharacterTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	
	CharacterTemplateMgr.GetTemplateNames(AllTemplateNames);

	foreach AllTemplateNames(TemplateName)
	{
		CharacterTemplateMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);

		for ( ScanTemplates = 0; ScanTemplates < DataTemplates.Length; ++ScanTemplates )
		{
			CharacterTemplate = X2CharacterTemplate(DataTemplates[ScanTemplates]);
			if (CharacterTemplate != none)
			{
				ScanAdditions = default.AnimSetAdditions.Find('CharacterGroup', CharacterTemplate.CharacterGroupName);
				if (ScanAdditions != INDEX_NONE)
				{
					CharacterTemplate.AdditionalAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype(default.AnimSetAdditions[ScanAdditions].AnimSet)));
					CharacterTemplate.AdditionalAnimSetsFemale.AddItem(AnimSet(`CONTENT.RequestGameArchetype(default.AnimSetAdditions[ScanAdditions].FemaleAnimSet)));
				}
			}
		}
	}
}


static function UpdateStorage()
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Updating HQ Storage to add primary secondaries variants");
	
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	AddPrimaryVariants(XComHQ, NewGameState);

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

static function UpdateStorageForItem(X2DataTemplate ItemTemplate, optional bool bOnItemConstructionCompleted = false)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Updating HQ Storage to add primary secondaries variants");

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	AddPrimaryVariantToHQ(ItemTemplate, XComHQ, NewGameState, bOnItemConstructionCompleted);

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

static function AddPrimaryVariants(out XComGameState_HeadquartersXCom XComHQ, out XComGameState NewGameState)
{
	local X2ItemTemplateManager ItemTemplateMgr;
	local array<X2ItemTemplate> ItemTemplates;
	local X2DataTemplate ItemTemplate;
	local XComGameState_Item NewItemState;
	local array<name> AllTemplateNames;
	local name TemplateName;
	local int i;

	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplateMgr.GetTemplateNames(AllTemplateNames);

	foreach AllTemplateNames(TemplateName)
	{
		ItemTemplate = ItemTemplateMgr.FindItemTemplate(TemplateName);

		if (default.SkipWeapons.Find(ItemTemplate.DataName) != INDEX_NONE) continue;

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

static function AddPrimaryVariantToHQ(X2DataTemplate ItemTemplate, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState, optional bool bOnItemConstructionCompleted = false)
{
	local XComGameStateHistory History;
	local X2ItemTemplateManager ItemTemplateMgr;
	local XComGameState_Item NewItemState, RemoveItemState;
	local X2DataTemplate ItemTemplatePrimary;
	local int QuantitySecondary, QuantityPrimary, QuantityToAdd, QuantityToRemove, Index, InventoryIndex;
	local StateObjectReference ItemRef;
	local array <XComGameState_Unit> AllSoldiers;
	local XComGameState_Unit Soldier;
	local array<name> Upgrades;

	History = `XCOMHISTORY;

	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	if (!IsSecondaryPistolWeaponTemplate(X2WeaponTemplate(ItemTemplate)) && !IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate(ItemTemplate)))
	{
		return;
	}

	ItemTemplatePrimary = ItemTemplateMgr.FindItemTemplate(name(ItemTemplate.DataName $ "_Primary"));

	QuantitySecondary = XComHQ.GetNumItemInInventory(ItemTemplate.DataName);
	QuantityPrimary = XComHQ.GetNumItemInInventory(ItemTemplatePrimary.DataName);

	if (!X2WeaponTemplate(ItemTemplate).bInfiniteItem)
	{
		AllSoldiers = XComHQ.GetSoldiers();
		foreach AllSoldiers(Soldier)
		{
			if (ItemTemplate.DataName == Soldier.GetItemInSlot(eInvSlot_SecondaryWeapon, NewGameState).GetMyTemplateName())
			{
				`LOG(GetFuncName() @ Soldier.SummaryString() @ "has secondary " @ ItemTemplate.DataName @ "equipped", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
				QuantitySecondary += 1;
			}

			if (ItemTemplatePrimary.DataName == Soldier.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState).GetMyTemplateName())
			{
				`LOG(GetFuncName() @ Soldier.SummaryString() @ "has primary " @ ItemTemplate.DataName @ "equipped", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
				QuantityPrimary += 1;
			}
		}
	}

	QuantityToAdd = QuantitySecondary - QuantityPrimary;

	`LOG(GetFuncName() @ "Checking" @ ItemTemplate.DataName @ "QuantitySecondary:" @ QuantitySecondary @ "QuantityPrimary:" @ QuantityPrimary @ "QuantityToAdd:" @ QuantityToAdd, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
	
	if (XComHQ.HasItem(X2ItemTemplate(ItemTemplate)))
	{
		if (!XComHQ.HasItem(X2ItemTemplate(ItemTemplatePrimary)) || QuantityToAdd > 0)
		{
			`LOG(GetFuncName() @ "-->Adding to HQ" @ ItemTemplatePrimary.DataName @ "("  $ QuantityToAdd $ ")", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
			NewItemState = X2ItemTemplate(ItemTemplatePrimary).CreateInstanceFromTemplate(NewGameState);
			NewItemState.Quantity = QuantityToAdd;
			NewItemState.bMergedOut = false;
			NewItemState.MergedItemCount = 0;
			XComHQ.AddItemToHQInventory(NewItemState);
		}
		else if(QuantityToAdd < 0 && !X2WeaponTemplate(ItemTemplate).bInfiniteItem)
		{
			QuantityToRemove  = QuantityToAdd * -1;
			
			for (Index = 0; Index < QuantityToRemove; Index++)
			{
				for(InventoryIndex = 0; InventoryIndex < XComHQ.Inventory.Length; InventoryIndex++)
				{
					RemoveItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[InventoryIndex].ObjectId));

					if(RemoveItemState != none && RemoveItemState.GetMyTemplateName() == ItemTemplatePrimary.DataName)
					{
						Upgrades = RemoveItemState.GetMyWeaponUpgradeTemplateNames();

						//`LOG(GetFuncName() @ "try to remove" @ ItemTemplatePrimary.DataName @ RemoveItemState.ObjectID @ Upgrades.Length, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');

						if (Upgrades.Length == 0)
						{
							ItemRef.ObjectID = RemoveItemState.ObjectID;
							XComHQ.RemoveItemFromInventory(NewGameState, ItemRef, 1);
							`LOG(GetFuncName() @ "<-- removing from HQ" @ ItemTemplatePrimary.DataName @ "(1)" @ ItemRef.ObjectID, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
						}
						else
						{
							continue;
						}
					}
				}
			}
		}
		else
		{
			`LOG(GetFuncName() @ "<-> Primary variant of" @ ItemTemplate.DataName @ "is already present", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		}
	}
	else
	{
		//XComHQ.RemoveItemFromInventory();
		`LOG(GetFuncName() @ "<->" @ ItemTemplate.DataName @ "is not in inventory", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
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
			ActionPointCost = GetAbilityCostActionPoints(Template);
			if (ActionPointCost != none && ActionPointCost.DoNotConsumeAllSoldierAbilities.Find('QuickDrawPrimary') == INDEX_NONE)
			{
				ActionPointCost.DoNotConsumeAllSoldierAbilities.AddItem('QuickDrawPrimary');
				ActionPointCost.DoNotConsumeAllSoldierAbilities.AddItem('Quickdraw');
				`LOG("Patching Template" @ TemplateName @ "adding QuickDrawPrimary and Quickdraw to DoNotConsumeAllSoldierAbilities", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
			}
		}
	}

	TemplateNames.Length = 0;
	TemplateNames.AddItem('Bladestorm');
	
	foreach TemplateNames(TemplateName)
	{
		Template = TemplateManager.FindAbilityTemplate(TemplateName);
		if (Template != none)
		{
			Template.AdditionalAbilities.AddItem('BladestormAttackPrimary');
		}
	}
	

}

static function X2AbilityCost_ActionPoints GetAbilityCostActionPoints(X2AbilityTemplate Template)
{
	local X2AbilityCost Cost;
	foreach Template.AbilityCosts(Cost)
	{
		if (X2AbilityCost_ActionPoints(Cost) != none)
		{
			return X2AbilityCost_ActionPoints(Cost);
		}
	}
	return none;
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
		if (default.SkipWeapons.Find(TemplateName) != INDEX_NONE) continue;

		ItemTemplateManager.FindDataTemplateAllDifficulties(TemplateName, DifficultyVariants);
		// Iterate over all variants
		
		foreach DifficultyVariants(ItemTemplate)
		{
			ClonedTemplate = none;
			WeaponTemplate = X2WeaponTemplate(ItemTemplate);

			if (WeaponTemplate == none)
				continue;

			`Log(WeaponTemplate.DataName @ WeaponTemplate.StowedLocation @ WeaponTemplate.WeaponCat, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');

			if (IsSecondaryPistolWeaponTemplate(WeaponTemplate))
			{
				ClonedTemplate = new WeaponTemplate.Class (WeaponTemplate);
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
				ClonedTemplate.RangeAccuracy = default.MIDSHORT_CONVENTIONAL_RANGE;
				//`LOG(WeaponTemplate.DataName @ WeaponTemplate.GameplayInstanceClass, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
				//ClonedTemplate.Tier -= 5;
			}

			if (IsSecondaryMeleeWeaponTemplate(WeaponTemplate) && InStr(WeaponTemplate.DataName, "SpecOpsKnife") == INDEX_NONE)
			{
				ClonedTemplate = new WeaponTemplate.Class (WeaponTemplate);
				ClonedTemplate.SetTemplateName(name(TemplateName $ "_Primary"));
				ClonedTemplate.InventorySlot =  eInvSlot_PrimaryWeapon;
				if (ClonedTemplate.Abilities.Find('SwordSlice') == INDEX_NONE)
				{
					ClonedTemplate.Abilities.AddItem('SwordSlice');
				}

				WeaponTemplate.Abilities.AddItem('DualSlashSecondary');

				// Make sure the templates get added to the bottom if the list
				//ClonedTemplate.Tier -= 10;
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

				if (WeaponTemplate.BaseItem != '' )
					ClonedTemplate.BaseItem = name(WeaponTemplate.BaseItem $ "_Primary");
				
				if (WeaponTemplate.UpgradeItem != '' )
					ClonedTemplate.UpgradeItem = name(WeaponTemplate.UpgradeItem $ "_Primary");


				if (WeaponTemplate.BaseItem != '' )
					ClonedTemplate.BaseItem = name(WeaponTemplate.BaseItem $ "_Primary");

				if (WeaponTemplate.UpgradeItem != '' )
					ClonedTemplate.UpgradeItem = name(WeaponTemplate.UpgradeItem $ "_Primary");
				

				ItemTemplateManager.AddItemTemplate(ClonedTemplate, true);
			}

		}

		if (ClonedTemplate != none)
		{
			`Log("Generating Template" @ ClonedTemplate.WeaponCat @ TemplateName $ "_Primary with" @ ClonedTemplate.DefaultAttachments.Length @ "default attachments", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		}
	}

	ItemTemplateManager.LoadAllContent();
}

static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	//local XComGameState_Item SecondaryItemState;
	//local array<SoldierClassAbilityType> EarnedSoldierAbilities;
	local int Index;

	`LOG(GetFuncName(), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
	
	// Associate all melee abilities with the primary weapon if primary melee weapons are equipped
	if (UnitState.IsSoldier() && !HasDualMeleeEquipped(UnitState) && HasPrimaryMeleeEquipped(UnitState))
	{
		for(Index = 0; Index <= SetupData.Length; Index++)
		{
			if (SetupData[Index].Template.IsMelee() && SetupData[Index].TemplateName != 'DualSlashSecondary')
			{
				SetupData[Index].SourceWeaponRef = UnitState.GetPrimaryWeapon().GetReference();
				`LOG(GetFuncName() @ UnitState.GetFullName() @ "setting" @ SetupData[Index].TemplateName @ "to" @ UnitState.GetPrimaryWeapon().GetMyTemplateName(), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
			}
		}
	}

	// Associate all pistol abilities with the primary weapon if primary pistol weapons are equipped
	//if (UnitState.IsSoldier() && !HasDualPistolEquipped(UnitState) && HasPrimaryPistol(UnitState))
	//{
	//	EarnedSoldierAbilities = UnitState.GetEarnedSoldierAbilities();
	//	SecondaryItemState = UnitState.GetSecondaryWeapon();
	//	for(Index = 0; Index <= SetupData.Length; Index++)
	//	{
	//		if (!SetupData[Index].Template.IsMelee() &&
	//			!SetupData[Index].Template.IsPassive &&
	//			EarnedSoldierAbilities.Find('AbilityName', SetupData[Index].TemplateName) != INDEX_NONE)
	//		{
	//			if (SecondaryItemState.ObjectID == SetupData[Index].SourceWeaponRef.ObjectID)
	//			{
	//				SetupData[Index].SourceWeaponRef = UnitState.GetPrimaryWeapon().GetReference();
	//				`LOG(GetFuncName() @ UnitState.GetFullName() @ "setting" @ SetupData[Index].TemplateName @ "to" @ UnitState.GetPrimaryWeapon().GetMyTemplateName(), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLo, 'PrimarySecondaries');
	//			}
	//		}
	//	}
	//}
}

static function UpdateWeaponAttachments(out array<WeaponAttachment> Attachments, XComGameState_Item ItemState)
{
	local XComGameState_Unit UnitState;
	local int i;
	local name NewSocket;
	local vector Scale;
	local WeaponConfig IndividualWeaponConfigLocal;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));

	if(UnitState != none && HasDualMeleeEquipped(UnitState))
	{
		return;
	}

	if (default.WeaponCategoryBlacklist.Find(X2WeaponTemplate(ItemState.GetMyTemplate()).WeaponCat) != INDEX_NONE)
	{
		return;
	}

	FindIndividualWeaponConfig(ItemState.GetMyTemplateName(), IndividualWeaponConfigLocal);
	if (!IndividualWeaponConfigLocal.bUseSideSheaths)
	{
		NewSocket = 'Sheath';
	}

	if(NewSocket == 'None' && IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate(ItemState.GetMyTemplate())))
	{
		NewSocket = 'PrimaryMeleeLeftSheath';
	}

	if (NewSocket != '')
	{
		for (i = Attachments.Length; i >= 0; i--)
		{
			if (Attachments[i].AttachToPawn && (Attachments[i].AttachSocket == 'Sheath' || Attachments[i].AttachSocket == 'PrimaryMeleeLeftSheath'))
			{
				Attachments[i].AttachSocket = NewSocket;
				if (UnitState.kAppearance.iGender == eGender_Female)
				{
					Scale.X = 0.85f;
					Scale.Y = 0.85f;
					Scale.Z = 0.85f;
					XGUnit(UnitState.GetVisualizer()).GetPawn().Mesh.GetSocketByName(NewSocket).RelativeScale = Scale;
				}
				`LOG(GetFuncName() @ UnitState.GetFullName() @ ItemState.GetMyTemplateName() @ NewSocket @ "bUseSideSheaths" @ IndividualWeaponConfigLocal.bUseSideSheaths, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
			}
		}
	}
}

static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item ItemState=none)
{
	local X2WeaponTemplate WeaponTemplate;
	local XComGameState_Unit UnitState;
	local array<string> AnimSetPaths;
	local string AnimSetPath;
	//local AnimSet Anim;
	local bool bResetAnimsets;
	local WeaponConfig IndividualWeaponConfigLocal;

	bResetAnimsets = true;

	if (ItemState == none)
	{
		return;
	}
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));

	if (UnitState == none || (UnitState != none && !AllowUnitState(UnitState)))
	{
		return;
	}

	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

	if (default.WeaponCategoryBlacklist.Find(WeaponTemplate.WeaponCat) != INDEX_NONE)
	{
		return;
	}

	FindIndividualWeaponConfig(WeaponTemplate.DataName, IndividualWeaponConfigLocal);
	
	if (IndividualWeaponConfigLocal.bKeepPawnWeaponAnimation)
	{
		return;
	}

	//`LOG(GetFuncName() @ "Spawn" @ WeaponArchetype @ ItemState.GetMyTemplateName() @ Weapon.CustomUnitPawnAnimsets.Length, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');

	if (IndividualWeaponConfigLocal.bUseEmptyHandSoldierAnimations)
	{
		if (IsPrimaryMeleeWeaponTemplate(WeaponTemplate) && HasPrimaryMeleeEquipped(UnitState))
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
			
		if (IsPrimaryPistolWeaponTemplate(WeaponTemplate) && HasPrimaryPistolEquipped(UnitState))
		{
			if (WeaponTemplate.WeaponCat == 'sidearm')
			{
				AnimSetPaths.AddItem("PrimarySecondaries_ANIM.Anims.AS_AutoPistol");
			}
			else if (WeaponTemplate.WeaponCat == 'pistol')
			{
				AnimSetPaths.AddItem("PrimarySecondaries_ANIM.Anims.AS_PrimaryPistol");
			}
		}
	}
	else
	{
		if (IsPrimaryMeleeWeaponTemplate(WeaponTemplate) && HasPrimaryMeleeEquipped(UnitState))
		{
			Weapon.DefaultSocket = 'R_Hand';
		
			if (InStr(WeaponTemplate.DataName, "SpecOpsKnife") == INDEX_NONE)
			{
				// Patching the sequence name from FF_MeleeA to FF_Melee to support random sets via prefixes A,B,C etc
				Weapon.WeaponFireAnimSequenceName = IndividualWeaponConfigLocal.CustomFireAnim != 'None' ? IndividualWeaponConfigLocal.CustomFireAnim : 'FF_Melee';
				Weapon.WeaponFireKillAnimSequenceName = IndividualWeaponConfigLocal.CustomFireAnim != 'None' ? IndividualWeaponConfigLocal.CustomFireAnim : 'FF_MeleeKill';
				
				AnimSetPaths.AddItem("PrimarySecondaries_PrimaryMelee.Anims.AS_Sword");
			}
			else
			{
				AnimSetPaths.AddItem("PrimarySecondaries_ANIM.Anims.AS_KnifeMelee");
			}
		}
		else if (IsPrimaryPistolWeaponTemplate(WeaponTemplate) && HasPrimaryPistolEquipped(UnitState))
		{
			Weapon.DefaultSocket = 'R_Hand';

			if (IndividualWeaponConfigLocal.CustomFireAnim != 'None')
			{
				Weapon.WeaponFireAnimSequenceName = IndividualWeaponConfigLocal.CustomFireAnim;
				Weapon.WeaponFireKillAnimSequenceName = IndividualWeaponConfigLocal.CustomFireAnim;
			}

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
		else if (IsSecondaryMeleeWeaponTemplate(WeaponTemplate) && HasPrimaryPistolEquipped(UnitState))
		{
			AnimSetPaths.AddItem("PrimarySecondaries_Pistol.Anims.AS_SecondarySword");
		}
		else if (IsSecondaryPistolWeaponTemplate(WeaponTemplate) && WeaponTemplate.WeaponCat == 'sidearm')
		{
			// Patching the default autopistol template here so other soldiers than templars can use it
			AnimSetPaths.AddItem("PrimarySecondaries_AutoPistol.Anims.AS_AutoPistol_Secondary");
		}
		if (IsSecondaryPistolWeaponTemplate(WeaponTemplate) && HasPrimaryMeleeEquipped(UnitState))
		{
			bResetAnimsets = false;
			AnimSetPaths.AddItem("PrimarySecondaries_PrimaryMelee.Anims.AS_SecondaryPistol");
		}

		if (default.DontOverrideMeleeCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE)
		{
			bResetAnimsets = false;
		}

		if (IndividualWeaponConfigLocal.CustomWeaponPawnAnimset != "")
		{
			AnimSetPaths.Length = 0;
			AnimSetPaths.AddItem(IndividualWeaponConfigLocal.CustomWeaponPawnAnimset);
		}

		if (AnimSetPaths.Length > 0)
		{
			if (bResetAnimsets)
			{
				Weapon.CustomUnitPawnAnimsets.Length = 0;
				Weapon.CustomUnitPawnAnimsetsFemale.Length = 0;
			}

			foreach AnimSetPaths(AnimSetPath)
			{
				Weapon.CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype(AnimSetPath)));
				`LOG(GetFuncName() @ "----> Adding" @ AnimSetPath @ "to CustomUnitPawnAnimsets of" @ WeaponTemplate.DataName @ "Weapon.DefaultSocket" @ Weapon.DefaultSocket, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
			}
		

			//foreach Weapon.CustomUnitPawnAnimsets(Anim)
			//{
			//	`LOG(Pathname(Anim), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
			//}
		}
	}
}

static function UnitPawnPostInitAnimTree(XComGameState_Unit UnitState, XComUnitPawnNativeBase Pawn, SkeletalMeshComponent SkelComp)
{
	local AnimTree AnimTreeTemplate;

	if (UnitState != none && !AllowUnitState(UnitState))
	{
		return;
	}

	if (HasPrimaryPistolEquipped(UnitState))
	{
		AnimTreeTemplate = AnimTree(`CONTENT.RequestGameArchetype("PrimarySecondaries_AT.AT_Soldier", class'AnimTree'));
		SkelComp.SetAnimTreeTemplate(AnimTreeTemplate);
	}
}

static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
	local string AnimSetPath, FemaleSuffix;
	local AnimSet Anim;
	local int Index;
	local WeaponConfig IndividualWeaponConfigLocal;

	//`LOG(default.class @ GetFuncName(),, 'DLCSort');
	
	if (UnitState != none && !AllowUnitState(UnitState))
	{
		return;
	}

	CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_Target.Anims.AS_Advent")));
	
	if (HasPrimaryMeleeOrPistolEquipped(UnitState))
	{
		FindIndividualWeaponConfig(UnitState.GetPrimaryWeapon().GetMyTemplateName(), IndividualWeaponConfigLocal);
		
		if (IndividualWeaponConfigLocal.bUseEmptyHandSoldierAnimations)
		{
			UnitState.kAppearance.iAttitude = 0;
			UnitState.UpdatePersonalityTemplate();
			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_Armory.Anims.AS_Armory_Unarmed")));
			AddAnimSet(Pawn, AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_ANIM.Anims.AS_Primary")), 4);
			return;
		}

		If (UnitState.kAppearance.iGender == eGender_Female)
		{
			FemaleSuffix = "_F";
		}

		if (HasPrimaryPistolEquipped(UnitState))
		{
			if (X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate()).WeaponCat == 'sidearm')
			{
				AnimSetPath = "PrimarySecondaries_AutoPistol.Anims.AS_Soldier";
				CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_AutoPistol.Anims.AS_Armory" $ FemaleSuffix)));
			}
			else
			{
				AnimSetPath = "PrimarySecondaries_Pistol.Anims.AS_Soldier";
				CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_Pistol.Anims.AS_Armory" $ FemaleSuffix)));
			}
		}
		else if (HasPrimaryMeleeEquipped(UnitState))
		{
			AnimSetPath = "PrimarySecondaries_PrimaryMelee.Anims.AS_Soldier" $ FemaleSuffix;

			CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("PrimarySecondaries_PrimaryMelee.Anims.AS_Armory" $ FemaleSuffix)));
		}
		

		if (AnimSetPath != "")
		{
			//CustomAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype(AnimSetPath)));

			AddAnimSet(Pawn, AnimSet(`CONTENT.RequestGameArchetype(AnimSetPath)), Pawn.DefaultUnitPawnAnimsets.Length);

			`LOG(GetFuncName() @ "Adding" @ AnimSetPath @ "to" @ UnitState.GetFullName(), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLogAnimations, 'PrimarySecondaries');
		}
		
		Index = 0;
		foreach Pawn.Mesh.AnimSets(Anim)
		{
			`LOG(GetFuncName() @ "Pawn.Mesh.AnimSets" @ Index @ Pathname(Anim), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLogAnimations, 'PrimarySecondaries');
			Index++;
		}

		Index = 0;
		foreach Pawn.DefaultUnitPawnAnimsets(Anim)
		{
			`LOG(GetFuncName() @ "DefaultUnitPawnAnimsets" @ Index @ Pathname(Anim) @ Anim.ObjectArchetype @ Anim.Name, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLogAnimations, 'PrimarySecondaries');
			Index++;
		}

		`LOG(GetFuncName() @ "--------------------------------------------------------------", class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLogAnimations, 'PrimarySecondaries');

		//Pawn.Mesh.UpdateAnimations();
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
		`LOG(GetFuncName() @ "adding" @ AnimSetToAdd @ "at Index" @ Index, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLogAnimations, 'PrimarySecondaries');
	}
}

static function DLCAppendWeaponSockets(out array<SkeletalMeshSocket> NewSockets, XComWeapon Weapon, XComGameState_Item ItemState)
{
    local vector					RelativeLocation;
	local rotator					RelativeRotation;
    local SkeletalMeshSocket		Socket;
	local X2WeaponTemplate			Template;
	local array<name>				BoneNames;
	local name						Bone, BoneNameToUse;
	local XComGameState_Unit		UnitState;
	local WeaponConfig				IndividualWeaponConfigLocal;

	Template = X2WeaponTemplate(ItemState.GetMyTemplate());

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ItemState.OwnerStateObject.ObjectID));

	if (!HasPrimaryMeleeOrPistolEquipped(UnitState))
	{
		return;
	}

	if (default.WeaponCategoryBlacklist.Find(Template.WeaponCat) != INDEX_NONE)
	{
		return;
	}

	FindIndividualWeaponConfig(Template.DataName, IndividualWeaponConfigLocal);
	if (IndividualWeaponConfigLocal.bUseEmptyHandSoldierAnimations)
	{
		return;
	}

	if (IsPrimaryPistolWeaponTemplate(Template) || IsPrimaryMeleeWeaponTemplate(Template))
	{
		SkeletalMeshComponent(Weapon.Mesh).GetBoneNames(BoneNames);
		foreach BoneNames(Bone)
		{
			`LOG(GetFuncName() @ ItemState.GetMyTemplateName() @ "Bone" @ Bone, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
			if (Instr(Locs(Bone), "root") != INDEX_NONE)
			{
				BoneNameToUse = Bone;
				break;
			}
		}

		if (BoneNameToUse == 'None')
		{
			BoneNameToUse = SkeletalMeshComponent(Weapon.Mesh).GetBoneName(0);
			`LOG(GetFuncName() @ ItemState.GetMyTemplateName() @ "No root Bone found. Using bone on index 0" @ BoneNameToUse, class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		}

		if (Template.WeaponCat == 'sword')
		{
			RelativeLocation.X = -10;
			RelativeLocation.Y = -1;
			RelativeLocation.Z = -9;
		
			//RelativeRotation.Roll = int(-90 * DegToUnrRot);
			RelativeRotation.Pitch = int(-10 * DegToUnrRot);
			//RelativeRotation.Yaw = int(45 * DegToUnrRot);

			Socket = new class'SkeletalMeshSocket';
			Socket.SocketName = 'left_hand';
			Socket.BoneName = Bone;
			Socket.RelativeLocation = RelativeLocation;
			Socket.RelativeRotation = RelativeRotation;
			NewSockets.AddItem(Socket);

			`LOG(GetFuncName() @ ItemState.GetMyTemplateName() @ "Overriding" @ Socket.SocketName @ "socket on" @ Bone @ `showvar(RelativeLocation) @ `showvar(RelativeRotation), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		}

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
			Socket.BoneName = Bone;
			Socket.RelativeLocation = RelativeLocation;
			Socket.RelativeRotation = RelativeRotation;
			NewSockets.AddItem(Socket);

			`LOG(GetFuncName() @ ItemState.GetMyTemplateName() @ "Overriding" @ Socket.SocketName @ "socket on" @ Bone @ `showvar(RelativeLocation) @ `showvar(RelativeRotation), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
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
			Socket.BoneName = Bone;
			Socket.RelativeLocation = RelativeLocation;
			Socket.RelativeRotation = RelativeRotation;
			NewSockets.AddItem(Socket);

			`LOG(GetFuncName() @ ItemState.GetMyTemplateName() @ "Overriding" @ Socket.SocketName @ "socket on" @ Bone @ `showvar(RelativeLocation) @ `showvar(RelativeRotation), class'X2DownloadableContentInfo_PrimarySecondaries'.default.bLog, 'PrimarySecondaries');
		}
	}
}

static function string DLCAppendSockets(XComUnitPawn Pawn)
{
	local XComHumanPawn HumanPawn;
	local XComGameState_Unit UnitState;

	//`LOG("DLCAppendSockets" @ Pawn,, 'DualWieldMelee');

	HumanPawn = XComHumanPawn(Pawn);
	if (HumanPawn == none) { return ""; }

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(HumanPawn.ObjectID));

	if (UnitState == none || (UnitState != none && !AllowUnitState(UnitState))) { return ""; }

	if (HasPrimaryMeleeEquipped(UnitState))
	{
		if (UnitState.kAppearance.iGender == eGender_Female)
		{
			return "PrimarySecondaries_Sockets.Meshes.PrimaryMelee_SocketsOverride_F";
		}
		else
		{
			return "PrimarySecondaries_Sockets.Meshes.PrimaryMelee_SocketsOverride";
		}
	}

	if (HasPrimaryPistolEquipped(UnitState))
	{
		return "PrimarySecondaries_Sockets.Meshes.PrimaryPistol_SocketsOverride";
	}

	return "";
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
	return SecondaryWeaponTemplate.WeaponCat == 'shield' && default.SkipWeapons.Find(SecondaryWeaponTemplate.DataName) == INDEX_NONE;
}

static function bool HasDualPistolEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return IsPrimaryPistolWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate())) &&
		IsSecondaryPistolWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate()));
}

static function bool CheckDualPistolGetsEquipped(XComGameState_Unit UnitState, XComGameState_Item ItemState, optional XComGameState CheckGameState)
{
	if (UnitState == none)
	{
		return false;
	}

	return (IsPrimaryPistolWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate())) &&
		IsSecondaryPistolWeaponTemplate(X2WeaponTemplate(ItemState.GetMyTemplate())))
		||
		(IsPrimaryPistolWeaponTemplate(X2WeaponTemplate(ItemState.GetMyTemplate())) &&
		IsSecondaryPistolWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate())));
}

static function bool HasDualMeleeEquipped(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	if (UnitState == none)
	{
		return false;
	}

	return IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate())) &&
		IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState).GetMyTemplate()));
}

static function bool IsPrimaryPistolWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		default.SkipWeapons.Find(WeaponTemplate.DataName) == INDEX_NONE &&
		WeaponTemplate.StowedLocation == eSlot_None &&
		WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon &&
		default.PistolCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE &&
		default.WeaponCategoryBlacklist.Find(WeaponTemplate.WeaponCat) == INDEX_NONE;
}

static function bool IsSecondaryPistolWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		default.SkipWeapons.Find(WeaponTemplate.DataName) == INDEX_NONE &&
		WeaponTemplate.StowedLocation == eSlot_None &&
		WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon &&
		default.PistolCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE &&
		InStr(WeaponTemplate.DataName, "_TMP_") == INDEX_NONE && // Filter RF Templar Weapons
		default.WeaponCategoryBlacklist.Find(WeaponTemplate.WeaponCat) == INDEX_NONE;
}

static function bool IsPrimaryMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		default.SkipWeapons.Find(WeaponTemplate.DataName) == INDEX_NONE &&
		WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon &&
		WeaponTemplate.iRange == 0 &&
		WeaponTemplate.WeaponCat != 'wristblade' &&
		WeaponTemplate.WeaponCat != 'shield' &&
		WeaponTemplate.WeaponCat != 'gauntlet' &&
		default.WeaponCategoryBlacklist.Find(WeaponTemplate.WeaponCat) == INDEX_NONE;
}

static function bool FindIndividualWeaponConfig(name TemplateName, out WeaponConfig FoundWeaponConfig)
{
	local int Index;

	Index = default.IndividualWeaponConfig.Find('TemplateName', TemplateName);
	if (Index != INDEX_NONE)
	{
		FoundWeaponConfig = default.IndividualWeaponConfig[Index];
		return true;
	}

	return false;
}

static function bool IsSecondaryMeleeWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	return WeaponTemplate != none &&
		default.SkipWeapons.Find(WeaponTemplate.DataName) == INDEX_NONE &&
		WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon &&
		WeaponTemplate.iRange == 0 &&
		WeaponTemplate.WeaponCat != 'wristblade' &&
		WeaponTemplate.WeaponCat != 'shield' &&
		WeaponTemplate.WeaponCat != 'gauntlet' &&
		default.WeaponCategoryBlacklist.Find(WeaponTemplate.WeaponCat) == INDEX_NONE;
}

static function bool AllowUnitState(XComGameState_Unit UnitState)
{
	return UnitState.IsSoldier() ||
		   (UnitState.IsAdvent() && (HasPrimaryPistolEquipped(UnitState) || HasDualPistolEquipped(UnitState)));
}

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

exec function PS_ResetWeaponsToDefaultSockets()
{
	local XComTacticalController TacticalController;
	local XComGameState_Unit UnitState;
	//local XComUnitPawn Pawn;
	local XGUnit Unit;
	local XGInventory Inventory;

	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	if (TacticalController != none)
	{
		Unit = TacticalController.GetActiveUnit();
		//Unit.ResetWeaponsToDefaultSockets();

		//Pawn = TacticalController.GetActivePawn();
		//Pawn.CreateVisualInventoryAttachments();
		
		UnitState = XComGameState_Unit(
			`XCOMHISTORY.GetGameStateForObjectID(
				TacticalController.GetActiveUnitStateRef().ObjectID
			)
		);
		Inventory = Unit.Spawn(class'XGInventory', XGUnit(UnitState.GetVisualizer()).Owner);
		Inventory.PostInit();
		XGUnit(UnitState.GetVisualizer()).SetInventory(Inventory);
		UnitState.SyncVisualizer();
	}
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
