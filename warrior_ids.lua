-- warrior_ids.lua — Classic Anniversary Warrior IDs
local IDS = {
  Ability = {
    -- Basic
    HeroicStrike     = 78,
    Cleave           = 845,
    
    -- Arms
    MortalStrike     = 12294,
    Rend             = 772,
    Overpower        = 7384,
    Sweeping Strikes = 12328,
    
    -- Fury  
    Bloodthirst      = 23881,
    Whirlwind        = 1680,
    Rampage          = 29801,
    
    -- Shared
    Execute          = 5308,
    Hamstring        = 1715,
    Charge           = 100,
    Intercept        = 20252,
    BerserkerRage    = 18499,
    
    -- Defensive
    ShieldBlock      = 2565,
    Revenge          = 6572,
    ShieldSlam       = 23922,
    SunderArmor      = 7386,
    
    -- Buffs
    BattleShout      = 6673,
    BerserkerStance  = 2458,
    BattleStance     = 2457,
    DefensiveStance  = 71,
  },
  Rank = {
    HeroicStrike     = {78, 284, 285, 1608, 11564, 11565, 11566, 11567},
    Cleave           = {845, 7369, 11608, 11609, 20569},
    MortalStrike     = {12294, 21551, 21552, 21553},
    Rend             = {772, 6546, 6547, 6548, 11572, 11573, 11574},
    Overpower        = {7384, 7887, 11584, 11585},
    SweepingStrikes  = {12328},
    Bloodthirst      = {23881, 23892, 23893, 23894},
    Whirlwind        = {1680},
    Rampage          = {29801},
    Execute          = {5308, 20658, 20660, 20661, 20662},
    Hamstring        = {1715, 7372, 7373},
    Charge           = {100, 6178, 11578},
    Intercept        = {20252, 20616, 20617},
    BerserkerRage    = {18499},
    ShieldBlock      = {2565},
    Revenge          = {6572, 6574, 7379, 11600, 11601},
    ShieldSlam       = {23922, 23923, 23924, 23925},
    SunderArmor      = {7386, 7405, 8380, 11596, 11597},
    BattleShout      = {6673, 5242, 6192, 11549, 11550, 11551},
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

_G.TacoRot_IDS_Warrior = IDS

-- Icon fallbacks
_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end

setOnce(78,    "Interface\\Icons\\Ability_Rogue_Ambush")
setOnce(845,   "Interface\\Icons\\Ability_Warrior_Cleave")
setOnce(12294, "Interface\\Icons\\Ability_Warrior_SavageBlow")
setOnce(772,   "Interface\\Icons\\Ability_Gouge")
setOnce(7384,  "Interface\\Icons\\Ability_MeleeDamage")
setOnce(12328, "Interface\\Icons\\Ability_Rogue_SliceDice")
setOnce(23881, "Interface\\Icons\\Spell_Nature_BloodLust")
setOnce(1680,  "Interface\\Icons\\Ability_Whirlwind")
setOnce(5308,  "Interface\\Icons\\INV_Sword_48")
setOnce(1715,  "Interface\\Icons\\Ability_ShockWave")
setOnce(100,   "Interface\\Icons\\Ability_Warrior_Charge")
setOnce(20252, "Interface\\Icons\\Ability_Rogue_Sprint")
setOnce(18499, "Interface\\Icons\\Spell_Nature_AncestralGuardian")
setOnce(6673,  "Interface\\Icons\\Ability_Warrior_BattleShout")
setOnce(2458,  "Interface\\Icons\\Ability_Racial_Avatar")
setOnce(2457,  "Interface\\Icons\\Ability_Warrior_OffensiveStance")
setOnce(71,    "Interface\\Icons\\Ability_Warrior_DefensiveStance")