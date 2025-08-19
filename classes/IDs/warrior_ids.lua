-- warrior_ids.lua — Classic Anniversary Warrior IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Warrior IDS loaded")

local IDS = {
  Ability = {
    -- Basic Attacks
    HeroicStrike     = 78,
    Cleave           = 845,
    AutoAttack       = 6603,
    Shoot            = 3018,  -- For thrown/bow
    
    -- Arms Tree
    MortalStrike     = 12294,
    Rend             = 772,
    Overpower        = 7384,
    SweepingStrikes  = 12328,
    ThunderClap      = 6343,
    
    -- Fury Tree  
    Bloodthirst      = 23881,
    Whirlwind        = 1680,
    Rampage          = 29801,
    PiercingHowl     = 12323,
    BerserkerRage    = 18499,
    Recklessness     = 1719,
    DeathWish        = 12328,
    
    -- Protection
    ShieldBlock      = 2565,
    Revenge          = 6572,
    ShieldSlam       = 23922,
    SunderArmor      = 7386,
    ShieldWall       = 871,
    LastStand        = 12975,
    Disarm           = 676,
    ShieldBash       = 72,
    
    -- Shared Abilities
    Execute          = 5308,
    Hamstring        = 1715,
    Charge           = 100,
    Intercept        = 20252,
    Pummel           = 6552,
    VictoryRush      = 34428,
    Slam             = 1464,
    
    -- Shouts & Buffs
    BattleShout      = 6673,
    CommandingShout  = 469,
    DemoralizingShout= 1160,
    IntimidatingShout= 5246,
    
    -- Stances
    BattleStance     = 2457,
    DefensiveStance  = 71,
    BerserkerStance  = 2458,
  },
  
  Rank = {
    -- Basic Attacks
    HeroicStrike     = {78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286},
    Cleave           = {845, 7369, 11608, 11609, 20569},
    
    -- Arms
    MortalStrike     = {12294, 21551, 21552, 21553},
    Rend             = {772, 6546, 6547, 6548, 11572, 11573, 11574},
    Overpower        = {7384, 7887, 11584, 11585},
    ThunderClap      = {6343, 8198, 8204, 8205, 11580, 11581},
    
    -- Fury
    Bloodthirst      = {23881, 23892, 23893, 23894},
    Whirlwind        = {1680},
    Slam             = {1464, 8820, 11604, 11605},
    
    -- Protection
    Revenge          = {6572, 6574, 7379, 11600, 11601, 25288},
    ShieldSlam       = {23922, 23923, 23924, 23925},
    SunderArmor      = {7386, 7405, 8380, 11596, 11597},
    ShieldBlock      = {2565},
    ShieldBash       = {72, 1671, 1672},
    Disarm           = {676},
    
    -- Shared
    Execute          = {5308, 20658, 20660, 20661, 20662},
    Hamstring        = {1715, 7372, 7373},
    Charge           = {100, 6178, 11578},
    Intercept        = {20252, 20616, 20617},
    Pummel           = {6552, 6554},
    
    -- Shouts
    BattleShout      = {6673, 5242, 6192, 11549, 11550, 11551, 25289},
    CommandingShout  = {469, 47439, 47440},
    DemoralizingShout= {1160, 6190, 11554, 11555, 11556},
    
    -- Padding
    AutoAttack       = {6603},
    Shoot            = {3018},
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
setOnce(6603,  "Interface\\Icons\\Ability_MeleeDamage")
