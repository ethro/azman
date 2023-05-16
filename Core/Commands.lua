local azman, E, L, V, P, G = unpack(select(2, ...))
local AB = E:GetModule('ActionBars')
local LCS = E.Libs.LCS

local next, pairs, strlower, wipe = next, pairs, strlower, wipe

local C_SpecializationInfo_GetPvpTalentSlotInfo = E.Retail and C_SpecializationInfo.GetPvpTalentSlotInfo
local GetNumSpecializationsForClassID = (not E.Retail and LCS.GetNumSpecializationsForClassID) or GetNumSpecializationsForClassID
local GetSpecializationInfoForClassID = (not E.Retail and LCS.GetSpecializationInfoForClassID) or GetSpecializationInfoForClassID
local GetClassInfo = GetClassInfo
local IsAddOnLoaded = IsAddOnLoaded


-- Register all commands
function azman:load_commands()
	self:RegisterChatCommand('azgen', 'generate_macros')
	self:RegisterChatCommand('azrst', 'reset_user_specific_macros')
	self:RegisterChatCommand('azcvars', 'get_cvars')
	self:RegisterChatCommand('azset', 'set_me_up')
end

local _blank_macro_icon = 134400
local nomod = 2
local ctrl = 3
local shift = 4
local alt = 5
local mod_map = {}
mod_map[nomod] = 'nomod'
mod_map[ctrl] = 'ctrl'
mod_map[shift] = 'shift'
mod_map[alt] = 'alt'

function azman:set_me_up()
   azman:setup_details()
   azman:setup_plater()
   azman:setup_warpdeplete()
   azman:setup_elvui()
   ReloadUI()
end

function azman:get_cvars()
   az_cvars['cvars'] = C_Console.GetAllCommands()
   az_cvars['plater_azman_00'] = PlaterDB['profiles']['azman_00']
   az_cvars['warpdeplete_azman_00'] = WarpDepleteDB["profiles"]['azman_00']
   az_cvars['elvui_db'] = E.db
end

function azman:generate_macros()
   local _action_bar_contents = azman:scan_action_bars()
   local _className, _classNameUpper, _classIndex = UnitClass("player")
   local _num_specs = GetNumSpecializationsForClassID(_classIndex)
	for _button = 1, 12 do
	   _button_entry = _action_bar_contents['button_'.._button]

      _alt_txt   = ""
      _shift_txt = ""
      _ctrl_txt  = ""
      _nomod_txt = ""
	   if _button_entry then
	      if _button_entry['alt'] then
	         _alt_txt = _alt_txt.."[mod:alt]".._button_entry['alt']..";"
	      end
	      if _button_entry['shift'] then
	         _shift_txt = _shift_txt.."[mod:shift]".._button_entry['shift']..";"
	      end
	      if _button_entry['ctrl'] then
	         _ctrl_txt = _ctrl_txt.."[mod:ctrl]".._button_entry['ctrl']..";"
	      end
	      if _button_entry['nomod'] then
	         _nomod_txt = _nomod_txt.._button_entry['nomod']
	      end
	   end
	   _macro_text = "#showtooltip\n/use ".._alt_txt.._shift_txt.._ctrl_txt.._nomod_txt
	   _button_entry['macro_text'] = _macro_text
      macro_id = EditMacro(120 + _button, nil, _blank_macro_icon, _macro_text)
	end
end

function azman:scan_action_bars()
   local _action_bar_contents = {}
	for barName, bar in pairs(AB.handledBars) do
		if bar and (bar.id == nomod or bar.id == ctrl or bar.id == shift or bar.id == alt) then
		   for _button_idx, _button in pairs(bar.buttons) do
		      _button_key = 'button_'.._button_idx
		      _mod_key = mod_map[bar.id]
		      if not _action_bar_contents[_button_key] then
		         _action_bar_contents[_button_key] = {}
		      end
	         if _button._state_type == "action" then
		         local action_type, action_id, action_subtype = GetActionInfo(_button._state_action)
		         if action_type == "spell" then
		            local abilityName = GetSpellInfo(action_id)
                  _action_bar_contents[_button_key][_mod_key] = abilityName
		         elseif action_type == "item" then
		            local itemInfo = GetItemInfo(action_id)
                  _action_bar_contents[_button_key][_mod_key] = itemInfo
		         elseif action_type == "summonmount" then
		            local mount_name = C_MountJournal.GetMountInfoByID(action_id)
                  _action_bar_contents[_button_key][_mod_key] = mount_name
               -- else
               --    print(action_type, action_id, action_subtype)
		         end
		      end
		   end
      end
	end
	return _action_bar_contents
end

-- TODO: Need to be able to put the user specific macros back onto ActionBar 1
-- after deleting them...
function azman:reset_user_specific_macros()
	-- Start at the end, and move backward to first position (121).
   for i = 120 + select(2,GetNumMacros()), 121, -1 do
	   local _name, _icon, _body = GetMacroInfo(i)
	   if _name then
	      DeleteMacro(i)
	   end
   end
	for _button = 1, 12 do
	   local _macro_name = string.format("N_%02d",_button)
	   local _name, _icon, _body = GetMacroInfo(120+_button)
	   if not _name then
         macro_id = CreateMacro(_macro_name, _blank_macro_icon, "/train", true)
	   end
	end
   azman:generate_macros()
end

local function on_player_spec_changed()
   azman:generate_macros()
end

-- Plater profile
function azman:setup_plater()
	if not IsAddOnLoaded('Plater') then return end

	-- Profile name
	local name = "azman_00"

	-- Profile creation
	PlaterDB["profiles"][name] = PlaterDB["profiles"][name] or {}

	-- Profile data
	if E.Retail then
		PlaterDB["profiles"][name] = {
		["script_data"] = {
			{
				["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --settings\n    envTable.NameplateSizeOffset = scriptTable.config.castBarHeight\n    envTable.ShowArrow = scriptTable.config.showArrow\n    envTable.ArrowAlpha = scriptTable.config.arrowAlpha\n    envTable.HealthBarColor = scriptTable.config.healthBarColor\n    \n    --creates the spark to show the cast progress inside the health bar\n    envTable.overlaySpark = envTable.overlaySpark or Plater:CreateImage (unitFrame.healthBar)\n    envTable.overlaySpark:SetBlendMode (\"ADD\")\n    envTable.overlaySpark.width = 16\n    envTable.overlaySpark.height = 36\n    envTable.overlaySpark.alpha = .9\n    envTable.overlaySpark.texture = [[Interface\\AddOns\\Plater\\images\\spark3]]\n    \n    envTable.topArrow = envTable.topArrow or Plater:CreateImage (unitFrame.healthBar)\n    envTable.topArrow:SetBlendMode (\"ADD\")\n    envTable.topArrow.width = scriptTable.config.arrowWidth\n    envTable.topArrow.height = scriptTable.config.arrowHeight\n    envTable.topArrow.alpha = envTable.ArrowAlpha\n    envTable.topArrow.texture = [[Interface\\BUTTONS\\Arrow-Down-Up]]\n    \n    --scale animation\n    envTable.smallScaleAnimation = envTable.smallScaleAnimation or Plater:CreateAnimationHub (unitFrame.healthBar)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 1, 0.075, 1, 1, 1.08, 1.08)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 2, 0.075, 1, 1, 0.95, 0.95)    \n    --envTable.smallScaleAnimation:Play() --envTable.smallScaleAnimation:Stop()\n    \nend\n\n\n\n\n\n\n\n",
				["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    \n    envTable.overlaySpark:Hide()\n    envTable.topArrow:Hide()\n    \n    Plater.RefreshNameplateColor (unitFrame)\n    \n    envTable.smallScaleAnimation:Stop()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)\nend\n\n\n",
				["OptionsValues"] = {
				},
				["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.overlaySpark:Show()\n    \n    if (envTable.ShowArrow) then\n        envTable.topArrow:Show()\n    end\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    envTable.smallScaleAnimation:Play()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    envTable.overlaySpark.height = nameplateHeight + 5\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    self:SetStatusBarColor (Plater:ParseColors (scriptTable.config.castBarColor))\nend\n\n\n\n\n\n\n",
				["ScriptType"] = 2,
				["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --update the percent\n    envTable.overlaySpark:SetPoint (\"left\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100)-9, 0)\n    \n    envTable.topArrow:SetPoint (\"bottomleft\", unitFrame.healthBar, \"topleft\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100) - 4, 2 )\n    \n    --forces the script to update on a 60Hz base\n    self.ThrottleUpdate = 0\n    \n\nend\n\n\n",
				["Time"] = 1661180262,
				["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --settings\n    envTable.NameplateSizeOffset = scriptTable.config.castBarHeight\n    envTable.ShowArrow = scriptTable.config.showArrow\n    envTable.ArrowAlpha = scriptTable.config.arrowAlpha\n    envTable.HealthBarColor = scriptTable.config.healthBarColor\n    \n    --creates the spark to show the cast progress inside the health bar\n    envTable.overlaySpark = envTable.overlaySpark or Plater:CreateImage (unitFrame.healthBar)\n    envTable.overlaySpark:SetBlendMode (\"ADD\")\n    envTable.overlaySpark.width = 16\n    envTable.overlaySpark.height = 36\n    envTable.overlaySpark.alpha = .9\n    envTable.overlaySpark.texture = [[Interface\\AddOns\\Plater\\images\\spark3]]\n    \n    envTable.topArrow = envTable.topArrow or Plater:CreateImage (unitFrame.healthBar)\n    envTable.topArrow:SetBlendMode (\"ADD\")\n    envTable.topArrow.width = scriptTable.config.arrowWidth\n    envTable.topArrow.height = scriptTable.config.arrowHeight\n    envTable.topArrow.alpha = envTable.ArrowAlpha\n    envTable.topArrow.texture = [[Interface\\BUTTONS\\Arrow-Down-Up]]\n    \n    --scale animation\n    envTable.smallScaleAnimation = envTable.smallScaleAnimation or Plater:CreateAnimationHub (unitFrame.healthBar)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 1, 0.075, 1, 1, 1.08, 1.08)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 2, 0.075, 1, 1, 0.95, 0.95)    \n    --envTable.smallScaleAnimation:Play() --envTable.smallScaleAnimation:Stop()\n    \nend\n\n\n\n\n\n\n\n",
				["url"] = "",
				["Icon"] = 2175503,
				["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    \n    envTable.overlaySpark:Hide()\n    envTable.topArrow:Hide()\n    \n    Plater.RefreshNameplateColor (unitFrame)\n    \n    envTable.smallScaleAnimation:Stop()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)\nend\n\n\n",
				["Enabled"] = true,
				["Revision"] = 470,
				["semver"] = "",
				["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
				["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --update the percent\n    envTable.overlaySpark:SetPoint (\"left\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100)-9, 0)\n    \n    envTable.topArrow:SetPoint (\"bottomleft\", unitFrame.healthBar, \"topleft\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100) - 4, 2 )\n    \n    --forces the script to update on a 60Hz base\n    self.ThrottleUpdate = 0\n    \n\nend\n\n\n",
				["Author"] = "Bombad�o-Azralon",
				["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
				["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.overlaySpark:Show()\n    \n    if (envTable.ShowArrow) then\n        envTable.topArrow:Show()\n    end\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    envTable.smallScaleAnimation:Play()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    envTable.overlaySpark.height = nameplateHeight + 5\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    self:SetStatusBarColor (Plater:ParseColors (scriptTable.config.castBarColor))\nend\n\n\n\n\n\n\n",
				["SpellIds"] = {
					240446, -- [1]
				},
				["Prio"] = 99,
				["Name"] = "Explosion Affix M+ [Plater]",
				["PlaterCore"] = 1,
				["version"] = -1,
				["Desc"] = "Explosive Affix Script",
				["Options"] = {
					{
						["Type"] = 6,
						["Name"] = "Option 1",
						["Value"] = 0,
						["Key"] = "option1",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
						["Desc"] = "",
					}, -- [1]
					{
						["Type"] = 5,
						["Name"] = "Option 2",
						["Value"] = "Plays a special animation showing the explosion time.",
						["Key"] = "option2",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
						["Desc"] = "",
					}, -- [2]
					{
						["Type"] = 6,
						["Name"] = "Option 3",
						["Value"] = 0,
						["Key"] = "option3",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
						["Desc"] = "",
					}, -- [3]
					{
						["Type"] = 2,
						["Max"] = 6,
						["Desc"] = "Increases the cast bar height by this value",
						["Min"] = 0,
						["Fraction"] = false,
						["Value"] = 3,
						["Key"] = "castBarHeight",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
						["Name"] = "Cast Bar Height Mod",
					}, -- [4]
					{
						["Type"] = 1,
						["Name"] = "Cast Bar Color",
						["Value"] = {
							1, -- [1]
							0.5843137254902, -- [2]
							0, -- [3]
							1, -- [4]
						},
						["Key"] = "castBarColor",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
						["Desc"] = "Changes the cast bar color to this one.",
					}, -- [5]
					{
						["Type"] = 6,
						["Name"] = "Option 7",
						["Value"] = 0,
						["Key"] = "option7",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
						["Desc"] = "",
					}, -- [6]
					{
						["Type"] = 5,
						["Name"] = "Arrow:",
						["Value"] = "Arrow:",
						["Key"] = "option6",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
						["Desc"] = "",
					}, -- [7]
					{
						["Type"] = 4,
						["Name"] = "Show Arrow",
						["Value"] = true,
						["Key"] = "showArrow",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
						["Desc"] = "Show an arrow above the nameplate showing the cast bar progress.",
					}, -- [8]
					{
						["Type"] = 2,
						["Max"] = 1,
						["Desc"] = "Arrow alpha.",
						["Min"] = 0,
						["Fraction"] = true,
						["Value"] = 0.5,
						["Key"] = "arrowAlpha",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
						["Name"] = "Arrow Alpha",
					}, -- [9]
					{
						["Type"] = 2,
						["Max"] = 12,
						["Desc"] = "Arrow Width.",
						["Min"] = 4,
						["Fraction"] = false,
						["Value"] = 8,
						["Key"] = "arrowWidth",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
						["Name"] = "Arrow Width",
					}, -- [10]
					{
						["Type"] = 2,
						["Max"] = 12,
						["Desc"] = "Arrow Height.",
						["Min"] = 4,
						["Fraction"] = false,
						["Value"] = 8,
						["Key"] = "arrowHeight",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
						["Name"] = "Arrow Height",
					}, -- [11]
					{
						["Type"] = 6,
						["Name"] = "Option 13",
						["Value"] = 0,
						["Key"] = "option13",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
						["Desc"] = "",
					}, -- [12]
					{
						["Type"] = 5,
						["Name"] = "Dot Animation:",
						["Value"] = "Dot Animation:",
						["Key"] = "option12",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
						["Desc"] = "",
					}, -- [13]
					{
						["Type"] = 1,
						["Name"] = "Dot Color",
						["Value"] = {
							1, -- [1]
							0.6156862745098, -- [2]
							0, -- [3]
							1, -- [4]
						},
						["Key"] = "dotColor",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
						["Desc"] = "Adjust the color of the dot animation.",
					}, -- [14]
					{
						["Type"] = 2,
						["Max"] = 10,
						["Desc"] = "Dot X Offset",
						["Min"] = -10,
						["Fraction"] = false,
						["Value"] = 4,
						["Key"] = "xOffset",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
						["Name"] = "Dot X Offset",
					}, -- [15]
					{
						["Type"] = 2,
						["Max"] = 10,
						["Desc"] = "Dot Y Offset",
						["Min"] = -10,
						["Fraction"] = false,
						["Value"] = 3,
						["Key"] = "yOffset",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
						["Name"] = "Dot Y Offset",
					}, -- [16]
				},
				["NpcNames"] = {
				},
			}, -- [1]
			{
				["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
				["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    local unitPowerBar = unitFrame.powerBar\n    unitPowerBar:Hide()\nend\n\n\n",
				["ScriptType"] = 1,
				["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE) then\n        return \n    end\n    \n    local continuationToken\n    local slots\n    local foundAura = false\n    \n    repeat    \n        slots = { UnitAuraSlots(unitId, \"HELPFUL\", BUFF_MAX_DISPLAY, continuationToken) }\n        continuationToken = slots[1]\n        numSlots = #slots\n        \n        for i = 2, numSlots do\n            local slot = slots[i]\n            local name, texture, count, actualAuraType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, auraAmount = UnitAuraBySlot(unitId, slot) \n            \n            if (spellId == envTable._SpellID) then --need to get the trigger spellId\n                --Ablative Shield\n                local unitPowerBar = unitFrame.powerBar\n                if (not unitPowerBar:IsShown()) then\n                    unitPowerBar:SetUnit(unitId)\n                end\n                \n                foundAura = true\n                return\n            end\n        end\n        \n    until continuationToken == nil\n    \n    if (not foundAura) then\n        local unitPowerBar = unitFrame.powerBar\n        if (unitPowerBar:IsShown()) then\n            unitPowerBar:Hide()\n        end\n    end\nend",
				["Time"] = 1660259323,
				["url"] = "",
				["Icon"] = 610472,
				["Enabled"] = true,
				["Revision"] = 52,
				["semver"] = "",
				["Author"] = "Keyspell-Azralon",
				["Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
				["Desc"] = "Show power bar where its value is the buff value (usualy shown in the buff tooltip)",
				["NpcNames"] = {
				},
				["SpellIds"] = {
					227548, -- [1]
				},
				["PlaterCore"] = 1,
				["Name"] = "Aura is Shield [P]",
				["version"] = -1,
				["Options"] = {
				},
				["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
			}, -- [2]
			{
				["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
				["OnHideCode"] = "		function (self, unitId, unitFrame, envTable, scriptTable)\n			--insert code here\n			\n		end\n	",
				["ScriptType"] = 1,
				["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (UnitIsUnit(unitId .. \"target\", \"player\")) then\n        Plater.SetNameplateColor(unitFrame, scriptTable.config.nameplateColor)\n    else\n        Plater.RefreshNameplateColor(unitFrame)\n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n",
				["Time"] = 1660340256,
				["url"] = "",
				["Icon"] = "Interface\\ICONS\\Ability_Fixated_State_Red",
				["Enabled"] = true,
				["Revision"] = 25,
				["semver"] = "",
				["Author"] = "Ditador-Azralon",
				["Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
				["Desc"] = "Alert about a unit fixated on the player by using a buff on the enemy unit.",
				["NpcNames"] = {
				},
				["SpellIds"] = {
					285388, -- [1]
				},
				["PlaterCore"] = 1,
				["Name"] = "Fixate by Unit Buff [P]",
				["version"] = -1,
				["Options"] = {
					{
						["Type"] = 1,
						["Name"] = "Nameplate Color",
						["Value"] = {
							0, -- [1]
							0.5568627450980392, -- [2]
							0.03529411764705882, -- [3]
							1, -- [4]
						},
						["Key"] = "nameplateColor",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
						["Desc"] = "Change the enemy nameplate color to this color when fixating you!",
					}, -- [1]
				},
				["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
			}, -- [3]
			{
				["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local castBar = unitFrame.castBar\n    local castBarPortion = castBar:GetWidth()/scriptTable.config.segmentsAmount\n    local castBarHeight = castBar:GetHeight()\n    \n    unitFrame.felAnimation = unitFrame.felAnimation or {}\n    \n    if (not unitFrame.felAnimation.textureStretched) then\n        unitFrame.felAnimation.textureStretched = castBar:CreateTexture(nil, \"overlay\", nil, 5)\n    end\n    \n    if (not unitFrame.felAnimation.Textures) then\n        unitFrame.felAnimation.Textures = {}\n        \n        for i = 1, scriptTable.config.segmentsAmount do\n            local texture = castBar:CreateTexture(nil, \"overlay\", nil, 6)\n            unitFrame.felAnimation.Textures[i] = texture            \n            \n            texture.animGroup = texture.animGroup or texture:CreateAnimationGroup()\n            local animationGroup = texture.animGroup\n            animationGroup:SetToFinalAlpha(true)            \n            animationGroup:SetLooping(\"NONE\")\n            \n            texture:SetTexture([[Interface\\COMMON\\XPBarAnim]])\n            texture:SetTexCoord(0.2990, 0.0010, 0.0010, 0.4159)\n            texture:SetBlendMode(\"ADD\")\n            \n            texture.scale = animationGroup:CreateAnimation(\"SCALE\")\n            texture.scale:SetTarget(texture)\n            \n            texture.alpha = animationGroup:CreateAnimation(\"ALPHA\")\n            texture.alpha:SetTarget(texture)\n            \n            texture.alpha2 = animationGroup:CreateAnimation(\"ALPHA\")\n            texture.alpha2:SetTarget(texture)\n        end\n    end\n    \n    \n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
				["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    for i = 1, scriptTable.config.segmentsAmount  do\n        local texture = unitFrame.felAnimation.Textures[i]\n        texture:Hide()\n    end\n    \n    local textureStretched = unitFrame.felAnimation.textureStretched\n    textureStretched:Hide()    \n    \nend\n\n\n\n\n\n\n",
				["ScriptType"] = 2,
				["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local castBar = unitFrame.castBar\n    \n    local textures = unitFrame.felAnimation.Textures\n\n    if (envTable._CastPercent > envTable.NextPercent) then\n        local nextPercent = 100  / scriptTable.config.segmentsAmount\n        \n        textures[envTable.CurrentTexture]:Show()\n        textures[envTable.CurrentTexture].animGroup:Play()\n        envTable.NextPercent = envTable.NextPercent + nextPercent \n        envTable.CurrentTexture = envTable.CurrentTexture + 1\n        \n        if (envTable.CurrentTexture == #textures) then\n            envTable.NextPercent = 98\n        elseif (envTable.CurrentTexture > #textures) then\n            envTable.NextPercent = 999\n        end\n    end\n    \n    local normalizedPercent = envTable._CastPercent / 100\n    local textureStretched = unitFrame.felAnimation.textureStretched\n    local point = DetailsFramework:GetBezierPoint(normalizedPercent, 0, 0.001, 1)\n    textureStretched:SetPoint(\"left\", castBar, \"left\", point * envTable.castBarWidth, 0)\nend",
				["Time"] = 1666836560,
				["url"] = "",
				["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_glow",
				["Enabled"] = true,
				["Revision"] = 346,
				["semver"] = "",
				["Author"] = "Terciob",
				["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
				["Desc"] = "Show a different animation for the cast bar.",
				["NpcNames"] = {
				},
				["SpellIds"] = {
					373429, -- [1]
				},
				["PlaterCore"] = 1,
				["Name"] = "Cast - Glowing [P]",
				["version"] = -1,
				["Options"] = {
					{
						["Type"] = 2,
						["Max"] = 20,
						["Desc"] = "Need a /reload",
						["Min"] = 5,
						["Name"] = "Amount of Segments",
						["Value"] = 7,
						["Fraction"] = false,
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
						["Key"] = "segmentsAmount",
					}, -- [1]
					{
						["Type"] = 1,
						["Key"] = "sparkColor",
						["Value"] = {
							0.9568627450980391, -- [1]
							1, -- [2]
							0.9882352941176471, -- [3]
							1, -- [4]
						},
						["Name"] = "Spark Color",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
						["Desc"] = "",
					}, -- [2]
					{
						["Type"] = 1,
						["Key"] = "glowColor",
						["Value"] = {
							0.8588235294117647, -- [1]
							0.4313725490196079, -- [2]
							1, -- [3]
							1, -- [4]
						},
						["Name"] = "Glow Color",
						["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
						["Desc"] = "",
					}, -- [3]
				},
				["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    local castBar = unitFrame.castBar\n    envTable.castBarWidth = castBar:GetWidth()\n    castBar.Spark:SetVertexColor(DetailsFramework:ParseColors(scriptTable.config.sparkColor))\n    \n    local textureStretched = unitFrame.felAnimation.textureStretched\n    textureStretched:Show()\n    textureStretched:SetVertexColor(DetailsFramework:ParseColors(scriptTable.config.glowColor))\n    textureStretched:SetAtlas(\"XPBarAnim-OrangeTrail\")\n    textureStretched:ClearAllPoints()\n    textureStretched:SetPoint(\"right\", castBar.Spark, \"center\", 0, 0)\n    textureStretched:SetHeight(castBar:GetHeight())\n    textureStretched:SetBlendMode(\"ADD\") \n    textureStretched:SetAlpha(0.5)\n    textureStretched:SetDrawLayer(\"overlay\", 7)\n    \n    for i = 1, scriptTable.config.segmentsAmount  do\n        local texture = unitFrame.felAnimation.Textures[i]\n        --texture:SetVertexColor(DetailsFramework:ParseColors(scriptTable.config.trailColor))\n        texture:SetVertexColor(1, 1, 1, 1)\n        texture:SetDesaturated(true)\n        \n        local castBarPortion = castBar:GetWidth()/scriptTable.config.segmentsAmount\n        \n        texture:SetSize(castBarPortion+5, castBar:GetHeight())\n        texture:SetDrawLayer(\"overlay\", 6)\n        \n        texture:ClearAllPoints()\n        if (i == scriptTable.config.segmentsAmount) then\n            texture:SetPoint(\"right\", castBar, \"right\", 0, 0)\n        else\n            texture:SetPoint(\"left\", castBar, \"left\", (i-1)*castBarPortion, 2)\n        end\n        \n        texture:SetAlpha(0)\n        texture:Hide()\n        \n        texture.scale:SetOrder(1)\n        texture.scale:SetDuration(0.5)\n        texture.scale:SetScaleFrom(0.2, 1)\n        texture.scale:SetScaleTo(1, 1.5)\n        texture.scale:SetOrigin(\"right\", 0, 0)\n        \n        local durationTime = DetailsFramework:GetBezierPoint(i / scriptTable.config.segmentsAmount, 0.2, 0.01, 0.6)\n        local duration = abs(durationTime-0.6)\n        \n        texture.alpha:SetOrder(1)\n        texture.alpha:SetDuration(0.05)\n        texture.alpha:SetFromAlpha(0)\n        texture.alpha:SetToAlpha(0.4)\n        \n        texture.alpha2:SetOrder(1)\n        texture.alpha2:SetDuration(duration) --0.6\n        texture.alpha2:SetStartDelay(duration)\n        texture.alpha2:SetFromAlpha(0.5)\n        texture.alpha2:SetToAlpha(0)\n    end\n    \n    envTable.CurrentTexture = 1\n    envTable.NextPercent  = 100  / scriptTable.config.segmentsAmount\nend\n\n\n\n\n\n\n\n\n",
			}, -- [4]
		},
		["health_cutoff_upper"] = false,
		["aura2_y_offset"] = 5,
		["cast_statusbar_color_nointerrupt"] = {
			1, -- [1]
			0, -- [2]
			0, -- [3]
		},
		["npc_cache"] = {
			[116549] = {
				"Backup Singer", -- [1]
				"Return to Karazhan", -- [2]
			},
			[150253] = {
				"Weaponized Crawler", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114541] = {
				"Spectral Patron", -- [1]
				"Return to Karazhan", -- [2]
			},
			[81407] = {
				"Grimrail Bombardier", -- [1]
				"Grimrail Depot", -- [2]
			},
			[114334] = {
				"Damaged Golem", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114350] = {
				"Shade of Medivh", -- [1]
				"Return to Karazhan", -- [2]
			},
			[150190] = {
				"HK-8 Aerial Oppression Unit", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[115402] = {
				"Bishop", -- [1]
				"Return to Karazhan", -- [2]
			},
			[115418] = {
				"Spider", -- [1]
				"Return to Karazhan", -- [2]
			},
			[176551] = {
				"Vault Purifier", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[179388] = {
				"Hourglass Tidesage", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[151657] = {
				"Bomb Tonk", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[144294] = {
				"Mechagon Tinkerer", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[116550] = {
				"Spectral Patron", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114526] = {
				"Ghostly Understudy", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114542] = {
				"Ghostly Philanthropist", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114319] = {
				"Lady Keira Berrybuck", -- [1]
				"Return to Karazhan", -- [2]
			},
			[151658] = {
				"Strider Tonk", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[150160] = {
				"Scrapbone Bully", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[152009] = {
				"Malfunctioning Scrapbot", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[180091] = {
				"Ancient Core Hound", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[151659] = {
				"Rocket Tonk", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[144296] = {
				"Spider Tank", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[179837] = {
				"Tracker Zo'korss", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[114320] = {
				"Lord Robin Daris", -- [1]
				"Return to Karazhan", -- [2]
			},
			[176395] = {
				"Overloaded Mailemental", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[115388] = {
				"King", -- [1]
				"Return to Karazhan", -- [2]
			},
			[79720] = {
				"Grom'kar Boomer", -- [1]
				"Grimrail Depot", -- [2]
			},
			[176555] = {
				"Achillite", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[115484] = {
				"Fel Bat", -- [1]
				"Return to Karazhan", -- [2]
			},
			[144298] = {
				"Defense Bot Mk III", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[150195] = {
				"Gnome-Eating Slime", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114783] = {
				"Reformed Maiden", -- [1]
				"Return to Karazhan", -- [2]
			},
			[176556] = {
				"Alcruux", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[144299] = {
				"Workshop Defender", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114624] = {
				"Arcane Warden", -- [1]
				"Return to Karazhan", -- [2]
			},
			[81235] = {
				"Grimrail Laborer", -- [1]
				"Grimrail Depot", -- [2]
			},
			[179840] = {
				"Market Peacekeeper", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[150292] = {
				"Mechagon Cavalry", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[180159] = {
				"Brawling Patron", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[82590] = {
				"Grimrail Scout", -- [1]
				"Grimrail Depot", -- [2]
			},
			[144300] = {
				"Mechagon Citizen", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[115533] = {
				"Gleeful Immolator", -- [1]
				"Return to Karazhan", -- [2]
			},
			[179841] = {
				"Veteran Sparkcaster", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[150293] = {
				"Mechagon Prowler", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114338] = {
				"Mana Confluence", -- [1]
				"Return to Karazhan", -- [2]
			},
			[144301] = {
				"Living Waste", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114625] = {
				"Phantom Guest", -- [1]
				"Return to Karazhan", -- [2]
			},
			[81236] = {
				"Grimrail Technician", -- [1]
				"Grimrail Depot", -- [2]
			},
			[179842] = {
				"Commerce Enforcer", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[115486] = {
				"Erudite Slayer", -- [1]
				"Return to Karazhan", -- [2]
			},
			[115757] = {
				"Wrathguard Flamebringer", -- [1]
				"Return to Karazhan", -- [2]
			},
			[179269] = {
				"Oasis Security", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[163746] = {
				"Walkie Shockie X1", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[150295] = {
				"Tank Buster MK1", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[153196] = {
				"Scrapbone Grunter", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[150168] = {
				"Toxic Monstrosity", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114626] = {
				"Forlorn Spirit", -- [1]
				"Return to Karazhan", -- [2]
			},
			[115407] = {
				"Rook", -- [1]
				"Return to Karazhan", -- [2]
			},
			[179334] = {
				"Portalmancer Zo'nyy", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[79739] = {
				"Grom'kar Grenadier", -- [1]
				"Grimrail Depot", -- [2]
			},
			[154663] = {
				"Gnome-Eating Droplet", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[79548] = {
				"Assault Cannon", -- [1]
				"Grimrail Depot", -- [2]
			},
			[151476] = {
				"Blastatron X-80", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[120651] = {
				"Explosives", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[176562] = {
				"Brawling Patron", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[179399] = {
				"Drunk Pirate", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[114324] = {
				"Winged Assistant", -- [1]
				"Return to Karazhan", -- [2]
			},
			[80935] = {
				"Grom'kar Boomer", -- [1]
				"Grimrail Depot", -- [2]
			},
			[114627] = {
				"Shrieking Terror", -- [1]
				"Return to Karazhan", -- [2]
			},
			[176563] = {
				"Zo'gron", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[115488] = {
				"Infused Pyromancer", -- [1]
				"Return to Karazhan", -- [2]
			},
			[180567] = {
				"Frenzied Nightclaw", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[177807] = {
				"Customs Security", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[114803] = {
				"Spectral Stable Hand", -- [1]
				"Return to Karazhan", -- [2]
			},
			[150547] = {
				"Scrapbone Grunter", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114637] = {
				"Spectral Sentry", -- [1]
				"Return to Karazhan", -- [2]
			},
			[80936] = {
				"Grom'kar Grenadier", -- [1]
				"Grimrail Depot", -- [2]
			},
			[114544] = {
				"Skeletal Usher", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114628] = {
				"Skeletal Waiter", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114796] = {
				"Wholesome Hostess", -- [1]
				"Return to Karazhan", -- [2]
			},
			[177808] = {
				"Armored Overseer", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[176565] = {
				"Disruptive Patron", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[82594] = {
				"Grimrail Loader", -- [1]
				"Grimrail Depot", -- [2]
			},
			[144244] = {
				"The Platinum Pummeler", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[150396] = {
				"Aerial Unit R-21/X", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[115401] = {
				"Bishop", -- [1]
				"Return to Karazhan", -- [2]
			},
			[189878] = {
				"Nathrezim Infiltrator", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114262] = {
				"Attumen the Huntsman", -- [1]
				"Return to Karazhan", -- [2]
			},
			[79545] = {
				"Nitrogg Thundertower", -- [1]
				"Grimrail Depot", -- [2]
			},
			[175546] = {
				"Timecap'n Hooktail", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[150142] = {
				"Scrapbone Trashtosser", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[178142] = {
				"Murkbrine Fishmancer", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[150397] = {
				"King Mechagon", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114675] = {
				"Guardian's Image", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114629] = {
				"Spectral Retainer", -- [1]
				"Return to Karazhan", -- [2]
			},
			[150159] = {
				"King Gobbamak", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[144293] = {
				"Waste Processing Unit", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[115406] = {
				"Knight", -- [1]
				"Return to Karazhan", -- [2]
			},
			[150712] = {
				"Trixie Tazer", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[144246] = {
				"K.U.-J.0.", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[150143] = {
				"Scrapbone Grinder", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114801] = {
				"Spectral Apprentice", -- [1]
				"Return to Karazhan", -- [2]
			},
			[177237] = {
				"Chains of Damnation", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[177269] = {
				"So'leah", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[145185] = {
				"Gnomercy 4.U.", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[176396] = {
				"Defective Sorter", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[153377] = {
				"Goop", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[144295] = {
				"Mechagon Mechanic", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[80938] = {
				"Grom'kar Hulk", -- [1]
				"Grimrail Depot", -- [2]
			},
			[177716] = {
				"So' Cartel Assassin", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[115395] = {
				"Queen", -- [1]
				"Return to Karazhan", -- [2]
			},
			[150169] = {
				"Toxic Lurker", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[178163] = {
				"Murkbrine Shorerunner", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[151579] = {
				"Shield Generator", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114264] = {
				"Midnight", -- [1]
				"Return to Karazhan", -- [2]
			},
			[115730] = {
				"Felguard Sentry", -- [1]
				"Return to Karazhan", -- [2]
			},
			[150154] = {
				"Saurolisk Bonenipper", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[175677] = {
				"Smuggled Creature", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[183423] = {
				"Reformed Bachelor", -- [1]
				"Return to Karazhan", -- [2]
			},
			[179821] = {
				"Commander Zo'far", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[114790] = {
				"Viz'aduum the Watcher", -- [1]
				"Return to Karazhan", -- [2]
			},
			[151325] = {
				"Alarm-o-Bot", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114312] = {
				"Moroes", -- [1]
				"Return to Karazhan", -- [2]
			},
			[77803] = {
				"Railmaster Rocketspark", -- [1]
				"Grimrail Depot", -- [2]
			},
			[150146] = {
				"Scrapbone Shaman", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[178388] = {
				"Bazaar Strongarm", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[114284] = {
				"Elfyra", -- [1]
				"Return to Karazhan", -- [2]
			},
			[150249] = {
				"Pistonhead Scrapper", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[183424] = {
				"Virtuous Gentleman", -- [1]
				"Return to Karazhan", -- [2]
			},
			[175806] = {
				"So'azmi", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[178133] = {
				"Murkbrine Wavejumper", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[178165] = {
				"Coastwalker Goliath", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[82597] = {
				"Grom'kar Captain", -- [1]
				"Grimrail Depot", -- [2]
			},
			[79888] = {
				"Iron Infantry", -- [1]
				"Grimrail Depot", -- [2]
			},
			[114249] = {
				"Volatile Energy", -- [1]
				"Return to Karazhan", -- [2]
			},
			[151773] = {
				"Junkyard D.0.G.", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[183425] = {
				"Wholesome Host", -- [1]
				"Return to Karazhan", -- [2]
			},
			[176705] = {
				"Venza Goldfuse", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[180429] = {
				"Adorned Starseer", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[175616] = {
				"Zo'phex", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[80940] = {
				"Iron Infantry", -- [1]
				"Grimrail Depot", -- [2]
			},
			[180015] = {
				"Burly Deckhand", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[114632] = {
				"Spectral Attendant", -- [1]
				"Return to Karazhan", -- [2]
			},
			[177816] = {
				"Interrogation Specialist", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[150276] = {
				"Heavy Scrapbot", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[144248] = {
				"Head Machinist Sparkflux", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[178394] = {
				"Cartel Lackey", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[155090] = {
				"Anodized Coilbearer", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[180335] = {
				"Cartel Smuggler", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[152033] = {
				"Inconspicuous Plant", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114792] = {
				"Virtuous Lady", -- [1]
				"Return to Karazhan", -- [2]
			},
			[116561] = {
				"Unbound Pyrelord", -- [1]
				"Return to Karazhan", -- [2]
			},
			[177817] = {
				"Support Officer", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[115419] = {
				"Ancient Tome", -- [1]
				"Return to Karazhan", -- [2]
			},
			[180431] = {
				"Focused Ritualist", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[191046] = {
				"Shady Dealer", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[180495] = {
				"Enraged Direhorn", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[81212] = {
				"Grimrail Overseer", -- [1]
				"Grimrail Depot", -- [2]
			},
			[114633] = {
				"Spectral Valet", -- [1]
				"Return to Karazhan", -- [2]
			},
			[180336] = {
				"Cartel Wiseguy", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[114247] = {
				"The Curator", -- [1]
				"Return to Karazhan", -- [2]
			},
			[151649] = {
				"Defense Bot Mk I", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[180432] = {
				"Devoted Accomplice", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[77483] = {
				"Grom'kar Gunner", -- [1]
				"Grimrail Depot", -- [2]
			},
			[150254] = {
				"Scraphound", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[115765] = {
				"Abstract Nullifier", -- [1]
				"Return to Karazhan", -- [2]
			},
			[177500] = {
				"Corsair Brute", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[116562] = {
				"Flamewaker Centurion", -- [1]
				"Return to Karazhan", -- [2]
			},
			[151613] = {
				"Anti-Personnel Squirrel", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114251] = {
				"Galindre", -- [1]
				"Return to Karazhan", -- [2]
			},
			[180433] = {
				"Wandering Pulsar", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[178392] = {
				"Gatewarden Zo'mazz", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[175663] = {
				"Hylbrande", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[144303] = {
				"G.U.A.R.D.", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114634] = {
				"Undying Servant", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114650] = {
				"Phantom Hound", -- [1]
				"Return to Karazhan", -- [2]
			},
			[150222] = {
				"Gunker", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[150165] = {
				"Slime Elemental", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[178139] = {
				"Murkbrine Shellcrusher", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[178171] = {
				"Stormforged Guardian", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[179733] = {
				"Invigorating Fish Stick", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[153755] = {
				"Naeno Megacrash", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114584] = {
				"Phantom Crew", -- [1]
				"Return to Karazhan", -- [2]
			},
			[155094] = {
				"Mechagon Trooper", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114794] = {
				"Skeletal Hound", -- [1]
				"Return to Karazhan", -- [2]
			},
			[77816] = {
				"Borka the Brute", -- [1]
				"Grimrail Depot", -- [2]
			},
			[114316] = {
				"Baroness Dorothea Millstipe", -- [1]
				"Return to Karazhan", -- [2]
			},
			[175646] = {
				"P.O.S.T. Master", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[154744] = {
				"Toxic Monstrosity", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[114364] = {
				"Mana-Gorged Wyrm", -- [1]
				"Return to Karazhan", -- [2]
			},
			[176394] = {
				"P.O.S.T. Worker", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[150250] = {
				"Pistonhead Blaster", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[151812] = {
				"Detect-o-Bot", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[88163] = {
				"Grom'kar Cinderseer", -- [1]
				"Grimrail Depot", -- [2]
			},
			[178141] = {
				"Murkbrine Scalebinder", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[114715] = {
				"Ghostly Chef", -- [1]
				"Return to Karazhan", -- [2]
			},
			[154758] = {
				"Toxic Monstrosity", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[82579] = {
				"Grom'kar Far Seer", -- [1]
				"Grimrail Depot", -- [2]
			},
			[190174] = {
				"Hypnosis Bat", -- [1]
				"Return to Karazhan", -- [2]
			},
			[150251] = {
				"Pistonhead Mechanic", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[150297] = {
				"Mechagon Renormalizer", -- [1]
				"Operation: Mechagon", -- [2]
			},
			[115831] = {
				"Mana Devourer", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114317] = {
				"Lady Catriona Von'Indi", -- [1]
				"Return to Karazhan", -- [2]
			},
			[80937] = {
				"Grom'kar Gunner", -- [1]
				"Grimrail Depot", -- [2]
			},
			[114804] = {
				"Spectral Charger", -- [1]
				"Return to Karazhan", -- [2]
			},
			[113971] = {
				"Maiden of Virtue", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114636] = {
				"Phantom Guardsman", -- [1]
				"Return to Karazhan", -- [2]
			},
			[115417] = {
				"Rat", -- [1]
				"Return to Karazhan", -- [2]
			},
			[80005] = {
				"Skylord Tovra", -- [1]
				"Grimrail Depot", -- [2]
			},
			[179386] = {
				"Corsair Officer", -- [1]
				"Tazavesh, the Veiled Market", -- [2]
			},
			[190128] = {
				"Zul'gamux", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114716] = {
				"Ghostly Baker", -- [1]
				"Return to Karazhan", -- [2]
			},
			[114802] = {
				"Spectral Journeyman", -- [1]
				"Return to Karazhan", -- [2]
			},
		},
		["aura_stack_shadow_color"] = {
			nil, -- [1]
			nil, -- [2]
			nil, -- [3]
			0, -- [4]
		},
		["minor_height_scale"] = 0.9999999403953552,
		["indicator_worldboss"] = false,
		["aura_width2"] = 20,
		["aura_height2"] = 20,
		["aura_show_crowdcontrol"] = true,
		["health_cutoff"] = false,
		["ui_parent_cast_strata"] = "LOW",
		["class_colors"] = {
			["DEATHKNIGHT"] = {
				["colorStr"] = "ffc31d3a",
			},
			["WARRIOR"] = {
				["colorStr"] = "ffc69a6d",
			},
			["PALADIN"] = {
				["colorStr"] = "fff48bb9",
			},
			["WARLOCK"] = {
				["colorStr"] = "ff8687ed",
			},
			["DEMONHUNTER"] = {
				["colorStr"] = "ffa22fc8",
			},
			["ROGUE"] = {
				["colorStr"] = "fffff467",
			},
			["DRUID"] = {
				["colorStr"] = "ffff7c09",
			},
			["EVOKER"] = {
				["colorStr"] = "ff33937e",
			},
			["SHAMAN"] = {
				["colorStr"] = "ff006fdd",
			},
		},
		["extra_icon_anchor"] = {
			["x"] = -2,
		},
		["ui_parent_buff2_strata"] = "LOW",
		["range_check_alpha"] = 1,
		["semver"] = "3.3.0",
		["use_name_translit"] = true,
		["cast_statusbar_texture"] = "Minimalist",
		["extra_icon_height"] = 20,
		["extra_icon_show_purge"] = true,
		["spell_animations"] = false,
		["aura_consolidate"] = true,
		["extra_icon_width"] = 26,
		["health_statusbar_texture"] = "Minimalist",
		["hook_auto_imported"] = {
			["Reorder Nameplate"] = 4,
			["Dont Have Aura"] = 1,
			["Players Targetting Amount"] = 4,
			["Color Automation"] = 1,
			["Extra Border"] = 2,
			["Cast Bar Icon Config"] = 2,
			["Attacking Specific Unit"] = 2,
			["Combo Points"] = 6,
			["Hide Neutral Units"] = 1,
			["Target Color"] = 3,
			["Execute Range"] = 1,
			["Aura Reorder"] = 3,
		},
		["minor_width_scale"] = 0.9999999403953552,
		["aura_frame1_anchor"] = {
			["y"] = 2,
		},
		["aura_timer_text_font"] = "Expressway",
		["extra_icon_stack_font"] = "Expressway",
		["aura_height"] = 20,
		["cast_statusbar_bgtexture"] = "Minimalist",
		["aura2_x_offset"] = 0,
		["target_indicator"] = "NONE",
		["aura_show_buff_by_the_unit"] = false,
		["castbar_target_notank"] = true,
		["saved_cvars"] = {
			["nameplateSelectedAlpha"] = "1",
			["ShowClassColorInNameplate"] = "1",
			["nameplateOverlapV"] = "1.6",
			["nameplateLargeTopInset"] = "-1",
			["nameplateShowEnemyMinus"] = "1",
			["nameplateMinAlphaDistance"] = "-158489.31924611",
			["nameplateMotionSpeed"] = "0.05",
			["NamePlateClassificationScale"] = "1",
			["nameplateShowFriendlyTotems"] = "0",
			["nameplateShowEnemyMinions"] = "1",
			["nameplateShowFriendlyPets"] = "0",
			["nameplateShowFriendlyNPCs"] = "1",
			["nameplateSelectedScale"] = "1",
			["nameplateOverlapH"] = "1",
			["nameplateTargetRadialPosition"] = "1",
			["nameplateShowFriendlyMinions"] = "0",
			["nameplateMinAlpha"] = "0.90",
			["nameplateResourceOnTarget"] = "0",
			["nameplateMotion"] = "1",
			["clampTargetNameplateToScreen"] = "1",
			["nameplateMinScale"] = "1",
			["nameplateMaxDistance"] = "100",
			["nameplateOtherTopInset"] = "-1",
			["nameplatePersonalHideDelaySeconds"] = "0.2",
			["nameplateTargetBehindMaxDistance"] = "30",
			["ShowNamePlateLoseAggroFlash"] = "0",
			["nameplateShowFriendlyGuardians"] = "0",
			["NamePlateHorizontalScale"] = "1",
			["nameplateShowFriends"] = "0",
			["nameplateShowEnemies"] = "1",
			["nameplateShowAll"] = "1",
			["NamePlateVerticalScale"] = "1",
		},
		["login_counter"] = 276,
		["extra_icon_caster_name"] = false,
		["click_space_friendly"] = {
			nil, -- [1]
			18, -- [2]
		},
		["bossmod_aura_height"] = 30,
		["aura_stack_font"] = "Expressway",
		["hide_friendly_castbars"] = true,
		["OptionsPanelDB"] = {
			["PlaterOptionsPanelFrame"] = {
				["scale"] = 1,
			},
		},
		["aura_timer_text_shadow_color"] = {
			nil, -- [1]
			nil, -- [2]
			nil, -- [3]
			0, -- [4]
		},
		["auras_per_row_amount"] = 6,
		["target_highlight_texture"] = "Interface\\AddOns\\Plater\\images\\selection_indicator2",
		["plate_config"] = {
			["player"] = {
				["spellpercent_text_font"] = "Expressway",
				["percent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["power_percent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["spellname_text_font"] = "Expressway",
				["power_percent_text_font"] = "Expressway",
				["percent_text_font"] = "Expressway",
				["spellname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["spellpercent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
			},
			["friendlyplayer"] = {
				["spellpercent_text_font"] = "Expressway",
				["actorname_use_class_color"] = true,
				["cast"] = {
					190, -- [1]
					12, -- [2]
				},
				["percent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["spellname_text_outline"] = "OUTLINE",
				["level_text_font"] = "Expressway",
				["actorname_text_font"] = "Expressway",
				["actorname_use_guild_color"] = false,
				["level_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["cast_incombat"] = {
					190, -- [1]
				},
				["actorname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["spellname_text_font"] = "Expressway",
				["actorname_text_size"] = 11,
				["level_text_outline"] = "OUTLINE",
				["percent_text_font"] = "Expressway",
				["spellpercent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["spellname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["health_incombat"] = {
					190, -- [1]
					18, -- [2]
				},
				["health"] = {
					190, -- [1]
					18, -- [2]
				},
			},
			["friendlynpc"] = {
				["spellpercent_text_font"] = "Expressway",
				["cast"] = {
					190, -- [1]
					12, -- [2]
				},
				["percent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["spellname_text_outline"] = "OUTLINE",
				["big_actorname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["level_text_font"] = "Expressway",
				["actorname_text_font"] = "Expressway",
				["all_names"] = false,
				["actorname_text_outline"] = "OUTLINE",
				["big_actortitle_text_font"] = "Expressway",
				["level_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["cast_incombat"] = {
					190, -- [1]
				},
				["relevance_state"] = 3,
				["actorname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["big_actortitle_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["spellname_text_font"] = "Expressway",
				["actorname_text_size"] = 11,
				["big_actorname_text_font"] = "Expressway",
				["level_text_outline"] = "OUTLINE",
				["big_actortitle_text_size"] = 9,
				["percent_text_font"] = "Expressway",
				["spellname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["health_incombat"] = {
					190, -- [1]
					18, -- [2]
				},
				["health"] = {
					190, -- [1]
					18, -- [2]
				},
				["spellpercent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
			},
			["enemynpc"] = {
				["spellpercent_text_font"] = "Expressway",
				["cast"] = {
					190, -- [1]
					12, -- [2]
				},
				["spellpercent_text_anchor"] = {
					["x"] = -1,
				},
				["big_actorname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["level_text_font"] = "Expressway",
				["actorname_text_font"] = "Expressway",
				["actorname_text_outline"] = "OUTLINE",
				["big_actortitle_text_font"] = "Expressway",
				["spellpercent_text_size"] = 9,
				["level_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["cast_incombat"] = {
					190, -- [1]
					12, -- [2]
				},
				["actorname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["spellname_text_anchor"] = {
					["x"] = 1,
					["side"] = 10,
				},
				["big_actortitle_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["percent_text_anchor"] = {
					["side"] = 11,
				},
				["spellname_text_font"] = "Expressway",
				["big_actorname_text_font"] = "Expressway",
				["level_text_outline"] = "OUTLINE",
				["percent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["percent_show_health"] = false,
				["percent_text_size"] = 11,
				["percent_text_font"] = "Expressway",
				["spellname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["health_incombat"] = {
					190, -- [1]
					18, -- [2]
				},
				["health"] = {
					190, -- [1]
					18, -- [2]
				},
				["spellpercent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["actorname_text_anchor"] = {
					["x"] = 1,
					["side"] = 10,
				},
				["spellname_text_size"] = 9,
				["level_text_enabled"] = false,
			},
			["global_health_height"] = 18,
			["enemyplayer"] = {
				["big_actorname_text_size"] = 10,
				["spellpercent_text_font"] = "Expressway",
				["level_text_size"] = 8,
				["cast"] = {
					190, -- [1]
					12, -- [2]
				},
				["big_actortitle_text_size"] = 10,
				["spellpercent_text_anchor"] = {
					["x"] = -1,
				},
				["spellname_text_outline"] = "OUTLINE",
				["big_actorname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["level_text_font"] = "Expressway",
				["actorname_text_font"] = "Expressway",
				["all_names"] = true,
				["actorname_text_outline"] = "OUTLINE",
				["actorname_text_spacing"] = 10,
				["quest_color_enemy"] = {
					1, -- [1]
					0.369, -- [2]
					0, -- [3]
					1, -- [4]
				},
				["big_actortitle_text_font"] = "Expressway",
				["spellpercent_text_size"] = 9,
				["level_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["cast_incombat"] = {
					190, -- [1]
				},
				["actorname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["spellname_text_anchor"] = {
					["x"] = 1,
					["side"] = 10,
				},
				["big_actortitle_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["percent_text_anchor"] = {
					["side"] = 11,
				},
				["spellpercent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["quest_color_neutral"] = {
					1, -- [1]
					0.65, -- [2]
					0, -- [3]
					1, -- [4]
				},
				["actorname_text_size"] = 11,
				["big_actorname_text_font"] = "Expressway",
				["percent_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["level_text_outline"] = "OUTLINE",
				["percent_show_health"] = false,
				["percent_text_size"] = 11,
				["percent_text_font"] = "Expressway",
				["quest_enabled"] = true,
				["actorname_text_anchor"] = {
					["x"] = 1,
					["side"] = 10,
				},
				["spellname_text_shadow_color"] = {
					nil, -- [1]
					nil, -- [2]
					nil, -- [3]
					0, -- [4]
				},
				["health_incombat"] = {
					190, -- [1]
					18, -- [2]
				},
				["health"] = {
					190, -- [1]
					18, -- [2]
				},
				["spellname_text_font"] = "Expressway",
				["quest_color_enabled"] = true,
				["spellname_text_size"] = 9,
				["level_text_enabled"] = false,
			},
			["global_health_width"] = 190,
		},
		["aura_y_offset"] = 2,
		["indicator_elite"] = false,
		["cast_statusbar_use_fade_effects"] = false,
		["indicator_spec"] = false,
		["resources_settings"] = {
			["chr"] = {
				["Player-55-0799659A"] = "HolyPower",
				["Player-55-09963EFE"] = "ComboPoints",
			},
		},
		["focus_color"] = {
			0.4509804248809815, -- [1]
			0.1529411822557449, -- [2]
			0.5764706134796143, -- [3]
			0.8752859085798264, -- [4]
		},
		["castbar_icon_size"] = "same as castbar plus healthbar",
		["hook_data"] = {
			{
				["Enabled"] = true,
				["Revision"] = 106,
				["Options"] = {
				},
				["HooksTemp"] = {
				},
				["Author"] = "Luckyone-Laughing Skull",
				["OptionsValues"] = {
				},
				["Desc"] = "",
				["Hooks"] = {
					["Nameplate Updated"] = "function(self, unitId, unitFrame, envTable)\n    \n    local unitName = UnitName(unitId)\n    \n    -- Show First Name [Whitelist table]\n    local firstName = {\n        [3527] = true, -- Healing Stream Totem\n        [2630] = true, -- Earthbind Totem\n        [61245] = true, -- Capacitor Totem\n        [5925] = true, -- Grounding Totem\n        [105451] = true, -- Counterstrike Totem\n        [105427] = true, -- Skyfury Totem\n        [97369] = true, -- Liquid Magma Totem\n    }\n    \n    -- Show Full Name [Whitelist table]\n    local fullName = {\n        [167406] = true, -- Sire Fated\n    }\n    \n    if (unitName) then\n        local a , b, c, d, e, f = strsplit(' ', unitName, 5)\n        \n        if firstName [unitFrame.namePlateNpcId] then\n            unitFrame.healthBar.unitName:SetText(a)\n        elseif fullName[unitFrame.namePlateNpcId] then\n            unitFrame.healthBar.unitName:SetText(unitName)\n        else\n            unitFrame.healthBar.unitName:SetText(f or e or d or c or b or a)\n        end\n    end\nend",
				},
				["Prio"] = 1,
				["Name"] = "LuckyoneUI - Name",
				["PlaterCore"] = 1,
				["LastHookEdited"] = "",
				["Time"] = 1661180206,
				["Icon"] = 132115,
				["LoadConditions"] = {
					["talent"] = {
					},
					["group"] = {
					},
					["class"] = {
					},
					["map_ids"] = {
					},
					["role"] = {
					},
					["pvptalent"] = {
					},
					["spec"] = {
					},
					["race"] = {
					},
					["encounter_ids"] = {
					},
					["affix"] = {
					},
				},
			}, -- [1]
			{
				["Enabled"] = true,
				["Revision"] = 74,
				["Options"] = {
				},
				["HooksTemp"] = {
				},
				["Author"] = "Luckyone-Laughing Skull",
				["OptionsValues"] = {
				},
				["Desc"] = "",
				["Hooks"] = {
					["Nameplate Removed"] = "function(self, unitId, unitFrame, envTable)\n    envTable.UpdateBorder(unitFrame, false)\nend",
					["Cast Update"] = "function(self, unitId, unitFrame, envTable)\n    envTable.UpdateIconPosition(unitFrame)\nend",
					["Cast Start"] = "function(self, unitId, unitFrame, envTable)\n    envTable.UpdateIconPosition(unitFrame)\n    envTable.UpdateBorder(unitFrame, true)\nend",
					["Constructor"] = "function(self, unitId, unitFrame, envTable)\n    local hooksecurefunc = hooksecurefunc\n    \n    envTable.ShowIcon = Plater.db.profile.castbar_icon_show\n    envTable.IconAnchor = 'left'\n    envTable.IconSizeOffset = 0\n    \n    function envTable.UpdateIconPosition (unitFrame)\n        local castBar = unitFrame.castBar\n        local icon = castBar.Icon\n        local shield = castBar.BorderShield\n        \n        shield:Hide()\n        \n        if (envTable.ShowIcon) then\n            icon:ClearAllPoints()\n            \n            if (envTable.IconAnchor == 'left') then\n                icon:SetPoint ('topright', unitFrame.healthBar, 'topleft', 0, envTable.IconSizeOffset)\n                icon:SetPoint ('bottomright', unitFrame.castBar, 'bottomleft', 0, 0)\n                \n            elseif (envTable.IconAnchor == 'right') then\n                icon:SetPoint ('topleft', unitFrame.healthBar, 'topright', 0, envTable.IconSizeOffset)\n                icon:SetPoint ('bottomleft', unitFrame.castBar, 'bottomright', 0, 0)\n                \n            end\n            \n            icon:SetWidth (icon:GetHeight())\n            icon:Show()\n        else\n            icon:Hide()\n        end\n    end\n    \n    function envTable.UpdateBorder(unitFrame, casting)\n        local healthBar = unitFrame.healthBar\n        local castBar = unitFrame.castBar\n        \n        if casting then\n            if envTable.ShowIcon and castBar.Icon:IsShown() then\n                if envTable.IconAnchor == 'left' then\n                    healthBar.border:SetPoint('TOPLEFT', castBar.Icon, 'TOPLEFT', 0, 0)\n                    healthBar.border:SetPoint('BOTTOMRIGHT', castBar, 'BOTTOMRIGHT', 0, 0)\n                elseif envTable.IconAnchor == 'right' then\n                    healthBar.border:SetPoint('TOPRIGHT', castBar.Icon, 'TOPRIGHT', 0, 0)\n                    healthBar.border:SetPoint('BOTTOMLEFT', castBar, 'BOTTOMLEFT', 0, 0) \n                end\n            else\n                if envTable.IconAnchor == 'left' then\n                    healthBar.border:SetPoint('TOPLEFT', healthBar, 'TOPLEFT', 0, 0)\n                    healthBar.border:SetPoint('BOTTOMRIGHT', castBar, 'BOTTOMRIGHT', 0, 0)\n                elseif envTable.IconAnchor == 'right' then\n                    healthBar.border:SetPoint('TOPRIGHT', healthBar, 'TOPRIGHT', 0, 0)\n                    healthBar.border:SetPoint('BOTTOMLEFT', castBar, 'BOTTOMLEFT', 0, 0) \n                end\n            end\n        else\n            if envTable.IconAnchor == 'left' then\n                healthBar.border:SetPoint('TOPLEFT', healthBar, 'TOPLEFT', 0, 0)\n                healthBar.border:SetPoint('BOTTOMRIGHT', healthBar, 'BOTTOMRIGHT', 0, 0)\n            elseif envTable.IconAnchor == 'right' then\n                healthBar.border:SetPoint('TOPRIGHT', healthBar, 'TOPRIGHT', 0, 0)\n                healthBar.border:SetPoint('BOTTOMLEFT', healthBar, 'BOTTOMLEFT', 0, 0) \n            end\n        end\n    end\n    \n    if not unitFrame.castBar.borderChangeHooked then\n        hooksecurefunc(unitFrame.castBar, 'Hide', function() envTable.UpdateBorder(unitFrame, false) end)\n        unitFrame.castBar.borderChangeHooked = true\n    end\nend",
				},
				["Prio"] = 1,
				["Name"] = "LuckyoneUI - Castbar",
				["PlaterCore"] = 1,
				["LastHookEdited"] = "Cast Update",
				["Time"] = 1668361574,
				["Icon"] = 132144,
				["LoadConditions"] = {
					["talent"] = {
					},
					["group"] = {
					},
					["class"] = {
					},
					["map_ids"] = {
					},
					["role"] = {
					},
					["pvptalent"] = {
					},
					["spec"] = {
					},
					["race"] = {
					},
					["encounter_ids"] = {
					},
					["affix"] = {
					},
				},
			}, -- [2]
			{
				["OptionsValues"] = {
				},
				["HooksTemp"] = {
				},
				["UID"] = "0x622bc8122a7529d",
				["Hooks"] = {
					["Initialization"] = "function(modTable)\n    local default = \"#00fbff\"\n    local affix = \"#C69B6D\"\n    \n    modTable.NpcColors = {\n        -- Grimrail Depot [DEPOT]\n        [81236] = default, -- Grimrail Technician\n        [81407] = default, -- Grimrail Bombardier\n        [80937] = default, -- Grom'kar Gunner\n        [88163] = default, -- Grom'kar Cinderseer\n        [82597] = default, -- Grom'kar Captain\n        -- Iron Docks [DOCKS]\n        [81603] = default, -- Champion Druna\n        [83025] = default, -- Grom'kar Battlemaster\n        [86526] = default, -- Grom'kar Chainmaster\n        [83026] = default, -- Siegemaster Olugar\n        [84028] = default, -- Siegemaster Rokra\n        -- Karazhan Lower [LOWER]\n        [114584] = default, -- Phantom Crew\n        [114628] = default, -- Skele] = default, \n        [114802] = default, -- Spectral Journeyman\n        -- Karazhan Upper [UPPER]\n        [114338] = default, -- Mana Confluence\n        [114249] = default, -- Volatile Energy\n        [115757] = default, -- Wrathguard Flamebringer\n        [115418] = default, -- Spider\n        [115488] = default, -- Infused Pyromancer\n        -- Mechagon Workshop [WORK]\n        [144293] = default, -- Waste Processing Unit\n        [144294] = default, -- Mechagon Tinkerer\n        [151325] = default, -- Alarm o Bot\n        [151657] = default, -- Bomb Tonk\n        -- Mechagon Junkyard [YARD]\n        [150146] = default, -- Scrapbone Shaman\n        [150160] = default, -- Scrapbone Bully\n        [150168] = default, -- Toxic Monstrosity\n        [150250] = default, -- Pistonhead Blaster\n        [150251] = default, -- Pistonhead Mechanic\n        [150292] = default, -- Mechagon Cavalry\n        [150297] = default, -- Mechagon Renormalizer\n        -- Tazavesh [TZ]\n        [178141] = default, -- Murkbrine Scalebinder\n        [179733] = default, -- Invigorating Fish Stick\n        [180431] = default, -- Focused Ritualist\n        [180433] = default, -- Wandering Pulsar\n        -- Affix Season 4\n        [189878] = affix, -- Nathrezim Infiltrator\n        [190174] = affix, -- Hypnosis Bat\n        [190128] = affix, -- Zul'gamux\n    }\n    function modTable.UpdateColor(unitFrame, envTable)\n        if not unitFrame or unitFrame.IsNpcWithoutHealthbar or unitFrame.IsFriendlyPlayerWithoutHealthbar then return end\n        -- Get color from modTable.NpcColors\n        local color = modTable.NpcColors [unitFrame.namePlateNpcId]\n        -- Set color from modTable.NpcColors\n        if (color) then\n            Plater.SetNameplateColor(unitFrame, color)\n        end\n    end\nend",
					["Nameplate Updated"] = "function (self, unitId, unitFrame, envTable, modTable)\n    modTable.UpdateColor (unitFrame, envTable)\nend",
				},
				["Time"] = 1661180206,
				["LoadConditions"] = {
					["talent"] = {
					},
					["group"] = {
					},
					["class"] = {
					},
					["map_ids"] = {
					},
					["role"] = {
					},
					["pvptalent"] = {
					},
					["spec"] = {
					},
					["race"] = {
					},
					["encounter_ids"] = {
					},
					["affix"] = {
					},
				},
				["Icon"] = 132276,
				["Enabled"] = true,
				["Revision"] = 54,
				["Options"] = {
				},
				["Author"] = "Luckyone-Laughing Skull",
				["Desc"] = "",
				["Prio"] = 1,
				["Name"] = "LuckyoneUI - Colors",
				["PlaterCore"] = 1,
				["LastHookEdited"] = "",
			}, -- [3]
		},
		["extra_icon_caster_outline"] = "OUTLINE",
		["auras_per_row_amount2"] = 6,
		["aura_width"] = 20,
		["castbar_target_shadow_color"] = {
			nil, -- [1]
			nil, -- [2]
			nil, -- [3]
			0, -- [4]
		},
		["pet_width_scale"] = 0.9999999403953552,
		["quick_hide"] = true,
		["extra_icon_timer_size"] = 11,
		["target_highlight_color"] = {
			nil, -- [1]
			0.6078431606292725, -- [2]
			0.6078431606292725, -- [3]
		},
		["extra_icon_stack_outline"] = "OUTLINE",
		["resources"] = {
			["scale"] = 1,
		},
		["click_space"] = {
			nil, -- [1]
			18, -- [2]
		},
		["castbar_target_font"] = "Expressway",
		["pet_height_scale"] = 0.9999999403953552,
		["aura_x_offset"] = 0,
		["first_run3"] = true,
		["bossmod_cooldown_text_size"] = 15,
		["ui_parent_scale_tune"] = 1,
		["ui_parent_buff_strata"] = "LOW",
		["health_statusbar_bgtexture"] = "Minimalist",
		["indicator_raidmark_anchor"] = {
			["y"] = 0.5,
			["x"] = 1,
		},
		["tank"] = {
			["colors"] = {
				["nocombat"] = {
					0.91, -- [1]
					0.12, -- [2]
					0.07, -- [3]
				},
			},
		},
		["aura_tracker"] = {
			["buff_tracked"] = {
				["321402"] = true,
				["322773"] = true,
				["333241"] = true,
				["327416"] = true,
				["322433"] = true,
				["333737"] = true,
				[297133] = true,
				["321754"] = true,
				["178658"] = true,
				[227931] = true,
				["326450"] = true,
				["331510"] = true,
				["343558"] = true,
				["327808"] = true,
				["209859"] = true,
				["317936"] = true,
				["326892"] = true,
				["333227"] = true,
				["344739"] = true,
				[233210] = true,
				["343502"] = true,
				["336451"] = true,
				[163689] = true,
				["336499"] = true,
				["343470"] = true,
				["330545"] = true,
				["340873"] = true,
				["226510"] = true,
			},
			["buff_banned"] = {
				["206150"] = true,
				["333553"] = true,
				["61574"] = true,
				["61573"] = true,
			},
		},
		["extra_icon_caster_font"] = "Expressway",
		["cast_statusbar_color"] = {
			0.02, -- [1]
			1, -- [2]
		},
		["update_throttle"] = 0.2499999850988388,
		["health_selection_overlay"] = "Minimalist",
		["indicator_extra_raidmark"] = false,
		["aura_sort"] = true,
		["extra_icon_timer_font"] = "Expressway",
		["target_highlight_alpha"] = 1,
		["ui_parent_base_strata"] = "LOW",
		["aura_timer_text_size"] = 10,
		["target_shady_enabled"] = false,
		["target_highlight_height"] = 12,
		["version"] = 13,
		["use_ui_parent"] = true,
		["cast_statusbar_bgcolor"] = {
			0.05, -- [1]
			0.05, -- [2]
			0.05, -- [3]
			0.8, -- [4]
		},
		["bossmod_aura_width"] = 30,
		["color_override_colors"] = {
			[3] = {
				0.91, -- [1]
				0.12, -- [2]
				0.07, -- [3]
			},
		},
		["health_selection_overlay_alpha"] = 1,
		["cast_statusbar_color_interrupted"] = {
			0.3, -- [1]
			0.3, -- [2]
			0.3, -- [3]
		},
		["range_check_in_range_or_target_alpha"] = 1,
		["ui_parent_buff_special_strata"] = "LOW",
		["number_region_first_run"] = true,
		["health_statusbar_bgcolor"] = {
			0.05, -- [1]
			0.05, -- [2]
			0.05, -- [3]
			0.8, -- [4]
		},
		["extra_icon_timer_outline"] = "OUTLINE",
		["castbar_target_anchor"] = {
			["x"] = 2,
			["side"] = 6,
		},
		["script_auto_imported"] = {
			["Unit - Important"] = 11,
			["Aura - Buff Alert"] = 13,
			["Cast - Very Important"] = 12,
			["Explosion Affix M+"] = 11,
			["Aura - Debuff Alert"] = 11,
			["Aura is Shield [P]"] = 1,
			["Cast - Castbar is Timer [P]"] = 2,
			["Cast - Ultra Important"] = 11,
			["Cast - Big Alert"] = 12,
			["Unit - Show Energy"] = 11,
			["Cast - Small Alert"] = 11,
			["Cast - Important Target [P]"] = 1,
			["Auto Set Skull"] = 11,
			["Spiteful Affix"] = 3,
			["Cast - Tank Interrupt"] = 12,
			["Unit - Main Target"] = 11,
			["Aura - Blink Time Left"] = 13,
			["Unit - Health Markers"] = 12,
			["Countdown"] = 11,
			["Fixate by Unit Buff [P]"] = 1,
			["Cast - Frontal Cone"] = 11,
			["Fixate"] = 11,
			["Cast - Glowing [P]"] = 2,
			["Cast - Alert + Timer [P]"] = 2,
			["Relics 9.2 M Dungeons"] = 2,
			["Fixate On You"] = 11,
		},
		["aura_alpha"] = 1,
		["cast_statusbar_spark_texture"] = "Interface\\AddOns\\Plater\\images\\spark8",
		["indicator_faction"] = false,
		["aura_show_enrage"] = true,
		["indicator_pet"] = false,
		["patch_version"] = 20,
		["indicator_rare"] = false,
		["indicator_raidmark_scale"] = 0.8999999761581421,
		}
	end

	-- Profile key
	PlaterDB["profileKeys"][E.mynameRealm] = name
end

-- Elvui profile
function azman:setup_elvui()
   if not E.db['movers'] then E.db['movers'] = {} end
   E.db["actionbar"]["bar1"]["buttonSize"] = 26
   E.db["actionbar"]["bar1"]["buttonSpacing"] = 1
   E.db["actionbar"]["bar1"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar1"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar1"]["countFontSize"] = 9
   E.db["actionbar"]["bar1"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar1"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar1"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar1"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar1"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar1"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar1"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar1"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar1"]["macroFontSize"] = 9
   E.db["actionbar"]["bar1"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar1"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar1"]["point"] = "TOPLEFT"
   E.db["actionbar"]["bar2"]["buttonSize"] = 30
   E.db["actionbar"]["bar2"]["buttonSpacing"] = 0
   E.db["actionbar"]["bar2"]["buttonsPerRow"] = 3
   E.db["actionbar"]["bar2"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar2"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar2"]["countFontSize"] = 9
   E.db["actionbar"]["bar2"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar2"]["enabled"] = true
   E.db["actionbar"]["bar2"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar2"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar2"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar2"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar2"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar2"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar2"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar2"]["macroFontSize"] = 9
   E.db["actionbar"]["bar2"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar2"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar2"]["macrotext"] = true
   E.db["actionbar"]["bar2"]["point"] = "TOPLEFT"
   E.db["actionbar"]["bar3"]["buttonSize"] = 30
   E.db["actionbar"]["bar3"]["buttonSpacing"] = 0
   E.db["actionbar"]["bar3"]["buttons"] = 12
   E.db["actionbar"]["bar3"]["buttonsPerRow"] = 3
   E.db["actionbar"]["bar3"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar3"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar3"]["countFontSize"] = 9
   E.db["actionbar"]["bar3"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar3"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar3"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar3"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar3"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar3"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar3"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar3"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar3"]["macroFontSize"] = 9
   E.db["actionbar"]["bar3"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar3"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar3"]["macrotext"] = true
   E.db["actionbar"]["bar3"]["point"] = "TOPLEFT"
   E.db["actionbar"]["bar4"]["backdrop"] = false
   E.db["actionbar"]["bar4"]["buttonSize"] = 30
   E.db["actionbar"]["bar4"]["buttonSpacing"] = 0
   E.db["actionbar"]["bar4"]["buttonsPerRow"] = 3
   E.db["actionbar"]["bar4"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar4"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar4"]["countFontSize"] = 9
   E.db["actionbar"]["bar4"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar4"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar4"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar4"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar4"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar4"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar4"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar4"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar4"]["macroFontSize"] = 9
   E.db["actionbar"]["bar4"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar4"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar4"]["macrotext"] = true
   E.db["actionbar"]["bar4"]["point"] = "TOPLEFT"
   E.db["actionbar"]["bar5"]["buttonSize"] = 30
   E.db["actionbar"]["bar5"]["buttonSpacing"] = 0
   E.db["actionbar"]["bar5"]["buttons"] = 12
   E.db["actionbar"]["bar5"]["buttonsPerRow"] = 3
   E.db["actionbar"]["bar5"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar5"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar5"]["countFontSize"] = 9
   E.db["actionbar"]["bar5"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar5"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar5"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar5"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar5"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar5"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar5"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar5"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar5"]["macroFontSize"] = 9
   E.db["actionbar"]["bar5"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar5"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar5"]["macrotext"] = true
   E.db["actionbar"]["bar5"]["point"] = "TOPLEFT"
   E.db["actionbar"]["bar6"]["buttonSize"] = 30
   E.db["actionbar"]["bar6"]["buttonSpacing"] = 0
   E.db["actionbar"]["bar6"]["buttonsPerRow"] = 3
   E.db["actionbar"]["bar6"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar6"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar6"]["countFontSize"] = 9
   E.db["actionbar"]["bar6"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar6"]["enabled"] = true
   E.db["actionbar"]["bar6"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar6"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar6"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar6"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar6"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar6"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar6"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar6"]["macroFontSize"] = 9
   E.db["actionbar"]["bar6"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar6"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar6"]["macrotext"] = true
   E.db["actionbar"]["bar6"]["point"] = "TOPLEFT"
   E.db["actionbar"]["bar7"]["buttonSize"] = 26
   E.db["actionbar"]["bar7"]["buttonSpacing"] = 1
   E.db["actionbar"]["bar7"]["buttonsPerRow"] = 3
   E.db["actionbar"]["bar7"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar7"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar7"]["countFontSize"] = 9
   E.db["actionbar"]["bar7"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar7"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar7"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar7"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar7"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar7"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar7"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar7"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar7"]["macroFontSize"] = 9
   E.db["actionbar"]["bar7"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar7"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar7"]["macrotext"] = true
   E.db["actionbar"]["bar7"]["point"] = "TOPLEFT"
   E.db["actionbar"]["bar8"]["buttonSize"] = 26
   E.db["actionbar"]["bar8"]["buttonSpacing"] = 1
   E.db["actionbar"]["bar8"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar8"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar8"]["countFontSize"] = 9
   E.db["actionbar"]["bar8"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar8"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar8"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar8"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar8"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar8"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar8"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar8"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar8"]["macroFontSize"] = 9
   E.db["actionbar"]["bar8"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar8"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar8"]["macrotext"] = true
   E.db["actionbar"]["bar9"]["buttonSize"] = 26
   E.db["actionbar"]["bar9"]["buttonSpacing"] = 1
   E.db["actionbar"]["bar9"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar9"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar9"]["countFontSize"] = 9
   E.db["actionbar"]["bar9"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar9"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar9"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar9"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar9"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar9"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar9"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar9"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar9"]["macroFontSize"] = 9
   E.db["actionbar"]["bar9"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar9"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar9"]["macrotext"] = true
   E.db["actionbar"]["bar10"]["buttonSize"] = 26
   E.db["actionbar"]["bar10"]["buttonSpacing"] = 1
   E.db["actionbar"]["bar10"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar10"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar10"]["countFontSize"] = 9
   E.db["actionbar"]["bar10"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar10"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar10"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar10"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar10"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar10"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar10"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar10"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar10"]["macroFontSize"] = 9
   E.db["actionbar"]["bar10"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar10"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar10"]["macrotext"] = true
   E.db["actionbar"]["bar13"]["buttonSize"] = 26
   E.db["actionbar"]["bar13"]["buttonSpacing"] = 1
   E.db["actionbar"]["bar13"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar13"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar13"]["countFontSize"] = 9
   E.db["actionbar"]["bar13"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar13"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar13"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar13"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar13"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar13"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar13"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar13"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar13"]["macroFontSize"] = 9
   E.db["actionbar"]["bar13"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar13"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar13"]["macrotext"] = true
   E.db["actionbar"]["bar14"]["buttonSize"] = 26
   E.db["actionbar"]["bar14"]["buttonSpacing"] = 1
   E.db["actionbar"]["bar14"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar14"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar14"]["countFontSize"] = 9
   E.db["actionbar"]["bar14"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar14"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar14"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar14"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar14"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar14"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar14"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar14"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar14"]["macroFontSize"] = 9
   E.db["actionbar"]["bar14"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar14"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar14"]["macrotext"] = true
   E.db["actionbar"]["bar15"]["buttonSize"] = 26
   E.db["actionbar"]["bar15"]["buttonSpacing"] = 1
   E.db["actionbar"]["bar15"]["countFont"] = "Expressway"
   E.db["actionbar"]["bar15"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar15"]["countFontSize"] = 9
   E.db["actionbar"]["bar15"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar15"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["bar15"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar15"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["bar15"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["bar15"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["bar15"]["macroFont"] = "Expressway"
   E.db["actionbar"]["bar15"]["macroFontOutline"] = "OUTLINE"
   E.db["actionbar"]["bar15"]["macroFontSize"] = 9
   E.db["actionbar"]["bar15"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["bar15"]["macroTextYOffset"] = 1
   E.db["actionbar"]["bar15"]["macrotext"] = true
   E.db["actionbar"]["barPet"]["backdrop"] = false
   E.db["actionbar"]["barPet"]["buttonSize"] = 26
   E.db["actionbar"]["barPet"]["buttonSpacing"] = 1
   E.db["actionbar"]["barPet"]["buttonsPerRow"] = 10
   E.db["actionbar"]["barPet"]["countFont"] = "Expressway"
   E.db["actionbar"]["barPet"]["countFontOutline"] = "OUTLINE"
   E.db["actionbar"]["barPet"]["countFontSize"] = 9
   E.db["actionbar"]["barPet"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["barPet"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["barPet"]["hotkeyFontSize"] = 8
   E.db["actionbar"]["barPet"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["barPet"]["hotkeyTextYOffset"] = 0
   E.db["actionbar"]["barPet"]["point"] = "TOPLEFT"
   E.db["actionbar"]["cooldown"]["override"] = false
   E.db["actionbar"]["countTextPosition"] = "BOTTOM"
   E.db["actionbar"]["countTextYOffset"] = 1
   E.db["actionbar"]["extraActionButton"]["clean"] = true
   E.db["actionbar"]["extraActionButton"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["extraActionButton"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["extraActionButton"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["extraActionButton"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["flyoutSize"] = 26
   E.db["actionbar"]["font"] = "Expressway"
   E.db["actionbar"]["fontOutline"] = "OUTLINE"
   E.db["actionbar"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["macroTextPosition"] = "BOTTOM"
   E.db["actionbar"]["microbar"]["buttonHeight"] = 26
   E.db["actionbar"]["microbar"]["buttonSize"] = 18
   E.db["actionbar"]["microbar"]["buttonSpacing"] = 1
   E.db["actionbar"]["microbar"]["enabled"] = true
   E.db["actionbar"]["microbar"]["mouseover"] = true
   E.db["actionbar"]["stanceBar"]["buttonHeight"] = 24
   E.db["actionbar"]["stanceBar"]["buttonSize"] = 26
   E.db["actionbar"]["stanceBar"]["buttonSpacing"] = 1
   E.db["actionbar"]["stanceBar"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["stanceBar"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["stanceBar"]["hotkeyFontSize"] = 9
   E.db["actionbar"]["stanceBar"]["hotkeyTextPosition"] = "TOPLEFT"
   E.db["actionbar"]["stanceBar"]["hotkeyTextYOffset"] = -1
   E.db["actionbar"]["stanceBar"]["mouseover"] = true
   E.db["actionbar"]["stanceBar"]["style"] = "classic"
   E.db["actionbar"]["transparent"] = true
   E.db["actionbar"]["vehicleExitButton"]["hotkeyFont"] = "Expressway"
   E.db["actionbar"]["vehicleExitButton"]["hotkeyFontOutline"] = "OUTLINE"
   E.db["actionbar"]["zoneActionButton"]["clean"] = true
   E.db["bags"]["autoToggle"]["guildBank"] = true
   E.db["bags"]["autoToggle"]["soulBind"] = false
   E.db["bags"]["bagSize"] = 30
   E.db["bags"]["bagWidth"] = 414
   E.db["bags"]["bankSize"] = 30
   E.db["bags"]["bankWidth"] = 414
   E.db["bags"]["clearSearchOnClose"] = true
   E.db["bags"]["countFont"] = "Expressway"
   E.db["bags"]["countFontOutline"] = "OUTLINE"
   E.db["bags"]["countFontSize"] = 11
   E.db["bags"]["itemInfoFont"] = "Expressway"
   E.db["bags"]["itemInfoFontOutline"] = "OUTLINE"
   E.db["bags"]["itemInfoFontSize"] = 11
   E.db["bags"]["itemLevelFont"] = "Expressway"
   E.db["bags"]["itemLevelFontOutline"] = "OUTLINE"
   E.db["bags"]["itemLevelFontSize"] = 11
   E.db["bags"]["moneyFormat"] = "BLIZZARD"
   E.db["bags"]["transparent"] = true
   E.db["bags"]["vendorGrays"]["enable"] = true
   E.db["chat"]["desaturateVoiceIcons"] = false
   E.db["chat"]["editBoxPosition"] = "ABOVE_CHAT_INSIDE"
   E.db["chat"]["editboxHistorySize"] = 5
   E.db["chat"]["enableCombatRepeat"] = false
   E.db["chat"]["fade"] = false
   E.db["chat"]["fadeTabsNoBackdrop"] = false
   E.db["chat"]["font"] = "Expressway"
   E.db["chat"]["fontOutline"] = "OUTLINE"
   E.db["chat"]["hideChatToggles"] = true
   E.db["chat"]["historySize"] = 200
   E.db["chat"]["keywords"] = "%MYNAME%"
   E.db["chat"]["lfgIcons"] = false
   E.db["chat"]["maxLines"] = 500
   E.db["chat"]["numScrollMessages"] = 2
   E.db["chat"]["panelColor"]["a"] = 0.9
   E.db["chat"]["panelColor"]["b"] = 0.05
   E.db["chat"]["panelColor"]["g"] = 0.05
   E.db["chat"]["panelColor"]["r"] = 0.05
   E.db["chat"]["panelHeight"] = 138
   E.db["chat"]["panelWidth"] = 414
   E.db["chat"]["showHistory"]["CHANNEL"] = false
   E.db["chat"]["showHistory"]["EMOTE"] = false
   E.db["chat"]["showHistory"]["GUILD"] = false
   E.db["chat"]["showHistory"]["INSTANCE"] = false
   E.db["chat"]["showHistory"]["PARTY"] = false
   E.db["chat"]["showHistory"]["RAID"] = false
   E.db["chat"]["showHistory"]["SAY"] = false
   E.db["chat"]["showHistory"]["YELL"] = false
   E.db["chat"]["tabFont"] = "Expressway"
   E.db["chat"]["tabFontOutline"] = "OUTLINE"
   E.db["chat"]["tabFontSize"] = 10
   E.db["chat"]["tabSelector"] = "NONE"
   E.db["chat"]["throttleInterval"] = 0
   E.db["convertPages"] = true
   E.db["databars"]["azerite"]["enable"] = false
   E.db["databars"]["experience"]["font"] = "Expressway"
   E.db["databars"]["experience"]["height"] = 138
   E.db["databars"]["experience"]["orientation"] = "VERTICAL"
   E.db["databars"]["experience"]["questCompletedOnly"] = true
   E.db["databars"]["experience"]["showBubbles"] = true
   E.db["databars"]["experience"]["width"] = 10
   E.db["databars"]["honor"]["enable"] = false
   E.db["databars"]["petExperience"]["enable"] = false
   E.db["databars"]["reputation"]["enable"] = true
   E.db["databars"]["reputation"]["font"] = "Expressway"
   E.db["databars"]["reputation"]["height"] = 161
   E.db["databars"]["reputation"]["orientation"] = "VERTICAL"
   E.db["databars"]["reputation"]["width"] = 10
   E.db["databars"]["threat"]["enable"] = false
   E.db["general"]["afkChat"] = false
   E.db["general"]["altPowerBar"]["font"] = "Expressway"
   E.db["general"]["altPowerBar"]["statusBar"] = "Minimalist"
   E.db["general"]["autoAcceptInvite"] = true
   E.db["general"]["autoRepair"] = "PLAYER"
   E.db["general"]["backdropcolor"]["b"] = 0.13
   E.db["general"]["backdropcolor"]["g"] = 0.13
   E.db["general"]["backdropcolor"]["r"] = 0.13
   E.db["general"]["backdropfadecolor"]["a"] = 0.9
   E.db["general"]["backdropfadecolor"]["b"] = 0.05
   E.db["general"]["backdropfadecolor"]["g"] = 0.05
   E.db["general"]["backdropfadecolor"]["r"] = 0.05
   E.db["general"]["bonusObjectivePosition"] = "AUTO"
   E.db["general"]["bottomPanel"] = false
   E.db["general"]["customGlow"]["color"]["a"] = 1
   E.db["general"]["customGlow"]["color"]["b"] = 1
   E.db["general"]["customGlow"]["color"]["g"] = 1
   E.db["general"]["customGlow"]["color"]["r"] = 1
   E.db["general"]["customGlow"]["style"] = "Autocast Shine"
   E.db["general"]["customGlow"]["useColor"] = true
   E.db["general"]["durabilityScale"] = 0.5
   E.db["general"]["enhancedPvpMessages"] = false
   E.db["general"]["font"] = "Expressway"
   E.db["general"]["fontSize"] = 11
   E.db["general"]["interruptAnnounce"] = "EMOTE"
   E.db["general"]["itemLevel"]["itemLevelFont"] = "Expressway"
   E.db["general"]["itemLevel"]["itemLevelFontSize"] = 11
   E.db["general"]["loginmessage"] = false
   E.db["general"]["lootRoll"]["buttonSize"] = 22
   E.db["general"]["lootRoll"]["spacing"] = 3
   E.db["general"]["lootRoll"]["statusBarTexture"] = "Minimalist"
   E.db["general"]["lootRoll"]["style"] = "fullbar"
   E.db["general"]["lootRoll"]["width"] = 340
   E.db["general"]["minimap"]["icons"]["classHall"]["scale"] = 0.6
   E.db["general"]["minimap"]["icons"]["difficulty"]["scale"] = 0.7
   E.db["general"]["minimap"]["icons"]["difficulty"]["xOffset"] = 1
   E.db["general"]["minimap"]["icons"]["difficulty"]["yOffset"] = 1
   E.db["general"]["minimap"]["locationFontSize"] = 11
   E.db["general"]["minimap"]["locationText"] = "SHOW"
   E.db["general"]["minimap"]["size"] = 153
   E.db["general"]["objectiveFrameHeight"] = 600
   E.db["general"]["talkingHeadFrameBackdrop"] = true
   E.db["general"]["talkingHeadFrameScale"] = 0.7
   E.db["general"]["totems"]["growthDirection"] = "HORIZONTAL"
   E.db["general"]["vehicleSeatIndicatorSize"] = 64
   E.db["movers"]["AlertFrameMover"] = "TOP,ElvUIParent,TOP,0,-178"
   E.db["movers"]["AltPowerBarMover"] = "TOP,UIParent,TOP,0,-18"
   E.db["movers"]["ArenaHeaderMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-243,-500"
   E.db["movers"]["BNETMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,1,140"
   E.db["movers"]["BelowMinimapContainerMover"] = "TOPRIGHT,UIParent,TOPRIGHT,-80,-207"
   E.db["movers"]["BossBannerMover"] = "TOP,ElvUIParent,TOP,0,-199"
   E.db["movers"]["BossButton"] = "BOTTOM,UIParent,BOTTOM,157,482"
   E.db["movers"]["BossHeaderMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-243,-500"
   E.db["movers"]["BuffsMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-157,-1"
   E.db["movers"]["ClassBarMover"] = "BOTTOM,ElvUIParent,BOTTOM,0,440"
   E.db["movers"]["DTPanelLuckyone_ActionBars_DTMover"] = "BOTTOMLEFT,UIParent,BOTTOMLEFT,427,0"
   E.db["movers"]["DTPanelLuckyone_MiniMap_DTMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-46,-141"
   E.db["movers"]["DebuffsMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-157,-110"
   E.db["movers"]["DurabilityFrameMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-1,-184"
   E.db["movers"]["ElvAB_1"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,427,11"
   E.db["movers"]["ElvAB_10"] = "TOPLEFT,ElvUIParent,TOPLEFT,1,-429"
   E.db["movers"]["ElvAB_13"] = "TOPLEFT,ElvUIParent,TOPLEFT,1,-402"
   E.db["movers"]["ElvAB_14"] = "TOPLEFT,ElvUIParent,TOPLEFT,1,-375"
   E.db["movers"]["ElvAB_15"] = "TOPLEFT,ElvUIParent,TOPLEFT,1,-348"
   E.db["movers"]["ElvAB_2"] = "BOTTOM,ElvUIParent,BOTTOM,-138,319"
   E.db["movers"]["ElvAB_3"] = "BOTTOM,ElvUIParent,BOTTOM,-46,319"
   E.db["movers"]["ElvAB_4"] = "BOTTOM,ElvUIParent,BOTTOM,46,319"
   E.db["movers"]["ElvAB_5"] = "BOTTOM,ElvUIParent,BOTTOM,138,319"
   E.db["movers"]["ElvAB_6"] = "BOTTOM,ElvUIParent,BOTTOM,-378,319"
   E.db["movers"]["ElvAB_7"] = "BOTTOM,UIParent,BOTTOM,-380,306"
   E.db["movers"]["ElvAB_8"] = "TOPLEFT,ElvUIParent,TOPLEFT,1,-483"
   E.db["movers"]["ElvAB_9"] = "TOPLEFT,ElvUIParent,TOPLEFT,1,-456"
   E.db["movers"]["ElvUF_FocusCastbarMover"] = "BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-604,501"
   E.db["movers"]["ElvUF_FocusMover"] = "BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-605,520"
   E.db["movers"]["ElvUF_PartyMover"] = "BOTTOMLEFT,UIParent,BOTTOMLEFT,665,301"
   E.db["movers"]["ElvUF_PetCastbarMover"] = "BOTTOM,UIParent,BOTTOM,-395,25"
   E.db["movers"]["ElvUF_PetMover"] = "BOTTOMLEFT,UIParent,BOTTOMLEFT,750,43"
   E.db["movers"]["ElvUF_PlayerCastbarMover"] = "BOTTOM,ElvUIParent,BOTTOM,0,462"
   E.db["movers"]["ElvUF_PlayerMover"] = "BOTTOM,ElvUIParent,BOTTOM,-304,440"
   E.db["movers"]["ElvUF_Raid1Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,1,140"
   E.db["movers"]["ElvUF_Raid2Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,1,140"
   E.db["movers"]["ElvUF_Raid3Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,1,140"
   E.db["movers"]["ElvUF_TargetCastbarMover"] = "BOTTOM,ElvUIParent,BOTTOM,304,421"
   E.db["movers"]["ElvUF_TargetMover"] = "BOTTOM,ElvUIParent,BOTTOM,304,440"
   E.db["movers"]["ElvUF_TargetTargetMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-577,460"
   E.db["movers"]["ElvUIBagMover"] = "BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-4,141"
   E.db["movers"]["ElvUIBankMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,1,140"
   E.db["movers"]["EventToastMover"] = "TOP,ElvUIParent,TOP,0,-117"
   E.db["movers"]["ExperienceBarMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,416,1"
   E.db["movers"]["GMMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-434,-1"
   E.db["movers"]["LeftChatMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,1,1"
   E.db["movers"]["LootFrameMover"] = "TOP,ElvUIParent,TOP,0,-155"
   E.db["movers"]["LossControlMover"] = "TOP,ElvUIParent,TOP,0,-490"
   E.db["movers"]["MawBuffsBelowMinimapMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,1,-28"
   E.db["movers"]["MicrobarMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,1,0"
   E.db["movers"]["MinimapMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-1,-1"
   E.db["movers"]["MirrorTimer1Mover"] = "TOP,ElvUIParent,TOP,0,-60"
   E.db["movers"]["MirrorTimer2Mover"] = "TOP,ElvUIParent,TOP,0,-79"
   E.db["movers"]["MirrorTimer3Mover"] = "TOP,ElvUIParent,TOP,0,-98"
   E.db["movers"]["ObjectiveFrameMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-80,-184"
   E.db["movers"]["PetAB"] = "BOTTOM,ElvUIParent,BOTTOM,-395,0"
   E.db["movers"]["PlayerChoiceToggle"] = "BOTTOM,UIParent,BOTTOM,0,369"
   E.db["movers"]["PowerBarContainerMover"] = "TOP,ElvUIParent,TOP,0,-39"
   E.db["movers"]["ReputationBarMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-416,1"
   E.db["movers"]["RightChatMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-1,1"
   E.db["movers"]["ShiftAB"] = "BOTTOM,UIParent,BOTTOM,0,4"
   E.db["movers"]["TalkingHeadFrameMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-2,140"
   E.db["movers"]["TooltipMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-427,0"
   E.db["movers"]["TopCenterContainerMover"] = "TOP,ElvUIParent,TOP,0,-39"
   E.db["movers"]["TorghastBuffsMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,4,-51"
   E.db["movers"]["TorghastChoiceToggle"] = "BOTTOM,UIParent,BOTTOM,0,548"
   E.db["movers"]["TotemTrackerMover"] = "BOTTOM,UIParent,BOTTOM,0,4"
   E.db["movers"]["UIErrorsFrameMover"] = "TOP,ElvUIParent,TOP,0,-117"
   E.db["movers"]["VOICECHAT"] = "TOPLEFT,ElvUIParent,TOPLEFT,1,-28"
   E.db["movers"]["VehicleLeaveButton"] = "BOTTOM,UIParent,BOTTOM,0,204"
   E.db["movers"]["VehicleSeatMover"] = "TOPLEFT,ElvUIParent,TOPLEFT,1,-79"
   E.db["movers"]["ZoneAbility"] = "BOTTOM,ElvUIParent,BOTTOM,-157,482"
   E.db["unitframe"]["colors"]["auraBarBuff"]["b"] = 0.7294117808342
   E.db["unitframe"]["colors"]["auraBarBuff"]["g"] = 0.54901963472366
   E.db["unitframe"]["colors"]["auraBarBuff"]["r"] = 0.95686280727386
   E.db["unitframe"]["colors"]["castClassColor"] = true
   E.db["unitframe"]["colors"]["healthclass"] = true
   E.db["unitframe"]["font"] = "Expressway"
   E.db["unitframe"]["fontOutline"] = "OUTLINE"
   E.db["unitframe"]["fontSize"] = 12
   E.db["unitframe"]["statusbar"] = "Minimalist"
   E.db["unitframe"]["units"]["boss"]["height"] = 32
   E.db["unitframe"]["units"]["boss"]["spacing"] = 16
   E.db["unitframe"]["units"]["boss"]["width"] = 190
   E.db["unitframe"]["units"]["focus"]["castbar"]["width"] = 241
   E.db["unitframe"]["units"]["focus"]["height"] = 40
   E.db["unitframe"]["units"]["focus"]["width"] = 240
   E.db["unitframe"]["units"]["party"]["debuffs"]["anchorPoint"] = "LEFT"
   E.db["unitframe"]["units"]["party"]["debuffs"]["countFont"] = "Expressway"
   E.db["unitframe"]["units"]["party"]["debuffs"]["sizeOverride"] = 32
   E.db["unitframe"]["units"]["party"]["debuffs"]["xOffset"] = 1
   E.db["unitframe"]["units"]["party"]["debuffs"]["yOffset"] = -1
   E.db["unitframe"]["units"]["party"]["groupBy"] = "ROLE"
   E.db["unitframe"]["units"]["party"]["growthDirection"] = "DOWN_RIGHT"
   E.db["unitframe"]["units"]["party"]["height"] = 35
   E.db["unitframe"]["units"]["party"]["horizontalSpacing"] = 1
   E.db["unitframe"]["units"]["party"]["orientation"] = "MIDDLE"
   E.db["unitframe"]["units"]["party"]["rdebuffs"]["enable"] = false
   E.db["unitframe"]["units"]["party"]["roleIcon"]["enable"] = false
   E.db["unitframe"]["units"]["party"]["verticalSpacing"] = 1
   E.db["unitframe"]["units"]["party"]["width"] = 190
   E.db["unitframe"]["units"]["player"]["RestIcon"]["enable"] = false
   E.db["unitframe"]["units"]["player"]["castbar"]["width"] = 366
   E.db["unitframe"]["units"]["player"]["classbar"]["detachFromFrame"] = true
   E.db["unitframe"]["units"]["player"]["classbar"]["detachedWidth"] = 366
   E.db["unitframe"]["units"]["player"]["classbar"]["height"] = 18
   E.db["unitframe"]["units"]["player"]["height"] = 40
   E.db["unitframe"]["units"]["player"]["width"] = 240
   E.db["unitframe"]["units"]["target"]["castbar"]["width"] = 240
   E.db["unitframe"]["units"]["target"]["debuffs"]["countYOffset"] = 14
   E.db["unitframe"]["units"]["target"]["height"] = 40
   E.db["unitframe"]["units"]["target"]["width"] = 240
   E.db["unitframe"]["units"]["targettarget"]["height"] = 20
   E.db["unitframe"]["units"]["targettarget"]["width"] = 278
end

-- Details profile
function azman:setup_details()
	if not IsAddOnLoaded('Details') then return end

	-- Profile name
	local name = "azman_00"

	-- Profile strings
	local retail = 'T336YTTrwc)S89JVAtQAKwChG7u7pOSKS1ejkVcYXBQYLGajbjrjqaoaGsMzRON99CP7gxiafLJTtMSCQjwKe9LtF6Z9ZPrFN(D3EN)Q8SzXjr4hlwK9uqyEuAyqEwsuq8KS07gFN)KWvLRZJcYJctW2Ta)7jq7xfLKmjSOe)YY4IjtdldXphUoN(BuAu(8n4NMgUmCEe8PY78ZHzzw4uy8tHrBK(D(WhgzC3iTJnWNVkjCtuEW0OYW4KIGNItNM9ebFtcbaf7W4W8GYOpJq1D((pSjjof(qXdWa5FwYJF4cCCctsc4XQaxvbZZZwVcxpRlG1cUutJxgwgNLwGGyE0QS8YaCXfaJ3dfytZJwM9iVYxgmlpBzqA4Yi8jlJHEVEza84CCMMKTCCyzqz8see1aSwsyrbHdlckwcn5o)lslJYNfoj6tdNo960IpDkVg)umIDk(e1LivZfquzwWtlYUZ)oF5CnljComjo4KebOI1P0AlAkUoWvhajLjr4pMonOikh6xWQWC4tiOpnAw46KYGXZbOojlhX8AdSa86tz5jtLlL4IGY8WIfyxw94QGWcbkeMKXzzpSmm)bAxiOi(xXfnmakuAaqCennaWsWy8yucohw235dFBYdbXLrldsIWFhgCIyGAp2kDBecdlxal8SKY4vWJGzcBitkuStQN40IYW0jawCzu66GjjXW8bOWSvreXSA)IWCPrpnzb81OuI6KqEfrjZeigezb00uJtxVkijBE26s8NRMMPXfHJtqCEEWI45lsG)JAcH8GbkDsyjWtvsKn04gmEJGpRmkCjXX0eVD3ittjwaMtgAkqEGPrJxpBgSHSoFfWm4plpokDAYMzXiRWuarLLhIlgMl1FEEeSUHPnlbqDWN2a8Sa7KKJeiYMIOnC1a9gOwqMiCDlwwjza(tqGfmEDzPGDzjWzKVjihG)roweWofb1K4LXLmXzfoQiAoSBuwqJgtMkhFEpLPSiwUva364X5rpgtieavi2egNN9qeZ3Jmd1g91RwLhvijxhPPyDq5cf3ncOOYwrm6DjnPSdY2WpljBHzh5Pdk3SkcPZ8txVmkpg6CqXMcKoUyZYXzjfOyVsGnDwwAzaYKt7xiri8OZZJ)1NV))AD40CyP8893EljjKHYIjlIwgs0Ynj8FkEAjSEmTHvKcfgUe4QbmSLwnCaZkaZxqWQmAItZYxYIR3C35hzRzyyBBRB7Qz6Qz7C3SJSGnTpF3OJg4QFSMM2axhBhdat90DN7A655A46PzyAQRBsTgEYc4jE6Admnn880CTnG9D4joe9dqHYtgIJ(mTyEcaDnnSFJmG)wITBrmX6QexsyvDuqgWNwUaOcMVqUjH8qXGCmKZc1nr0LexnSMxaSN0IggBM)hacyWXpdZdiBJKRzybBGZwNKmolFkq9WIQ0o2waka7Cq2mb4uJbvqOZZGonb6iXa(VwcQgCBcHnugFaPe9fLWxVlfbgWYkexPG2Kj5zOOeuHvD2euGesxfecYvsdwcYTJdqsSIY8405eRyqWtGSzuah3N6lxjARb(vafeqqA5agW40zz7YiaGXyYEUiPMYRqbvOpY0EjISjn1J5F4g5piu4DsR2v9ZRIYNae)vKlZI)mWMskFyj1DTrHKLRaWexw5KuzKijjAg)HXrLpHchfBMS5eGy8jpiuCYAWvAc6a2Am5sYqCY1QOsuYd6c7Lvd7r7QFA4KjaDzAzyYZ3)EqQg(LjBoUSCgQOCcjKIi4qkzG0DwreSCocT4ab9P5zRW1B)yffGj0ABG2PHIINkxKKvvcO657pjm)eIy657joRLztJsirmGyxGeJ(oyfgAmic(XtpjNKIbppk)TO(NJVcMeqRtvR)iAOXNo7)(9dh5FX1J0m(0PxF9Pdp1)tVbuufMNh(P3C9LNo8MBgE51V5d(hV0qoFHjRwekyH5XSg4Z)GQj6Yov1e5oIy17i3xNSUOemVJ1U8)GkC0)TJF(E6tM)g9hJFt2yq5qArsCj38k0MCuAVtx1G9JdISLydQrgKXV1MTMGlTo5azpEziOnjCgm2QFdn3beP0Kq9yxHftUmXk(xlCClLlqgF1aPOyAP5Mm1NgUtWX6eCGiK7RqyylZDPEophK)rAMvZx3WczPMsqJu2r1EaAIqdHmKLMkXgud7L5vHhO1kOXFmy58jYbSMCHIEKLTpcgedwh0DpF)pii4(BkkW)))yxmNVtqKiOH7aWWfALzP12toNSCS4CWcUOp9Hlos89lJlkp6DvDqsaT9CF6)w8KY1l7u05EtMBb(wbZqru7nN6YH3fU8CBlD00gthWQftnYyfB7ULOVnWdyAX8)JOdJKydD04jLEpIQuW51eeq7gBQNSdzYkP)353TK9A0T139ueBJrhMGHZ)hq5)fLbG9XRxnv4oHGJmc8qkSeqs(JUE0zOT)S6odMqtAe127H(rWkiUeGcW6ImaiwIWas1JwhrSmv2AW6Bjd8BUijBYy(WwIeob3IobTah(hh2ocezm6iduiwiBMxjA4BriaBWYAk54g1uK5drtaSxu5)xqvCayRjf7usBRyRa1jBaNt2aAABuhiR0pmWGA1yQv2EEv6q7ax9wbnutrP6gGdRS0uDDxhHavDJbwSm1JhORS7ndT7nLy1L2Rxt3vCkZiaF8XWK1uyeqQmyW3ZgAUVn0AFBO9(2qN9THU7Bd923goyFBiqQUVTCV3B037nh99E3rFV3E0339NYg0)sNG8m2YZdPluIGPDfgLlW1JIY4juy3kcOPOKNUzzyWeazdTadKnCN2L)IwUJ2N(uC5KfbO2uucBHWYMNIxrRpXJXWCWH1QTKkdPBIJCnrJJYJW2ZE2vtibUMMJEannopAchYb9Thnt1Oz6PMCW57hKIEah2j)UdchhdMggJbEWe)o4w2sX3GvLFjiNRamQ2p8razHMQhHQjbbnND7WlU0pW)2H3(b)tgEtW7V8dV9IrbVbmb(NKUW0FZE)PV3xfOdCG3DlVvftHBLH2axNN)I6QgIEIQcmYTsxYWh5ZgvRXF7nVOpi7C54F2BV6Sr3(7gq1)gdO82ZVxO04Rcuwk8VDpqRLncuWEyV6w8JQW4uJDe5iA(auGKmoETzQSumvAyymeH9ym(5I0WvVJc188k91oSCPAM43iUgaxSmEgGLzHBhYNgTooLbYS0KnCyuW5uguPARyouPKmMwHVscyCS)cONswVCRyFySKTD82Jxt0us84QytUZq2DURURRTRUJLMNgglor45wLfNctYLNDEROBwqICOWojcYJcHA6w7)Pm2NXbN7OPz5oyGTMPUJMdyunyzTfIA67jM99ewEEjg7taaV(JncJxafyAbDTdr7DKjNiO1ZJt7u6CZD49G4fhco0wYq9s4b4l35FEiOlOMGtcAbhrhJgSvMTQYwujICl9pn3ljIHjRZbBRPCJ1IEugtoz0BL6KAevZJmCf84LcLufySIBIgAsosrppRiEsy2FIJamVZteGnnAilLves50bTtb0QIyp2ZePpaa3AeO5ug4(sqAcG(IcewvRgWtQ5FHVsBF90vbqztNVXu79BITAuwCohhuPVyVGBC17wYtGTuQ(ThXIRXwV(XexgldQ7OFunz8cvn1JNZjz9jqm9QWvr5TrY15W7nW2rFEsgqS2GLsVglfgXOsLBMNdKja5LNNURNLJXahMMqUO8PO7Wz7djnQhapodhNBnW1ZEGUhizBGTHMftCsHyhWZyQ12Iwjzds4Rsij5eyTaoCXBUEK)NUy0pha0pXjb3cqcYR)c2CQCvw6bnLhl01(AoOkd)uNbJVTZ2TI8MHkxLSJIgc8Phn)SREV2C4apcW8UAwdCCDD0hyOHpYGzK1TmSmb3rnW)Zt77qQC2TLZ)FLm60YoLVl5X5VMsd)Dll83v8V2HriDjxOR4y1Nl2hcN1HWzDiCwFLcNfAYQ9a0FillhtDYgcBZVad)3kixDfjSxi2uFBJlwprY61gqS2rxFFI0)xECV2FNDoeHSdri7plri7qLXCOYyouzmhQmMdvgZHkJ5qLX8xUkJ57zkT(Qg37wjfRZSG1Bnf)7n9yMnti4(KESDL5R9k1zVI0J5nyGJMPM(addpxxlPJG)lv6XyK9p3rYm7iQP9MaTTtAv7SA1FoSED5gUDgV(kuryV6u89Tmjz)bfI96PbVN6u5qIE(6LONEoekFJY1J5UY1JjiCWY01yGoGVTKP4xqi6aBcMGSnOrUo1ienazlqVSmDGpXi3d565qUEoKRNd565qUEoKRNd565Vg56X4qUEoKRNd565qUEoKRNd565qUEoKRNd565qUEoKRNd565BtUES(Jpxpu0qnCq6BDndlv0qXP7vNxNZD8SSTC1nTCD1m9084KW0D2DC8mWyJyASv2DA)eZ(EYHS78NLS78NSGQFi7o)fo7owFzz3XZ20Wq31fKnzAzZNTttXrYt3Z0YWs3w32gPH(6riUTKKdVo2(696yB3gECijpFJsYtRWx(crXTR87STnp)EFJ086u7UFP95vRj9qsGoKeO)cNeODxsc7vgFE15r6FfYb0Ri)n7t2H60n0(msVhVCoK9Ndz)5plz)P3aa1k8l7FUn)JpYrDvur9(((QEak(k8c0HteCpfAtVXoQvem2rb5S)bjQpx4)xJah1vrgvl(r7rr)0xSf6RM(2v872riL2Nqw9niqsnRuQwvI3xNGd9hIp5hYg9HSrFiB0hYg9HSrFiB0hYg9F5YgDTC)CihpF9YXZELF5Vnz8PS9Dl1QhPLB77liIygWWOPteDuBegrEUh2kqs2QV4PFOv0DLH2vgxxbiBwPZvKYdMiTUA4MCkDCdg5pdLtPmqLWESoVAUsQCqPfG5iHmviNDeWMfrWw5sSCjsMilUsKaIyfkyxjbqETpjHuoGADeYpCRlpMVhYssINkOhex8tbafj4iAiZvS1vi24SIIoVBXa2)5luxqE8fgxJlko72DQ6ggtKAbqc0sPp1h5vtsRbVxEKoX9njjBnivMVP(QUX9ckdFiknafNUPCbgGs0THjG0Xe5nnMrTD9Axzv4(poUlqyfCkpc03oTfL6M6M)856Fb7bDt55J20MoxDrFjFB)ZxwyeBag1rdHXdeKXPfld)(I4OKPf8pWsIbzDeu(Upm62ZUPP4)JbToQeyyliNmifpFemB9IR7T9I2QZn2)DdVA4OAPirMHedlpnlhp3(MLRg(2ZE5U1CYE)z3UhZKPRCMOoD6nF4ItvDZ0fD20v2xRbw6wAoDV2U66r)uLenzxmDguVlhRwx4OsHqB4TV7NgDXBFxNaBFDdW6IacUpa6wOZBU(TFOcFwdLy0CW2Ev(Hr)0iq6Z2RZ(qOV)MloZ)29CU2cqF)WlhE6fJ6LASnEziiIbdIyVZNgOA2Z1YRBG9SrND1V07K1Mu5mylVj3IC72u03(aZ3H(yUVBETM2pm6T3C9hE)7VC4VuBIF5nIZ(5R)PADWwZCapju36NO2FxsdAohLQB90GIWhJOA0O2nsiimwfE0QsFyrw5KS8u8cimBfzuXTC8LyjAS1pnV4cn2(IfeS1y(8OC5LlO9w3RF4vvzbfbxln517j4)1QfGsQtK3PKKvo8vtkjpxne4VdAtk4aYiv(X3DJrtJj9qJZZcNI3ARn9sNuprrVfSyJV1mFIK9NnnJZHt40ysVGJig8vr(r033d4XrggYhpdJZeLv3A4PQBTr59yiGdwg(z59ajz7XTvk9TSRu6d8iSQUA2KVLMGJDKos7zk29T6sdWXUEsAkPXrwMBl8xsSBjAJN7wY5TKgzj5whqAKhEZzJgg8lND5Lkbr1nKtk6OB(el58kbT2c91vCHIwOz1w6EJjZEqFIXDDvSlsaJXdND55Qg5nqtFGK11q3wA0g)7T0Iz2c47se5XdKgaAlzsDn7sY9w2C3wy9wXxKr8V9MZoRA2C8CucEKd1aTTfMc7D66U19N9yyb6uz0TkPo6Dlz1rUZPl3yCh0LMqBj1NTEJ2n6SpC7ndVSlcMoKoAOOcK0E2UowTvDkPvgi31SeUqrUMHxTVG5XZlQFRV2mNZK0XO0nG9zu6CIkkWyfWr9NUgylxaopVilzkNp5ON6JFwhw4s(zt2etL4RvG0Yju0ijPAaieUKkPL0zXuM1NXsTyxTPP)FUgfunnQuKxd6kBgmcLdd1KWjlOXkflylqSBHmkvvYLdNmjkPU4)LOHYtcMUoDEenILTU4Hr7Z5BEy8t1U6HvxS192cw0fcB1mLDKJrn9J6dSn17qnzltogPB54wrn1w94XYg7WT2XSMAC7wQ9Bp0OZv7JDYqd13H1GTBRXoScOzBH1MxfhLQ1U9S4mSRwDstO07ggS2xhgG2AVllDB3ChNxHDXWGVR9UTBDnSHPHN(2yKT7YGDbpkZH8en3P3D8TARTR7UmNR9EtnI7oaKMgMnY2tFh0PBn0w7OXTgzdh7DGX3QXo7I8BRwxHquGHx)TENK2Brg6mOpA7TBRR2UaK2nVwR7xStBclDnJ(r6n52C17fYBHt01m7FZP1GA0lHAlYdSIW6hr3Aun3fr6w0DM7V)mayyVJnLwYNC03txyagCNDq83ExRI4)LCnDunMQT5tArcvsbmgdUBwQmapCnXvVAZwefsvrIQ(YBBNO0oDtv8ubNcgZP9FKRiXKyTIf989(OfiYGxYfhohz3MM642oXondwQRcaXR69GYW85ryCOmQLApe0)i323r)PSzNwj7HOMhYJsalkapY8XIxXVdxbXMH(aY(tXj1NDcAScl1t6ZXYWvwCUntJDvWARLtffXSYkBDLXFsZz54w7xSEmvfgvzH4KQbwetxA4jeJOIGQL1b)t4YswhPP9VKSy2LurbwOx7l3uRzuriVCzy60MuleETwPj6Wqs)bG(vC8HuaE)Ps3uTx2xULi8IQS7PaLgmEE1OwLudWHOlV8KRV(N(eLe(XzzpC07bJMpsxblIDolY)34Li6Ezu5ISPe5HaskMGjRxCmsqOXwZvKQ4JmTf(wjAROGMgNvs5AvbEvwAQF3522EAw2gMEgAEgM8BhrU8K8mnaTKggwEEanIPgxpTy5j564APBAP76AA7OpWKtNhLOpnW0bDxl7b4nff4cJOWLQyp3DomQbJ1ZoGxlpQ9KsDKLBB(eWgEWK)hJl3qHsxMTf23azSTXEGbBUKpAfij2UYwG0fa2fcHVpJLrXPE4PRcJb4ArvPOrUFeMqa00vf4(5xC6D48yw78E8cPRb8RQPRl1JUtr4YvOBDutnfzUjawLLuUV2DkCe0v3E97RvNCkN4WSYSbZdbkKGpsMDNZNTymfofvD6AuPiLIeGyRmg5PEet9cQHGdTKmtdgVykQ6mbqtJMfUoPmOEPDAVTZVZYXIaGpdhSFGZtYghEkxMfc6Q8OjCuZACYCqpFfU1Qo3ijXZaYuUQPykLKOhPsjLZfePHjE5socdK(fSuiXcglaJgj5i7QjXtd4YQCkl7uUBlQ(dzv2HN)imfuQyyIhg4OvyTzxjmrVQAvrf5IQ7RYH7QD7Mjgep6oFE1aTYik3uaQibO0fLmyWTV56t4dQt1Qb95nomjynWPXrBfXEyoGWAjeicNIMqSemLGpusJSq6kkzCGB8LrZXOmKGU9xg8pxhLVHi06BqiqMD2MfoaOpcFXNkdzSOaXxUgEEgG8n8CFYzd3veHyCYiE3gC014PAKHnvza7Zq2NRDc4On2gJcbp5sM5TYwx1C0zVu1iwJEv9Zn6uFsAQF3iwV9VUfsFWs3lSxlSiwWFHD7lAlPpCVAfv2hvjh1EygYxJRukXj(ck)jlcbM0P35)8)4OJE(EOfpF)tlIG)TCbyulp3pFp3mqLeWJ889yhPr4xbQ6wJWU6m28)g(Wy4liGanpojHMwA8IbEq5aXpVmRbqjun()daeOPaBlMAyyixTU857xaQlvJlOUzXZ3JXrS2KG)WKiE8zOimPiRrdkRb)CQyG5QqUiM(8)a7nsCbJ1mrdjM9NVhy3raM0MJaO4PNIpfgbrQBE((FqiLhSRZw7hF(Fiwuh30Casl2Z3)FsT6VZZlJeWrMKfbGaGEhhwc6gz7R)BiWirrfaWNwIiaw8jJnLgNaFdiHaOzEgU3GAg5gqaDwYuOBSwyeRbRUOWhHVqZGa8lZxhvd(7X4hAnGnvSiilGQH9aDyaujd7zrd8JzTHVvgRyuJPyqvH5vSg4SzblHKSNy0egIwI0f7A1uGjHP)jbfzZPeJMoSXIje0)KWZfBnqJLGC4(pUjAgcxdLp681Pu4Gl(HFumoGf2i9hQie3X(vKbzkTJKh9pxhJu0W(8)oOsoluS4Ekl)H6lblpTNVhgfRgutTsD1Xv0tq7)793o2uhUHkcV1frIDlbHxzu4sKxlbrTHfIhsk2u)8p0hHI4OtVru548y1KizbIowUMiAjYuA8LO6NcZtjctKZKoaj1Nn96ObHTAIEqeLzR5LNU2FNK6qzHK5VLcFQlIcelu0PCn6yVWex0zBH2P4Ijdhw63e13)RzyfJLSNK5YWe9fmsu)kybgIUJo4YNYHaWoPG8qWOTO0jOV(r5cFEFiAtrjAVsvvuPS2cpLcIJDyPsJZwg(bg8rNF5cCsWbyaQXfCOeuEPBs)Rb9V60)QjYunyDyEmFWhq3sxgM)qG6hr3AdbRWweLSs6be6WWhVy0Px)XakxLbxn8NUy0BXYm2NsRcVeegvog1qpMR94riSufmhYy)5yPbJd51)8z3m8YlpD4Tdd(4WBgrdjAs)v4bj76Roz4Tb3EXvNHtJiTBGo9uajoHv0kGjmVAbFye(hcKMuMJvtfMyiUkIQV4wNIUBuFL5F7nNn8QZuhkSZV4g4N(WiwxF3e2Ceru7GCEMUvAtXYGInPu66Pn(kdZjVgtaZlcWsqROz)itZFc1UcW0WFPQgfaoyYuaHT95HY6gSfLtjA5YDToltBrjrU5HfRWI4sHXzyX0ci4hIzFBvf)qJjw0wrTJPCXGC3PP9qOHqtLaZw9SbaHhIeQmbqVGeRx(4AkY(wtxNB6Cpv4bfti07jmMHDImmr(QAiV(z4L8elknkF(MkZ35D5BG9PZbPZB5S(3Sz8KAMtS1PG(7YSAP99AwVIclX3RzBi5)43rchtTVNZ23nIfuynwB7SkB0jBzGMmbFKR5Ap6sVY)E1j)OhNKWyFqUHHcjEdDol4tPK8nkb6BhfFt)ZsFmoplfdIcy3XLHpg(JKa72vo(qkGXBcUzXMm4dlc(5SKjHPzYx9ek3g9VkkjkQZXGQ(CWIVPbuD0msMHhQal8hUgnielbSE78hJcxb4ItaCRMR8vuHiCEBTwof2cq1j7E94VE2SmebkFrwGdNxhdNFcOvA3J1BWJ)fwr7VplUaGtnd5l9ckMYDmONdKhZx3ZWsBzbdZb0CuWvGGZROkZyJ8fKbHYh4mGlLg)lzBDv(ICvyE5g001tjYTFKd9PPJMRJH8vNbrh4ABYW2jjzztXTaSEGBbsToYEIZXcNUcSBIQiw(Q2qe8GowWjj9UNWl4RcNhpj4C0bYOCS9Q3kh4G601GcUw8J9tXTgzIohzmWg6VkopUu9(7ahZbEAgmT77WOra2PF2Nf2qtlctxBph17XdcTR5z4YDzigf3ecRnRC)rAHu3qS2Ss5jBGT1vg5tPvyCSzZxVQSOLqPNadNXCj5tvqEAkDAerJAQoiyP0PRItFHy4wHwbT1yvnayfP5lpBsJvsOMgUHm4vECZtXZOEivQ7ztM2ZPSqAF(KmWDwGDuyvoMNWcmkTyuNwVmLdUfz1K8TjbDM1segYJXsokTi(XOJqJ9O5u8dCuoLpLZXijWUK4j5Bqc5JHze4ljBulvXwxhRLsvsl9WSM1ayjWc2YMgREpxioTnf8bFMtsbDMdBDkCk5CaSmQ27EaoUW1YWcf0x5r1d3kZadwBVthLao9eHfVvusGCieQoW2ZNdGXn2OfNTCWVT8PTIDEZD7gDIIWtRPNMNfymLPYTcxLZIZl46kLTMwKPPM5gjM1vsDx9kDG(rhBDkNeOYmvwEuHeNFRhTKkkwdk7PbQxsx8PQhC14xZWtuMp(Yq4ezBOMKfGtyV59XM()e4gxOmVoU4s1wuTxWcg1QDom9l8PaMt1CdiQ7xbD9Dtxn6ObU6hRPPnW1XgZ8pFo398CnC9WK8PRtNNVVsNZD5RhQVryu9kmk(k)bpgw0GmUB0Q52y)xedB8AXW)XCxIjF9A1hI281GOn)kGOT6drR9kPK)Z1B1t5BNS(WZgDHN3huM6DQsfkJKErXyGFrPu9QUrelJBVy0VeC77U5SH32)MPH8)31M53GDL)iEDAu5oJsypN0vDhhptxll80wO00uxnBJ3ozC43ABZqLnnkLx3m8ItBO8Iukb6PEjTDuiHMYVIc5rNEVeIPSq82FPzrOxE3D)Vp'

	if E.Retail then
		_detalhes:ImportProfile(retail, name)
	end

	-- Apply the profile
	if _detalhes:GetCurrentProfileName() ~= name then
		_detalhes:ApplyProfile(name)
	end

	-- Load the profile on all characters
	_detalhes.always_use_profile = true
	_detalhes.always_use_profile_name = name
end

-- WarpDeplete Profile
function azman:setup_warpdeplete()
	if not IsAddOnLoaded('WarpDeplete') then return end

	-- Profile name
	local name = 'azman_00'

	-- Profile data
	WarpDepleteDB["profiles"][name] = WarpDepleteDB["profiles"][name] or {}
	WarpDepleteDB["profiles"][name] = {
		["objectivesFontSize"] = 11,
		["keyFontSize"] = 11,
		["bar2FontSize"] = 11,
		["timerFontSize"] = 22,
		["frameX"] = 2.000365018844605,
		["keyDetailsFontSize"] = 11,
		["bar3FontSize"] = 11,
		["bar1Texture"] = "Minimalist",
		["showPrideGlow"] = false,
		["bar3TextureColor"] = "ff0dff00",
		["bar2Texture"] = "Minimalist",
		["frameAnchor"] = "TOPRIGHT",
		["frameY"] = -176.0004425048828,
		["bar2TextureColor"] = "ff0052c0",
		["forcesOverlayTexture"] = "Minimalist",
		["bar1FontSize"] = 11,
		["forcesTexture"] = "Minimalist",
		["bar3Texture"] = "Minimalist",
		["forcesOverlayTextureColor"] = "fffc00ff",
		["deathsFontSize"] = 11,
		["forcesTextureColor"] = "ffffd82f",
		["bar1TextureColor"] = "ffe26800",
		["forcesFontSize"] = 11,
		["barWidth"] = 240,
	}

	-- Profile key
	WarpDepleteDB["profileKeys"][E.mynameRealm] = name

	print(L["WarpDeplete profile has been set."])
end

-- This is called in azman:Initialize()
function azman:RegisterEvents()
	azman:RegisterEvent('PLAYER_ENTERING_WORLD')
	azman:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', on_player_spec_changed)
end

function azman:PLAYER_ENTERING_WORLD(_, initLogin, isReload)
	azman:load_commands()
   azman:generate_macros()
   if not az_cvars then az_cvars = {} end
end


-- ACTIONBAR_SLOT_CHANGED
-- SPELL_PUSHED_TO_ACTIONBAR
-- SPELLBOOK_SPELL_NOT_ON_ACTION_BAR
--
