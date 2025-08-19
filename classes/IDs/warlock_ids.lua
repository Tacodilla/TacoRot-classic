-- warlock_ids.lua — Enhanced Classic Anniversary Warlock IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Enhanced Warlock IDS loaded")

local IDS = {
  Ability = {
    -- Main damage spells
    ShadowBolt = 686,
    Immolate = 348,
    Corruption = 172,
    CurseOfAgony = 980,
    CurseOfElements = 1490,
    CurseOfDoom = 603,
    SearingPain = 5676,
    
    -- Affliction spells
    DrainSoul = 1120,
    DrainLife = 689,
    DrainMana = 5138,
    Haunt = 48181,
    SiphonSoul = 17877,
    UnstableAffliction = 30108,
    
    -- Destruction spells
    Incinerate = 29722,
    Conflagrate = 17962,
    SoulFire = 6353,
    Shadowburn = 17877,
    
    -- Demonology spells
    ShadowCleave = 50796,
    
    -- Buffs and utility
    DemonArmor = 687,
    DemonSkin = 687,
    FelArmor = 28176,
    LifeTap = 1454,
    DarkRitual = 7328,
    
    -- Summons
    SummonImp = 688,
    SummonVoidwalker = 697,
    SummonSuccubus = 712,
    SummonFelhunter = 691,
    
    -- Fear and CC
    Fear = 5782,
    Banish = 710,
    
    -- Utility
    HealthFunnel = 755,
    Wand = 5019,
    AutoAttack = 6603,
    
    -- Set defaults
    Main = 686,  -- Shadow Bolt
    Buff = 687,  -- Demon Skin/Armor
  },
  Rank = {
    -- Shadow Bolt ranks
    ShadowBolt = {686, 695, 705, 1088, 1106, 7641, 11659, 11660, 11661, 25307},
    
    -- Immolate ranks
    Immolate = {348, 707, 1094, 2941, 11665, 11667, 11668, 25309},
    
    -- Corruption ranks  
    Corruption = {172, 6222, 6223, 7648, 11671, 11672, 25311},
    
    -- Curse of Agony ranks
    CurseOfAgony = {980, 1014, 6217, 11711, 11712, 11713},
    
    -- Curse of Elements ranks
    CurseOfElements = {1490, 11721, 11722, 27228},
    
    -- Searing Pain ranks
    SearingPain = {5676, 17919, 17920, 17921, 17922, 17923},
    
    -- Drain Soul ranks
    DrainSoul = {1120, 8288, 8289, 11675},
    
    -- Drain Life ranks
    DrainLife = {689, 699, 709, 7651, 11699, 11700},
    
    -- Life Tap ranks
    LifeTap = {1454, 1455, 1456, 11687, 11688, 11689},
    
    -- Demon Armor/Skin ranks
    DemonArmor = {687, 696, 706, 1086, 11733, 11734, 11735},
    DemonSkin = {687, 696},
    
    -- Fear ranks
    Fear = {5782, 6213, 6215},
    
    -- Summon ranks
    SummonImp = {688},
    SummonVoidwalker = {697}, 
    SummonSuccubus = {712},
    SummonFelhunter = {691},
    
    -- Health Funnel ranks
    HealthFunnel = {755, 3698, 3699, 3700, 11693, 11694, 11695},
    
    -- Utility
    Wand = {5019},
    AutoAttack = {6603},
    Banish = {710},
    
    -- TBC+ spells (if available)
    Incinerate = {29722, 32231},
    Conflagrate = {17962, 18930, 18931, 18932},
    SoulFire = {6353, 17924, 27211, 30545},
    UnstableAffliction = {30108, 30404, 30405},
    FelArmor = {28176, 28189},
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
  local afflictionPts = select(3, GetTalentTabInfo(1)) or 0
  local demonologyPts = select(3, GetTalentTabInfo(2)) or 0
  local destructionPts = select(3, GetTalentTabInfo(3)) or 0
  
  if afflictionPts >= demonologyPts and afflictionPts >= destructionPts then
    -- Affliction spec priority - prefer DoTs and drains
    if self.Ability.Corruption and IsSpellKnown(self.Ability.Corruption) then
      self.Ability.Main = self.Ability.Corruption
    else
      self.Ability.Main = self.Ability.ShadowBolt
    end
  elseif destructionPts >= demonologyPts then
    -- Destruction spec priority - prefer direct damage
    if self.Ability.Incinerate and IsSpellKnown(self.Ability.Incinerate) then
      self.Ability.Main = self.Ability.Incinerate
    elseif self.Ability.Immolate and IsSpellKnown(self.Ability.Immolate) then
      self.Ability.Main = self.Ability.Immolate
    else
      self.Ability.Main = self.Ability.ShadowBolt
    end
  else
    -- Demonology spec priority - shadow bolt focus
    self.Ability.Main = self.Ability.ShadowBolt
  end
  
  -- Update armor buff
  if self.Ability.FelArmor and IsSpellKnown(self.Ability.FelArmor) then
    self.Ability.Buff = self.Ability.FelArmor
  else
    self.Ability.Buff = self.Ability.DemonArmor
  end
end

_G.TacoRot_IDS_Warlock = IDS

-- Icon fallbacks
_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end

setOnce(686,   "Interface\\Icons\\Spell_Shadow_ShadowBolt")
setOnce(348,   "Interface\\Icons\\Spell_Fire_Immolation")
setOnce(172,   "Interface\\Icons\\Spell_Shadow_AbominationExplosion")
setOnce(980,   "Interface\\Icons\\Spell_Shadow_CurseOfMannoroth")
setOnce(1490,  "Interface\\Icons\\Spell_Shadow_ChillTouch")
setOnce(5676,  "Interface\\Icons\\Spell_Fire_SoulBurn")
setOnce(1120,  "Interface\\Icons\\Spell_Shadow_Haunting")
setOnce(689,   "Interface\\Icons\\Spell_Shadow_LifeDrain02")
setOnce(687,   "Interface\\Icons\\Spell_Shadow_RagingScream")
setOnce(1454,  "Interface\\Icons\\Spell_Shadow_BurningSpirit")
setOnce(688,   "Interface\\Icons\\Spell_Shadow_SummonImp")
setOnce(5782,  "Interface\\Icons\\Spell_Shadow_Possession")
setOnce(5019,  "Interface\\Icons\\INV_Wand_01")
setOnce(6603,  "Interface\\Icons\\Ability_MeleeDamage")
