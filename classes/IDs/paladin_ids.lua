-- paladin_ids.lua — Enhanced Classic Anniversary Paladin IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Enhanced Paladin IDS loaded")

local IDS = {
  Ability = {
    -- Seals and Judgements
    Judgement = 20271,
    SealOfRighteousness = 21084,
    SealOfTheCrusader = 21082,
    SealOfCommand = 20375,
    SealOfWisdom = 20166,
    SealOfLight = 20165,
    SealOfJustice = 20164,
    
    -- Holy spells
    HolyLight = 635,
    FlashOfLight = 19750,
    HolyWrath = 2812,
    Consecration = 26573,
    Exorcism = 879,
    HammerOfWrath = 24275,
    
    -- Protection spells
    HolyShield = 20925,
    BlessedRecovery = 20924,
    Taunt = 62124,  -- Righteous Fury
    
    -- Retribution spells
    SealOfCommand = 20375,
    Retribution = 7294,
    
    -- Blessings
    BlessingOfMight = 19740,
    BlessingOfWisdom = 19742,
    BlessingOfKings = 20217,
    BlessingOfSalvation = 1038,
    BlessingOfSanctuary = 20911,
    BlessingOfFreedom = 1044,
    BlessingOfProtection = 1022,
    
    -- Auras
    DevotionAura = 465,
    RetributionAura = 7294,
    ConcentrationAura = 19746,
    ShadowResistanceAura = 19876,
    FrostResistanceAura = 19888,
    FireResistanceAura = 19891,
    SanctityAura = 20218,
    
    -- Utility
    Cleanse = 4987,
    TurnUndead = 2878,
    SenseUndead = 5502,
    Purify = 1152,
    LayOnHands = 633,
    DivineProtection = 498,
    DivineShield = 642,
    Hammer = 853,  -- Hammer of Justice
    
    -- Generic
    AutoAttack = 6603,
    
    -- Set defaults
    Main = 20271,  -- Judgement
    Buff = 19740,  -- Blessing of Might
  },
  Rank = {
    -- Judgement (no ranks, but different seals change its effect)
    Judgement = {20271},
    
    -- Seals
    SealOfRighteousness = {21084, 20287, 20288, 20289, 20290, 20291, 20292, 20293},
    SealOfTheCrusader = {21082, 20162, 20305, 20306, 20307, 20308},
    SealOfCommand = {20375, 20424, 20915, 20918, 20919, 20920},
    SealOfWisdom = {20166, 20356, 20357},
    SealOfLight = {20165, 20347, 20348, 20349},
    SealOfJustice = {20164},
    
    -- Holy Light ranks
    HolyLight = {635, 639, 647, 1026, 1042, 3472, 10328, 10329, 25292, 27135},
    
    -- Flash of Light ranks
    FlashOfLight = {19750, 19939, 19940, 19941, 19942, 19943, 27137},
    
    -- Holy Wrath ranks
    HolyWrath = {2812, 10318, 27139},
    
    -- Consecration ranks
    Consecration = {26573, 20116, 20922, 20923, 20924, 27173},
    
    -- Exorcism ranks
    Exorcism = {879, 5614, 5615, 10312, 10313, 10314, 27138},
    
    -- Hammer of Wrath ranks
    HammerOfWrath = {24275, 24274, 24239, 27180},
    
    -- Blessings - Might
    BlessingOfMight = {19740, 19834, 19835, 19836, 19837, 19838, 25291, 27140},
    
    -- Blessings - Wisdom
    BlessingOfWisdom = {19742, 19850, 19852, 19853, 19854, 25290, 27142},
    
    -- Blessings - Other
    BlessingOfKings = {20217},
    BlessingOfSalvation = {1038, 1038},
    BlessingOfSanctuary = {20911, 20912, 20913, 20914, 27168},
    BlessingOfFreedom = {1044},
    BlessingOfProtection = {1022, 5599, 10278},
    
    -- Auras
    DevotionAura = {465, 10290, 643, 10291, 1032, 10292, 10293, 27149},
    RetributionAura = {7294, 10298, 10299, 10300, 10301, 27150},
    ConcentrationAura = {19746, 19752, 19896, 19897, 19898, 27151},
    ShadowResistanceAura = {19876, 19895, 19896, 19897, 19898, 27152},
    FrostResistanceAura = {19888, 19897, 19898, 19899, 19900, 27153},
    FireResistanceAura = {19891, 19899, 19900, 19901, 19902, 27154},
    SanctityAura = {20218, 20359, 20360, 20361, 27155},
    
    -- Utility
    Cleanse = {4987},
    TurnUndead = {2878, 5627},
    SenseUndead = {5502},
    Purify = {1152, 5614},
    LayOnHands = {633, 2800, 10310, 27154},
    DivineProtection = {498, 5573},
    DivineShield = {642, 1020},
    Hammer = {853, 5588, 5589, 10308},
    
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
  local holyPts = select(3, GetTalentTabInfo(1)) or 0
  local protectionPts = select(3, GetTalentTabInfo(2)) or 0
  local retributionPts = select(3, GetTalentTabInfo(3)) or 0
  
  if retributionPts >= holyPts and retributionPts >= protectionPts then
    -- Retribution spec priority - DPS focus
    if self.Ability.SealOfCommand and IsSpellKnown(self.Ability.SealOfCommand) then
      self.Ability.Main = self.Ability.SealOfCommand  -- Seal before judging
    elseif self.Ability.SealOfRighteousness and IsSpellKnown(self.Ability.SealOfRighteousness) then
      self.Ability.Main = self.Ability.SealOfRighteousness
    else
      self.Ability.Main = self.Ability.Judgement
    end
    self.Ability.Buff = self.Ability.BlessingOfMight
  elseif protectionPts >= holyPts then
    -- Protection spec priority - tank focus
    if self.Ability.SealOfRighteousness and IsSpellKnown(self.Ability.SealOfRighteousness) then
      self.Ability.Main = self.Ability.SealOfRighteousness
    else
      self.Ability.Main = self.Ability.Judgement
    end
    self.Ability.Buff = self.Ability.BlessingOfSanctuary
  else
    -- Holy spec priority - healing focus, but still needs seals for DPS
    if self.Ability.SealOfRighteousness and IsSpellKnown(self.Ability.SealOfRighteousness) then
      self.Ability.Main = self.Ability.SealOfRighteousness
    else
      self.Ability.Main = self.Ability.Judgement
    end
    self.Ability.Buff = self.Ability.BlessingOfWisdom
  end
end

_G.TacoRot_IDS_Paladin = IDS

-- Icon fallbacks
_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end

setOnce(20271, "Interface\\Icons\\Spell_Holy_RighteousFury")
setOnce(21084, "Interface\\Icons\\Ability_ThunderBolt")
setOnce(21082, "Interface\\Icons\\Spell_Holy_HolyBolt")
setOnce(20375, "Interface\\Icons\\Ability_Warrior_InnerRage")
setOnce(20166, "Interface\\Icons\\Spell_Holy_RighteousnessAura")
setOnce(20165, "Interface\\Icons\\Spell_Holy_HealingAura")
setOnce(635,   "Interface\\Icons\\Spell_Holy_HolyBolt")
setOnce(19750, "Interface\\Icons\\Spell_Holy_FlashHeal")
setOnce(2812,  "Interface\\Icons\\Spell_Holy_Excorcism")
setOnce(26573, "Interface\\Icons\\Spell_Holy_InnerFire")
setOnce(879,   "Interface\\Icons\\Spell_Holy_Excorcism_02")
setOnce(19740, "Interface\\Icons\\Spell_Holy_FistOfJustice")
setOnce(19742, "Interface\\Icons\\Spell_Holy_SealOfWisdom")
setOnce(20217, "Interface\\Icons\\Spell_Magic_MageArmor")
setOnce(465,   "Interface\\Icons\\Spell_Holy_DevotionAura")
setOnce(7294,  "Interface\\Icons\\Spell_Holy_AuraOfLight")
setOnce(4987,  "Interface\\Icons\\Spell_Holy_Renew")
setOnce(633,   "Interface\\Icons\\Spell_Holy_LayOnHands")
setOnce(642,   "Interface\\Icons\\Spell_Holy_DivineProtection")
setOnce(853,   "Interface\\Icons\\Spell_Holy_SealOfMight")
setOnce(6603,  "Interface\\Icons\\Ability_MeleeDamage")
