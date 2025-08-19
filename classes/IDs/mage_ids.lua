-- mage_ids.lua — Classic Anniversary Mage IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Mage IDS loaded")

local IDS = {
  Ability = {
    -- Basic
    Fireball         = 133,
    Frostbolt        = 116,
    ArcaneMissiles   = 5143,
    AutoAttack       = 6603,
    Wand             = 5019,
    
    -- Fire
    Scorch           = 2948,
    FireBlast        = 2136,
    Flamestrike      = 2120,
    Pyroblast        = 11366,
    Combustion       = 11129,
    BlastWave        = 11113,
    DragonBreath     = 31661,
    
    -- Frost
    FrostNova        = 122,
    Blizzard         = 10,
    ConeOfCold       = 120,
    IceLance         = 30455,
    IceBlock         = 45438,
    IceBarrier       = 11426,
    ColdSnap         = 11958,
    FrostArmor       = 168,
    IceArmor         = 7302,
    
    -- Arcane
    ArcaneExplosion  = 1449,
    ArcanePower      = 12042,
    PresenceOfMind   = 12043,
    ArcaneIntellect  = 1459,
    ArcaneBrilliance = 23028,
    ManaShield       = 1463,
    Counterspell     = 2139,
    Evocation        = 12051,
    MageArmor        = 6117,
    
    -- Utility
    Polymorph        = 118,
    RemoveCurse      = 475,
    SlowFall         = 130,
    Blink            = 1953,
    FrostWard        = 6143,
    FireWard         = 543,
    DampenMagic      = 604,
    AmplifyMagic     = 1008,
    ManaGem          = 759,
  },
  
  Rank = {
    Fireball         = {133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151},
    Frostbolt        = {116, 205, 837, 7322, 7323, 7324, 10179, 10180, 10181},
    ArcaneMissiles   = {5143, 5144, 5145, 8416, 8417, 10211, 10212},
    Scorch           = {2948, 8444, 8445, 8446, 10205, 10206, 10207},
    FireBlast        = {2136, 2137, 2138, 8412, 8413, 10197, 10199},
    Flamestrike      = {2120, 2121, 8422, 8423, 10215, 10216},
    Pyroblast        = {11366, 12505, 12522, 12523, 12524, 12525, 12526},
    FrostNova        = {122, 865, 6131, 10230},
    Blizzard         = {10, 6141, 8427, 10185, 10186, 10187},
    ConeOfCold       = {120, 8492, 10159, 10160, 10161},
    ArcaneExplosion  = {1449, 8437, 8438, 8439, 10201, 10202},
    ArcaneIntellect  = {1459, 1460, 1461, 10156, 10157},
    FrostArmor       = {168, 7300, 7301},
    IceArmor         = {7302, 7320, 10219, 10220},
    MageArmor        = {6117, 22782, 22783},
    ManaShield       = {1463, 8494, 8495, 10191, 10192, 10193},
    Polymorph        = {118, 12824, 12825, 12826},
    AutoAttack       = {6603},
    Wand             = {5019},
  },
}

local function bestRank(list)
  if not list then return nil end
  for i = #list, 1, -1 do
    local id = list[i]
    if IsSpellKnown and IsSpellKnown(id) then
      return id
    end
  end
  return list[#list] or list[1]
end

function IDS:UpdateRanks()
  for key, list in pairs(self.Rank) do
    local id = bestRank(list)
    if id then self.Ability[key] = id end
  end
end

_G.TacoRot_IDS_Mage = IDS

_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end
setOnce(133,  "Interface\\Icons\\Spell_Fire_FlameBolt")
setOnce(116,  "Interface\\Icons\\Spell_Frost_FrostBolt02")
setOnce(5143, "Interface\\Icons\\Spell_Nature_StarFall")
setOnce(5019, "Interface\\Icons\\INV_Wand_01")
setOnce(6603, "Interface\\Icons\\Ability_MeleeDamage")
