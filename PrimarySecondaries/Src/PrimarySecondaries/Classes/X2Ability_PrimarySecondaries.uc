class X2Ability_PrimarySecondaries extends X2Ability
	dependson (XComGameStateContext_Ability) config(PrimarySecondaries);

var config int PISTOL_MOVEMENT_BONUS;
var config int PISTOL_DETECTIONRADIUS_MODIFER;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AddBothBarrels());
	Templates.AddItem(PrimaryPistolsBonus('PrimaryPistolsBonus', default.PISTOL_MOVEMENT_BONUS, default.PISTOL_DETECTIONRADIUS_MODIFER));
	Templates.AddItem(PrimaryAnimSet());

	return Templates;
}

static function X2AbilityTemplate AddBothBarrels()
{
	local X2AbilityTemplate								Template;	
	local X2AbilityCost_Ammo							AmmoCost;
	local X2AbilityCost_QuickdrawActionPointsPatched	ActionPointCost;
	local X2Effect_ApplyWeaponDamage					WeaponDamageEffect;
	local array<name>									SkipExclusions;
	local X2Effect_Knockback							KnockbackEffect;
	local X2AbilityTarget_Single						SingleTarget;

	// Macro to do localisation and stuffs
	`CREATE_X2ABILITY_TEMPLATE(Template, 'PrimaryBothBarrels');

	// Icon Properties
	//Template.bDontDisplayInAbilitySummary = true;
	Template.IconImage = "img:///PrimarySawedoffShotgun.UI.UIPerk_AbilityBothBarrels";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_PISTOL_SHOT_PRIORITY + 1;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.DisplayTargetHitChance = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';                                       // color of the icon
	Template.bHideOnClassUnlock = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

	// Activated by a button press; additionally, tells the AI this is an activatable
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// *** VALIDITY CHECKS *** //
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// Targeting Details
	// Can only shoot visible enemies
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	// Can't target dead; Can't target friendlies
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	// Can't shoot while dead
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	// Only at single targets that are in range.
	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	SingleTarget.bAllowDestructibleObjects=true;
	SingleTarget.bShowAOE = true;
	Template.AbilityTargetStyle = SingleTarget;

	// Action Point
	ActionPointCost = new class'X2AbilityCost_QuickdrawActionPointsPatched';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);	

	// Ammo
	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 2;
	Template.AbilityCosts.AddItem(AmmoCost);
	Template.bAllowAmmoEffects = true; // 	

	// Weapon Upgrade Compatibility
	Template.bAllowFreeFireWeaponUpgrade = true;                                            // Flag that permits action to become 'free action' via 'Hair Trigger' or similar upgrade / effects

	// Damage Effect
	WeaponDamageEffect = new class'X2Effect_DoubleDamage';
	Template.AddTargetEffect(WeaponDamageEffect);

	// Hit Calculation (Different weapons now have different calculations for range)
	Template.AbilityToHitCalc = default.SimpleStandardAim;
	Template.AbilityToHitOwnerOnMissCalc = default.SimpleStandardAim;
		
	// Targeting Method
	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
	Template.bUsesFiringCamera = true;
	Template.CinescriptCameraType = "StandardGunFiring";

	// MAKE IT LIVE!
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 5;
	Template.AddTargetEffect(KnockbackEffect);

	Template.bUseAmmoAsChargesForHUD = false;

	return Template;	
}

static function X2AbilityTemplate PrimaryPistolsBonus(name TemplateName, int Bonus, float DetectionModifier)
{
	local X2AbilityTemplate                 Template;	
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, Bonus);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_DetectionModifier, DetectionModifier);
	Template.AddTargetEffect(PersistentStatChangeEffect);
	
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	
	return Template;
}

static function X2AbilityTemplate PrimaryAnimSet()
{
	local X2AbilityTemplate                 Template;	
	local X2Effect_AdditionalAnimSets		AnimSets;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PrimaryAnimSet');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	AnimSets = new class'X2Effect_AdditionalAnimSets';
	AnimSets.AddAnimSetWithPath("PrimaryPistols_ANIM.Anims.AS_Primary");
	AnimSets.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(AnimSets);
	
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	
	return Template;
}