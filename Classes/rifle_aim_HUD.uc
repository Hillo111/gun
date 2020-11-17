class rifle_aim_HUD extends Hat_HUDElementFancy
	dependson(Hat_HUDInputButtonRender);

var rifle_weapon Weapon;

var int pulseCounter;
var float pulseScale;

var int DisplayState;

defaultproperties 
{
	pulseCounter = 0;
	pulseScale = 0.1;
	DisplayState = 0;
}

function bool Tick(HUD H, float d)
{
	pulseCounter += 4;
	pulseCounter = pulseCounter % 360;
	
	if (Weapon != None && Weapon.displayHUD)
	{
		DisplayState = 1;
	}
	else {
		DisplayState = 0;
	}
	
	return true;
}

function bool Render(HUD H)
{
	local float strwidth, strheight;
	local string AmmoMessage;
	local float strsize;
	local float displaySize;
	local float posx, posy;
	
	if (!Super.Render(H)) return false;
	if (Weapon == None) return false;
		
	
	strsize = FMin(H.Canvas.ClipX, H.Canvas.ClipY) * 0.07;
	
	if (Weapon != None){
		AmmoMessage = "Ammo: " @ string(Weapon.curAmmo);
	}
	else 
	{
		AmmoMessage = "HUD IS NOT ATTACHED TO A WEAPON OBJECT";
	}
	H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont(AmmoMessage);
	
	H.Canvas.StrLen(AmmoMessage, strwidth, strheight);
	
	displaySize = strsize * 0.014;
	
	if (Weapon.curAmmo == 0){
		H.Canvas.SetDrawColor(255, 0, 0, 255 * DisplayState);
		displaySize += Sin(pulseCounter / 180.0 * Pi) * displaySize * pulseScale;
	}
	else {
		H.Canvas.SetDrawColor(255, 255, 255, 255 * DisplayState);
	}
	
	H.Canvas.StrLen("Reload", strwidth, strheight);
	
	posx = H.Canvas.ClipX * 0.9 - strwidth;
	posy = H.Canvas.ClipY * 0.7;
	
	DrawCenterLeftText(H.Canvas, AmmoMessage, posx + strsize * 0.5, posy, displaySize, displaySize);
	
	if (Weapon.curAmmo < Weapon.maxAmmo){
		displaySize = strsize * 0.014;
	
		posx = H.Canvas.ClipX * 0.9 - strwidth;
		posy = H.Canvas.ClipY * 0.76;
		
		H.Canvas.SetDrawColor(255, 255, 255, 255 * DisplayState);

		class'Hat_HUDInputButtonRender'.static.Render(H, HatControllerBind_Player_Interact, posx + strsize * 0.5, posy, strsize * 0.5);
		DrawCenterLeftText(H.Canvas, "Reload", posx + strsize, posy, displaySize * 0.5, displaySize * 0.5);
	}
	
	
	
	
	
	return true;
}