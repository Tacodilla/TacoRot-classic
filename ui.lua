local TR = _G.TacoRot
if not TR then return end

local UI = {}
TR.UI = UI

-- Helper to fetch texture with fallback
local function iconTexture(id)
  if not id then return nil end
  local tex = GetSpellTexture and GetSpellTexture(id)
  if tex then return tex end
  if _G.TacoRotIconFallbacks then
    return _G.TacoRotIconFallbacks[id]
  end
  return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function UI:Init()
  self.frames = {}
  local anchor = TR.db and TR.db.profile and TR.db.profile.anchor or {"CENTER", UIParent, "CENTER", 0, 0}

  -- Main icon
  local f1 = CreateFrame("Frame", "TacoRotWindow", UIParent)
  f1:SetMovable(true)
  f1:EnableMouse(true)
  f1:RegisterForDrag("LeftButton")
  f1:SetScript("OnDragStart", function(frm) frm:StartMoving() end)
  f1:SetScript("OnDragStop", function(frm)
    frm:StopMovingOrSizing()
    TR.db.profile.anchor = {frm:GetPoint(1)}
  end)
  f1.texture = f1:CreateTexture(nil, "ARTWORK")
  f1.texture:SetAllPoints()
  self.f1 = f1

  -- Next icons
  local f2 = CreateFrame("Frame", "TacoRotWindow2", f1)
  f2.texture = f2:CreateTexture(nil, "ARTWORK")
  f2.texture:SetAllPoints()
  self.f2 = f2

  local f3 = CreateFrame("Frame", "TacoRotWindow3", f1)
  f3.texture = f3:CreateTexture(nil, "ARTWORK")
  f3.texture:SetAllPoints()
  self.f3 = f3

  self.frames = {f1, f2, f3}

  -- Flash texture
  local flash = f1:CreateTexture(nil, "OVERLAY")
  flash:SetAllPoints()
  flash:SetTexture("Interface\\Cooldown\\star4")
  flash:SetBlendMode("ADD")
  flash:Hide()
  self.flash = flash

  self:ApplySettings()
  TR:UpdateLock()
  TR:UpdateVisibility()
end

function UI:ApplySettings()
  if not TR.db or not self.f1 then return end
  local size = TR.db.profile.iconSize or 52
  local nextScale = TR.db.profile.nextScale or 0.82
  local anchor = TR.db.profile.anchor or {"CENTER", UIParent, "CENTER", 0, 0}

  self.f1:SetSize(size, size)
  self.f1:ClearAllPoints()
  self.f1:SetPoint(unpack(anchor))

  self.f2:SetSize(size * nextScale, size * nextScale)
  self.f2:ClearAllPoints()
  self.f2:SetPoint("LEFT", self.f1, "RIGHT", 4, 0)

  self.f3:SetSize(size * nextScale, size * nextScale)
  self.f3:ClearAllPoints()
  self.f3:SetPoint("LEFT", self.f2, "RIGHT", 4, 0)
end

function UI:Update(main, next1, next2)
  if not self.f1 then return end
  self.f1.texture:SetTexture(iconTexture(main))
  self.f2.texture:SetTexture(iconTexture(next1))
  self.f3.texture:SetTexture(iconTexture(next2))
end

function TR:SetMainCastFlash(show)
  local flash = self.UI and self.UI.flash
  if not flash then return end
  if show then flash:Show() else flash:Hide() end
end

