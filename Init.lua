local E, _, V, P, G = unpack(ElvUI)
local L = E.Libs.ACL:GetLocale('ElvUI', E.global.general.locale)
local EP = LibStub('LibElvUIPlugin-1.0')
local addon, Engine = ...

local _G = _G
local format = format
local GetAddOnMetadata = GetAddOnMetadata
local SetCVar = SetCVar

local azman = E:NewModule(addon, 'AceConsole-3.0', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

Engine[1] = azman -- azman
Engine[2] = E -- ElvUI Engine
Engine[3] = L -- ElvUI Locales
Engine[4] = V -- ElvUI PrivateDB
Engine[5] = P -- ElvUI ProfileDB
Engine[6] = G -- ElvUI GlobalDB
_G[addon] = Engine

-- Constants
azman.Config = {}
azman.CreditsList = {}
azman.DefaultFont = 'Expressway'
azman.DefaultTexture = 'Minimalist'
-- azman.Logo = 'Interface\\AddOns\\azman\\Media\\Textures\\Clover.tga'
azman.Name = '|cff4beb2cazman|r'
azman.RequiredVersion = 13.01
azman.Version = GetAddOnMetadata(addon, 'Version')

function azman:initialize()
	-- EP:RegisterPlugin(addon, azman.Config)
	azman:RegisterEvents()
end

local function callback_initialize()
	azman:initialize()
end

E:RegisterModule(addon, callback_initialize)
