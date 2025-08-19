-- druid_ids.lua — Enhanced Classic Anniversary Druid IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Enhanced Druid IDS loaded")

local IDS = {
  Ability = {
    -- Caster form spells
    Wrath = 5176,
    Starfire = 2912,
    Moonfire = 8921,
    Sunfire = 93402,  -- If available
    Insect_Swarm = 5570,
    Entangling_Roots = 339,
    Hurricane = 16914,
    
    -- Healing spells
    Healing_Touch = 5185,
    Rejuvenation = 774,
    Regrowth = 8936,
    Tranquility = 740,
    Innervate = 29166,
    
    -- Balance buffs
    Mark_of_the_Wild = 1126,
    Thorns = 467,
    Natures_Grace = 16880,
    
    -- Cat Form spells
    Cat_Form = 768,
    Prowl = 5215,
    Claw = 1082,
    Rake = 1822,
    Rip = 1079,
    Ferocious_Bite = 22568,
    Tigers_Fury = 5217,
    Dash = 1850,
    
    -- Bear Form spells
    Bear_Form = 5487,
    Dire_Bear_Form = 9634,
    Maul = 6807,
    Swipe = 779,
    Bash = 5211,
    Growl = 6795,
    Demoralizing_Roar = 99,
    
    -- Travel forms
    Travel_Form = 783,
    Aquatic_Form = 1066,
    Flight_Form = 33943,
    
    -- Utility
    Cure_Poison = 8946,
    Remove_Curse = 2782,
    Faerie_Fire = 770,
    Soothe_Animal = 2908,
    Hibernate = 2637,
    
    -- Generic
    AutoAttack = 6603,
    
    -- Set defaults
    Main = 5176,  -- Wrath
    Buff = 1126,  -- Mark of the Wild
  },
  Rank = {
    -- Wrath ranks
    Wrath = {5176, 5177, 5178, 5179, 5180, 6780, 8905, 9912, 9913, 26984, 26985},
    
    -- Starfire ranks
    Starfire = {2912, 8949, 8950, 8951, 9875, 9876, 25298},
    
    -- Moonfire ranks
    Moonfire = {8921, 8924, 8925, 8926, 8927, 8928, 8929, 9833, 9834, 9835, 26987, 26988},
    
    -- Insect Swarm ranks (if available)
    Insect_Swarm = {5570, 24974, 24975, 24976, 24977},
    
    -- Entangling Roots ranks
    Entangling_Roots = {339, 1062, 5195, 5196, 9852, 9853, 26989},
    
    -- Hurricane ranks
    Hurricane = {16914, 17401, 17402, 26983},
    
    -- Healing Touch ranks
    Healing_Touch = {5185, 5186, 5187, 5188, 5189, 6778, 8903, 9758, 9888, 9889, 25297, 26978, 26979},
    
    -- Rejuvenation ranks
    Rejuvenation = {774, 1058, 1430, 2090, 2091, 3627, 8910, 9839, 9840, 9841, 25299, 26981, 26982},
    
    -- Regrowth ranks
    Regrowth = {8936, 8938, 8939, 8940, 8941, 9750, 9856, 9857, 9858, 26980},
    
    -- Mark of the Wild ranks
    Mark_of_the_Wild = {1126, 5232, 6756, 5234, 8907, 9884, 9885, 26990},
    
    -- Thorns ranks
    Thorns = {467, 782, 1075, 8914, 9756, 9910, 26992},
    
    -- Cat Form abilities
    Cat_Form = {768},
    Prowl = {5215, 6783},
    Claw = {1082, 3029, 5201, 9849, 9850, 27000},
    Rake = {1822, 1823, 1824, 9904, 9905, 27003},
    Rip = {1079, 9492, 9493, 9752, 9894, 9896, 27008},
    Ferocious_Bite = {22568, 22827, 22828, 22829, 31018},
    Tigers_Fury = {5217, 6793, 9845, 9846},
    Dash = {1850, 9821},
    
    -- Bear Form abilities
    Bear_Form = {5487},
    Dire_Bear_Form = {9634},
    Maul = {6807, 6808, 6809, 8972, 9745, 9880, 9881, 26996},
    Swipe = {779, 780, 769, 9754, 9908, 26997}, 
    Bash = {5211, 6798, 8983},
    Growl = {6795},
    Demoralizing_Roar = {99, 1735, 9490, 9747, 9898, 26998},
    
    -- Travel forms
    Travel_Form = {783},
    Aquatic_Form = {1066},
    Flight_Form = {33943, 40120},
    
    -- Utility
    Cure_Poison = {8946},
    Remove_Curse = {2782},
    Faerie_Fire = {770, 778, 9749, 9907, 26993},
    Soothe_Animal = {2908, 8955, 9901},
    Hibernate = {2637, 18657, 18658},
    Tranquility = {740, 8918, 9862, 9863, 26983},
    Innervate = {29166},
    
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
  local balancePts = select(3, GetTalentTabInfo(1)) or 0
  local feralPts = select(3, GetTalentTabInfo(2)) or 0
  local restorationPts = select(3, GetTalentTabInfo(3)) or 0
  
  if balancePts >= feralPts and balancePts >= restorationPts then
    -- Balance spec priority - caster DPS
    if self.Ability.Starfire and IsSpellKnown(self.Ability.Starfire) then
      self.Ability.Main = self.Ability.Starfire  -- Higher damage than Wrath
    else
      self.Ability.Main = self.Ability.Wrath
    end
  elseif feralPts >= restorationPts then
    -- Feral spec priority - melee focus, but caster when not in form
    self.Ability.Main = self.Ability.Wrath  -- Default to caster when not in form
  else
    -- Restoration spec priority - healing focus, Wrath for damage
    self.Ability.Main = self.Ability.Wrath
  end
end

-- Check what form we're in
function IDS:GetCurrentForm()
  for i = 1, GetNumShapeshiftForms() do
    local _, _, active = GetShapeshiftFormInfo(i)
    if active then
      return i
    end
  end
  return 0  -- Caster form
end

function IDS:IsInCasterForm()
  return self:GetCurrentForm() == 0
end

function IDS:IsInCatForm()
  local form = self:GetCurrentForm()
  -- Cat form is typically form 1, but check for cat form buff to be sure
  return form > 0 and UnitBuff("player", GetSpellInfo(self.Ability.Cat_Form))
end

function IDS:IsInBearForm()
  local form = self:GetCurrentForm()
  -- Bear forms are typically 2-3, check for bear form buffs
  return form > 0 and (UnitBuff("player", GetSpellInfo(self.Ability.Bear_Form)) or 
                       UnitBuff("player", GetSpellInfo(self.Ability.Dire_Bear_Form)))
end

_G.TacoRot_IDS_Druid = IDS

-- Icon fallbacks
_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end

setOnce(5176,  "Interface\\Icons\\Spell_Nature_AbolishMagic")
setOnce(2912,  "Interface\\Icons\\Spell_Arcane_StarFire")
setOnce(8921,  "Interface\\Icons\\Spell_Nature_StarFall")
setOnce(5570,  "Interface\\Icons\\Spell_Nature_InsectSwarm")
setOnce(339,   "Interface\\Icons\\Spell_Nature_StrangleVines")
setOnce(5185,  "Interface\\Icons\\Spell_Nature_HealingTouch")
setOnce(774,   "Interface\\Icons\\Spell_Nature_Rejuvenation")
setOnce(8936,  "Interface\\Icons\\Spell_Nature_ResistNature")
setOnce(1126,  "Interface\\Icons\\Spell_Nature_Regeneration")
setOnce(467,   "Interface\\Icons\\Spell_Nature_Thorns")
setOnce(768,   "Interface\\Icons\\Ability_Druid_CatForm")
setOnce(5487,  "Interface\\Icons\\Ability_Racial_BearForm")
setOnce(9634,  "Interface\\Icons\\Ability_Racial_BearForm")
setOnce(1082,  "Interface\\Icons\\Ability_Druid_Rake")
setOnce(1822,  "Interface\\Icons\\Ability_Druid_Disembowel")
setOnce(1079,  "Interface\\Icons\\Ability_GhoulFrenzy")
setOnce(6807,  "Interface\\Icons\\Ability_Druid_Maul")
setOnce(779,   "Interface\\Icons\\INV_Misc_MonsterClaw_03")
setOnce(770,   "Interface\\Icons\\Spell_Nature_FaerieFire")
setOnce(6603,  "Interface\\Icons\\Ability_MeleeDamage")
