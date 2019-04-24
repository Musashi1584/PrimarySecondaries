class AnimNotify_Slomo extends AnimNotify_Scripted;

var() editinline float Speed;

event Notify(Actor Owner, AnimNodeSequence AnimSeqInstigator)
{
	`CHEATMGR.Slomo(Speed);
}

defaultproperties
{
	Speed = 1
}