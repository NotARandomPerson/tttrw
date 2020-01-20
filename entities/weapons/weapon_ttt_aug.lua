AddCSLuaFile()

SWEP.HoldType           = "ar2"

SWEP.PrintName          = "Steyr AUG"
SWEP.Slot               = 2

SWEP.Ortho = {9, 0}

SWEP.ViewModelFlip      = false
SWEP.ViewModelFOV       = 54

SWEP.Base                  = "weapon_tttbase"

SWEP.Bullets = {
	HullSize = 0,
	Num = 1,
	DamageDropoffRange = 650,
	DamageDropoffRangeMax = 4200,
	DamageMinimumPercent = 0.1,
	Spread = Vector(0.02, 0.03)
}

SWEP.Primary.Damage        = 17
SWEP.Primary.Delay         = 0.11
SWEP.Primary.Recoil        = 2
SWEP.Primary.Automatic     = true
SWEP.Primary.Ammo          = "SMG1"
SWEP.Primary.ClipSize      = 30
SWEP.Primary.DefaultClip   = 60
SWEP.Primary.Sound         = Sound "Weapon_AUG.Single"

SWEP.HeadshotMultiplier    = 1.9
SWEP.DeploySpeed = 1.3

SWEP.AutoSpawnable         = true
SWEP.Spawnable             = true
SWEP.AmmoEnt               = "item_ammo_pistol_ttt"

SWEP.ViewModel			= "models/weapons/cstrike/c_rif_aug.mdl"
SWEP.WorldModel			= "models/weapons/w_rif_aug.mdl"

SWEP.Ironsights = {
	Pos = Vector(-6.61, 0, 1.5),
	Angle = Vector(3.1, -3, 0),
	TimeTo = 0.25,
	TimeFrom = 0.15,
	SlowDown = 0.4,
	Zoom = 0.75,
}