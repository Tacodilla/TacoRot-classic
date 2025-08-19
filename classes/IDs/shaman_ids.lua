-- shaman_ids.lua — Enhanced Classic Anniversary Shaman IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Enhanced Shaman IDS loaded")

local IDS = {
  Ability = {
    -- Lightning spells
    LightningBolt = 403,
    ChainLightning = 421,
    LightningShield = 324,
    
    -- Shock spells
    EarthShock = 8042,
    FlameShock = 8050,
    FrostShock = 8056,
    
    -- Totems
    SearingTotem = 3599,
    MagmaTotem = 8190,
    StrengthOfEarthTotem = 8075,
    StoneskinTotem = 8071,
    HealingStreamTotem = 5394,
    ManaSpringTotem = 5675,
    WindfuryTotem = 8512,
    GraceOfAirTotem = 8835,
    TremorTotem = 8143,
    GroundingTotem = 8177,
    
    -- Enhancement melee
    Stormstrike = 17364,
    WindfuryWeapon = 8232,
    FlametongueWeapon = 8024,
    FrostbrandWeapon = 8033,
    RockbiterWeapon = 8017,
    
    -- Healing
    HealingWave = 331,
    LesserHealingWave = 8004,
    ChainHeal = 1064,
    
    -- Utility
    GhostWolf = 2645,
    WaterWalking = 546,
    WaterBreathing = 131,
    AstralRecall = 556,
    Purge = 370,
    CureDisease = 2870,
    CurePoison = 526,
    
    -- Weapon imbues
    RockbiterWeapon = 8017,
    FlametongueWeapon = 8024,
    FrostbrandWeapon = 8033,
    WindfuryWeapon = 8232,
    
    -- Generic
    AutoAttack = 6603,
    
    -- Set defaults
    Main = 403,  -- Lightning Bolt
    Buff = 324,  -- Lightning Shield
  },
  Rank = {
    -- Lightning Bolt ranks
    LightningBolt = {403, 529, 548, 915, 943, 6041, 10391, 10392, 15207, 15208, 25448, 25449},
    
    -- Chain Lightning ranks
    ChainLightning = {421, 930, 2860, 10605, 25439, 25442},
    
    -- Lightning Shield ranks
    LightningShield = {324, 325, 905, 945, 8134, 10431, 10432},
    
    -- Earth Shock ranks
    EarthShock = {8042, 8044, 8045, 8046, 10412, 10413, 10414, 25454},
    
    -- Flame Shock ranks
    FlameShock = {8050, 8052, 8053, 10447, 10448, 29228},
    
    -- Frost Shock ranks
    FrostShock = {8056, 8058, 10472, 10473},
    
    -- Searing Totem ranks
    SearingTotem = {3599, 6363, 6364, 6365, 10437, 10438},
    
    -- Magma Totem ranks
    MagmaTotem = {8190, 10585, 10586, 10587},
    
    -- Strength of Earth Totem ranks
    StrengthOfEarthTotem = {8075, 8160, 8161, 10442, 25361},
    
    -- Stoneskin Totem ranks
    StoneskinTotem = {8071, 8154, 8155, 10406, 10407, 10408},
    
    -- Healing Stream Totem ranks
    HealingStreamTotem = {5394, 6375, 6377, 10462, 10463, 25567},
    
    -- Mana Spring Totem ranks
    ManaSpringTotem = {5675, 10495, 10496, 10497, 25570},
    
    -- Windfury Totem ranks
    WindfuryTotem = {8512, 10613, 10614},
    
    -- Grace of Air Totem ranks
    GraceOfAirTotem = {8835, 10627, 25359},
    
    -- Healing Wave ranks
    HealingWave = {331, 332, 547, 913, 939, 959, 8005, 10395, 10396, 25357, 25391},
    
    -- Lesser Healing Wave ranks
    LesserHealingWave = {8004, 8008, 8010, 10466, 10467, 10468, 25420},
    
    -- Chain Heal ranks
    ChainHeal = {1064, 10622, 10623, 25422, 25423},
    
    -- Weapon imbue ranks
    RockbiterWeapon = {8017, 8018, 8019, 10399, 16314, 16315, 16316, 25479, 25485},
    FlametongueWeapon = {8024, 8027, 8030, 16339, 16341, 16342, 25489},
    FrostbrandWeapon = {8033, 8038, 10456, 16355, 16356, 25500},
    WindfuryWeapon = {8232, 8235, 10486, 16362, 25505},
    
    -- Utility
    GhostWolf = {2645},
    WaterWalking = {546},
    WaterBreathing = {131},
    AstralRecall = {556},
    Purge = {370, 8012},
    CureDisease = {2870},
    CurePoison = {526},
    TremorTotem = {8143},
    GroundingTotem = {8177},
    
    -- Enhancement
    Stormstrike = {17364, 17365},
    
    AutoAttack = {6603},
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
  
  -- Update main abilities based on spec detection
  self:UpdateMainAbilities()
end

function IDS:UpdateMainAbilities()
  -- Detect primary spec based on talents
  local elementalPts = select(3, GetTalentTabInfo(1)) or 0
  local enhancementPts = select(3, GetTalentTabInfo(2)) or 0
  local restorationPts = select(3, GetTalentTabInfo(3)) or 0
  
  if elementalPts >= enhancementPts and elementalPts >= restorationPts then
    -- Elemental spec priority - caster DPS
    if self.Ability.ChainLightning and IsSpellKnown(self.Ability.ChainLightning) then
      self.Ability.Main = self.Ability.ChainLightning  -- Better for AoE
    else
      self.Ability.Main = self.Ability.LightningBolt
    end
  elseif enhancementPts >= restorationPts then
    -- Enhancement spec priority - melee focus, but still cast at range
    if self.Ability.Stormstrike and IsSpellKnown(self.Ability.Stormstrike) then
      self.Ability.Main = self.Ability.Stormstrike
    else
      self.Ability.Main = self.Ability.LightningBolt  -- Still cast when not in melee
    end
  else
    -- Restoration spec priority - healing focus, Lightning Bolt for damage
    self.Ability.Main = self.Ability.LightningBolt
  end
end

_G.TacoRot_IDS_Shaman = IDS

-- Icon fallbacks
_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end

setOnce(403,   "Interface\\Icons\\Spell_Nature_Lightning")
setOnce(421,   "Interface\\Icons\\Spell_Nature_ChainLightning")
setOnce(324,   "Interface\\Icons\\Spell_Nature_LightningShield")
setOnce(8042,  "Interface\\Icons\\Spell_Nature_EarthShock")
setOnce(8050,  "Interface\\Icons\\Spell_Fire_FlameShock")
setOnce(8056,  "Interface\\Icons\\Spell_Frost_FrostShock02")
setOnce(3599,  "Interface\\Icons\\Spell_Fire_SearingTotem")
setOnce(8075,  "Interface\\Icons\\Spell_Nature_EarthElemental_Totem")
setOnce(5394,  "Interface\\Icons\\INV_Spear_04")
setOnce(5675,  "Interface\\Icons\\Spell_Nature_ManaRegenTotem")
setOnce(8512,  "Interface\\Icons\\Spell_Nature_Windfury")
setOnce(331,   "Interface\\Icons\\Spell_Nature_MagicImmunity")
setOnce(8004,  "Interface\\Icons\\Spell_Nature_HealingWaveGreater")
setOnce(1064,  "Interface\\Icons\\Spell_Nature_HealingWaveGreater")
setOnce(8017,  "Interface\\Icons\\Spell_Nature_RockBiter")
setOnce(8024,  "Interface\\Icons\\Spell_Fire_FlameTounge")
setOnce(8033,  "Interface\\Icons\\Spell_Frost_FrostBrand")
setOnce(8232,  "Interface\\Icons\\Spell_Nature_Cyclone")
setOnce(17364, "Interface\\Icons\\Ability_Shaman_StormStrike")
setOnce(2645,  "Interface\\Icons\\Spell_Nature_SpiritWolf")
setOnce(6603,  "Interface\\Icons\\Ability_MeleeDamage")
