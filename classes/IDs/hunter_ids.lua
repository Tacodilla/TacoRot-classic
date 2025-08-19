-- hunter_ids.lua — Classic Anniversary Hunter IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Hunter IDS loaded")

local IDS = {
  Ability = {
    -- Shots
    AutoShot         = 75,
    AimedShot        = 19434,
    ArcaneShot       = 3044,
    MultiShot        = 2643,
    SerpentSting     = 1978,
    ScorpidSting     = 3043,
    ViperSting       = 3034,
    ConcussiveShot   = 5116,
    ScatterShot      = 19503,
    TranquilizingShot= 19801,
    
    -- Melee
    RaptorStrike     = 2973,
    MongooseBite     = 1495,
    WingClip         = 2974,
    Counterattack    = 19306,
    AutoAttack       = 6603,
    
    -- Traps
    FreezingTrap     = 1499,
    FrostTrap        = 13809,
    ExplosiveTrap    = 13813,
    ImmolationTrap   = 13795,
    
    -- Aspects
    AspectOfTheHawk  = 13165,
    AspectOfTheMonkey= 13163,
    AspectOfTheCheetah= 5118,
    AspectOfThePack  = 13159,
    AspectOfTheWild  = 20043,
    AspectOfTheBeast = 13161,
    
    -- Pet
    CallPet          = 883,
    RevivePet        = 982,
    MendPet          = 136,
    FeedPet          = 6991,
    DismissPet       = 2641,
    TameBeast        = 1515,
    BeastLore        = 1462,
    EyesOfTheBeast   = 1002,
    BestialWrath     = 19574,
    Intimidation     = 19577,
    
    -- Buffs
    HuntersMark      = 1130,
    TrueshotAura     = 19506,
    RapidFire        = 3045,
    
    -- Utility
    FeignDeath       = 5384,
    Disengage        = 781,
    Deterrence       = 19263,
    TrackBeasts      = 1494,
    TrackHumanoids   = 19883,
    TrackUndead      = 19884,
    TrackHidden      = 19885,
    TrackElementals  = 19880,
    TrackDemons      = 19878,
    TrackGiants      = 19882,
    TrackDragonkin   = 19879,
    Flare            = 1543,
    Volley           = 1510,
  },
  
  Rank = {
    AutoShot         = {75},
    AimedShot        = {19434, 20900, 20901, 20902, 20903, 20904},
    ArcaneShot       = {3044, 14281, 14282, 14283, 14284, 14285, 14286, 14287},
    MultiShot        = {2643, 14288, 14289, 14290},
    SerpentSting     = {1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555},
    ScorpidSting     = {3043},
    ViperSting       = {3034, 14279, 14280},
    ConcussiveShot   = {5116},
    RaptorStrike     = {2973, 14260, 14261, 14262, 14263, 14264, 14265, 14266},
    MongooseBite     = {1495, 14269, 14270, 14271},
    WingClip         = {2974, 14267, 14268},
    FreezingTrap     = {1499, 14310, 14311},
    FrostTrap        = {13809},
    ExplosiveTrap    = {13813, 14316, 14317},
    ImmolationTrap   = {13795, 14302, 14303, 14304, 14305},
    AspectOfTheHawk  = {13165, 14318, 14319, 14320, 14321, 14322},
    AspectOfTheMonkey= {13163},
    AspectOfTheCheetah= {5118},
    CallPet          = {883},
    RevivePet        = {982},
    MendPet          = {136, 3111, 3661, 3662, 13542, 13543, 13544},
    HuntersMark      = {1130, 14323, 14324, 14325},
    TrueshotAura     = {19506, 20905, 20906},
    RapidFire        = {3045},
    FeignDeath       = {5384},
    Disengage        = {781, 14272, 14273},
    Volley           = {1510, 14294, 14295},
    AutoAttack       = {6603},
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

_G.TacoRot_IDS_Hunter = IDS

_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end
setOnce(75,    "Interface\\Icons\\INV_Weapon_Bow_07")
setOnce(19434, "Interface\\Icons\\INV_Spear_07")
setOnce(3044,  "Interface\\Icons\\Ability_ImpalingBolt")
setOnce(1978,  "Interface\\Icons\\Ability_Hunter_Quickshot")
setOnce(2973,  "Interface\\Icons\\Ability_MeleeDamage")
setOnce(1130,  "Interface\\Icons\\Ability_Hunter_SniperShot")
setOnce(6603,  "Interface\\Icons\\Ability_MeleeDamage")
