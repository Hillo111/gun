class rifle_weapon extends Hat_Weapon_Umbrella;

//Need these variables
var Interaction KeyCaptureInteraction;
var Hat_PlayerController PC;

var bool firing;
var bool canFire;
var float fireTimer;

var float slomoTimer;
var float slomoAmount;

var int curAmmo;
var int maxAmmo;

var float reloadTime;
var bool reloading;

var bool hasFiredInAir; // checks if we have already activated the slomo in the air

var DynamicCameraActor Camera; // since we cant change hat kid's camera, we create our own that we can control and assign it to hat kid
var bool aiming;
var float aimRotationSpeed;
var float camDistFromPlayer;

var float minPitchLimit;
var float maxPitchLimit;

var SoundCue ShotSoundEffect;

var bool displayHUD;

var() class<Projectile> Projectile;

defaultproperties
{
	Components.Remove(Mesh1);
	Components.Remove(Mesh2);

	Begin Object Class=SkeletalMeshComponent Name=UniqueName
		SkeletalMesh=SkeletalMesh'HatkidgunContent.Ak47_skelmodel'
		PhysicsAsset=PhysicsAsset'HatInTime_Weapons.Physics.umbrella_shaft_Physics'
		bOnlyOwnerSee=false
		CastShadow=true
		bCastDynamicShadow=true
		CollideActors=false
		BlockRigidBody=false
		MaxDrawDistance=6000
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bAcceptsStaticDecals=false
		bAcceptsDynamicDecals=false
	End Object
	Components.Add(UniqueName);
	
	OpenMesh = None;
	ShaftMesh = UniqueName;

	Begin Object Name=Mesh0
		SkeletalMesh = SkeletalMesh'HatkidgunContent.Ak47_skelmodel'
		Materials(0) = None
	End Object

		
	CoopTexture = None;
	
	HUDIcon = Texture2D'HatkidgunContent.Rifleicon'
	HitSound = SoundCue'HatinTime_SFX_Metro.SoundCues.Weapon_Baseball_Bat_General_Hit'
	
	WeaponName = "weapon_rifle"
	WeaponDescription(0) = "weapon_rifle_desc"

	IsUmbrellaWeapon = false
	
	firing = false;
	canFire = true;
	
	// PARAMS TO NERF/BUFF
	
	fireTimer = 0.17; // Time inbetween shots
	slomoTimer = 1.0; // How long the slomo stays active. doesnt matter if we touch the ground
	slomoAmount = 0.5; // how much the game is slowed down
	aimRotationSpeed = 1000.0; // how fast you can turn the camera
	
	maxAmmo = 13; 
	curAmmo = 13;
	
	reloadTime = 0.8; // how long it takes to reload
	
	hasFiredInAir = false;
	reloading = false;
	aiming = false;
	
	minPitchLimit = -20.0;
	maxPitchLimit = 100.0;
	
	ShotSoundEffect = SoundCue'HatkidgunContent.RifleFire_cue';
	
	displayHUD = false;
	
	camDistFromPlayer = 20;
	
	Projectile = class'rifle_bullet';
	
}

function OnAttackParticle(ParticleSystemComponent PSC)
{
	PSC.SetMaterialParameter('Material', MaterialInstanceConstant'HatInTime_Costumes3.Materials.AttackSwing_BaseballBat');
}

simulated function bool GroundAttack()
{
    return Attack();
}

simulated function bool SpecialGroundAttack()
{
    return Super.GroundAttack();
}

simulated function bool AirAttack()
{
	if (!hasFiredInAir && !reloading && curAmmo > 0)
	{
		DoSlomo();
		hasFiredInAir = true;
	}
    return Attack();
}

function bool Attack()
{    
	// I just have this here to eat all the attacks, so it doesnt get in the way of the real attacks
	return true;
}

simulated function bool StartAttack()
{
   if(!Super.StartAttack())
   {
      return false;
   }
   
   if (reloading) return false;
   
   firing = true;
   if (curAmmo == 0)
   {
		PlaySound(SoundCue'HatkidgunContent.outofammosoundeffect_cue');
   }
   
   return true;
}

simulated function EndAttack()
{
	Print("Ended attack");
	firing = false;
}

function bool ReceivedNativeInputKey(int ControllerId, name Key, EInputEvent EventType, float AmountDepressed, bool bGamepad)
{
	
	switch(Key)
	{
		case 'Hat_Player_Attack':
			if (EventType == IE_Pressed)
			{
				// firing = true; // i dont want to do it here since it means youre able to fire during the cutscenes and while swinging. not good.
			}
			else if (EventType == IE_Released)
			{
				firing = false;
			}
			break;
		case 'Hat_Player_Ability':
			if (EventType == IE_Pressed)
			{
				aiming = true;
			}
			else if (EventType == IE_Released){
				aiming = false;
			}
			break;
		case 'Hat_Player_Interact':
			if (EventType == IE_Pressed)
			{
				firing = false;
				Reload();
			}
			break;
		
	}
	
	
	/* Bindings list for reference
	Bindings=(Name="Hat_Player_Crouch",Command="GBA_Duck")
	Bindings=(Name="Hat_Player_Ability",Command="GBA_Ability")
	Bindings=(Name="Hat_Player_AbilitySwap",Command="GBA_AbilitySwap")
	Bindings=(Name="Hat_Player_Jump",Command="GBA_Jump")
	Bindings=(Name="Hat_Player_Attack",Command="GBA_Fire")
	Bindings=(Name="Hat_Player_Interact",Command="GBA_Use")
	
	enum EInputEvent
	{
		IE_Pressed,
		IE_Released,
		IE_Repeat,
		IE_DoubleClick,
		IE_Axis
	};
	*/
	
	return false;
}

function bool ReceivedNativeInputAxis( int ControllerId, name Key, float Delta, float DeltaTime, optional bool bGamepad )
{
	local Rotator CameraRot;
	CameraRot = Camera.Rotation;
	if (aiming){
		if(Key == 'Hat_Player_LookX')
		{
			CameraRot.Yaw += aimRotationSpeed * Delta;
		}
		else if(Key == 'Hat_Player_LookY')
		{
			CameraRot.Pitch += aimRotationSpeed * Delta;
			CameraRot.Pitch = Max(CameraRot.Pitch, minPitchLimit);
			CameraRot.Pitch = Min(CameraRot.Pitch, maxPitchLimit);
		}
		Camera.SetRotation(CameraRot);
	}
	
	return false;
}

static function Print(string s)
{
    class'WorldInfo'.static.GetWorldInfo().Game.Broadcast(class'WorldInfo'.static.GetWorldInfo(), s);
}

function DoFire()
{
	local Projectile p;
	
	Hat_Player(Instigator).SetCollision(false,false);

	PlaySound(ShotSoundEffect);
	
	p = Spawn(Projectile, Hat_Player(Instigator),, Hat_Player(Instigator).Location, Hat_Player(Instigator).Rotation);
	p.Init(Vector(Hat_Player(Instigator).Rotation));
	
	Hat_Player(Instigator).SetCollision(true,true);
}

function AllowFire()
{
	canFire = true;
	Print("Allowed fire");
}

function DoSlomo()
{
	Owner.CustomTimeDilation = slomoAmount;
	class'WorldInfo'.static.GetWorldInfo().Game.SetTimer(slomoTimer, false, NameOf(DeactivateSlomo), self);
}

function DeactivateSlomo()
{
	if (Owner.CustomTimeDilation == slomoAmount) // we do the check to not interfere with the time stop hat
	{
		Owner.CustomTimeDilation = 1;
	}
	
}

function Reload()
{
	if (curAmmo == maxAmmo) return;
	if (reloading) return;
	reloading = true;
	DeactivateSlomo();
	PlaySound(SoundCue'HatkidgunContent.RifleReload_cue');
	class'WorldInfo'.static.GetWorldInfo().Game.SetTimer(reloadTime, false, NameOf(ResetAmmo), self);
}

function ResetAmmo()
{
	reloading = false;
	curAmmo = maxAmmo;
}

simulated event tick(float d)
{
	local rifle_aim_HUD riflehud;
	
	if (firing)
	{
		if (canFire && curAmmo > 0){
			curAmmo -= 1;
			canFire = false;
			DoFire();
			class'WorldInfo'.static.GetWorldInfo().Game.SetTimer(fireTimer, false, NameOf(AllowFire), self);
			
			Print("Current ammo: " @ string(curAmmo));
			/*
			if (curAmmo == 0){
				Reload();
			}
			*/
			if (curAmmo == 0){
				PlaySound(SoundCue'HatkidgunContent.outofammosoundeffect_cue');
			}
		}
	}
	if (Owner.Physics == PHYS_Walking)
	{
		// the player is on the ground;
		DeactivateSlomo();
		hasFiredInAir = false;
	}
	
	riflehud = rifle_aim_HUD(Hat_HUD(PC.MyHUD).OpenHUD(class'rifle_aim_HUD'));
	riflehud.Weapon = self;
}

function GivenTo( Pawn NewOwner, optional bool bDoNotActivate )
{
	local Hat_PlayerController p;
    Super.GivenTo(NewOwner, bDoNotActivate);
	
	p = Hat_PlayerController(Pawn(Owner).Controller);
	AttachPlayer(p);
	
	displayHUD = true;
}

function OnLoadoutChanged(PlayerController Controller, Object Loadout, Object BackpackItem)
{

	local Hat_PlayerController PlyController;
	PlyController = Hat_PlayerController(Controller);

	if (PlyController.GetLoadout().MyLoadout.Weapon.BackpackClass == class'rifle_weapon') // check that its our weapon being removed
	{
		displayHUD = false;
		DetachPlayer();
	}
}

//This will insert our key capture interaction into the playercontroller
function AttachPlayer(Hat_PlayerController player)
{
	local int iInput;
	PC = player;
	KeyCaptureInteraction = new(PC) class'Interaction';
	//Set the functions for received keys and axis data to our own
	KeyCaptureInteraction.OnReceivedNativeInputKey = ReceivedNativeInputKey;
	KeyCaptureInteraction.OnReceivedNativeInputAxis = ReceivedNativeInputAxis;

	iInput = PC.Interactions.Find(PC.PlayerInput);
	PC.Interactions.InsertItem(Max(iInput, 0), KeyCaptureInteraction);
}

function DetachPlayer()
{
	PC.Interactions.RemoveItem(KeyCaptureInteraction);
	KeyCaptureInteraction = none;
	PC = none;
}