class rifle_bullet extends Hat_Projectile;

var() Meshcomponent Mesh;

defaultproperties
{
	Begin Object Name=CollisionCylinder
         CollisionRadius=9
         CollisionHeight=9
	End Object

	Begin Object Class=StaticMeshComponent Name=Mesh0
		StaticMesh=StaticMesh'HatkidgunContent.Rifle_bullet'
		bUsePrecomputedShadows = false
		Scale=0.1
	End Object
	
	Components.Add(Mesh0);
	Mesh = Mesh0;

	speed=5000
	MaxSpeed=5000

	LifeSpan=7
	 
	 Damage = 1;
     MyDamageType=class'Hat_DamageType_bump';
     IgnoreTeam = true;
     ExplodeOnPlayerImpact = true;
     AllowJumpOn = false;
     DiveOnJumpOn = false;
     ExplodeOnJumpOn = false;
}

function Actor NearbyPawn()
{
	local Hat_Pawn b;
	foreach NearbyDynamicActors(class'Hat_Pawn', b, 1000)
	{
		if (b.bHidden) continue;
		if (VSize(b.Location - Instigator.Location - Instigator.Velocity*0.5) > Lerp(200,700,FClamp(Vector(Instigator.Rotation) dot Normal((b.Location - Instigator.Location - Instigator.Velocity*0.6)*vect(1,1,0)),0,1))) continue;
		return b;
	}
	return None;
}

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	PlaySound(SoundCue'HatkidgunContent.BulletHitSound_cue');
	if (ActorCanJumpOn(Other))
	{
		OnJumpedOn(Other, HitLocation, HitNormal);
		return;
	}
	if (!Other.bStatic && DamageRadius == 0.0)
	{
		Other.TakeDamage(Damage, InstigatorController, Location, MomentumTransfer * Normal(Velocity), MyDamageType,, self);
	}
	Destroy();
}

static function Print(string s)
{
    class'WorldInfo'.static.GetWorldInfo().Game.Broadcast(class'WorldInfo'.static.GetWorldInfo(), s);
}