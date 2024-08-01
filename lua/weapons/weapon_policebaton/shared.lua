AddCSLuaFile()
if SERVER then
    AddCSLuaFile("cl_init.lua")
	util.AddNetworkString("ArrestReason")
	util.AddNetworkString("ArrestReasonMessage")
end

/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Downloading content from workshop
---------------------------------------------------------------------------------------------------------------------------------------------
*/	

if SERVER then resource.AddWorkshop("615887479"); end

/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Config
---------------------------------------------------------------------------------------------------------------------------------------------
*/

SWEP.hitRequireForStun = 1;
SWEP.stunTime = 6;
SWEP.primaryFireDamage = 1;

SWEP.primaryFireDelay = 0.5;
SWEP.secondaryFireDelay = 2;
/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Default SWEP config
---------------------------------------------------------------------------------------------------------------------------------------------
*/

SWEP.reloadCooldown = CurTime();
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Author = "Drover"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.IconLetter = ""
SWEP.PrintName = "Police Baton"
SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "physgun"
SWEP.HoldType ="physgun"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Category = "Police Baton" 


SWEP.UseHands = true;
SWEP.ViewModel = Model("models/drover/baton.mdl");
SWEP.WorldModel = Model("models/drover/w_baton.mdl");

local SwingSound = Sound( "WeaponFrag.Throw" );
local HitSound = Sound( "Flesh.ImpactHard" );



SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""



/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Initialize
---------------------------------------------------------------------------------------------------------------------------------------------
*/

function SWEP:Initialize()
    self:SetHoldType("melee");
end



function SWEP:SetupShield()

end

/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Hook Can Drop Weapon
---------------------------------------------------------------------------------------------------------------------------------------------
*/

hook.Add("canDropWeapon", "NoDropPoliceBaton",function(ply, ent)
	if ent:GetClass() == "weapon_policebaton" then
		return false;
	end
end)

/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Some functions
---------------------------------------------------------------------------------------------------------------------------------------------
*/


SWEP.menuButtons = {};
SWEP.menuButtons[1] = {}
SWEP.menuButtons[1].buttonText = "Unarrest";
SWEP.menuButtons[1].left = true;
SWEP.menuButtons[1].func = function(owner,ent)
	if owner:GetPos():Distance(ent:GetPos()) > 150 then return end;
--	if not ent.stunnedBaton then return end;
	if not ent:isArrested() then return end;
	ent:unArrest(owner);
end


SWEP.menuButtons[3] = {}
SWEP.menuButtons[3].buttonText = "Arrest";
SWEP.menuButtons[3].left = true;
SWEP.menuButtons[3].func = function(owner, ent)
    if owner:GetPos():Distance(ent:GetPos()) > 150 then return end
    if not ent.stunnedBaton then DarkRP.notify(owner, 1, 4, "Target needs to be stunned!") return end
    if ent:isArrested() then return end
    if ent:isCP() and not GAMEMODE.Config.cpcanarrestcp then return end
    
    local jpc = DarkRP.jailPosCount()
    if not jpc or jpc == 0 then
        DarkRP.notify(owner, 1, 4, DarkRP.getPhrase("cant_arrest_no_jail_pos"))
    else
        if not ent.Babygod then
            -- Arrest the player immediately
            ent:arrest(nil, owner)
            DarkRP.notify(ent, 0, 20, DarkRP.getPhrase("youre_arrested_by", owner:Nick()))
            
            -- Then prompt for a reason
            net.Start("ArrestReason")
            net.WriteEntity(ent)
            net.Send(owner)
            
            if owner.SteamName then
                DarkRP.log(owner:Nick() .. " (" .. owner:SteamID() .. ") arrested " .. ent:Nick(), Color(0, 255, 255))
            end
        else
            DarkRP.notify(owner, 1, 4, DarkRP.getPhrase("cant_arrest_spawning_players"))
        end
    end
end


SWEP.menuButtons[2] = {}
SWEP.menuButtons[2].buttonText = "Wanted";
SWEP.menuButtons[2].left = false;
SWEP.menuButtons[2].func = function(owner,ent)

end



SWEP.menuButtons[4] = {}
SWEP.menuButtons[4].buttonText = "Warrant";
SWEP.menuButtons[4].left = false;
SWEP.menuButtons[4].func = function(owner,ent)

end


/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Reload
---------------------------------------------------------------------------------------------------------------------------------------------
*/

function SWEP:Reload()
	if self.reloadCooldown + 2 > CurTime() then return end;
	self.reloadCooldown = CurTime();
	if CLIENT then return end
	self.Weapon:SendWeaponAnim( ACT_VM_RELOAD);
end	


function SWEP:Draw()
	self:SendWeaponAnim(ACT_VM_DRAW);
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW);
end	

local drawMenu = false;
if CLIENT then
	hook.Add("PlayerBindPress","test1", function(ply,bind,pressed)
		local weap = ply:GetActiveWeapon();
		if weap == nil or weap == NULL or not IsValid(weap) or weap:GetClass() !="weapon_policebaton" then return end;
		if string.find(bind,"+reload") then 
			gui.EnableScreenClicker(true);
			weap.drawMenu = true;			
		end
	end)
	
	hook.Add("KeyRelease","test2",function(ply,key)
		local weap = ply:GetActiveWeapon();
		if weap == nil or weap == NULL or not IsValid(weap) or weap:GetClass() !="weapon_policebaton" then return end;
		if key == IN_RELOAD then
			gui.EnableScreenClicker(false);
			weap.drawMenu = false;
			net.Start("batondrawbut") net.SendToServer();
			
		end
	end)
	



end



/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Baton Stun / Unstun
---------------------------------------------------------------------------------------------------------------------------------------------
*/
function SWEP:Stun(ply)
	local ang = ply:GetAngles();
	ply:SetEyeAngles(Angle(60,ang.y,ang.r));
	ply:Freeze(true);
	ply.stunnedBaton = true;
	ply:SetNWInt('batonstuntime',CurTime());
	net.Start("batonstunanim") net.WriteEntity(ply) net.WriteBool(true) net.Broadcast();
	timer.Create("unstunbatonstun"..tostring(ply:EntIndex()),self.stunTime,1,function()
		if IsValid(ply) then 
			ply:Freeze(false);
			ply.stunnedBaton = false;
			net.Start("batonstunanim") net.WriteEntity(ply) net.WriteBool(false) net.Broadcast();
		end
	end)
end


/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Attack Player
---------------------------------------------------------------------------------------------------------------------------------------------
*/

function SWEP:AttackPlayer(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end;
	self.Owner:EmitSound(Sound("Flesh.ImpactHard"));
	ply:SetVelocity((ply:GetPos() - self:GetOwner():GetPos()) * 2);
	if ply.stunnedBaton == true then return end;
	local hits = ply.hitByBaton or 0;
	local lTime = ply.lastBatonHit or CurTime();
	if CurTime() > lTime + 3 then 
		hits = 0; 
	end
	local numb = 1;
	if ply:isArrested() then numb = 1000 end;
	ply.hitByBaton = hits + numb;
	ply.lastBatonHit = CurTime();
	if hits + numb >= self.hitRequireForStun then
		self:Stun(ply);
	end
end

/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Attack Entity
---------------------------------------------------------------------------------------------------------------------------------------------
*/

function SWEP:AttackEnt(ent,dmg)
		self.Owner:EmitSound(Sound("physics/wood/wood_box_impact_hard3.wav"));
        if FPP and FPP.plyCanTouchEnt(self:GetOwner(), ent, "EntityDamage") then
			if ent.SeizeReward and not ent.beenSeized and not ent.burningup and self:GetOwner():isCP() and ent.Getowning_ent and self:GetOwner() ~= ent:Getowning_ent() then
				 self:GetOwner():addMoney(ent.SeizeReward);
				 DarkRP.notify(self:GetOwner(), 1, 4, DarkRP.getPhrase("you_received_x", DarkRP.formatMoney(ent.SeizeReward), DarkRP.getPhrase("bonus_destroying_entity")));
				ent.beenSeized = true;
			 end
         ent:TakeDamage(dmg, self:GetOwner(), self);
		end
end
/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Make Hit
---------------------------------------------------------------------------------------------------------------------------------------------
*/
local entMeta = FindMetaTable("Entity");
function SWEP:MakeHit(dmg)
	self:GetOwner():SetAnimation(PLAYER_ATTACK1);
    if CLIENT then return end;
    local trace = util.QuickTrace(self:GetOwner():EyePos(), self:GetOwner():GetAimVector() * 90, {self:GetOwner()});
    
    if IsValid(trace.Entity) and trace.Entity:GetClass() == "func_breakable_surf" then
        trace.Entity:Fire("Shatter"); 
        return;
    end

	local ent = self:GetOwner():getEyeSightHitEntity(100, 15, fn.FAnd{fp{fn.Neq, self:GetOwner()}, fc{IsValid, entMeta.GetPhysicsObject}});
    if not IsValid(ent) then return end;
    if ent:IsPlayer() and not ent:Alive() then return end;

    

    if ent:IsPlayer() 	then
		self:AttackPlayer(ent);
		if dmg > 0 then
			ent:TakeDamage(dmg, self:GetOwner(), self);
		end
    elseif !ent:IsNPC() or !ent:IsVehicle() then
        self:AttackEnt(ent,dmg);
    end
end

/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Primary attack
---------------------------------------------------------------------------------------------------------------------------------------------
*/

function SWEP:PrimaryAttack()
	self:SetHoldType("melee");
	self:SetNextPrimaryFire(CurTime() + self.primaryFireDelay);
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK );
	self:GetOwner():EmitSound(SwingSound);
	self:MakeHit(0);
	
end


/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Secondary attack / Deploy static shield
---------------------------------------------------------------------------------------------------------------------------------------------
*/
function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + self.secondaryFireDelay);
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK );
	self:GetOwner():EmitSound(SwingSound);
	self:MakeHit(self.primaryFireDamage)
end

/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Network initialize && Client Receive
---------------------------------------------------------------------------------------------------------------------------------------------
*/

if SERVER then
	util.AddNetworkString("batonstunanim");
	util.AddNetworkString("batonsendfunc");
	util.AddNetworkString("batondrawbut");
	
	
	net.Receive("batonsendfunc",function(leng,ply)
		local id = net.ReadInt(3);
		local enemy = net.ReadEntity();
		if not IsValid(enemy) or not enemy:IsPlayer() or not enemy:Alive() then return end;
		if ply:GetActiveWeapon():GetClass() != "weapon_policebaton" then return end;
		ply:GetActiveWeapon().menuButtons[id].func(ply,enemy);
	end)
	
	net.Receive("batondrawbut",function(leng,ply)
		local enemy = net.ReadEntity();
		if ply:GetActiveWeapon():GetClass() != "weapon_policebaton" then return end;
		ply:GetActiveWeapon():Draw();
	end)
end

if CLIENT then
	net.Receive("batonstunanim",function()
		local ply = net.ReadEntity();
		local enable = net.ReadBool();
		if IsValid(ply) and ply:IsPlayer() and ply:Alive() then
			if enable then
				ply:AnimRestartGesture( GESTURE_SLOT_CUSTOM,ACT_HL2MP_IDLE_SLAM, false);   
			else
				ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM );
			end
		end	
	end)	
end


/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Deploy && Holster && Drop && Remove
---------------------------------------------------------------------------------------------------------------------------------------------
*/




function SWEP:Deploy()
	return true
end

function SWEP:Holster()
	return true;
end


function SWEP:OnDrop()
	return true;
end

function SWEP:OnRemove()
	return true;
end


/* 
---------------------------------------------------------------------------------------------------------------------------------------------
				Draw circles
---------------------------------------------------------------------------------------------------------------------------------------------
*/






-- NADIES ARREST REASON PROMPT STUFF THINGY..........


local color_red = Color(255, 0, 0)

if CLIENT then
    local function CreateMinimalistFrame(title)
        local frame = vgui.Create("DFrame")
        frame:SetSize(300, 180)
        frame:Center()
        frame:SetTitle("")
        frame:SetDraggable(true)
        frame:ShowCloseButton(false)
        frame:MakePopup()

        local titleBarHeight = 30
		surface.SetFont("DermaDefaultBold")
		local tw, th = surface.GetTextSize(title)

        frame.Paint = function(self, w, h)
            -- Title bar
            draw.RoundedBoxEx(4, 0, 0, w, titleBarHeight, Color(50, 50, 50), true, true, false, false)
            draw.SimpleText(title, "DermaDefaultBold", (w / 2) - tw / 2, titleBarHeight/2, Color(240, 240, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Main body
            draw.RoundedBoxEx(4, 0, titleBarHeight, w, h - titleBarHeight, Color(70, 70, 70), false, false, true, true)
        end

        local closeButton = vgui.Create("DButton", frame)
        closeButton:SetSize(20, 20)
        closeButton:SetPos(frame:GetWide() - 25, 5)
        closeButton:SetText("✕")
        closeButton:SetTextColor(Color(240, 240, 240))
        closeButton.Paint = function() end
        closeButton.DoClick = function() frame:Close() end

        return frame, titleBarHeight
    end

    net.Receive("ArrestReason", function()
        local target = net.ReadEntity()
        
        local frame, titleBarHeight = CreateMinimalistFrame("Arrest Reason")

        local textEntry = vgui.Create("DTextEntry", frame)
        textEntry:SetSize(280, 30)
        textEntry:SetPos(10, titleBarHeight + 20)
        textEntry:SetPlaceholderText("Enter reason for arrest...")
        textEntry:SetTextColor(Color(240, 240, 240))
        textEntry:SetPlaceholderColor(Color(180, 180, 180))
        textEntry.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60))
            self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
        end

        local submitButton = vgui.Create("DButton", frame)
        submitButton:SetSize(280, 30)
        submitButton:SetPos(10, titleBarHeight + 60)
        submitButton:SetText("Submit")
        submitButton:SetTextColor(Color(240, 240, 240))
        submitButton.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(70, 130, 180))
        end
        submitButton.DoClick = function()
            local reason = textEntry:GetValue()
            net.Start("ArrestReason")
            net.WriteEntity(target)
            net.WriteString(reason)
            net.SendToServer()
            frame:Close()
        end
    end)

    net.Receive("ArrestReasonMessage", function()
        local arrester = net.ReadString()
        local arrested = net.ReadString()
        local reason = net.ReadString()

        chat.AddText(color_red, "VN | ", Color(69, 112, 255), arrested, color_white, " was arrested by ", Color(69, 112, 255), arrester, color_white, " for: ", color_red, reason)
    end)
end

if SERVER then
    net.Receive("ArrestReason", function(len, ply)
        local target = net.ReadEntity()
        local reason = net.ReadString()
        
        if IsValid(target) and target:IsPlayer() and target:isArrested() then
            local arrester = ply:Nick()
			local arrested = target:Nick()

			net.Start("ArrestReasonMessage")
			net.WriteString(arrester)
			net.WriteString(arrested)
			net.WriteString(reason)
			net.Broadcast()
            
            DarkRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") arrest reason for " .. target:Nick() .. ": " .. reason, Color(0, 255, 255))
        end
    end)
end

hook.Add("PlayerInitialSpawn", "KANYEJOINED", function(ply)
	if ply:SteamID64() == kanyeSteamID then
		chat.AddText("[ALERT] THE ALPHA HAS LANDED")
	end	
end)