local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"

local ModWarningScreen = Class(Screen, function(self, title, text, buttons, texthalign, additionaltext, textsize)
	Screen._ctor(self, "ModWarningScreen")

	--darken everything behind the dialog
	self.black = self:AddChild(Image("images/global/square.tex"))
		:SetName("Background")
    	:SetSize(RES_X, RES_Y)
		:SetMultColor(UICOLORS.BACKGROUND_DARK)
		:SetMultColorAlpha(0.8)

	self.root = self:AddChild(Widget("ROOT"))

	--title
    self.title = self.root:AddChild(Text(FONTFACE.TITLE, FONTSIZE.DIALOG_TITLE))
    	:SetPosition(0, 170)
    	:SetText(title)

	--text
	local defaulttextsize = textsize or FONTSIZE.DIALOG_TEXT

    self.text = self.root:AddChild(Text(FONTFACE.BODYTEXT, defaulttextsize))
		:SetVAlign(ANCHOR_TOP)

	if texthalign then
		self.text:SetHAlign(texthalign)
	end


    self.text
		:SetPosition(0, 40, 0)
    	:SetText(text)
    	:EnableWordWrap(true)
    	:SetRegionSize(480*2, 200)

    if additionaltext then
	    self.additionaltext = self.root:AddChild(Text(FONTFACE.BODYTEXT, 50))
			:SetVAlign(ANCHOR_TOP)
	    	:SetPosition(0, -150, 0)
	    	:SetText(additionaltext)
	    	:EnableWordWrap(true)
	    	:SetRegionSize(480*2, 100)
    end

	self.version = self:AddChild(Text(FONTFACE.BODYTEXT, 50))
	--self.version:SetHRegPoint(ANCHOR_LEFT)
	--self.version:SetVRegPoint(ANCHOR_BOTTOM)
	self.version:SetAnchors("left", "center")
		:SetVAlign(ANCHOR_BOTTOM)
		:SetRegionSize(200, 40)
		:SetPosition(110, 30, 0)
		:SetText("Rev. "..APP_VERSION.." "..PLATFORM)

	if buttons then
	    --create the menu itself
	    local button_w = 200
	    local space_between = 20
	    local spacing = button_w + space_between

	    self.menu = self.root:AddChild(Menu(buttons, 250, true))
	    self.menu:SetHRegPoint(ANCHOR_MIDDLE)
	    self.menu:SetPosition(0, -250, 0)
	    self.default_focus = self.menu
	end

	if Platform.IsRail() then
		-- disable the mod forum button if it exists
		if self.menu and self.menu.items then
			for i,v in pairs(self.menu.items) do
				if v:GetText() == STRINGS.UI.MAINSCREEN.MODFORUMS then
					v:Select()
					v:SetToolTip(STRINGS.UI.MAINSCREEN.MODFORUMS_NOT_AVAILABLE_YET)
				end
			end
		end
	end
end)

return ModWarningScreen
