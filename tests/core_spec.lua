local function setupEnvironment()
  -- Minimal LibStub stub to allow loading core.lua
  _G.LibStub = function(lib)
    if lib == "AceAddon-3.0" then
      return {
        NewAddon = function(_, ...)
          local addon = {}
          function addon:UnregisterEvent(...) end
          function addon:SendMessage(...) end
          return addon
        end,
      }
    end
    return {}
  end
  -- Load core.lua to populate _G.TacoRot
  dofile("core.lua")
  return _G.TacoRot
end

describe("HandleWorldEnter", function()
  local TR

  before_each(function()
    TR = setupEnvironment()
  end)

  after_each(function()
    _G.TacoRot = nil
    _G.UnitClass = nil
    _G.LibStub = nil
    TR = nil
  end)

  it("starts warrior engine on world enter", function()
    _G.UnitClass = function() return nil, "WARRIOR" end
    local called = 0
    function TR:StartEngine_Warrior()
      called = called + 1
    end
    TR:HandleWorldEnter()
    assert.are.equal(1, called)
  end)

  it("starts hunter engine on world enter", function()
    _G.UnitClass = function() return nil, "HUNTER" end
    local called = 0
    function TR:StartEngine_Hunter()
      called = called + 1
    end
    TR:HandleWorldEnter()
    assert.are.equal(1, called)
  end)
end)
