class X2Item_SawedOffShotgun extends X2Item config(PrimarySecondaries);

// ***** UI Image definitions  *****
var config string SawedOffShotgun_CV_UIImage;
var config string SawedOffShotgun_MG_UIImage;
var config string SawedOffShotgun_BM_UIImage;

// ***** Damage arrays for attack actions  *****
var config WeaponDamageValue SawedOffShotgun_CONVENTIONAL_BASEDAMAGE;
var config WeaponDamageValue SawedOffShotgun_MAGNETIC_BASEDAMAGE;
var config WeaponDamageValue SawedOffShotgun_BEAM_BASEDAMAGE;

// ***** Core properties and variables for weapons *****
var config int SawedOffShotgun_CONVENTIONAL_AIM;
var config int SawedOffShotgun_CONVENTIONAL_CRITCHANCE;
var config int SawedOffShotgun_CONVENTIONAL_ICLIPSIZE;
var config int SawedOffShotgun_CONVENTIONAL_ISOUNDRANGE;
var config int SawedOffShotgun_CONVENTIONAL_IENVIRONMENTDAMAGE;
var config int SawedOffShotgun_CONVENTIONAL_ISUPPLIES;
var config int SawedOffShotgun_CONVENTIONAL_TRADINGPOSTVALUE;
var config int SawedOffShotgun_CONVENTIONAL_IPOINTS;
var config int SawedOffShotgun_CONVENTIONAL_RANGE;

var config int SawedOffShotgun_MAGNETIC_AIM;
var config int SawedOffShotgun_MAGNETIC_CRITCHANCE;
var config int SawedOffShotgun_MAGNETIC_ICLIPSIZE;
var config int SawedOffShotgun_MAGNETIC_ISOUNDRANGE;
var config int SawedOffShotgun_MAGNETIC_IENVIRONMENTDAMAGE;
var config int SawedOffShotgun_MAGNETIC_ISUPPLIES;
var config int SawedOffShotgun_MAGNETIC_TRADINGPOSTVALUE;
var config int SawedOffShotgun_MAGNETIC_IPOINTS;
var config int SawedOffShotgun_MAGNETIC_RANGE;

var config int SawedOffShotgun_BEAM_AIM;
var config int SawedOffShotgun_BEAM_CRITCHANCE;
var config int SawedOffShotgun_BEAM_ICLIPSIZE;
var config int SawedOffShotgun_BEAM_ISOUNDRANGE;
var config int SawedOffShotgun_BEAM_IENVIRONMENTDAMAGE;
var config int SawedOffShotgun_BEAM_ISUPPLIES;
var config int SawedOffShotgun_BEAM_TRADINGPOSTVALUE;
var config int SawedOffShotgun_BEAM_IPOINTS;
var config int SawedOffShotgun_BEAM_RANGE;

// ***** Schematic properties *****
var config int MAGNETIC_SCHEMATIC_SUPPLYCOST;
var config int BEAM_SCHEMATIC_SUPPLYCOST;

var config int MAGNETIC_SCHEMATIC_ALLOYCOST;
var config int BEAM_SCHEMATIC_ALLOYCOST;

var config int MAGNETIC_SCHEMATIC_ELERIUMCOST;
var config int BEAM_SCHEMATIC_ELERIUMCOST;

var config array<int> SAWED_OFF_RANGE;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	//create all three tech tiers of weapons
	Templates.AddItem(CreateTemplate_SawedOffShotgun_Conventional());
	Templates.AddItem(CreateTemplate_SawedOffShotgun_Magnetic());

	Templates.AddItem(CreateTemplate_SawedOffShotgun_Magnetic_Schematic());
	//Templates.AddItem(CreateTemplate_SawedOffShotgun_Beam_Schematic()); Not used -- JL

	return Templates;
}

// Initial SawedOffShotgun uses Pistol model and artwork until new artwork is complete
static function X2DataTemplate CreateTemplate_SawedOffShotgun_Conventional()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'SawedOffShotgun_CV_Primary');
	Template.EquipSound = "Conventional_Weapon_Equip";

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'pistol';
	Template.WeaponTech = 'conventional';
	Template.strImage = default.SawedOffShotgun_CV_UIImage; 
	Template.EquipSound = "Secondary_Weapon_Equip_Conventional";
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.Tier = 0;
	Template.RangeAccuracy = default.SAWED_OFF_RANGE;
	Template.BaseDamage = default.SawedOffShotgun_CONVENTIONAL_BASEDAMAGE;
	Template.Aim = default.SawedOffShotgun_CONVENTIONAL_AIM;
	Template.CritChance = default.SawedOffShotgun_CONVENTIONAL_CRITCHANCE;
	Template.iClipSize = default.SawedOffShotgun_CONVENTIONAL_ICLIPSIZE;
	Template.iSoundRange = default.SawedOffShotgun_CONVENTIONAL_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SawedOffShotgun_CONVENTIONAL_IENVIRONMENTDAMAGE;
	Template.iRange = default.SawedOffShotgun_CONVENTIONAL_RANGE;
	Template.NumUpgradeSlots = 1;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;

	Template.Abilities.AddItem('PrimaryBothBarrels');
	Template.Abilities.AddItem('PistolStandardShot');
	Template.Abilities.AddItem('PistolOverwatch');
	Template.Abilities.AddItem('PistolOverwatchShot');
	Template.Abilities.AddItem('PistolReturnFire');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('PrimaryPistolsBonus');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "PrimarySawedoffShotgun.Archetypes.WP_SawedoffShotgun_CV";

	Template.iPhysicsImpulse = 5;

	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;
	
	Template.DamageTypeTemplateName = 'Electrical';
	
	return Template;
}

static function X2DataTemplate CreateTemplate_SawedOffShotgun_Magnetic()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'SawedOffShotgun_MG_Primary');

	Template.WeaponCat = 'pistol';
	Template.WeaponTech = 'magnetic';
	Template.ItemCat = 'weapon';
	Template.strImage = default.SawedOffShotgun_MG_UIImage; 
	Template.WeaponPanelImage = "_MagneticRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.EquipSound = "Secondary_Weapon_Equip_Magnetic";
	Template.Tier = 2;

	Template.RangeAccuracy = default.SAWED_OFF_RANGE;
	Template.BaseDamage = default.SawedOffShotgun_MAGNETIC_BASEDAMAGE;
	Template.Aim = default.SawedOffShotgun_MAGNETIC_AIM;
	Template.CritChance = default.SawedOffShotgun_MAGNETIC_CRITCHANCE;
	Template.iClipSize = default.SawedOffShotgun_MAGNETIC_ICLIPSIZE;
	Template.iSoundRange = default.SawedOffShotgun_MAGNETIC_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SawedOffShotgun_MAGNETIC_IENVIRONMENTDAMAGE;
	Template.iRange = default.SawedOffShotgun_MAGNETIC_RANGE;
	Template.NumUpgradeSlots = 1;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;

	Template.Abilities.AddItem('PrimaryBothBarrels');
	Template.Abilities.AddItem('PistolStandardShot');
	Template.Abilities.AddItem('PistolOverwatch');
	Template.Abilities.AddItem('PistolOverwatchShot');
	Template.Abilities.AddItem('PistolReturnFire');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('PrimaryPistolsBonus');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "PrimarySawedoffShotgun.Archetypes.WP_SawedoffShotgun_MG";

	Template.iPhysicsImpulse = 5;
	
	Template.CreatorTemplateName = 'SawedoffShotgun_MG_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'SawedoffShotgun_CV'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Electrical';

	return Template;
}

static function X2DataTemplate CreateTemplate_SawedOffShotgun_Beam()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'SawedOffShotgun_BM');

	Template.WeaponCat = 'sawedoffshotgun';
	Template.WeaponTech = 'beam';
	Template.ItemCat = 'weapon';
	Template.strImage = default.SawedOffShotgun_BM_UIImage; 
	Template.EquipSound = "Secondary_Weapon_Equip_Beam";
	Template.WeaponPanelImage = "_BeamRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.Tier = 4;

	Template.RangeAccuracy = default.SAWED_OFF_RANGE;
	Template.BaseDamage = default.SawedOffShotgun_BEAM_BASEDAMAGE;
	Template.Aim = default.SawedOffShotgun_BEAM_AIM;
	Template.CritChance = default.SawedOffShotgun_BEAM_CRITCHANCE;
	Template.iClipSize = default.SawedOffShotgun_BEAM_ICLIPSIZE;
	Template.iSoundRange = default.SawedOffShotgun_BEAM_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SawedOffShotgun_BEAM_IENVIRONMENTDAMAGE;
	Template.iRange = default.SawedOffShotgun_BEAM_RANGE;
	Template.NumUpgradeSlots = 1;
	
	Template.InventorySlot = eInvSlot_PrimaryWeapon;

	Template.Abilities.AddItem('PrimaryBothBarrels');
	Template.Abilities.AddItem('PistolStandardShot');
	Template.Abilities.AddItem('PistolOverwatch');
	Template.Abilities.AddItem('PistolOverwatchShot');
	Template.Abilities.AddItem('PistolReturnFire');
	Template.Abilities.AddItem('HotLoadAmmo');
	Template.Abilities.AddItem('Reload');
	Template.Abilities.AddItem('PrimaryPistolsBonusCV');
	
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "PrimarySawedoffShotgun.Archetypes.WP_SawedoffShotgun_BM";

	Template.iPhysicsImpulse = 5;

	Template.CreatorTemplateName = 'SawedoffShotgun_BM_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'SawedoffShotgun_MG'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.DamageTypeTemplateName = 'Electrical';

	return Template;
}

static function X2DataTemplate CreateTemplate_SawedOffShotgun_Magnetic_Schematic()
{
	local X2SchematicTemplate Template;
	local ArtifactCost Resources, Artifacts;

	`CREATE_X2TEMPLATE(class'X2SchematicTemplate', Template, 'SawedOffShotgun_MG_Schematic');

	Template.ItemCat = 'weapon';
	Template.strImage = default.SawedOffShotgun_MG_UIImage; 
	Template.CanBeBuilt = true;
	Template.bOneTimeBuild = true;
	Template.HideInInventory = true;
	Template.PointsToComplete = 0;
	Template.Tier = 1;
	Template.OnBuiltFn = class'X2Item_DefaultSchematics'.static.UpgradeItems;

	// Reference Item
	Template.ReferenceItemTemplate = 'SawedOffShotgun_MG_Primary';
	Template.HideIfPurchased = 'SawedOffShotgun_BM';

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('MagnetizedWeapons');
	Template.Requirements.RequiredEngineeringScore = 10;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = default.MAGNETIC_SCHEMATIC_SUPPLYCOST;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'AlienAlloy';
	Artifacts.Quantity = default.MAGNETIC_SCHEMATIC_ALLOYCOST;
	Template.Cost.ResourceCosts.AddItem(Artifacts);
	
	// only add elerium cost if configured value greater than 0
	if (default.MAGNETIC_SCHEMATIC_ELERIUMCOST > 0) {
		Artifacts.ItemTemplateName = 'EleriumDust';
		Artifacts.Quantity = default.MAGNETIC_SCHEMATIC_ELERIUMCOST;
		Template.Cost.ResourceCosts.AddItem(Artifacts);
	}

	return Template;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = true
}