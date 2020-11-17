class gun_GameMod extends GameMod
	config(Mods);
	
event OnModLoaded()
{
	HookActorSpawn(class'Hat_Player', 'Hat_Player');
	GiveItem(class'rifle_weapon');
}

event OnHookedActorSpawn(Object NewActor, Name Identifier)
{
	if (Identifier == 'Hat_Player') GiveItem(class'rifle_weapon');
}

event OnModUnloaded()
{
	GiveItem(class'rifle_weapon', true);
}

function PostSpawn()
{
	GiveItem(class'rifle_weapon');
}

function GiveItem(class Item, bool Clear = false)
{
	if(Clear)
	{
		Hat_PlayerController(GetALocalPlayerController()).GetLoadout().RemoveBackpack(class'Hat_Loadout'.static.MakeLoadoutItem(Item));
	}
	else
	{
		Hat_PlayerController(GetALocalPlayerController()).GetLoadout().AddBackpack(class'Hat_Loadout'.static.MakeLoadoutItem(Item), false);
	}
}