AddCSLuaFile()

SWEP.HoldType           = "ar2"

SWEP.PrintName          = "SG552"
SWEP.Slot               = 2

SWEP.ViewModelFlip      = false
SWEP.ViewModelFOV       = 64

SWEP.Ortho = {8, 0}

SWEP.Base                  = "weapon_tttbase"

SWEP.Kind                  = WEAPON_HEAVY
SWEP.WeaponID              = AMMO_PISTOL

SWEP.Bullets = {
	HullSize = 0,
	Num = 1,
	DamageDropoffRange = 3500,
	DamageDropoffRangeMax = 6520,
	DamageMinimumPercent = 0.1,
	Spread = Vector(0.03, 0.03, 0),
}

SWEP.Primary.Damage        = 18
SWEP.Primary.Delay         = 0.12
SWEP.Primary.Recoil        = 1.35
SWEP.Primary.Automatic     = true
SWEP.Primary.Ammo          = "Pistol"
SWEP.Primary.ClipSize      = 25 --25
SWEP.Primary.DefaultClip   = 50 --25
SWEP.Primary.Sound         = Sound "Weapon_SG552.Single"
SWEP.Secondary.Sound       = Sound "Default.Zoom"

SWEP.HeadshotMultiplier    = 1.45
SWEP.DeploySpeed = 1.8


SWEP.AutoSpawnable         = true
SWEP.Spawnable             = true
SWEP.AmmoEnt               = "item_ammo_pistol_ttt"

SWEP.ViewModel             = "models/weapons/cstrike/c_rif_sg552.mdl"
SWEP.WorldModel            = "models/weapons/w_rif_sg552.mdl"

SWEP.Ironsights = {
	Pos = Vector(-5, 0, 3),
	Angle = Vector(0, 0, 0),
	TimeTo = 0.25,
	TimeFrom = 0.2,
	SlowDown = 0.35,
	Zoom = 0.85,
}