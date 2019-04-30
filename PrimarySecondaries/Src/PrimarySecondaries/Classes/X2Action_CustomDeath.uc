class X2Action_CustomDeath extends X2Action_Death;

var name DeathAnimSequence;

simulated function Name ComputeAnimationToPlay()
{
	if (DeathAnimSequence != 'None')
	{
		`LOG(default.class @ GetFuncName() @ DeathAnimSequence,, 'PrimarySecondaries');
		return DeathAnimSequence;
	}
	
	return super.ComputeAnimationToPlay();
}
