-- fade nameplate frames based on current target
local addon = KuiNameplates
local kui = LibStub('Kui-1.0')
local mod = addon:NewPlugin('Fading')

local abs = math.abs
local UnitIsUnit = UnitIsUnit
local kff,kffr = kui.frameFade, kui.frameFadeRemoveFrame
local target_exists
local fade_rules

-- local functions #############################################################
local function ResetFrameFade(frame)
    kffr(frame)
    frame.fading_to = nil
end
local function FrameFade(frame,to)
    if frame.fading_to and to == frame.fading_to then return end

    ResetFrameFade(frame)

    local cur_alpha = frame:GetAlpha()
    if to == cur_alpha then return end

    local alpha_change = to - cur_alpha
    frame.fading_to = to

    kff(frame, {
        mode = alpha_change < 0 and 'OUT' or 'IN',
        timeToFade = abs(alpha_change) * .5,
        startAlpha = cur_alpha,
        endAlpha = to,
        finishedFunc = ResetFrameFade
    })
end
local function GetDesiredAlpha(frame)
    for i,f in pairs(fade_rules) do
        if f then
            local a = f(frame)
            if a then return a end
        end
    end

    return mod.faded_alpha
end
-- mod functions ###############################################################
function mod:UpdateAllFrames()
    -- update alpha of all visible frames
    for k,f in addon:Frames() do
        if f:IsVisible() then
            FrameFade(f,GetDesiredAlpha(f))
        end
    end
end
function mod:ResetFadeRules(no_msg)
    -- reset to default fade rules
    fade_rules = {
        function(f)
            return UnitIsUnit(f.unit,'player') and 1
        end,
        function()
            return not target_exists and 1
        end,
        function(f)
            return f.handler:IsTarget() and 1
        end
    }

    if not no_msg then
        -- let plugins re-add their own rules
        mod:DispatchMessage('FadeRulesReset')
    end
end
function mod:AddFadeRule(func)
    if type(func) ~= 'function' then return end
    tinsert(fade_rules,func)
    return #fade_rules
end
function mod:RemoveFadeRule(index)
    fade_rules[index] = nil
end
-- messages ####################################################################
function mod:TargetUpdate()
    target_exists = UnitExists('target')
    self:UpdateAllFrames()
end
function mod:Show(f)
    f:SetAlpha(0)
    FrameFade(f,GetDesiredAlpha(f))
end
function mod:Hide(f)
    ResetFrameFade(f)
end
-- register ####################################################################
function mod:OnEnable()
    self:RegisterEvent('PLAYER_TARGET_CHANGED','TargetUpdate')
    self:RegisterEvent('PLAYER_ENTERING_WORLD','TargetUpdate')
    self:RegisterMessage('GainedTarget','TargetUpdate')
    self:RegisterMessage('LostTarget','TargetUpdate')
    self:RegisterMessage('Show')
    self:RegisterMessage('Hide')
end
function mod:Initialise()
    self.faded_alpha = .5
    self:ResetFadeRules()
end
