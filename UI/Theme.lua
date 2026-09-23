local addonName, Buffadin = ...

Buffadin.Theme = {}

-- Status indicator colors
Buffadin.Theme.Colors = {
    Good     = { r = 0.12, g = 0.85, b = 0.20, a = 0.90 }, -- Green: All buffed
    Some     = { r = 0.95, g = 0.78, b = 0.15, a = 0.90 }, -- Yellow: Some unbuffed
    All      = { r = 0.95, g = 0.22, b = 0.22, a = 0.90 }, -- Red: All unbuffed
    Special  = { r = 0.20, g = 0.60, b = 1.00, a = 0.90 }, -- Blue: Custom single-target override
    Disabled = { r = 0.30, g = 0.30, b = 0.30, a = 0.60 },
    Gold     = { r = 0.90, g = 0.80, b = 0.50, a = 1.00 },
    TextMuted= { r = 0.70, g = 0.70, b = 0.70, a = 1.00 },
}

-- Return RGB for class token
function Buffadin.Theme:GetClassColor(classToken)
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
        local c = RAID_CLASS_COLORS[classToken]
        return c.r, c.g, c.b
    end
    return 0.8, 0.8, 0.8
end

-- Format remaining expiration time
function Buffadin.Theme:FormatTime(seconds)
    if not seconds or seconds <= 0 then
        return ""
    end
    if seconds >= 60 then
        local m = math.floor(seconds / 60)
        return string.format("%dm", m)
    else
        return string.format("%ds", math.floor(seconds))
    end
end

-- Style a window using Blizzard's native modern ButtonFrameTemplate or Backdrop
function Buffadin.Theme:StyleWindow(frame, titleText, portraitTexture)
    if not frame then return end

    portraitTexture = portraitTexture or "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings"

    -- Set title text if modern ButtonFrameTemplate structure exists
    if frame.TitleText then
        frame.TitleText:SetText(titleText or "Buffadin")
        if frame.TitleText.SetFontObject then
            frame.TitleText:SetFontObject(GameFontHighlightMedium or GameFontNormal)
        end
    end

    -- Dark circular backing behind the portrait so the circle is never see-through
    if not frame.portraitBg then
        local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -4)
        bg:SetSize(60, 60)
        bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -6, 7)
        bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
        bg:SetVertexColor(0.06, 0.08, 0.12, 1)
        frame.portraitBg = bg
    end

    local function ApplyPortraitIcon(texObj)
        if not texObj then return end
        texObj:SetTexture(portraitTexture)
        -- Use full texture coordinates (0 to 1) so the icon is NOT zoomed in
        texObj:SetTexCoord(0, 1, 0, 1)
        texObj:Show()

        -- In modern WoW, apply circular alpha mask to clip corners smoothly without zooming
        if texObj.AddMaskTexture and not texObj.buffadinMask then
            local mask = frame:CreateMaskTexture(nil, "OVERLAY")
            mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(texObj)
            texObj:AddMaskTexture(mask)
            texObj.buffadinMask = mask
        end
    end

    -- Modern retail PortraitContainer
    if frame.PortraitContainer and frame.PortraitContainer.portrait then
        ApplyPortraitIcon(frame.PortraitContainer.portrait)
    end

    -- Legacy frame.portrait
    if frame.portrait then
        ApplyPortraitIcon(frame.portrait)
    end

    -- Fallback: create explicit portrait icon if neither template container exists
    if not frame.portrait and not (frame.PortraitContainer and frame.PortraitContainer.portrait) and not frame.customPortrait then
        local pIcon = frame:CreateTexture(nil, "ARTWORK", nil, 1)
        pIcon:SetSize(42, 42)
        pIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
        ApplyPortraitIcon(pIcon)
        frame.customPortrait = pIcon
    end

    -- Window movement
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetClampedToScreen(true)
end

-- Style standard buttons with modern retail textures and font
function Buffadin.Theme:StyleButton(button, text)
    if not button then return end
    if text then
        button:SetText(text)
    end
    local fontString = button:GetFontString()
    if fontString then
        fontString:SetFontObject(GameFontNormalSmall or GameFontNormal)
    end
end

-- Apply backdrop styling to custom sub-panels or bar buttons
function Buffadin.Theme:ApplyCardBackdrop(frame, bgAlpha, borderAlpha)
    if not frame or not frame.SetBackdrop then return end

    bgAlpha = bgAlpha or 0.85
    borderAlpha = borderAlpha or 0.70

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropColor(0.08, 0.10, 0.14, bgAlpha)
    frame:SetBackdropBorderColor(0.25, 0.28, 0.35, borderAlpha)
end

-- Apply status color to a frame border
function Buffadin.Theme:SetBorderStatus(frame, statusType)
    if not frame or not frame.SetBackdropBorderColor then return end

    local color = self.Colors[statusType] or self.Colors.Disabled
    frame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
end
