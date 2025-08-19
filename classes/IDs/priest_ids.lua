-- priest_ids.lua — Enhanced Classic Anniversary Priest IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Enhanced Priest IDS loaded")

local IDS = {
  Ability = {
    -- Main damage spells
    Smite = 585,
    HolyFire = 14914,
    MindBlast = 8092,
    ShadowWordPain = 589,
    MindFlay = 15407,
    
    -- Shadow spells
    ShadowWordDeath = 32379,
    VampiricTouch = 34914,
    Devouring_Plague = 2944,
    
    -- Buffs and healing
    PowerWordFortitude = 1243,
    DivineSpirit = 14752,
    InnerFire = 588,
    InnerFocus = 14751,
    Renew = 139,
    Heal = 2054,
    FlashHeal = 2061,
    GreaterHeal = 2060,
    
    -- Utility
    PowerWordShield = 17,
    DispelMagic = 527,
    Wand = 5019,
    AutoAttack = 6603,
    
    -- Forms
    ShadowForm = 15473,
    
    -- Set defaults for rotation
    Main = 585,  -- Smite
    Buff = 1243, -- Power Word: Fortitude
  },
  Rank = {
    -- Smite ranks
    Smite = {585, 591, 598, 984, 1004, 6060, 10933, 10934},
    
    -- Holy Fire ranks  
    HolyFire = {14914, 15262, 15263, 15264, 15265, 15266, 15267, 15261},
    
    -- Mind Blast ranks
    MindBlast = {8092, 8102, 8103, 8104, 8105, 8106, 10945, 10946, 10947},
    
    -- Shadow Word: Pain ranks
    ShadowWordPain = {589, 594, 970, 992, 2767, 10892, 10893, 10894},
    
    -- Mind Flay ranks
    MindFlay = {15407, 17311, 17312, 17313, 17314, 18807},
    
    -- Power Word: Fortitude ranks
    PowerWordFortitude = {1243, 1244, 1245, 2791, 10937, 10938},
    
    -- Divine Spirit ranks
    DivineSpirit = {14752, 14818, 14819, 27841, 25312},
    
    -- Inner Fire ranks
    InnerFire = {588, 7128, 602, 1006, 10951, 10952},
    
    -- Renew ranks
    Renew = {139, 6074, 6075, 6076, 6077, 6078, 10927, 10928, 10929},
    
    -- Heal ranks
    Heal = {2054, 2055, 6063, 6064},
    
    -- Flash Heal ranks
    FlashHeal = {2061, 9472, 9473, 9474, 10915, 10916, 10917},
    
    -- Greater Heal ranks
    GreaterHeal = {2060, 10963, 10964, 10965, 25314, 25210, 25213},
    
    -- Power Word: Shield ranks
    PowerWordShield = {17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901},
    
    -- Dispel Magic ranks
    DispelMagic = {527, 988},
    
    -- Devouring Plague ranks (Undead racial)
    Devouring_Plague = {2944, 19276, 19277, 19278, 19279, 19280, 25467},
    
    -- Utility
    Wand = {5019},
    AutoAttack = {6603},
    ShadowForm = {15473},
    InnerFocus = {14751},
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
  local shadowPts = select(3, GetTalentTabInfo(3)) or 0
  local disciplinePts = select(3, GetTalentTabInfo(1)) or 0
  local holyPts = select(3, GetTalentTabInfo(2)) or 0
  
  if shadowPts >= disciplinePts and shadowPts >= holyPts then
    -- Shadow spec priority
    if self.Ability.MindFlay and IsSpellKnown(self.Ability.MindFlay) then
      self.Ability.Main = self.Ability.MindFlay
    elseif self.Ability.MindBlast and IsSpellKnown(self.Ability.MindBlast) then
      self.Ability.Main = self.Ability.MindBlast  
    else
      self.Ability.Main = self.Ability.Smite
    end
  else
    -- Holy/Discipline spec priority
    if self.Ability.HolyFire and IsSpellKnown(self.Ability.HolyFire) then
      self.Ability.Main = self.Ability.HolyFire
    elseif self.Ability.Smite and IsSpellKnown(self.Ability.Smite) then
      self.Ability.Main = self.Ability.Smite
    end
  end
end

_G.TacoRot_IDS_Priest = IDS

-- Icon fallbacks for spells without icons
_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end

-- Set fallback icons
setOnce(585,   "Interface\\Icons\\Spell_Holy_HolyBolt")
setOnce(14914, "Interface\\Icons\\Spell_Holy_SearingLight")
setOnce(8092,  "Interface\\Icons\\Spell_Shadow_UnholyFrenzy")
setOnce(589,   "Interface\\Icons\\Spell_Shadow_ShadowWordPain")
setOnce(15407, "Interface\\Icons\\Spell_Shadow_SiphonMana")
setOnce(1243,  "Interface\\Icons\\Spell_Holy_WordFortitude")
setOnce(14752, "Interface\\Icons\\Spell_Holy_DivineSpirit")
setOnce(588,   "Interface\\Icons\\Spell_Holy_InnerFire")
setOnce(139,   "Interface\\Icons\\Spell_Holy_Renew")
setOnce(17,    "Interface\\Icons\\Spell_Holy_PowerWordShield")
setOnce(15473, "Interface\\Icons\\Spell_Shadow_Shadowform")
setOnce(5019,  "Interface\\Icons\\INV_Wand_01")
setOnce(6603,  "Interface\\Icons\\Ability_MeleeDamage")
