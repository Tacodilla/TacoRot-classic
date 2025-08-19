-- rogue_ids.lua — Classic Anniversary Rogue IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Rogue IDS loaded")

local IDS = {
  Ability = {
    -- Basic
    SinisterStrike   = 1752,
    Eviscerate       = 2098,
    SliceAndDice     = 5171,
    AutoAttack       = 6603,
    Throw            = 2764,
    
    -- Stealth & Openers
    Stealth          = 1784,
    CheapShot        = 1833,
    Garrote          = 703,
    Ambush           = 8676,
    Sap              = 6770,
    Vanish           = 1856,
    
    -- Combat
    BladeFlurry      = 13877,
    AdrenalineRush   = 13750,
    Backstab         = 53,
    Gouge            = 1776,
    Kick             = 1766,
    Riposte          = 14251,
    
    -- Assassination
    ColdBlood        = 14177,
    Mutilate         = 1329,
    Rupture          = 1943,
    ExposeArmor      = 8647,
    Hemorrhage       = 16511,
    
    -- Subtlety
    Ghostly          = 14278,
    Shadowstep       = 36554,
    Preparation      = 14185,
    Premeditation    = 14183,
    
    -- Poisons & Utility
    InstantPoison    = 8679,
    DeadlyPoison     = 2823,
    CripplingPoison  = 3408,
    WoundPoison      = 8685,
    MindNumbingPoison= 5761,
    Sprint           = 2983,
    Evasion          = 5277,
    KidneyShot       = 408,
    Blind            = 2094,
    Distract         = 1725,
    PickPocket       = 921,
    PickLock         = 1804,
  },
  
  Rank = {
    SinisterStrike   = {1752, 1757, 1758, 1759, 1760, 8621, 11293, 11294},
    Eviscerate       = {2098, 6760, 6761, 6762, 8623, 8624, 11299, 11300},
    SliceAndDice     = {5171, 6774},
    Backstab         = {53, 2589, 2590, 2591, 8721, 11279, 11280, 11281},
    Ambush           = {8676, 8724, 8725, 11267, 11268, 11269},
    Rupture          = {1943, 8639, 8640, 11273, 11274, 11275},
    Garrote          = {703, 8631, 8632, 8633, 11289, 11290},
    ExposeArmor      = {8647, 8649, 8650, 11197, 11198},
    KidneyShot       = {408, 8643},
    Gouge            = {1776, 1777, 8629, 11285, 11286},
    CheapShot        = {1833},
    Hemorrhage       = {16511},
    Sprint           = {2983, 8696, 11305},
    Kick             = {1766, 1767, 1768, 1769},
    Stealth          = {1784, 1785, 1786, 1787},
    Vanish           = {1856, 1857, 26889},
    Evasion          = {5277, 26669},
    Sap              = {6770, 2070, 11297},
    AutoAttack       = {6603},
    Throw            = {2764},
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

_G.TacoRot_IDS_Rogue = IDS

-- Icon fallbacks
_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end

setOnce(1752, "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice")
setOnce(2098, "Interface\\Icons\\Ability_Rogue_Eviscerate")
setOnce(5171, "Interface\\Icons\\Ability_Rogue_SliceDice")
setOnce(6603, "Interface\\Icons\\Ability_MeleeDamage")
setOnce(53,   "Interface\\Icons\\Ability_BackStab")
setOnce(1784, "Interface\\Icons\\Ability_Stealth")
