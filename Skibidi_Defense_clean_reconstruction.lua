-- Global Deep Audit & Fixes Applied

if not game:IsLoaded() then
	game.Loaded:Wait()
end
if game.GameId ~= 4938220315 then
	return
end
-- Removed the external Kero-Hub bootstrap writer; macro/config persistence remains enabled.
-- Attribution validation
local Attribution = {
	Author = "Kero",
	OpenButton = "Skibidi Defense Hub",
	ToggleHint = "Hub opened | Press RightShift to hide."
}
do
	local function calculateAttributionHash(data)
		if type(data) ~= "string" then
			return nil
		end
		local count = 0
		for i = 1, # data do
			count = (count * 131 + string.byte(data, i)) % 10000019
		end
		return count
	end
	local function validateAttribution(data)
		if calculateAttributionHash(Attribution.Author) ~= 354808 or calculateAttributionHash(Attribution.OpenButton) ~= 7010519 or calculateAttributionHash(Attribution.ToggleHint) ~= 2144587 then
			return false
		end
		return not data or type(data.OpenButton) == "table" and calculateAttributionHash(data.Author) == 354808 and calculateAttributionHash(data.OpenButton.Title) == 7010519
	end
	function Attribution.Assert(data)
		if validateAttribution(data) then
			return true
		end
		Attribution.Stopped = true
		if Attribution.Cleanup then
			pcall(Attribution.Cleanup)
		end
		if Attribution.Window then
			pcall(function()
				Attribution.Window:Destroy()
			end)
		end
		error("Kero hub attribution check failed", 0)
	end
	function Attribution.Check(data)
		Attribution.Assert(data)
		Attribution.Options = data
		return data
	end
	function Attribution.Bind(data, options, callback, context)
		Attribution.Window = data
		Attribution.Cleanup = callback
		Attribution.Assert(Attribution.Options)
		if context and type(context.Notify) == "function" then
			pcall(function()
				context:Notify({
					Title = "Skibidi Defense Hub",
					Content = Attribution.ToggleHint,
					Duration = 3
				})
			end)
		end
		task.spawn(function()
			while not Attribution.Stopped and options() do
				Attribution.Assert(Attribution.Options)
				task.wait(1)
			end
		end)
		return data
	end
	Attribution.Assert()
end
-- Services and shared state
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local env = getgenv()
local previousHub = env.SkibidiDefenseHub
if previousHub and type(previousHub.Destroy) == "function" then
	pcall(previousHub.Destroy)
end
local Hub = {}
env.SkibidiDefenseHub = Hub
local State = {
	BlackScreen = false,
	Running = true,
	HideUser = false,
	AutoExecute = true,
	AntiAFK = true,
	HideName = false,
	FPSBoost = false,
	ReadyDelay = 1,
	SkipDelay = 0.35,
	StopAutoSkipAt = "",
	AutoKnockDoor = false,
	KnockMethod = "Walk",
	KnockWebhookEnabled = false,
	Recording = false,
	Playing = false,
	PlaybackEnabled = false,
	AutoPlaybackStarted = false,
	PlaybackFirstActionArmed = false,
	PlaybackFirstActionDone = false,
	AutoReady = false,
	AutoSkip = false,
	AutoReplay = false,
	AfterMatch = "None",
	AutoSkipCutscene = false,
	AutoSpeed = false,
	AutoMaxSpeed = false,
	SpeedScaleDelay = 1,
	AutoJoinMap = false,
	LobbyMode = "Story",
	LobbyChapter = "Chapter 1",
	LobbyModifiers = {},
	AutoBackLobby = false,
	MatchesBeforeLobby = 5,
	MatchesCompleted = 0,
	LastCountedJobId = "",
	PendingLobbyReturn = false,
	JoinRequested = false,
	WebhookEnabled = false,
	WebhookURL = "",
	WebhookMatchEnd = true,
	Speed = 1,
	PlaybackMode = "Hybrid",
	ProfileName = "",
	ProfileVersion = 6,
	Actions = {},
	RecordStartedAt = 0,
	NextHandle = 1,
	Connections = {},
	RecorderConnections = {},
	TowerMeta = setmetatable({}, {
		__mode = "k"
	}),
	RuntimeHandles = {},
	UsedRuntimeTowers = setmetatable({}, {
		__mode = "k"
	}),
	PendingAbilityClickAt = - math.huge,
	PendingAbilityIndex = 1
}
local MACRO_FOLDER = "SkibidiDefense_Macros"
local CONFIG_PATH = MACRO_FOLDER .. "/HubConfig.json"
local LEGACY_FOLDER = "Kero" .. "TTD_Macros"
local hasFileApi = type(isfolder) == "function" and type(makefolder) == "function" and type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
if hasFileApi and not isfolder(MACRO_FOLDER) then
	makefolder(MACRO_FOLDER)
end
if hasFileApi and type(listfiles) == "function" and isfolder(LEGACY_FOLDER) then
	for _, item2 in ipairs(listfiles(LEGACY_FOLDER)) do
		local matched = item2:match("([^\\/]+%.json)$")
		local matchedPath = matched and MACRO_FOLDER .. "/" .. matched
		if matchedPath and not isfile(matchedPath) then
			pcall(function()
				writefile(matchedPath, readfile(item2))
			end)
		end
	end
end
-- Remote references and game object discovery
local Remotes = {}
local LOBBY_PLACE_ID = 14279693118
local scriptedFolder
local towerData
local towerModels
local function bindMoneySync(remote)
	if State.MoneySyncRemote == remote and State.MoneySyncConnection then
		return
	end
	if State.MoneySyncConnection then
		State.MoneySyncConnection:Disconnect()
	end
	State.MoneySyncRemote, State.MoneySyncConnection = remote, nil
	State.ServerMoney, State.ServerMoneyAt = nil, nil
	if not remote then
		return
	end
	local ok2, result2 = pcall(function()
		return remote.OnClientEvent:Connect(function(data, options)
			if State.Running and State.MoneySyncRemote == remote and data == "Money" and tonumber(options) then
				State.ServerMoney = tonumber(options)
				State.ServerMoneyAt = os.clock()
				State.ServerMoneyVersion = (State.ServerMoneyVersion or 0) + 1
			end
		end)
	end)
	if ok2 and result2 then
		State.MoneySyncConnection = result2
		table.insert(State.Connections, result2)
	end
end
local function refreshRemotes()
	local event = ReplicatedStorage:FindFirstChild("Event")
	local game2 = ReplicatedStorage:FindFirstChild("Game")
	local gAMESTART = ReplicatedStorage:FindFirstChild("GAME_START")
	local events = ReplicatedStorage:FindFirstChild("Events")
	local value = game2 and game2:FindFirstChild("Speed")
	Remotes.Place = event and event:FindFirstChild("placeTower")
	Remotes.Upgrade = event and event:FindFirstChild("UpgradeTower")
	Remotes.Sell = event and event:FindFirstChild("RemoveTower")
	Remotes.Target = event and event:FindFirstChild("ChangeTowerTargetMode")
	local notification = ReplicatedStorage:FindFirstChild("Notification")
	Remotes.Notice = notification and notification:FindFirstChild("server")
	bindMoneySync(event and event:FindFirstChild("statUpdate"))
	Remotes.BoostSelect = ReplicatedStorage:FindFirstChild("BoostSelect")
	local towerScript = ReplicatedStorage:FindFirstChild("TowerScript")
	Remotes.Ability = towerScript and towerScript:FindFirstChild("spawnTowerAbility")
	Remotes.Skip = event and event:FindFirstChild("waveSkip")
	Remotes.Replay = event and event:FindFirstChild("ReplayCore")
	Remotes.Ready = gAMESTART and gAMESTART:FindFirstChild("readyButton")
	Remotes.Speed = value and value:FindFirstChild("Change")
	Remotes.CreateServer = events and events:FindFirstChild("createServer")
	Remotes.StartServer = events and events:FindFirstChild("start")
	Remotes.ModifierState = ReplicatedStorage:FindFirstChild("ModifierState")
	scriptedFolder = Workspace:FindFirstChild("Scripted")
	towerData = scriptedFolder and scriptedFolder:FindFirstChild("TowerData")
	towerModels = scriptedFolder and scriptedFolder:FindFirstChild("Towers")
end
local function remotesReady()
	refreshRemotes()
	return towerData ~= nil and towerModels ~= nil and Remotes.Place ~= nil and Remotes.Upgrade ~= nil and Remotes.Sell ~= nil and Remotes.Target ~= nil
end
refreshRemotes()
-- Runtime helpers and connection management
local function trackConnection(list, connection)
	table.insert(list or State.Connections, connection)
	return connection
end
local function disconnectAll(connections)
	for _, item in ipairs(connections) do
		pcall(function()
			item:Disconnect()
		end)
	end
	table.clear(connections)
end
local function waitUntil(predicate, timeout, interval)
	local value = os.clock() + (timeout or 5)
	interval = interval or 0.1
	repeat
		if not State.Running then
			return false
		end
		local ok2, result2 = pcall(predicate)
		if ok2 and result2 then
			return true, result2
		end
		task.wait(interval)
	until os.clock() >= value
	return false
end
-- Match state and HUD readers
local function getPlayerGui()
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end
local function getGameEndedGui()
	local value = getPlayerGui()
	return value and value:FindFirstChild("GameEnded")
end
local function isMatchEnded()
	local value = getGameEndedGui()
	local result = value and value:FindFirstChild("Frame")
	return value ~= nil and value.Enabled ~= false and result ~= nil and result.Visible ~= false
end
local function clickBackButton()
	if Hub.MatchFlow then
		return Hub.MatchFlow.ClickResult("back")
	end
	local value = getGameEndedGui()
	local result = value and value:FindFirstChild("Frame")
	local child = result and result:FindFirstChild("back")
	if not child or not child:IsA("GuiButton") then
		return false, "GameEnded.Frame.back was not found"
	end
	if type(getconnections) == "function" then
		local ok2, result2 = pcall(getconnections, child.MouseButton1Click)
		if ok2 and type(result2) == "table" then
			for _, item in ipairs(result2) do
				local ok3 = pcall(function()
					if type(item.Fire) == "function" then
						item:Fire()
					elseif type(item.Function) == "function" then
						item.Function()
					else
						error("Connection cannot be invoked")
					end
				end)
				if ok3 then
					return true
				end
			end
		end
	end
	if type(firesignal) == "function" then
		local ok4, result3 = pcall(firesignal, child.MouseButton1Click)
		if ok4 then
			return true
		end
		return false, tostring(result3)
	end
	return false, "Executor cannot invoke MouseButton1Click"
end
local function getMoney()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local value = leaderstats and leaderstats:FindFirstChild("Money")
	State.LastLeaderMoney = value and tonumber(value.Value) or 0
	local result = State.ServerMoney ~= nil and tonumber(State.ServerMoney) or State.LastLeaderMoney
	if result == - 9223372036854775808 or result == math.huge then
		return math.huge
	end
	if result ~= result or result == - math.huge then
		return 0
	end
	return result
end
local function formatMoney()
	local value = getMoney()
	if value == math.huge then
		return "Infinite"
	end
	if value % 1 ~= 0 then
		return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
	end
	return string.format("%.0f", value)
end
local function getWave()
	local value = getPlayerGui()
	local result = value and value:FindFirstChild("Data")
	local child = result and result:FindFirstChild("Wave")
	local element = child and child:FindFirstChild("Frame")
	local label = element and element:FindFirstChild("TextLabel")
	local textValue = label and label.Text or ""
	return tonumber(textValue:match("[Ww][Aa][Vv][Ee]%s*(%d+)")) or 0
end
local function getPlacementText()
	local value = getPlayerGui()
	local result = value and value:FindFirstChild("Towers")
	local child = result and result:FindFirstChild("Placement")
	local element = child and child:FindFirstChild("Frame")
	local label = element and element:FindFirstChild("TextLabel")
	return label and label.Text or "Units: ?/?"
end
local function getRuntimeText()
	local value = game.PlaceId == LOBBY_PLACE_ID and "Lobby" or "Wave " .. getWave()
	return value .. " | " .. State.PlaybackMode .. " | Cash: " .. formatMoney()
end
local function getSpeedMultiplier()
	local value = getPlayerGui()
	local result = value and value:FindFirstChild("Towers")
	local child = result and result:FindFirstChild("speedButton")
	local element = child and child:FindFirstChild("inner")
	local label = element and element:FindFirstChild("mult")
	local textValue = label and label.Text or ""
	return tonumber(textValue:match("(%d+)%s*[xX]"))
end
local hpLabel
local function getBaseHealthText()
	if hpLabel and hpLabel.Parent then
		return hpLabel.Text
	end
	local map = Workspace:FindFirstChild("Map")
	if not map then
		return "?/?"
	end
	for _, item in ipairs(map:GetDescendants()) do
		if item:IsA("TextLabel") and item.Name == "hp" and item.Parent and item.Parent.Name == "Frame" then
			hpLabel = item
			return item.Text
		end
	end
	return "?/?"
end
local function getMatchResult()
	local value = getGameEndedGui()
	if not value then
		return "Match Ended"
	end
	for _, item in ipairs(value:GetDescendants()) do
		if item:IsA("TextLabel") or item:IsA("TextButton") then
			local str = tostring(item.Text or "")
			local lowered = string.lower(str)
			if lowered:find("you have defeated", 1, true) or lowered:find("victory", 1, true) or lowered:find("you won", 1, true) then
				return "Victory"
			end
		end
	end
	for _, item3 in ipairs(value:GetDescendants()) do
		if item3:IsA("TextLabel") or item3:IsA("TextButton") then
			local lowered2 = string.lower(tostring(item3.Text or ""))
			if lowered2:find("defeat", 1, true) or lowered2:find("you lost", 1, true) or lowered2:find("game over", 1, true) then
				return "Defeat"
			end
		end
	end
	return "Match Ended"
end
local sendWebhookMessage, sendMatchEndReport
-- Macro profile storage
local function sanitizeProfileName(name)
	name = tostring(name or ""):gsub("[^%w%-%_]", "_")
	name = name:gsub("_+", "_")
	return name:sub(1, 48)
end
local function cframeToArray(cframe)
	return {
		cframe:GetComponents()
	}
end
local function arrayToCFrame(components)
	if type(components) ~= "table" or # components < 12 then
		return nil
	end
	return CFrame.new(table.unpack(components, 1, 12))
end
local function profilePath(name)
	return MACRO_FOLDER .. "/" .. sanitizeProfileName(name) .. ".json"
end
local function saveProfile(name)
	name = sanitizeProfileName(name)
	if name == "" then
		return false, "Profile name is empty"
	end
	if not hasFileApi then
		return false, "Executor filesystem APIs are unavailable"
	end
	local records = {
		Version = 6,
		Game = "Skibidi Defense",
		Universe = game.GameId,
		PlaceId = game.PlaceId,
		Name = name,
		RecordedAt = os.time(),
		Actions = State.Actions,
		Loadout = State.MacroLoadout
	}
	local ok2, result2 = pcall(HttpService.JSONEncode, HttpService, records)
	if not ok2 then
		return false, result2
	end
	writefile(profilePath(name), result2)
	State.ProfileName = name
	State.ProfileVersion = 6
	return true
end
local function loadProfile(name)
	name = sanitizeProfileName(name)
	if name == "" or not hasFileApi or not isfile(profilePath(name)) then
		return false, "Profile not found"
	end
	local ok2, result2 = pcall(function()
		return HttpService:JSONDecode(readfile(profilePath(name)))
	end)
	if not ok2 or type(result2) ~= "table" or type(result2.Actions) ~= "table" then
		return false, "Invalid profile file"
	end
	State.ProfileName = name
	State.ProfileVersion = tonumber(result2.Version) or 1
	State.Actions = result2.Actions
	State.MacroLoadout = Hub.MatchFlow and Hub.MatchFlow.ValidateLoadout(result2.Loadout) or nil
	return true
end
local function listProfiles()
	if not hasFileApi or type(listfiles) ~= "function" then
		return {}
	end
	local records = {}
	for _, item in ipairs(listfiles(MACRO_FOLDER)) do
		local matched2 = item:match("([^\\/]+)%.json$")
		if matched2 and matched2 ~= "HubConfig" then
			table.insert(records, matched2)
		end
	end
	table.sort(records)
	return records
end
-- Interface state and recorder bookkeeping
local UI = {}
local function setStatus(status, detail)
	State.Status, State.StatusDetail = status, detail or ""
	if UI.Status then
		local value = "State: " .. tostring(status)
		if UI.LastStatusTitle ~= value then
			UI.LastStatusTitle = value
			UI.Status:SetTitle(value)
		end
		if UI.LastStatusDetail ~= State.StatusDetail then
			UI.LastStatusDetail = State.StatusDetail
			UI.Status:SetDesc(State.StatusDetail)
		end
	end
end
local function updateActionSummary()
	if not UI.ActionSummary then
		return
	end
	UI.ActionSummary:SetTitle(string.format("Recorded actions: %d", # State.Actions))
	UI.ActionSummary:SetDesc(State.Playing and string.format("Playback: %d/%d", State.PlaybackIndex or 0, # State.Actions) or string.format("Selected macro: %s | %d actions", State.ProfileName ~= "" and State.ProfileName or "None", # State.Actions))
end
local function pushAction(action)
	if Hub.MatchFlow then
		Hub.MatchFlow.UpdateRecorderClock()
	end
	action.Wave = action.Wave or getWave()
	action.RecordedAt = action.RecordedAt or os.clock() - State.RecordStartedAt
	table.insert(State.Actions, action)
	updateActionSummary()
	setStatus("Recording", string.format("Captured %s at wave %d", action.Type, action.Wave))
end
local function queueTowerAction(meta, action)
	if Hub.MatchFlow then
		Hub.MatchFlow.UpdateRecorderClock()
	end
	action.Wave = getWave()
	action.RecordedAt = action.RecordedAt or os.clock() - State.RecordStartedAt
	if meta.PlaceRecorded then
		pushAction(action)
	else
		meta.PendingActions = meta.PendingActions or {}
		table.insert(meta.PendingActions, action)
	end
end
-- Ability metadata and input recording
local function isTruthyState(data)
	return data == true or type(data) == "number" and data > 0
end
local function abilityStateChanged(data, options, callback)
	return options ~= data and (isTruthyState(options) or callback and data == nil and options == 0)
end
local function isModeMarker(data)
	return data == "SwitchModeState" or data == "AttackMode"
end
local function getGameClock()
	local game2 = ReplicatedStorage:FindFirstChild("Game")
	local value = game2 and game2:FindFirstChild("Clock")
	local result = value and tonumber(value.Value)
	if result and result == result and result >= 0 and result < math.huge then
		return result, "Game"
	end
	return os.clock(), "Real"
end
local function recorderTrace(data, options)
	local recorderTrace2 = State.RecorderTrace
	if not recorderTrace2 then
		return
	end
	if # recorderTrace2 >= 400 then
		State.RecorderTraceDropped = (State.RecorderTraceDropped or 0) + 1
		return
	end
	table.insert(recorderTrace2, {
		At = os.clock() - State.RecordStartedAt,
		Type = data,
		Data = options
	})
end
local function sanitizeTraceValue(data)
	if type(data) == "number" then
		return data == data and math.abs(data) ~= math.huge and data or tostring(data)
	end
	if type(data) == "string" then
		return data:sub(1, 250)
	end
	if type(data) == "boolean" or data == nil then
		return data
	end
	return tostring(data)
end
local function parseCost(data)
	local value = tostring(data or ""):gsub("<[^>]+>", ""):gsub(",", ""):gsub("%s", "")
	local value, value1 = value:upper():match("%$?(%d+%.?%d*)([KMBT]?)")
	return (tonumber(value) or 0) * (({
		K = 1e3,
		M = 1e6,
		B = 1e9,
		T = 1e12
	})[value1] or 1)
end
local function readAbilityCard(data, options)
	local value = data
	for _ = 1, 12 do
		if not value then
			return nil
		end
		if value.Parent and value.Parent.Name == "Abilities" then
			break
		end
		value = value.Parent
	end
	if not value or not value.Parent or value.Parent.Name ~= "Abilities" then
		return nil
	end
	local title, cost = value:FindFirstChild("Title"), value:FindFirstChild("Cost")
	if not title or not cost then
		return nil
	end
	if not (title:IsA("TextLabel") or title:IsA("TextButton")) or not (cost:IsA("TextLabel") or cost:IsA("TextButton")) then
		return nil
	end
	local result = value
	while result do
		if not options and result:IsA("GuiObject") and not result.Visible then
			return nil
		end
		if not options and result:IsA("ScreenGui") and not result.Enabled then
			return nil
		end
		result = result.Parent
	end
	local child = tostring(title.Text):gsub("<[^>]+>", "")
	if child == "" or child == "..." then
		return nil
	end
	local element = ({
		["Switch Mode"] = "SwitchModeState",
		["Attack Mode Switch"] = "AttackMode"
	})[child] or "ATTACK" .. child:gsub("%s+", "")
	local locked = value:FindFirstChild("Locked")
	local label = locked and locked:FindFirstChild("Frame")
	local textValue = label and label:IsA("TextLabel") and tonumber(tostring(label.Text):match("([%d%.]+)")) or nil
	local indexValue = tonumber(value:GetAttribute("AbilityIndex")) or tonumber(value.Name:match("(%d+)$"))
	if not indexValue then
		local records = {}
		for index, item in ipairs(value.Parent:GetChildren()) do
			if item:IsA("GuiObject") and (options or item.Visible) and item:FindFirstChild("Title") and item:FindFirstChild("Cost") then
				table.insert(records, {
					Object = item,
					Order = index,
					Layout = item.LayoutOrder
				})
			end
		end
		table.sort(records, function(callback, context)
			return callback.Layout == context.Layout and callback.Order < context.Order or callback.Layout < context.Layout
		end)
		for index2, item3 in ipairs(records) do
			if item3.Object == value then
				indexValue = index2
				break
			end
		end
	end
	return {
		Card = value,
		Title = child,
		Marker = element,
		Index = indexValue or 1,
		Cost = parseCost(cost.Text),
		Cooldown = textValue,
		CooldownFloor = element == "AttackMode" and 5 or nil,
		At = os.clock()
	}
end
local function onAbilityCardClicked(data)
	local value = readAbilityCard(data)
	if not value then
		return
	end
	local pendingAbility = State.PendingAbility
	if pendingAbility and pendingAbility.Card == value.Card and value.At - pendingAbility.At < 0.1 then
		return
	end
	State.PendingAbility = value
	recorderTrace("ability_input", {
		Title = value.Title,
		Index = value.Index,
		GuessedMarker = value.Marker,
		Cost = value.Cost
	})
end
local function resolveAbilityCard(data)
	local pendingAbility = State.PendingAbility
	if pendingAbility and os.clock() - pendingAbility.At <= 12 and pendingAbility.Marker == data then
		return pendingAbility
	end
	local value = getPlayerGui()
	if value then
		for _, item in ipairs(value:GetDescendants()) do
			if item.Name == "Title" then
				local ok2, result2 = pcall(readAbilityCard, item, true)
				if ok2 and result2 and result2.Marker == data then
					return result2
				end
			end
		end
	end
	if data == "ATTACKSoundBlast" then
		return {
			Title = "SoundBlast",
			Index = 1,
			Cost = 2500000,
			Cooldown = 3.2
		}
	end
	if data == "SwitchModeState" then
		return {
			Title = "Switch Mode",
			Index = 1,
			Cost = 1000000
		}
	end
	if data == "AttackMode" then
		return {
			Title = "Attack Mode Switch",
			Index = 1,
			Cost = 1000,
			CooldownFloor = 5
		}
	end
end
local function sampleAbilityCooldown(data)
	if data.Session ~= State.RecordSession then
		return
	end
	local card = data.Card
	local value = card and card:FindFirstChild("Title")
	local result = card and card:FindFirstChild("Locked")
	local child = result and result:FindFirstChild("Frame")
	if not value or tostring(value.Text):gsub("<[^>]+>", "") ~= data.Action.AbilityName or not result or not result.Visible or not child or not child:IsA("TextLabel") then
		return
	end
	local num = tonumber(tostring(child.Text):match("^%s*(%d+%.?%d*)s%s*$"))
	if not num or num <= 0 or num > 3600 then
		return
	end
	local value, value1 = getGameClock()
	local element = value1 == data.Kind and value - data.At or os.clock() - data.RealAt
	local label = math.ceil((num + math.max(0, element)) * 10) / 10
	if label > (data.Action.Cooldown or 0) then
		data.Action.Cooldown = label
		recorderTrace("ability_cooldown", {
			Marker = data.Action.Marker,
			Seconds = label
		})
	end
end
Hub.RecordAbilityAction = function(data, options, callback, context)
	if not State.Recording or not towerData then
		return false
	end
	local value = typeof(data) == "Instance" and data or towerData:FindFirstChild(tostring(data or ""))
	local result = value and State.TowerMeta[value]
	if not result then
		return false
	end
	local child = context and context.CapturedIntent or State.SkillIntents and State.SkillIntents[tostring(value.Name)]
	if child and not child.Rejected and child.Session == State.RecordSession and os.clock() - child.At <= 12 then
		options = child.Index
		context = context or {}
		context.RecordedAt = child.RecordedAt
		context.RemoteIntent = true
		child.Marker = callback or child.Marker
	else
		child = nil
	end
	local now = os.clock()
	local lastAbilityAction = result.LastAbilityAction
	if lastAbilityAction and (child and result.LastAbilityIntent == child or not child and lastAbilityAction.Marker == (callback and tostring(callback) or nil) and now - (result.LastAbilityRecordedAt or - math.huge) <= 0.35) then
		lastAbilityAction.AbilityIndex = tonumber(options) or lastAbilityAction.AbilityIndex or 1
		if context and context.RecordedAt then
			lastAbilityAction.RecordedAt = context.RecordedAt
		end
		if callback and tostring(callback) ~= "" then
			lastAbilityAction.Marker = tostring(callback)
		end
		if context and isModeMarker(callback) and lastAbilityAction.ExpectedState == nil then
			lastAbilityAction.ExpectedState = context.ConfirmedValue or value:GetAttribute(callback)
			lastAbilityAction.FromState = context.PreviousValue
		end
		result.LastAbilityRecordedAt = now
		updateActionSummary()
		return true
	end
	local records = {
		Type = "Ability",
		Handle = result.Handle,
		AbilityIndex = tonumber(options) or 1,
		Marker = callback and tostring(callback) or nil,
		RecordedAt = context and context.RecordedAt,
		CaptureSource = context and context.RemoteIntent and "Remote" or nil
	}
	result.LastAbilityAction = records
	result.LastAbilityIntent = child
	result.LastAbilityRecordedAt = now
	if context then
		records.AbilityName = context.Title
		records.EstimatedCost = context.Cost
		records.Cooldown = math.max(tonumber(context.Cooldown) or 0, tonumber(context.CooldownFloor) or 0)
		records.RequiredLevel = tonumber(value:GetAttribute("Upgrade")) or 0
		if isModeMarker(callback) then
			records.ExpectedState = context.ConfirmedValue or value:GetAttribute(callback)
			records.FromState = context.PreviousValue
		end
	end
	queueTowerAction(result, records)
	if context and context.Card then
		local value, value1 = getGameClock()
		local copiedData = {
			Action = records,
			Card = context.Card,
			At = value,
			Kind = value1,
			RealAt = os.clock(),
			Session = State.RecordSession
		}
		State.RecordCooldownSamples = State.RecordCooldownSamples or {}
		table.insert(State.RecordCooldownSamples, copiedData)
		for _, item in ipairs({
			.25,
			.75
		}) do
			task.delay(item, function()
				if State.Recording and State.RecordSession == copiedData.Session then
					pcall(sampleAbilityCooldown, copiedData)
				end
			end)
		end
	end
	recorderTrace("ability_recorded", {
		Handle = result.Handle,
		Marker = callback,
		Index = options
	})
	return true
end
Hub.RecordBoostLinkAction = function(data, options)
	if not State.Recording or not towerData then
		return false
	end
	local value = typeof(data) == "Instance" and data or towerData:FindFirstChild(tostring(data or ""))
	local result = typeof(options) == "Instance" and options or towerData:FindFirstChild(tostring(options or ""))
	local child = value and State.TowerMeta[value]
	local element = result and State.TowerMeta[result]
	if not child or not element or value == result then
		return false
	end
	if not child.PlaceRecorded or not element.PlaceRecorded then
		if element.PendingBoostSourceHandle == child.Handle then
			return true
		end
		element.PendingBoostSourceHandle = child.Handle
		task.spawn(function()
			local label = waitUntil(function()
				return not State.Recording or child.PlaceRecorded and element.PlaceRecorded
			end, 3, 0.03)
			if element.PendingBoostSourceHandle == child.Handle then
				element.PendingBoostSourceHandle = nil
			end
			if label and State.Recording and value.Parent == towerData and result.Parent == towerData then
				Hub.RecordBoostLinkAction(value, result)
			end
		end)
		return true
	end
	local now = os.clock()
	local textValue = State.BoostIntents and State.BoostIntents[tostring(result.Name)]
	local indexValue = textValue and textValue.Session == State.RecordSession and textValue.Source == tostring(value.Name) and now - textValue.At <= 12 and textValue.RecordedAt or nil
	if element.LastBoostSourceHandle == child.Handle and now - (element.LastBoostRecordedAt or - math.huge) <= 0.5 then
		return true
	end
	element.LastBoostSourceHandle = child.Handle
	element.LastBoostRecordedAt = now
	pushAction({
		Type = "BoostLink",
		SourceHandle = child.Handle,
		TargetHandle = element.Handle,
		RecordedAt = indexValue
	})
	return true
end
local function clearLegacyAbilityHook()
	local keroSkibidiAbilityHook = env.KeroSkibidiAbilityHook
	if type(keroSkibidiAbilityHook) == "table" then
		keroSkibidiAbilityHook.Callback = nil
		keroSkibidiAbilityHook.Remote = nil
	end
	env.KeroSkibidiAbilityHook = nil
end
clearLegacyAbilityHook()
local function installSkillRouter()
	State.SkillIntents, State.BoostIntents = {}, {}
	local keroSkibidiSkillRouter = env.KeroSkibidiSkillRouter
	if not keroSkibidiSkillRouter then
		keroSkibidiSkillRouter = {
			Bypass = setmetatable({}, {
				__mode = "k"
			})
		}
		env.KeroSkibidiSkillRouter = keroSkibidiSkillRouter
	end
	keroSkibidiSkillRouter.Ability, keroSkibidiSkillRouter.Boost = Remotes.Ability, Remotes.BoostSelect
	keroSkibidiSkillRouter.Begin = function(data, options, callback)
		if not State.Running or not State.Recording or State.Playing then
			return
		end
		if type(options) ~= "string" and type(options) ~= "number" then
			return
		end
		if data == "Ability" and (type(callback) ~= "number" or callback < 1 or callback % 1 ~= 0) then
			return
		end
		if data == "Boost" and type(callback) ~= "string" and type(callback) ~= "number" then
			return
		end
		local now = os.clock()
		local records = {
			At = now,
			RecordedAt = math.max(0, now - State.RecordStartedAt),
			Session = State.RecordSession,
			Id = tostring(options),
			Index = callback,
			Source = tostring(options)
		}
		if data == "Ability" then
			State.SkillIntents[records.Id] = records
		else
			State.BoostIntents[tostring(callback)] = records
		end
		return records
	end
	keroSkibidiSkillRouter.Finish = function(data, options)
		if not data then
			return
		end
		if options == false then
			data.Rejected = true
		end
		if options ~= true then
			return
		end
		task.defer(function()
			if not State.Recording or State.RecordSession ~= data.Session then
				return
			end
			local value = towerData and towerData:FindFirstChild(data.Id)
			local result = value and State.TowerMeta[value]
			if not result then
				return
			end
			local lastAbilityAction = result.LastAbilityAction
			if lastAbilityAction and result.LastAbilityIntent == data then
				lastAbilityAction.AbilityIndex = data.Index
				lastAbilityAction.RecordedAt = data.RecordedAt
				lastAbilityAction.CaptureSource = "Remote"
				return
			end
			local pendingAbility = State.PendingAbility
			if not pendingAbility or os.clock() - pendingAbility.At > 3 then
				pendingAbility = nil
			end
			Hub.RecordAbilityAction(value, data.Index, data.Marker or pendingAbility and pendingAbility.Marker, {
				Title = pendingAbility and pendingAbility.Title,
				Cost = pendingAbility and pendingAbility.Cost,
				Card = pendingAbility and pendingAbility.Card,
				Cooldown = pendingAbility and pendingAbility.Cooldown,
				RecordedAt = data.RecordedAt,
				RemoteIntent = true,
				CapturedIntent = data
			})
		end)
	end
	if keroSkibidiSkillRouter.Installed then
		return
	end
	local function helperFunction(data, self, ...)
		local value = coroutine.running()
		if keroSkibidiSkillRouter.Bypass[value] then
			return data(self, ...)
		end
		local result = self == keroSkibidiSkillRouter.Ability and "Ability" or self == keroSkibidiSkillRouter.Boost and "Boost" or nil
		if not result then
			return data(self, ...)
		end
		local ok2, result2 = pcall(keroSkibidiSkillRouter.Begin, result, ...)
		if not ok2 or not result2 then
			return data(self, ...)
		end
		keroSkibidiSkillRouter.Bypass[value] = true
		keroSkibidiSkillRouter.Pending = (keroSkibidiSkillRouter.Pending or 0) + 1
		local result3 = table.pack(pcall(data, self, ...))
		keroSkibidiSkillRouter.Bypass[value] = nil
		if result3[1] and result == "Ability" then
			pcall(keroSkibidiSkillRouter.Finish, result2, result3[2])
		end
		keroSkibidiSkillRouter.Pending = keroSkibidiSkillRouter.Pending - 1
		if not result3[1] then
			error(result3[2], 0)
		end
		return table.unpack(result3, 2, result3.n)
	end
	local child = type(newcclosure) == "function" and newcclosure or function(data)
		return data
	end
	if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
		local element
		local ok3 = pcall(function()
			local result = child(function(self, ...)
				local value = getnamecallmethod()
				if value == "InvokeServer" or value == "FireServer" then
					return helperFunction(element, self, ...)
				end
				return element(self, ...)
			end)
			local cobalt = env.Cobalt
			local label = cobalt and cobalt.shared
			local textValue = label and label.Hooking
			if textValue and type(textValue.HookMetaMethod) == "function" then
				element = textValue.HookMetaMethod(game, "__namecall", result)
			else
				element = hookmetamethod(game, "__namecall", result)
			end
		end)
		keroSkibidiSkillRouter.Namecall = ok3
	end
	if type(hookfunction) == "function" then
		for _, item in ipairs({
			Remotes.Ability,
			Remotes.BoostSelect
		}) do
			local indexValue
			local ok4 = pcall(function()
				local value = item == Remotes.Ability and item.InvokeServer or item.FireServer
				indexValue = hookfunction(value, child(function(self, ...)
					return helperFunction(indexValue, self, ...)
				end))
			end)
			if ok4 then
				keroSkibidiSkillRouter.Direct = true
			end
		end
	end
	keroSkibidiSkillRouter.Installed = keroSkibidiSkillRouter.Namecall or keroSkibidiSkillRouter.Direct
	recorderTrace("skill_capture", {
		Namecall = keroSkibidiSkillRouter.Namecall or false,
		Direct = keroSkibidiSkillRouter.Direct or false
	})
end
-- Tower tracking and action recording
local function guessAbilityIndex(data)
	local value = data
	for _ = 1, 4 do
		if not value then
			break
		end
		for _, item in ipairs({
			"AbilityIndex",
			"Ability",
			"Index",
			"Slot"
		}) do
			local num = tonumber(value:GetAttribute(item))
			if num and num >= 1 then
				return math.floor(num)
			end
		end
		local num2 = tonumber(tostring(value.Name):match("(%d+)$"))
		if num2 and num2 >= 1 then
			return math.floor(num2)
		end
		if value:IsA("GuiObject") and value.LayoutOrder > 0 then
			return value.LayoutOrder
		end
		value = value.Parent
	end
	return 1
end
local function isOwnTower(tower)
	return tower and tower.Parent == towerData and tower:GetAttribute("Creator") == LocalPlayer.Name
end
local function waitForTowerModel(data, options)
	if not towerModels then
		return nil
	end
	local value
	waitUntil(function()
		value = towerModels:FindFirstChild(tostring(data))
		return value
	end, options or 2, 0.05)
	return value
end
local function getTowerCFrame(data)
	local value = State.RecordPlacementReceipts and State.RecordPlacementReceipts[tostring(data.Name)]
	if value and value.Unit == tostring(data:GetAttribute("ID")) then
		return value.CFrame
	end
	local boostPos = data:GetAttribute("BoostPos")
	local result = towerModels and towerModels:FindFirstChild(tostring(data.Name))
	if typeof(boostPos) ~= "Vector3" and not result then
		result = waitForTowerModel(data.Name, 2)
	end
	if typeof(boostPos) == "Vector3" then
		local child = CFrame.identity
		if result and result:IsA("Model") then
			local ok2, result2 = pcall(result.GetPivot, result)
			if ok2 then
				child = result2.Rotation
			end
		end
		return CFrame.new(boostPos) * child
	end
	return nil
end
local function isDefaultTargetMode(data)
	if data == nil then
		return true
	end
	local value = tostring(data):upper():gsub("%s+", "")
	return value == "" or value == "N/A" or value == "NA" or value == "NONE"
end
local function matchUpgradeCosts(data)
	local upgradeActionQueue, upgradeCostQueue = data.UpgradeActionQueue, data.UpgradeCostQueue
	while # upgradeActionQueue > 0 and # upgradeCostQueue > 0 do
		local value, result = upgradeActionQueue[1], upgradeCostQueue[1]
		if math.abs(value.At - result.At) <= 1 then
			value.Action.EstimatedCost = result.Value
			table.remove(upgradeActionQueue, 1)
			table.remove(upgradeCostQueue, 1)
		elseif value.At < result.At then
			table.remove(upgradeActionQueue, 1)
		else
			table.remove(upgradeCostQueue, 1)
		end
	end
	while # upgradeActionQueue > 0 and os.clock() - upgradeActionQueue[1].At > 1 do
		table.remove(upgradeActionQueue, 1)
	end
	while # upgradeCostQueue > 0 and os.clock() - upgradeCostQueue[1].At > 1 do
		table.remove(upgradeCostQueue, 1)
	end
end
local function trackTower(tower, handle)
	if State.TowerMeta[tower] then
		return
	end
	local records = {
		Handle = handle,
		Session = State.RecordSession,
		Level = tonumber(tower:GetAttribute("Upgrade")) or 0,
		SellPrice = tonumber(tower:GetAttribute("SellPrice")) or 0,
		PendingUpgradeCost = nil,
		UpgradeActionQueue = {},
		UpgradeCostQueue = {},
		TargetMode = tower:GetAttribute("TargetMode"),
		LastUpgradeAt = - math.huge,
		AbilityMarkers = {},
		LastAbilityAction = nil,
		LastAbilityRecordedAt = - math.huge,
		ClockBoost = tower:GetAttribute("ClockBoost"),
		LastBoostSourceHandle = nil,
		LastBoostRecordedAt = - math.huge,
		PendingBoostSourceHandle = nil,
		PlaceRecorded = false
	}
	for index, item in pairs(tower:GetAttributes()) do
		if tostring(index):match("^ATTACK") or isModeMarker(index) then
			records.AbilityMarkers[index] = item
		end
	end
	State.TowerMeta[tower] = records
	local copiedData = {}
	for index2, item3 in pairs(tower:GetAttributes()) do
		copiedData[index2] = sanitizeTraceValue(item3)
	end
	recorderTrace("tower_attached", {
		Handle = handle,
		RuntimeId = tower.Name,
		Attributes = copiedData
	})
	trackConnection(State.RecorderConnections, tower:GetAttributeChangedSignal("SellPrice"):Connect(function()
		local value = tonumber(tower:GetAttribute("SellPrice")) or records.SellPrice
		if value > records.SellPrice then
			records.PendingUpgradeCost = math.max(0, (value - records.SellPrice) * 2)
			records.LastUpgradeAt = os.clock()
			if State.Recording and records.Session == State.RecordSession then
				table.insert(records.UpgradeCostQueue, {
					At = os.clock(),
					Value = records.PendingUpgradeCost
				})
				matchUpgradeCosts(records)
			end
		end
		records.SellPrice = value
	end))
	trackConnection(State.RecorderConnections, tower:GetAttributeChangedSignal("Upgrade"):Connect(function()
		local value = tonumber(tower:GetAttribute("Upgrade")) or records.Level
		if State.Recording and records.Session == State.RecordSession and value > records.Level then
			records.LastUpgradeAt = os.clock()
			local actionData = {
				Type = "Upgrade",
				Handle = records.Handle,
				FromLevel = records.Level,
				ToLevel = value,
				EstimatedCost = records.PendingUpgradeCost or 0
			}
			queueTowerAction(records, actionData)
			table.insert(records.UpgradeActionQueue, {
				At = os.clock(),
				Action = actionData
			})
			matchUpgradeCosts(records)
		end
		records.Level = value
		records.PendingUpgradeCost = nil
	end))
	trackConnection(State.RecorderConnections, tower:GetAttributeChangedSignal("TargetMode"):Connect(function()
		local targetMode = tower:GetAttribute("TargetMode")
		local targetMode2 = records.TargetMode
		local value = isDefaultTargetMode(targetMode2) and os.clock() - records.LastUpgradeAt <= 0.5
		if State.Recording and records.Session == State.RecordSession and targetMode and targetMode ~= targetMode2 and not value then
			queueTowerAction(records, {
				Type = "Target",
				Handle = records.Handle,
				Mode = targetMode
			})
		end
		records.TargetMode = targetMode
	end))
	trackConnection(State.RecorderConnections, tower:GetAttributeChangedSignal("ClockBoost"):Connect(function()
		local clockBoost = records.ClockBoost
		local clockBoost2 = tower:GetAttribute("ClockBoost")
		records.ClockBoost = clockBoost2
		if not State.Recording or clockBoost2 == nil or tostring(clockBoost2) == "" or tostring(clockBoost2) == "0" or tostring(clockBoost2) == tostring(clockBoost) then
			return
		end
		Hub.RecordBoostLinkAction(clockBoost2, tower)
	end))
	trackConnection(State.RecorderConnections, tower.AttributeChanged:Connect(function(data)
		if State.Recording and records.Session == State.RecordSession then
			local actionData = {
				Damage = true,
				CurrentTarget = true,
				Stun = true,
				StunMark = true,
				Health = true,
				StunTime = true,
				StunAccum = true
			}
			if not actionData[data] then
				recorderTrace("tower_attribute", {
					Handle = records.Handle,
					Key = data,
					Value = sanitizeTraceValue(tower:GetAttribute(data))
				})
			end
		end
		if not tostring(data):match("^ATTACK") and not isModeMarker(data) then
			return
		end
		local value = records.AbilityMarkers[data]
		local result = tower:GetAttribute(data)
		records.AbilityMarkers[data] = result
		if not State.Recording or records.Session ~= State.RecordSession or value == result then
			return
		end
		local pendingAbility = State.PendingAbility
		local child = State.SkillIntents and State.SkillIntents[tostring(tower.Name)]
		local element = pendingAbility and pendingAbility.Marker == data and os.clock() - pendingAbility.At <= 3 or child and not child.Rejected and child.Session == State.RecordSession and os.clock() - child.At <= 12
		if not isModeMarker(data) and not abilityStateChanged(value, result, element) then
			return
		end
		if data == "SwitchModeState" and value == nil and result ~= 2 then
			return
		end
		if data == "AttackMode" and (value == nil or type(result) ~= "number" or result < 1 or result > 3) then
			return
		end
		task.defer(function()
			if not State.Recording or records.Session ~= State.RecordSession then
				return
			end
			local ok2, result2 = pcall(resolveAbilityCard, data)
			if not ok2 or not result2 then
				recorderTrace("unmapped_activation", {
					Handle = records.Handle,
					Marker = data,
					Reason = not ok2 and tostring(result2) or "No known native skill mapping"
				})
				return
			end
			local abilityData = {
				Title = result2.Title,
				Card = result2.Card,
				Cost = result2.Cost,
				Cooldown = result2.Cooldown,
				CooldownFloor = result2.CooldownFloor,
				ConfirmedValue = result,
				PreviousValue = value
			}
			Hub.RecordAbilityAction(tower, result2.Index, data, abilityData)
		end)
	end))
end
local stopRecording
local function startRecording(profileName)
	if State.Playing then
		return false, "Stop playback first"
	end
	if not remotesReady() then
		return false, "Recording is only available after entering a match"
	end
	profileName = sanitizeProfileName(profileName)
	if profileName == "" then
		return false, "Enter a profile name"
	end
	disconnectAll(State.RecorderConnections)
	State.Actions = {}
	State.ProfileName = profileName
	State.ProfileVersion = 6
	State.MacroLoadout = nil
	State.RecordAwaitFirstWave = nil
	State.RecordStartedAt = os.clock()
	State.RecordSession = {}
	local recordSession = State.RecordSession
	State.NextHandle = 1
	State.TowerMeta = setmetatable({}, {
		__mode = "k"
	})
	State.PendingAbilityClickAt = - math.huge
	State.PendingAbilityIndex = 1
	State.PendingAbility = nil
	State.RecorderTrace = {}
	State.RecorderTraceDropped = 0
	State.RecorderDebugFile = nil
	State.RecordCooldownSamples = {}
	State.Recording = true
	installSkillRouter()
	if Hub.MatchFlow then
		Hub.MatchFlow.RecordLoadout()
	end
	State.RecordPlacementReceipts, State.RecordPlacementActions = {}, {}
	local ok2, result2 = pcall(function()
		return Remotes.Place.OnClientEvent:Connect(function(data, options, callback, context)
			if not State.Recording or State.RecordSession ~= recordSession or data ~= LocalPlayer or typeof(callback) ~= "CFrame" or type(context) ~= "number" and type(context) ~= "string" then
				return
			end
			if Hub.MatchFlow then
				Hub.MatchFlow.UpdateRecorderClock()
			end
			local str = tostring(context)
			local records = {
				Unit = tostring(options),
				CFrame = callback,
				RecordedAt = os.clock() - State.RecordStartedAt
			}
			State.RecordPlacementReceipts[str] = records
			local value = State.RecordPlacementActions[str]
			if value and value.Unit == records.Unit then
				value.CFrame, value.PlacementSpace = cframeToArray(callback), "Ground"
				value.RecordedAt = records.RecordedAt
			end
		end)
	end)
	if ok2 and result2 then
		trackConnection(State.RecorderConnections, result2)
	end
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local copiedData = setmetatable({}, {
		__mode = "k"
	})
	local function helperFunction(data)
		if copiedData[data] or not data:IsA("GuiObject") then
			return
		end
		local value, isActive = data, false
		for _ = 1, 12 do
			if not value then
				break
			end
			if value.Name == "Abilities" then
				isActive = true
				break
			end
			value = value.Parent
		end
		if not isActive then
			return
		end
		copiedData[data] = true
		trackConnection(State.RecorderConnections, data.InputBegan:Connect(function(options)
			if State.Recording and State.RecordSession == recordSession and (options.UserInputType == Enum.UserInputType.MouseButton1 or options.UserInputType == Enum.UserInputType.Touch) then
				onAbilityCardClicked(data)
			end
		end))
	end
	if playerGui then
		for _, item in ipairs(playerGui:GetDescendants()) do
			helperFunction(item)
		end
		trackConnection(State.RecorderConnections, playerGui.DescendantAdded:Connect(helperFunction))
		trackConnection(State.RecorderConnections, game:GetService("UserInputService").InputBegan:Connect(function(data)
			if not State.Recording or State.RecordSession ~= recordSession then
				return
			end
			if data.UserInputType ~= Enum.UserInputType.MouseButton1 and data.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local ok3, result3 = pcall(playerGui.GetGuiObjectsAtPosition, playerGui, data.Position.X, data.Position.Y)
			local records = {}
			if ok3 then
				for index, item3 in ipairs(result3) do
					if index > 12 then
						break
					end
					local name = item3.Name
					pcall(function()
						name = item3:GetFullName():gsub("Players%.[^%.]+%.", "Players.Local.")
					end)
					local value = ""
					if item3:IsA("TextLabel") or item3:IsA("TextButton") then
						value = item3.Text
					end
					records[# records + 1] = {
						Path = name,
						Class = item3.ClassName,
						Text = tostring(value):sub(1, 120)
					}
				end
			end
			recorderTrace("pointer_input", {
				HitTestOK = ok3,
				Hits = records
			})
			if ok3 then
				for _, item4 in ipairs(result3) do
					if readAbilityCard(item4) then
						onAbilityCardClicked(item4)
						break
					end
				end
			end
		end))
	end
	local count = 0
	for _, item5 in ipairs(towerData:GetChildren()) do
		if isOwnTower(item5) then
			count = count + 1
		end
	end
	trackConnection(State.RecorderConnections, towerData.ChildAdded:Connect(function(data)
		if Hub.MatchFlow then
			Hub.MatchFlow.UpdateRecorderClock()
		end
		local value = os.clock() - State.RecordStartedAt
		task.spawn(function()
			local result = waitUntil(function()
				return isOwnTower(data) and data:GetAttribute("ID") ~= nil
			end, 5, 0.05)
			if not result or not State.Recording or State.RecordSession ~= recordSession then
				return
			end
			local child = "T" .. State.NextHandle
			State.NextHandle = State.NextHandle + 1
			trackTower(data, child)
			local element = getTowerCFrame(data)
			if not element then
				setStatus("Record warning", "Could not read placement CFrame for tower " .. data.Name)
				return
			end
			if not State.Recording or State.RecordSession ~= recordSession then
				return
			end
			local label = tonumber(data:GetAttribute("SellPrice")) or 0
			local textValue = State.RecordPlacementReceipts[tostring(data.Name)]
			local records = {
				Type = "Place",
				Handle = child,
				Unit = tostring(data:GetAttribute("ID")),
				CFrame = cframeToArray(element),
				PlacementSpace = "Ground",
				RecordedAt = textValue and textValue.RecordedAt or value,
				EstimatedCost = label * 2
			}
			State.RecordPlacementActions[tostring(data.Name)] = records
			pushAction(records)
			local indexValue = State.TowerMeta[data]
			if indexValue then
				indexValue.PlaceRecorded = true
				for _, item3 in ipairs(indexValue.PendingActions or {}) do
					pushAction(item3)
				end
				indexValue.PendingActions = nil
			end
		end)
	end))
	trackConnection(State.RecorderConnections, towerData.ChildRemoved:Connect(function(data)
		local value = State.TowerMeta[data]
		if not value then
			return
		end
		task.delay(0.15, function()
			if State.Recording and State.RecordSession == recordSession and not isMatchEnded() then
				pushAction({
					Type = "Sell",
					Handle = value.Handle
				})
			end
		end)
	end))
	local cachedValue = getGameEndedGui()
	if cachedValue then
		trackConnection(State.RecorderConnections, cachedValue:GetPropertyChangedSignal("Enabled"):Connect(function()
			if State.Recording and cachedValue.Enabled then
				task.defer(function()
					if State.Recording then
						stopRecording(true)
					end
				end)
			end
		end))
	end
	updateActionSummary()
	if count > 0 then
		setStatus("Recording", string.format("Started with %d existing tower(s); new actions only", count))
	else
		setStatus("Recording", "Passive recorder active; play normally")
	end
	return true
end
stopRecording = function(data)
	if not State.Recording then
		return false, "Recorder is not running"
	end
	local keroSkibidiSkillRouter = env.KeroSkibidiSkillRouter
	if keroSkibidiSkillRouter and (keroSkibidiSkillRouter.Pending or 0) > 0 then
		waitUntil(function()
			return (keroSkibidiSkillRouter.Pending or 0) == 0
		end, 2, .03)
	end
	task.wait()
	for _, item in ipairs(State.RecordCooldownSamples or {}) do
		pcall(sampleAbilityCooldown, item)
	end
	State.Recording = false
	local records = {}
	for index, item3 in ipairs(State.Actions) do
		records[item3] = index
	end
	table.sort(State.Actions, function(options, callback)
		local value, result = tonumber(options.RecordedAt) or 0, tonumber(callback.RecordedAt) or 0
		if value == result then
			return records[options] < records[callback]
		end
		return value < result
	end)
	if UI.SetRecordToggle then
		UI.SetRecordToggle(false)
	end
	disconnectAll(State.RecorderConnections)
	if Hub.ExportDebug then
		local ok2, result2 = pcall(Hub.ExportDebug, "recording stopped")
		if ok2 and result2 then
			State.RecorderDebugFile = result2
		end
	end
	if data then
		local value, value1 = saveProfile(State.ProfileName)
		if not value then
			setStatus("Save failed", value1)
			return false, value1
		end
		setStatus("Saved", string.format("%s | %d actions", State.ProfileName, # State.Actions))
		if UI.RefreshProfiles then
			UI.RefreshProfiles(State.ProfileName)
		end
		if UI.QueueSave then
			UI.QueueSave()
		end
	else
		setStatus("Recorder stopped", string.format("%d unsaved actions", # State.Actions))
	end
	return true
end
-- Macro playback and tower actions
local function flatDistance(a, b)
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end
local function getActionCFrame(data)
	local value = arrayToCFrame(data.CFrame)
	if not value or data.PlacementSpace == "Ground" then
		return value
	end
	local copy = table.clone(data.CFrame)
	copy[2] = tonumber(copy[2]) - 4.7
	return arrayToCFrame(copy)
end
local function findRuntimeTower(data, options)
	if not towerData then
		return nil
	end
	local value = getActionCFrame(data)
	if not value then
		return nil
	end
	local result
	for _, item in ipairs(towerData:GetChildren()) do
		if isOwnTower(item) and not State.UsedRuntimeTowers[item] and (not options or not options[item]) and tostring(item:GetAttribute("ID")) == tostring(data.Unit) then
			local boostPos = item:GetAttribute("BoostPos")
			if typeof(boostPos) == "Vector3" and flatDistance(boostPos, value.Position) <= 0.35 and math.abs(boostPos.Y - value.Position.Y) <= 1 then
				if result then
					return nil, "Multiple matching towers at the recorded position"
				end
				result = item
			end
		end
	end
	return result
end
local function isPlaying(session)
	return State.Running and State.Playing and (session == nil or State.PlaySession == session)
end
-- Every temporary signal created by Playback belongs to one session.
-- This guarantees cleanup on normal completion, cancellation, or errors.
local function trackPlaybackConnection(session, connection)
	if connection and type(session) == "table" then
		session.Connections = session.Connections or {}
		table.insert(session.Connections, connection)
	end
	return connection
end
local function disconnectPlaybackConnection(session, connection)
	if not connection then
		return
	end
	pcall(function()
		connection:Disconnect()
	end)
	if type(session) == "table" and type(session.Connections) == "table" then
		for index = #session.Connections, 1, -1 do
			if session.Connections[index] == connection then
				table.remove(session.Connections, index)
			end
		end
	end
end
local function cleanupPlaybackSession(session)
	if type(session) ~= "table" then
		return
	end
	session.Cancelled = true
	if type(session.Connections) == "table" then
		disconnectAll(session.Connections)
	else
		session.Connections = {}
	end
end
local function waitForActionTime(action, startedAt, session)
	local value = tonumber(action.RecordedAt) or 0
	local result = tonumber(action.EstimatedCost) or 0
	local _ = tonumber(action.Wave) or 0
	return waitUntil(function()
		if not isPlaying(session) or isMatchEnded() then
			return true
		end
		local child = os.clock() - startedAt
		local element = child >= value
		local label = result <= 0 or getMoney() >= result
		local textValue = action.Type == "Upgrade" and State.RuntimeHandles[action.Handle]
		if textValue and textValue.Parent == towerData and (tonumber(textValue:GetAttribute("Upgrade")) or 0) >= (tonumber(action.ToLevel) or (tonumber(action.FromLevel) or 0) + 1) then
			label = true
		end
		if State.PlaybackMode == "Time" then
			return element
		elseif State.PlaybackMode == "Money" then
			return label
		end
		return element and label
	end, 600, 0.03)
end
-- Fix: playPlace previously shadowed the placement CFrame with findRuntimeTower's result.
-- That caused the receipt-position check and placeTower remote to receive a Model/nil instead of a CFrame.
local function playPlace(action, session)
	local placementCFrame = getActionCFrame(action)
	if not placementCFrame then
		return false, "Invalid placement CFrame"
	end
	local result = os.clock() + 180
	local requiredCost = math.max(0, tonumber(action.EstimatedCost) or tonumber(action.Cost) or 0)
	local count = 0
	local records = {}
	for _, item in ipairs(towerData:GetChildren()) do
		records[item] = true
	end
	while isPlaying(session) and os.clock() < result and not isMatchEnded() do
		if getMoney() >= requiredCost then
			local element = records
			local existingTower, findError = findRuntimeTower(action, element)
			if existingTower then
				State.RuntimeHandles[action.Handle] = existingTower
				State.UsedRuntimeTowers[existingTower] = true
				return true
			end
			if findError then
				return false, findError
			end
			if count >= 5 then
				return false, "Placement unconfirmed after 5 attempts"
			end
			count = count + 1
			local label = getMoney()
			local textValue, indexValue, cachedValue, nextValue, currentValue
			local copiedData = {}
			for index in pairs(element) do
				copiedData[tostring(index.Name)] = true
			end
			local ok2, result2 = pcall(function()
				return trackPlaybackConnection(session, Remotes.Place.OnClientEvent:Connect(function(data, options, callback, context)
					if not isPlaying(session) or isMatchEnded() or data ~= LocalPlayer or tostring(options) ~= tostring(action.Unit) or typeof(callback) ~= "CFrame" or type(context) ~= "number" and type(context) ~= "string" then
						return
					end
					local str = tostring(context)
					if copiedData[str] or str == "" then
						return
					end
					if flatDistance(callback.Position, placementCFrame.Position) > 0.35 or math.abs(callback.Position.Y - placementCFrame.Position.Y) > 1 then
						return
					end
					if textValue and textValue ~= str then
						indexValue = true
					end
					textValue = str
				end))
			end)
			if ok2 then
				cachedValue = result2
			end
			local ok3, result3 = pcall(function()
				return trackPlaybackConnection(session, Remotes.Notice.OnClientEvent:Connect(function(data)
					local entryValue = type(data) == "table" and tostring(data.Text or "") or tostring(data)
					local lowered = entryValue:lower()
					if lowered:find("place", 1, true) and (lowered:find("cash", 1, true) or lowered:find("money", 1, true)) and (lowered:find("need", 1, true) or lowered:find("enough", 1, true) or lowered:find("insufficient", 1, true)) then
						currentValue = {
							Text = entryValue,
							At = os.clock(),
							Cash = getMoney()
						}
						if lowered:find("need more cash to place", 1, true) then
							local num = tonumber(entryValue:gsub(",", ""):match("%$([%d%.]+)"))
							if num then
								requiredCost = math.max(requiredCost, math.ceil(getMoney() + num))
							end
						end
					end
				end))
			end)
			if ok3 then
				nextValue = result3
			end
			local ok4, result4 = pcall(Remotes.Place.FireServer, Remotes.Place, action.Unit, placementCFrame, false)
			local pendingValue
			local value3, value13 = waitUntil(function()
				if not isPlaying(session) or isMatchEnded() then
					return true
				end
				if indexValue then
					pendingValue = "Multiple placement receipts matched; no duplicate retry"
					return nil
				end
				if textValue then
					local entryValue = towerData:FindFirstChild(textValue)
					if entryValue and isOwnTower(entryValue) and not element[entryValue] and not State.UsedRuntimeTowers[entryValue] and tostring(entryValue:GetAttribute("ID")) == tostring(action.Unit) then
						return entryValue
					end
					return nil
				end
				local value2, value12 = findRuntimeTower(action, element)
				pendingValue = value12
				if value2 then
					return value2
				end
				if currentValue and not textValue and not pendingValue and os.clock() - currentValue.At >= 0.15 then
					return "funds_rejected"
				end
				return nil
			end, 2, 0.03)
			if textValue and not indexValue and not (value3 and typeof(value13) == "Instance") then
				value3, value13 = waitUntil(function()
					if not isPlaying(session) or isMatchEnded() then
						return true
					end
					local entryValue = towerData:FindFirstChild(textValue)
					if entryValue and isOwnTower(entryValue) and not element[entryValue] and not State.UsedRuntimeTowers[entryValue] and tostring(entryValue:GetAttribute("ID")) == tostring(action.Unit) then
						return entryValue
					end
				end, 6, .03)
			end
			if cachedValue then
				disconnectPlaybackConnection(session, cachedValue)
			end
			if nextValue then
				disconnectPlaybackConnection(session, nextValue)
			end
			if not isPlaying(session) or isMatchEnded() then
				return false, "Playback cancelled"
			end
			if value3 and typeof(value13) == "Instance" then
				State.RuntimeHandles[action.Handle] = value13
				State.UsedRuntimeTowers[value13] = true
				State.PlacementWait = nil
				return true
			end
			if value13 == "funds_rejected" and currentValue and not textValue then
				State.PlacementWait = {
					Handle = action.Handle,
					RequiredCost = requiredCost,
					ServerMessage = currentValue.Text
				}
				setStatus("Playback", "Place " .. tostring(action.Unit) .. " | waiting for server funds " .. formatMoney() .. "/" .. tostring(requiredCost))
				local elapsedValue = getMoney()
				waitUntil(function()
					return not isPlaying(session) or isMatchEnded() or getMoney() >= requiredCost and getMoney() ~= elapsedValue
				end, math.max(0.03, result - os.clock()), 0.03)
			else
				if pendingValue or textValue or not ok4 then
					return false, pendingValue or (textValue and "Placement accepted; metadata unconfirmed, no duplicate retry" or "Place transport failed: " .. tostring(result4))
				end
				if getMoney() < label then
					return false, "Placement changed cash; no duplicate resend"
				end
				for _, item3 in ipairs(towerData:GetChildren()) do
					if not element[item3] and isOwnTower(item3) then
						return false, "Unidentified new tower; no duplicate resend"
					end
				end
				if count >= 5 then
					return false, "Placement unconfirmed after 5 attempts"
				end
			end
		end
		task.wait(0.03)
	end
	if not isPlaying(session) or isMatchEnded() then
		return false, "Playback cancelled"
	end
	return false, "Place timed out waiting for server funds/acceptance"
end
local function getRuntimeTower(handle)
	local value = State.RuntimeHandles[handle]
	if value and value.Parent == towerData then
		return value
	end
	return nil
end
local function playUpgrade(action, session)
	local value = getRuntimeTower(action.Handle)
	if not value then
		return false, "Tower handle is missing: " .. tostring(action.Handle)
	end
	local result = tonumber(action.ToLevel) or (tonumber(action.FromLevel) or 0) + 1
	local num = math.max(0, tonumber(action.EstimatedCost) or 0)
	local child = os.clock() + 180
	local str, str2 = tostring(value.Name), tostring(value:GetAttribute("ID"))
	local records, element, label = {}, tonumber(value:GetAttribute("Upgrade")) or 0, nil
	local function helperFunction()
		for _, item in ipairs(records) do
			disconnectPlaybackConnection(session, item)
		end
		records = {}
	end
	local function createUiElement()
		helperFunction()
		for _, item in ipairs({
			"Upgrade",
			"SellPrice"
		}) do
			local ok2, result2 = pcall(function()
				return trackPlaybackConnection(session, value:GetAttributeChangedSignal(item):Connect(function()
					local textValue = tonumber(value:GetAttribute("Upgrade")) or 0
					element = math.max(element, textValue)
					if item == "Upgrade" then
						label = textValue
					end
				end))
			end)
			if ok2 and result2 then
				table.insert(records, result2)
			end
		end
	end
	local function setupUiElement(data, options)
		helperFunction()
		if data then
			State.UpgradeWait = nil
		end
		return data, options
	end
	createUiElement()
	local indexValue, count, count2, isActive, cachedValue = nil, 0, 0, false, nil
	while isPlaying(session) and not isMatchEnded() and os.clock() < child do
		local nextValue = towerData:FindFirstChild(str)
		if nextValue and nextValue ~= value and isOwnTower(nextValue) and tostring(nextValue:GetAttribute("ID")) == str2 then
			value = nextValue
			State.RuntimeHandles[action.Handle] = nextValue
			State.UsedRuntimeTowers[nextValue] = true
			createUiElement()
		end
		if value.Parent ~= towerData then
			return setupUiElement(false, "Tower disappeared during upgrade")
		end
		local currentValue = tonumber(value:GetAttribute("Upgrade")) or 0
		element = math.max(element, currentValue)
		local entryValue = element
		if entryValue >= result then
			return setupUiElement(true)
		end
		local pendingValue = getMoney()
		local elapsedValue = tonumber(value:GetAttribute("SellPrice")) or 0
		if indexValue and entryValue > indexValue.level then
			indexValue, num = nil, 0
		end
		if indexValue then
			indexValue.spent = indexValue.spent or elapsedValue > indexValue.price
			if pendingValue < indexValue.lastCash then
				indexValue.cashDropAt = os.clock()
			end
			indexValue.lastCash = pendingValue
			local storedValue = not indexValue.cashDropAt or os.clock() - indexValue.cashDropAt >= 1
			if not indexValue.spent and indexValue.cash ~= math.huge and storedValue and os.clock() - indexValue.at >= 2 and pendingValue >= num then
				indexValue = nil
			end
		end
		if not indexValue and pendingValue >= num then
			indexValue = {
				level = entryValue,
				cash = pendingValue,
				lastCash = pendingValue,
				price = elapsedValue,
				at = os.clock(),
				spent = false
			}
			count2 = count2 + 1
			cachedValue = cachedValue or os.clock()
			local ok3, result3 = pcall(Remotes.Upgrade.FireServer, Remotes.Upgrade, tostring(value.Name))
			if not ok3 then
				return setupUiElement(false, "Upgrade transport failed: " .. tostring(result3))
			end
		end
		State.UpgradeWait = {
			Handle = action.Handle,
			Level = entryValue,
			TargetLevel = result,
			RuntimeId = tostring(value.Name),
			RawLevel = currentValue,
			EventLevel = label,
			Cash = pendingValue,
			RequiredCost = num,
			Attempts = count2,
			Pending = indexValue ~= nil,
			Spent = indexValue and indexValue.spent or false,
			PendingAge = indexValue and os.clock() - indexValue.at or 0,
			CashDropAt = indexValue and indexValue.cashDropAt or nil
		}
		if indexValue and not isActive and cachedValue and os.clock() - cachedValue >= 4 and type(Hub.ExportDebug) == "function" then
			isActive = true
			pcall(Hub.ExportDebug, "Upgrade pending >4s: " .. tostring(action.Handle) .. " / server ID " .. str)
		end
		if os.clock() >= count then
			count = os.clock() + 0.5
			local targetValue = pendingValue < num and "money " .. formatMoney() .. "/" .. tostring(num) or "level confirmation | sent " .. tostring(count2)
			setStatus("Playback", string.format("Upgrade %s [ID %s] | Lv %d/%d | %s", tostring(action.Handle), tostring(value.Name), entryValue, result, targetValue))
		end
		task.wait(0.03)
	end
	if not isPlaying(session) or isMatchEnded() then
		return setupUiElement(false, "Playback cancelled")
	end
	return setupUiElement(false, "Upgrade timed out after 180s without confirmed target level")
end
local function isLegacyDuplicateTarget(data, options)
	if State.ProfileVersion >= 2 then
		return false
	end
	local value = State.Actions[data - 1]
	if not value or value.Type ~= "Upgrade" or value.Handle ~= options.Handle then
		return false
	end
	local num = tonumber(options.RecordedAt)
	local num2 = tonumber(value.RecordedAt)
	return num ~= nil and num2 ~= nil and num >= num2 and num - num2 <= 0.5
end
local function playSell(action, session)
	local value = getRuntimeTower(action.Handle)
	if not value then
		return true
	end
	for _ = 1, 3 do
		if not isPlaying(session) or value.Parent ~= towerData then
			return true
		end
		Remotes.Sell:FireServer(tostring(value.Name))
		if waitUntil(function()
			return value.Parent ~= towerData
		end, 3, 0.1) then
			return true
		end
		task.wait(1)
	end
	return false, "Sell was not confirmed"
end
local function playTargetMode(action, session)
	local value = getRuntimeTower(action.Handle)
	if not value then
		return false, "Tower handle is missing: " .. tostring(action.Handle)
	end
	for _ = 1, 8 do
		if not isPlaying(session) or value.Parent ~= towerData then
			return false, "Tower disappeared"
		end
		if value:GetAttribute("TargetMode") == action.Mode then
			return true
		end
		Remotes.Target:FireServer(tostring(value.Name))
		task.wait(0.25)
	end
	return value:GetAttribute("TargetMode") == action.Mode, "Target mode was not confirmed"
end
local function parseAbilityFailure(data, options)
	local records, value = {}, nil
	for i = 3, data.n or # data do
		local result = data[i]
		if type(result) == "string" then
			records[# records + 1] = result
		elseif type(result) == "table" then
			for _, item in ipairs({
				"Message",
				"Reason",
				"Error"
			}) do
				if type(result[item]) == "string" then
					records[# records + 1] = result[item]
				end
			end
			local num = tonumber(result.CooldownRemaining or result.RemainingCooldown or result.RetryAfter)
			if num and num >= 0 and num <= 3600 then
				value = num
			end
		end
	end
	local child = table.concat(records, " "):sub(1, 200)
	local lowered = child:lower()
	for _, item3 in ipairs({
		"invalid ability",
		"unknown ability",
		"invalid tower",
		"not owner",
		"not unlocked",
		"permission denied",
		"unsupported"
	}) do
		if lowered:find(item3, 1, true) then
			return nil, false, child
		end
	end
	local element = lowered:find("cooldown", 1, true) ~= nil or lowered:find("on cd", 1, true) ~= nil or value ~= nil
	if not value and element then
		value = tonumber(lowered:match("cooldown[^%d]*(%d+%.?%d*)"))
	end
	if value and value >= 0 and value <= 3600 then
		return math.max(.25, value), true, child
	end
	return math.min(30, 2 ^ math.min(options - 1, 5)), element, child
end
local function playAbility(action, session)
	local value = getRuntimeTower(action.Handle)
	if not value then
		return false, "Tower handle is missing: " .. tostring(action.Handle)
	end
	if not Remotes.Ability or not Remotes.Ability:IsA("RemoteFunction") then
		return false, "spawnTowerAbility is unavailable"
	end
	local str = tostring(action.Marker or "")
	if str == "" and action.CaptureSource ~= "Remote" then
		return false, "Ability has no confirmation marker; record this skill again"
	end
	if isModeMarker(str) and action.ExpectedState ~= nil and value:GetAttribute(str) == action.ExpectedState then
		return true
	end
	if str == "AttackMode" and action.ExpectedState ~= nil and not action.ModeStep then
		if type(action.ExpectedState) ~= "number" or action.ExpectedState < 1 or action.ExpectedState > 3 or action.ExpectedState % 1 ~= 0 then
			return false, "Invalid recorded attack mode"
		end
		local records = {}
		for index, item in pairs(action) do
			records[index] = item
		end
		records.ExpectedState = nil
		records.ModeStep = true
		records.Cooldown = math.max(5, tonumber(records.Cooldown) or 0)
		for _ = 1, 3 do
			if not isPlaying(session) or value.Parent ~= towerData then
				return false, "Mode change cancelled"
			end
			if value:GetAttribute(str) == action.ExpectedState then
				return true
			end
			local value, value1 = playAbility(records, session)
			if not value then
				return false, value1
			end
		end
		return value:GetAttribute(str) == action.ExpectedState, "Recorded attack mode was not reached"
	end
	local result = tonumber(action.RequiredLevel) or 0
	local num = math.max(0, tonumber(action.Cooldown) or 0)
	local child = tostring(action.Handle) .. ":" .. str .. ":" .. tostring(action.AbilityIndex or 1)
	local str2 = tostring(action.AbilityName or str)
	State.AbilityLastUsed = State.AbilityLastUsed or {}
	State.AbilityAttempts = State.AbilityAttempts or {}
	local value2, value12 = getGameClock()
	local now = os.clock()
	local count, element, count2 = 0, nil, 0
	local isActive = false
	local count3 = 0
	local function helperFunction()
		return isPlaying(session) and not isMatchEnded() and value.Parent == towerData
	end
	local function createUiElement()
		local value3, value13 = getGameClock()
		return os.clock() - now >= 900 or value13 == value12 and value3 - value2 >= 600
	end
	while helperFunction() and not createUiElement() and count3 < 32 do
		local pendingValue = waitUntil(function()
			if not helperFunction() or createUiElement() then
				return true
			end
			local value3, value13 = getGameClock()
			local label = State.AbilityLastUsed[child]
			local textValue = math.huge
			if type(label) == "table" then
				textValue = label.Kind == value13 and value3 - label.At or os.clock() - label.RealAt
			elseif type(label) == "number" then
				textValue = os.clock() - label
			end
			local indexValue = element == value13 and count - value3 or count2 - os.clock()
			local num2 = math.max(0, num - textValue, indexValue)
			local cachedValue = getMoney() >= (tonumber(action.EstimatedCost) or 0)
			local nextValue = (tonumber(value:GetAttribute("Upgrade")) or 0) >= result
			local currentValue = not str:match("^ATTACK") or not isTruthyState(value:GetAttribute(str))
			local entryValue = num2 > 0 and ((isActive or num - textValue > 0) and "Cooldown " or "Retry in ") .. math.ceil(num2) .. "s" or not cachedValue and "Waiting for cash" or not nextValue and "Waiting for upgrade" or not currentValue and "Waiting for active ability" or "Ready"
			State.AbilityWait = {
				Name = str2,
				Phase = entryValue,
				Attempt = count3,
				Action = State.PlaybackIndex
			}
			setStatus("Playback", string.format("Action %d/%d | %s | %s", State.PlaybackIndex or 1, # State.Actions, str2, entryValue))
			return num2 <= 0 and cachedValue and nextValue and currentValue
		end, 901, .1)
		if not helperFunction() then
			return false, "Ability cancelled or tower disappeared"
		end
		if not pendingValue or createUiElement() then
			break
		end
		if isModeMarker(str) and action.ExpectedState ~= nil and value:GetAttribute(str) == action.ExpectedState then
			State.AbilityWait = nil
			return true
		end
		count3 = count3 + 1
		local elapsedValue = value:GetAttribute(str)
		local isEnabled, storedValue = false, nil
		local function setupUiElement()
			local label = value:GetAttribute(str)
			if label == elapsedValue then
				return
			end
			if str:match("^ATTACK") and not abilityStateChanged(elapsedValue, label, true) then
				return
			end
			if str == "AttackMode" and (type(label) ~= "number" or label < 1 or label > 3 or label % 1 ~= 0) then
				return
			end
			if action.ExpectedState ~= nil and label ~= action.ExpectedState then
				return
			end
			isEnabled = true
		end
		local targetValue = str ~= "" and trackPlaybackConnection(session, value:GetAttributeChangedSignal(str):Connect(setupUiElement))
		local abilityThread = task.spawn(function()
			storedValue = table.pack(pcall(Remotes.Ability.InvokeServer, Remotes.Ability, tostring(value.Name), tonumber(action.AbilityIndex) or 1))
		end)
		waitUntil(function()
			if storedValue and storedValue[1] and storedValue[2] == true and action.CaptureSource == "Remote" then
				isEnabled = true
			end
			return not helperFunction() or isEnabled or storedValue and (not storedValue[1] or storedValue[2] == false)
		end, 12, .03)
		if helperFunction() and storedValue and storedValue[1] and storedValue[2] == false and not isEnabled then
			waitUntil(function()
				return not helperFunction() or isEnabled
			end, .25, .05)
		end
		if targetValue then
			disconnectPlaybackConnection(session, targetValue)
		end
		if not storedValue and abilityThread then
			pcall(task.cancel, abilityThread)
		end
		if not helperFunction() then
			return false, "Ability cancelled or tower disappeared"
		end
		if isEnabled then
			local value4, value14 = getGameClock()
			State.AbilityLastUsed[child] = {
				At = value4,
				Kind = value14,
				RealAt = os.clock()
			}
			State.AbilityWait = nil
			return true
		end
		if not storedValue then
			return false, "Ability response unconfirmed; no duplicate retry: " .. str2
		end
		if not storedValue[1] then
			return false, "Ability transport failed: " .. tostring(storedValue[2])
		end
		if storedValue[2] ~= false then
			return false, "Ability unconfirmed; no duplicate retry: " .. str2
		end
		local value5, value15, value22 = parseAbilityFailure(storedValue, count3)
		if not value5 then
			return false, "Ability unavailable: " .. value22
		end
		local value6, value16 = getGameClock()
		count, element, count2 = value6 + value5, value16, os.clock() + value5
		isActive = value15
		if # State.AbilityAttempts < 40 then
			table.insert(State.AbilityAttempts, {
				Name = str2,
				Attempt = count3,
				Reason = value22,
				Delay = value5,
				Cooldown = value15
			})
		end
	end
	return false, "Ability readiness timeout: " .. str2
end
local function playBoostLink(action, session)
	local value = getRuntimeTower(action.SourceHandle)
	local result = getRuntimeTower(action.TargetHandle)
	if not value then
		return false, "Boost source handle is missing: " .. tostring(action.SourceHandle)
	end
	if not result then
		return false, "Boost target handle is missing: " .. tostring(action.TargetHandle)
	end
	if not Remotes.BoostSelect or not Remotes.BoostSelect:IsA("RemoteEvent") then
		return false, "BoostSelect is unavailable"
	end
	local num = tonumber(value.Name)
	local str = tostring(result.Name)
	if not num then
		return false, "Boost source has an invalid server ID"
	end
	if tostring(result:GetAttribute("ClockBoost")) == tostring(num) then
		return true
	end
	Remotes.BoostSelect:FireServer(num, str)
	local child = waitUntil(function()
		return not isPlaying(session) or value.Parent ~= towerData or result.Parent ~= towerData or tostring(result:GetAttribute("ClockBoost")) == tostring(num)
	end, 5, 0.05)
	if not isPlaying(session) then
		return false, "Playback stopped while linking boost"
	end
	if value.Parent ~= towerData or result.Parent ~= towerData then
		return false, "Boost tower disappeared"
	end
	return child, child and nil or "Boost link was not confirmed"
end
function Hub.ExportDebug(data)
	local records = {
		Version = 1,
		Build = "skibidi-demo-server-money-20261031",
		LeaderMoney = State.LastLeaderMoney,
		ServerMoney = State.ServerMoney,
		ServerMoneyAge = State.ServerMoneyAt and os.clock() - State.ServerMoneyAt or nil,
		PlaceId = game.PlaceId,
		Profile = State.ProfileName,
		ProfileVersion = State.ProfileVersion,
		Mode = State.PlaybackMode,
		Wave = getWave(),
		Money = formatMoney(),
		ActionIndex = State.PlaybackIndex,
		Action = State.Actions[State.PlaybackIndex or 0],
		Reason = data or State.LastPlaybackFailure,
		Towers = {},
		UpgradeWait = State.UpgradeWait,
		PlacementWait = State.PlacementWait,
		MoneySource = State.ServerMoney ~= nil and "statUpdate" or "leaderstats",
		RecorderTrace = State.RecorderTrace,
		RecorderTraceDropped = State.RecorderTraceDropped,
		AbilityWait = State.AbilityWait,
		AbilityAttempts = State.AbilityAttempts,
		Knock = Hub.Knock and {
			Message = Hub.Knock.Message,
			LastAttempt = Hub.Knock.LastAttempt,
			LastRound = Hub.Knock.LastRound,
			WebhookResult = Hub.Knock.LastWebhookResult
		} or nil
	}
	if towerData then
		for _, item in ipairs(towerData:GetChildren()) do
			if isOwnTower(item) and # records.Towers < 100 then
				local boostPos = item:GetAttribute("BoostPos")
				table.insert(records.Towers, {
					RuntimeId = item.Name,
					Unit = item:GetAttribute("ID"),
					Upgrade = item:GetAttribute("Upgrade"),
					SellPrice = item:GetAttribute("SellPrice"),
					Position = typeof(boostPos) == "Vector3" and {
						boostPos.X,
						boostPos.Y,
						boostPos.Z
					} or nil
				})
			end
		end
	end
	local value = "SkibidiTD_Debug_" .. tostring(os.time()) .. ".json"
	if type(writefile) ~= "function" then
		return nil, "writefile unavailable"
	end
	local ok2, result2 = pcall(function()
		writefile(value, HttpService:JSONEncode(records))
	end)
	return ok2 and value or nil, ok2 and nil or tostring(result2)
end
local function stopPlayback(reason)
	local session = State.PlaySession
	-- Invalidate first so callbacks cannot schedule more work during cleanup.
	State.PlaySession = nil
	State.Playing = false
	cleanupPlaybackSession(session)
	State.RuntimeHandles = {}
	State.UsedRuntimeTowers = nil
	State.UpgradeWait, State.PlacementWait, State.AbilityWait = nil, nil, nil
	if reason and (reason:find("failed", 1, true) or reason:find("timed out", 1, true) or reason:find("error", 1, true)) then
		State.LastPlaybackFailure = reason
		pcall(Hub.ExportDebug, reason)
	end
	if reason then
		setStatus("Stopped", reason)
	end
end
local function startPlayback()
	if State.Recording then
		return false, "Stop recording first"
	end
	if not remotesReady() then
		return false, "Playback is armed and will start after entering a match"
	end
	if State.Playing then
		return false, "Playback is already running"
	end
	if # State.Actions == 0 then
		return false, "Load or record a profile first"
	end
	State.PlaySession = { Connections = {} }
	local playSession = State.PlaySession
	State.Playing = true
	State.AutoPlaybackStarted = true
	State.PlaybackFirstActionArmed = false
	State.PlaybackFirstActionDone = false
	State.RuntimeHandles = {}
	State.PlaybackIndex = 0
	State.UpgradeWait, State.PlacementWait = nil, nil
	State.UsedRuntimeTowers = setmetatable({}, {
		__mode = "k"
	})
	State.AbilityLastUsed = {}
	State.AbilityAttempts = {}
	State.AbilityWait = nil
	task.spawn(function()
		local ok2, result2 = xpcall(function()
			setStatus("Playback", string.format("Running %s", State.ProfileName))
			local now = os.clock()
			if Hub.MatchFlow then
				local value, value1 = Hub.MatchFlow.PreparePlayback(playSession)
				if not value then
					if isPlaying(playSession) then
						stopPlayback(value1 or "Preset loadout could not be applied")
					end
					return
				end
			end
			while isPlaying(playSession) and not isMatchEnded() and getWave() < 1 do
				now = os.clock()
				task.wait(0.03)
			end
			-- Normalize the macro timeline to its first action: the first tower should
			-- be eligible immediately at Wave 1, while later actions keep their recorded spacing.
			local firstActionRecordedAt = math.max(0, tonumber(State.Actions[1] and State.Actions[1].RecordedAt) or 0)
			now = os.clock() - firstActionRecordedAt
			for index, item in ipairs(State.Actions) do
				if not isPlaying(playSession) or isMatchEnded() then
					break
				end
				if index == 1 then
					State.PlaybackFirstActionArmed = true
				end
				State.PlaybackIndex = index
				updateActionSummary()
				setStatus("Playback", string.format("%d/%d  %s  W%d", index, # State.Actions, item.Type or "?", item.Wave or 0))
				local value = waitForActionTime(item, now, playSession)
				if not isPlaying(playSession) then
					return
				end
				if isMatchEnded() then
					stopPlayback("Match ended before the macro finished")
					break
				end
				if not value then
					-- A single delayed action must not abort the remaining macro.
					setStatus("Playback", string.format("Skipped action %d/%d: timed out waiting for %s | Money %s", index, #State.Actions, State.PlaybackMode, formatMoney()))
				else
					local actionSucceeded, actionError
					if item.Type == "Place" then
						actionSucceeded, actionError = playPlace(item, playSession)
					elseif item.Type == "Upgrade" then
						actionSucceeded, actionError = playUpgrade(item, playSession)
					elseif item.Type == "Sell" then
						actionSucceeded, actionError = playSell(item, playSession)
					elseif item.Type == "Target" then
						if isLegacyDuplicateTarget(index, item) then
							actionSucceeded = true
						else
							actionSucceeded, actionError = playTargetMode(item, playSession)
						end
					elseif item.Type == "Ability" then
						actionSucceeded, actionError = playAbility(item, playSession)
					elseif item.Type == "BoostLink" then
						actionSucceeded, actionError = playBoostLink(item, playSession)
					else
						actionSucceeded, actionError = false, "Unknown action type: " .. tostring(item.Type)
					end
					if not isPlaying(playSession) then
						return
					end
					if not actionSucceeded then
						-- Placement failures are skipped, not blindly resent: a late server receipt
						-- could otherwise create a duplicate tower on the next attempt.
						setStatus("Playback", string.format("Skipped action %d/%d: %s", index, #State.Actions, tostring(actionError or "unknown error")))
					end
				end
				if index == 1 then
					State.PlaybackFirstActionDone = true
				end
			end
			if isPlaying(playSession) then
				State.Playing = false
				cleanupPlaybackSession(playSession)
				State.PlaySession = nil
				State.RuntimeHandles = {}
				State.UsedRuntimeTowers = nil
				State.UpgradeWait, State.PlacementWait, State.AbilityWait = nil, nil, nil
				updateActionSummary()
				setStatus("Playback complete", "Waiting for the match to end")
			end
		end, function(data)
			return tostring(data)
		end)
		if not ok2 and isPlaying(playSession) then
			stopPlayback("Playback error: " .. tostring(result2))
		end
	end)
	return true
end
-- Lobby modes, chapters, and modifiers
local chaptersByMode = {
	Story = {
		"Chapter 1",
		"Chapter 1.5",
		"Chapter 2",
		"Chapter 3",
		"Chapter 4",
		"Chapter 5",
		"Chapter 6",
		"Chapter 7",
		"Chapter 8",
		"Chapter 9"
	},
	Multiverse = {
		"Multiverse Chapter 1",
		"Multiverse Chapter 2",
		"Multiverse Chapter 3"
	},
	Nightmare = {
		"Suspicious Detections",
		"Spreaded Corruption",
		"Rise Of The Corruption",
		"A Fight From the Past",
		"Land Of Creation",
		"The Final Showdown",
		"The Last Base",
		"Civil War"
	},
	Event = {
		"Act -2",
		"Act -1",
		"Act 1 2026",
		"Act 2 2026",
		"Act 3 2026",
		"Partner Takeover",
		"Skibi Trials"
	},
	Versus = {
		"Versus 1v1",
		"Versus 2v2",
		"Versus 3v3",
		"Versus 4v4"
	},
	Endless = {
		"Normal",
		"Roguelite"
	},
	Episodes = {
		"Episode 79",
		"Humble Beginnings"
	},
	Raid = {
		"WorldRaid"
	}
}
local modifierList = {
	"LBRUN",
	"BPXP",
	"NormalRegen",
	"GodlyRegen",
	"WeakerEnemies",
	"WayWeakerEnemies",
	"StrongerEnemies",
	"WayStrongerEnemies",
	"GodlyEnemies",
	"LessEnemies",
	"DoubleEnemies",
	"AcceleratingEnemies",
	"DeceleratingEnemies",
	"RandomSpeed",
	"RandomHP",
	"AllHidden",
	"NoHidden",
	"AllAir",
	"NoAir",
	"Ambushed",
	"AggressiveFoes",
	"AdvancedForces",
	"Deflection",
	"TowerNerf",
	"TowerNerf2",
	"ThreePlacement",
	"TenPlacement",
	"OnePlacement",
	"InfinitePlacement",
	"DoubleWaveMoney",
	"LessWaveMoney",
	"MoreDamageMoney",
	"LessDamageMoney",
	"MarketLock",
	"BudgetOptimization",
	"MassiveTowers",
	"PositionShift",
	"SmallWar",
	"ToiletSpawner",
	"RandomLoadout",
	"Freeze",
	"InfiniteHP",
	"InfiniteMoney",
	"SandboxMap"
}
local modifierSet = {}
local modifierByLabel = {}
local labelByModifier = {}
local modifierLabels = {}
local modifierLabelOverrides = {
	LBRUN = "Leaderboard Run",
	BPXP = "Battlepass XP"
}
local function modifierLabel(data)
	local value = modifierLabelOverrides[data]
	if value then
		return value
	end
	return data:gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2"):gsub("(%d)(%a)", "%1 %2")
end
for _, item6 in ipairs(modifierList) do
	modifierSet[item6] = true
	local sourceValue = modifierLabel(item6)
	modifierByLabel[sourceValue] = item6
	labelByModifier[item6] = sourceValue
	table.insert(modifierLabels, sourceValue)
end
local function normalizeModifiers(data)
	local records = {}
	if type(data) ~= "table" then
		return records
	end
	for index, item in pairs(data) do
		local value
		if type(index) == "string" and item == true then
			value = index
		elseif type(index) == "number" and type(item) == "string" then
			value = item
		end
		local result = value and (modifierByLabel[value] or value)
		if result and modifierSet[result] then
			records[result] = true
		end
	end
	return records
end
State.LobbyModifiers = normalizeModifiers(State.LobbyModifiers)
local function modifiersToLabels(data)
	local records = {}
	for _, item in ipairs(modifierList) do
		if data[item] == true then
			table.insert(records, labelByModifier[item])
		end
	end
	return records
end
local function applyLobbyModifiers()
	local records = {}
	for _, item in ipairs(modifierList) do
		if State.LobbyModifiers[item] == true then
			table.insert(records, item)
		end
	end
	if # records == 0 then
		return true
	end
	refreshRemotes()
	if not Remotes.ModifierState or not Remotes.ModifierState:IsA("RemoteEvent") then
		return false, "ReplicatedStorage.ModifierState was not found"
	end
	setStatus("Auto Join", string.format("Applying %d modifier(s)", # records))
	for _, item3 in ipairs(records) do
		local ok2, result2 = pcall(function()
			Remotes.ModifierState:FireServer(item3, true)
		end)
		if not ok2 then
			return false, item3 .. ": " .. tostring(result2)
		end
		task.wait(0.05)
	end
	return true
end
local function scanChapters()
	local value = getPlayerGui()
	for _, item in ipairs({
		"Main",
		"Frame",
		"Layout",
		"Servers",
		"List"
	}) do
		value = value and value:FindFirstChild(item)
	end
	if not value then
		return
	end
	local records = {
		Story = "Story",
		Multiverse = "Multiverse",
		Event = "Nightmare",
		Event2 = "Event",
		Endless = "Endless",
		Versus = "Versus",
		Episodes = "Episodes"
	}
	for index, item3 in pairs(records) do
		local result, copiedData = value:FindFirstChild(index), {}
		if result then
			for _, item4 in ipairs(result:GetChildren()) do
				if item4.Name == "Chapter" then
					local init = item4:FindFirstChild("Init")
					local child = init and init:FindFirstChild("TXT")
					local element = child and child:FindFirstChild("CH")
					local label = element and tostring(element.Text) or ""
					if label ~= "" and not table.find(copiedData, label) then
						table.insert(copiedData, label)
					end
				end
			end
		end
		if # copiedData > 0 then
			chaptersByMode[item3] = copiedData
		end
	end
end
local function getChapters(data)
	scanChapters()
	if data ~= "All" then
		return table.clone(chaptersByMode[data] or {})
	end
	local records = {}
	for _, item in pairs(chaptersByMode) do
		for _, item3 in ipairs(item) do
			if not table.find(records, item3) then
				table.insert(records, item3)
			end
		end
	end
	local servers = ReplicatedStorage:FindFirstChild("Servers")
	if servers then
		for _, item4 in ipairs(servers:GetChildren()) do
			if not table.find(records, item4.Name) then
				table.insert(records, item4.Name)
			end
		end
	end
	table.sort(records)
	return records
end
-- Webhook and match reports
local Reports = {}
Hub.Reports = Reports
function Reports.ValidURL(data)
	return type(data) == "string"
		and (data:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+$") ~= nil
			or data:match("^https://discordapp%.com/api/webhooks/%d+/[%w_%-]+$") ~= nil)
end
function Reports.Escape(data)
	return tostring(data or ""):gsub("([\\`*_~|<>])", "\\%1"):sub(1, 900)
end
function Reports.Post(data, options)
	if not Reports.ValidURL(data) then
		return false, "Enter a valid webhook URL"
	end
	local value = http_request or request or syn and syn.request or fluxus and fluxus.request
	if type(value) ~= "function" then
		return false, "Executor HTTP unavailable"
	end
	local records = {
		username = "Skibidi Defense Hub",
		allowed_mentions = {
			parse = {}
		},
		embeds = {
			options
		}
	}
	local ok2, result2 = pcall(function()
		return value({
			Url = data,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode(records)
		})
	end)
	if not ok2 then
		return false, "HTTP request failed"
	end
	local result = type(result2) == "table" and tonumber(result2.StatusCode or result2.Status)
	return result ~= nil and result >= 200 and result < 300, result and "HTTP " .. result or "HTTP result unconfirmed"
end
function Reports.FormatTime(data)
	data = tonumber(data)
	if not data then
		return "Unavailable"
	end
	data = math.floor(math.max(0, data))
	return string.format("%02d:%02d", math.floor(data / 60), data % 60)
end
function Reports.Lines(data)
	local records = {}
	for index in pairs(data) do
		records[# records + 1] = index
	end
	table.sort(records)
	local copiedData = {}
	for _, item in ipairs(records) do
		copiedData[# copiedData + 1] = "\226\128\162 " .. Reports.Escape(item) .. ": +" .. tostring(data[item])
	end
	return # copiedData > 0 and table.concat(copiedData, "\n"):sub(1, 1000) or "No reward reported"
end
function Reports.ParseRewards(data)
	local records = {}
	for item0, item1 in tostring(data or ""):gmatch("%+%s*([%d,]+)%s+([^!\n;]+)") do
		local value = item0:gsub(",", "")
		local num = tonumber(value)
		item1 = item1:gsub("^%s+", ""):gsub("%s+$", "")
		if num and item1 ~= "" then
			records[item1] = (records[item1] or 0) + num
		end
	end
	return records
end
function Reports.Visible(data)
	while data do
		if data:IsA("GuiObject") and not data.Visible then
			return false
		end
		if data:IsA("ScreenGui") and not data.Enabled then
			return false
		end
		data = data.Parent
	end
	return true
end
function Reports.MatchRewards()
	local value = getGameEndedGui()
	local records, copiedData = {}, {}
	if value then
		for _, item in ipairs(value:GetDescendants()) do
			if (item:IsA("TextLabel") or item:IsA("TextButton")) and Reports.Visible(item) then
				local result = tostring(item.Text or ""):gsub("<[^>]->", "")
				local lowered = result:lower()
				local child = next(Reports.ParseRewards(result)) ~= nil
				local element = item
				while element and element ~= value do
					if element.Name:lower():find("reward", 1, true) then
						child = true
						break
					end
					element = element.Parent
				end
				if child and result ~= "" and not copiedData[result] and # records < 12 then
					copiedData[result] = true
					records[# records + 1] = Reports.Escape(result)
				elseif lowered:find("reward", 1, true) and # result > 12 and not copiedData[result] and # records < 12 then
					copiedData[result] = true
					records[# records + 1] = Reports.Escape(result)
				end
			end
		end
	end
	return # records > 0 and table.concat(records, "\n"):sub(1, 1000) or "Unavailable"
end
function Reports.AccountTotals()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local records = {}
	if leaderstats then
		for _, item in ipairs(leaderstats:GetChildren()) do
			local lowered = item.Name:lower()
			if lowered == "crystals" or lowered == "jacks" or lowered == "credits" or lowered == "gems" or lowered == "candy" or lowered == "coins" then
				local ok2, result2 = pcall(function()
					return item.Value
				end)
				if ok2 then
					records[# records + 1] = "\226\128\162 " .. Reports.Escape(item.Name) .. ": " .. Reports.Escape(result2)
				end
			end
		end
	end
	return # records > 0 and table.concat(records, "\n"):sub(1, 1000) or "Unavailable"
end
function Reports.BuildMatch()
	local value = getMatchResult()
	local result = State.ReportStartedAt and (State.ReportEndedAt or os.clock()) - State.ReportStartedAt
	return {
		title = "Skibidi Defense Match Report",
		description = "**Stage:** " .. Reports.Escape(State.LobbyChapter) .. "\n**Mode:** " .. Reports.Escape(State.LobbyMode) .. "\n**Result:** " .. Reports.Escape(value),
		color = value == "Victory" and 65280 or value == "Defeat" and 16711680 or 16776960,
		fields = {
			{
				name = "Player Info",
				value = "\240\159\145\164 Name: ||" .. Reports.Escape(LocalPlayer.Name) .. "||\n\240\159\140\138 Waves: " .. getWave() .. "\n\226\157\164\239\184\143 Base HP: " .. Reports.Escape(getBaseHealthText()),
				inline = true
			},
			{
				name = "Clear Time",
				value = "\226\143\177\239\184\143 " .. Reports.FormatTime(result),
				inline = true
			},
			{
				name = "Match Rewards",
				value = Reports.MatchRewards(),
				inline = false
			},
			{
				name = "Account Totals",
				value = Reports.AccountTotals(),
				inline = false
			}
		},
		image = {
			url = "https://i.postimg.cc/1RYRdwrS/Bo-suu-tap.jpg"
		},
		footer = {
			text = "Made By Kero",
			icon_url = "https://i.postimg.cc/HWKcyfKJ/download-(2).jpg"
		},
		timestamp = DateTime.now():ToIsoDate()
	}
end
sendWebhookMessage = function(data, options, callback)
	if not State.WebhookEnabled then
		return false, "Webhook is disabled"
	end
	return Reports.Post(State.WebhookURL, {
		title = data,
		description = options,
		color = callback or 5793266,
		footer = {
			text = "Made By Kero"
		}
	})
end
sendMatchEndReport = function()
	if not State.WebhookEnabled or not State.WebhookMatchEnd then
		return
	end
	local ok2, result2 = pcall(Reports.BuildMatch)
	if not ok2 then
		State.LastWebhookError = tostring(result2)
		return false, State.LastWebhookError
	end
	local value, value1 = Reports.Post(State.WebhookURL, result2)
	State.LastWebhookResult = value and "Sent" or value1
	return value, value1
end
-- Match lifecycle and loadout integration
local MatchFlow = {
	Bound = {},
	Presets = {},
	Cutscene = setmetatable({}, {
		__mode = "k"
	})
}
Hub.MatchFlow = MatchFlow
function MatchFlow.Path(data, options)
	for item0 in options:gmatch("[^/]+") do
		data = data and data:FindFirstChild(item0)
	end
	return data
end
function MatchFlow.Visible(data)
	if not data or not data.Parent then
		return false
	end
	while data do
		if data:IsA("GuiObject") and not data.Visible then
			return false
		end
		if data:IsA("ScreenGui") and not data.Enabled then
			return false
		end
		data = data.Parent
	end
	return true
end
function MatchFlow.Click(data)
	if not data or not data:IsA("GuiButton") or not MatchFlow.Visible(data) or data.Active == false then
		return false, "Game button unavailable"
	end
	if type(getconnections) == "function" then
		for _, item in ipairs({
			"Activated",
			"MouseButton1Click"
		}) do
			local ok2, result2 = pcall(function()
				return getconnections(data[item])
			end)
			if ok2 and type(result2) == "table" then
				local isActive = false
				for _, item3 in ipairs(result2) do
					if item3.Enabled ~= false and item3.Connected ~= false then
						local ok3 = pcall(function()
							if type(item3.Fire) == "function" then
								item3:Fire()
							elseif type(item3.Function) == "function" then
								item3.Function()
							else
								error("No callable handler")
							end
						end)
						isActive = isActive or ok3
					end
				end
				if isActive then
					return true
				end
			end
		end
	end
	local ok4 = pcall(function()
		local absolutePosition, absoluteSize = data.AbsolutePosition, data.AbsoluteSize
		if absoluteSize.X <= 0 or absoluteSize.Y <= 0 then
			error("Button has no screen bounds")
		end
		local value, result = absolutePosition.X + absoluteSize.X / 2, absolutePosition.Y + absoluteSize.Y / 2
		local child = data:FindFirstAncestorWhichIsA("ScreenGui")
		if child and not child.IgnoreGuiInset then
			local element = game:GetService("GuiService"):GetGuiInset()
			value = value + element.X
			result = result + element.Y
		end
		local virtualInputManager = game:GetService("VirtualInputManager")
		virtualInputManager:SendMouseButtonEvent(value, result, 0, true, game, 0)
		virtualInputManager:SendMouseButtonEvent(value, result, 0, false, game, 0)
	end)
	return ok4, ok4 and nil or "Executor cannot activate the game button"
end
function MatchFlow.ClickResult(data)
	if not isMatchEnded() then
		return false, "Waiting for result screen"
	end
	return MatchFlow.Click(MatchFlow.Path(getGameEndedGui(), "Frame/" .. data))
end
function MatchFlow.ValidateLoadout(data)
	if type(data) ~= "table" or type(data.Towers) ~= "table" or # data.Towers < 1 or # data.Towers > 12 then
		return nil
	end
	local records = {}
	for _, item in ipairs(data.Towers) do
		if type(item) ~= "string" or # item == 0 or # item > 100 then
			return nil
		end
		records[# records + 1] = item
	end
	return {
		Index = tonumber(data.Index),
		Name = tostring(data.Name or "Preset"):sub(1, 100),
		Chapter = tostring(data.Chapter or ""):sub(1, 100),
		Towers = records
	}
end
function MatchFlow.SameTowers(data, options)
	if type(data) ~= "table" or type(options) ~= "table" or # data ~= # options or # data == 0 then
		return false
	end
	for index, item in ipairs(data) do
		if item ~= options[index] then
			return false
		end
	end
	return true
end
function MatchFlow.ReadCards()
	local value = MatchFlow.Path(getPlayerGui(), "EasyLoadout/Root/Cards")
	local records = {}
	if value then
		for i = 1, 4 do
			local result = value:FindFirstChild("Card" .. i)
			local child = result and result:FindFirstChild("List")
			local element = MatchFlow.Path(result, "Banner/Title")
			local copiedData = {}
			if child then
				for i2 = 1, 12 do
					local label = MatchFlow.Path(child, "Row" .. i2 .. "/Name")
					if not label then
						break
					end
					copiedData[# copiedData + 1] = label.Text
				end
			end
			if # copiedData > 0 then
				records[i] = {
					Name = element and element.Text or "Preset " .. i,
					Towers = copiedData
				}
			end
		end
	end
	return records, value
end
function MatchFlow.PickerOpen()
	local value = MatchFlow.Path(getPlayerGui(), "EasyLoadout/Root")
	local result = MatchFlow.Path(value, "Header/Title")
	return MatchFlow.Visible(value) and not (result and tostring(result.Text):upper():find("LOCKED", 1, true))
end
function MatchFlow.OnShow(data)
	if type(data) ~= "table" or type(data.Presets) ~= "table" then
		return
	end
	MatchFlow.Presets = data.Presets
	MatchFlow.Chapter = data.Chapter
	MatchFlow.Applied = nil
	MatchFlow.Requested = nil
	MatchFlow.ChoiceEpoch = {}
	MatchFlow.HydrateAfter = os.clock() + 0.5
end
function MatchFlow.HydrateApplied()
	if MatchFlow.Applied or os.clock() < (MatchFlow.HydrateAfter or 0) then
		return
	end
	local value = MatchFlow.Path(getPlayerGui(), "EasyLoadout/Root/Header/Title")
	if not value or not tostring(value.Text):upper():find("LOCKED IN", 1, true) then
		return
	end
	local value, value1 = MatchFlow.ReadCards()
	local result
	for index, item in pairs(value) do
		local child = MatchFlow.Path(value1, "Card" .. index .. "/Picked")
		local element = child and child:FindFirstChild("Label")
		if child and child.Visible and element and tostring(element.Text):upper():find("LOCKED IN", 1, true) then
			if result then
				return
			end
			result = {
				Index = index,
				Name = item.Name,
				Chapter = MatchFlow.Chapter,
				Towers = item.Towers
			}
		end
	end
	MatchFlow.Applied = MatchFlow.ValidateLoadout(result)
end
function MatchFlow.RecordLoadout()
	MatchFlow.HydrateApplied()
	if not State.Recording or not MatchFlow.Applied then
		return
	end
	State.MacroLoadout = MatchFlow.ValidateLoadout(MatchFlow.Applied)
	if State.MacroLoadout then
		if getWave() < 1 and # State.Actions == 0 then
			State.RecordStartedAt = os.clock()
			State.RecordAwaitFirstWave = true
		end
		setStatus("Recording", "Loadout confirmed: " .. State.MacroLoadout.Name)
		if UI.LoadoutStatus then
			UI.LoadoutStatus:SetDesc(State.MacroLoadout.Name)
		end
	end
end
function MatchFlow.UpdateRecorderClock()
	if State.Recording and State.RecordAwaitFirstWave and getWave() > 0 then
		State.RecordAwaitFirstWave = false
		State.RecordStartedAt = os.clock()
	end
end
function MatchFlow.UpdateLoadoutStatus()
	local value = State.MacroLoadout and State.MacroLoadout.Name or "Not recorded"
	if UI.LoadoutStatus and MatchFlow.LoadoutText ~= value then
		MatchFlow.LoadoutText = value
		UI.LoadoutStatus:SetDesc(value)
	end
end
function MatchFlow.SaveCurrentLoadout()
	if State.Playing or State.Recording then
		return false, "Stop recording/playback first"
	end
	if State.ProfileName == "" then
		return false, "Select a macro first"
	end
	MatchFlow.HydrateApplied()
	local value = MatchFlow.ValidateLoadout(MatchFlow.Applied)
	if not value then
		return false, "Choose a preset in the game first"
	end
	local macroLoadout = State.MacroLoadout
	State.MacroLoadout = value
	local ok2, result2, result22 = pcall(saveProfile, State.ProfileName)
	if not ok2 or not result2 then
		State.MacroLoadout = macroLoadout
		return false, tostring(ok2 and result22 or result2)
	end
	MatchFlow.UpdateLoadoutStatus()
	return true, value.Name
end
function MatchFlow.OnApplied(data)
	local presets = MatchFlow.Presets
	if not next(presets) then
		presets = MatchFlow.ReadCards()
	end
	for index, item in pairs(presets) do
		if MatchFlow.SameTowers(data, item.Towers) then
			MatchFlow.Applied = MatchFlow.ValidateLoadout({
				Index = index,
				Name = item.Name,
				Chapter = MatchFlow.Chapter,
				Towers = data
			})
			MatchFlow.RecordLoadout()
			return
		end
	end
end
function MatchFlow.Bind()
	local easyLoadout = ReplicatedStorage:FindFirstChild("EasyLoadout")
	local function helperFunction(data, options)
		if data and not MatchFlow.Bound[data] then
			MatchFlow.Bound[data] = true
			trackConnection(State.Connections, data.OnClientEvent:Connect(function(...)
				if State.Running then
					options(...)
				end
			end))
		end
	end
	helperFunction(easyLoadout and easyLoadout:FindFirstChild("Show"), MatchFlow.OnShow)
	helperFunction(easyLoadout and easyLoadout:FindFirstChild("Applied"), MatchFlow.OnApplied)
end
-- Fix: keep the recorded loadout separate from the live preset list returned by ReadCards().
function MatchFlow.PreparePlayback(session)
	local recordedLoadout = MatchFlow.ValidateLoadout(State.MacroLoadout)
	if not recordedLoadout then
		return true
	end
	local deadline = os.clock() + 70
	while isPlaying(session) and not isMatchEnded() and os.clock() < deadline do
		MatchFlow.Bind()
		MatchFlow.HydrateApplied()
		if MatchFlow.Applied then
			return MatchFlow.SameTowers(recordedLoadout.Towers, MatchFlow.Applied.Towers), "A different preset is already applied"
		end
		local availablePresets, cardsGui = MatchFlow.ReadCards()
		if next(MatchFlow.Presets) then
			availablePresets = MatchFlow.Presets
		end
		if MatchFlow.PickerOpen() then
			local matchingPresetIndex
			for index, preset in pairs(availablePresets) do
				if MatchFlow.SameTowers(recordedLoadout.Towers, preset.Towers) then
					matchingPresetIndex = index
					break
				end
			end
			if not matchingPresetIndex and next(availablePresets) then
				return false, "Recorded loadout is unavailable in this map"
			end
			local choiceEpoch = MatchFlow.ChoiceEpoch or cardsGui
			if matchingPresetIndex and cardsGui and MatchFlow.Requested ~= choiceEpoch then
				local card = cardsGui:FindFirstChild("Card" .. matchingPresetIndex)
				local clicked, clickError = MatchFlow.Click(card and (card:FindFirstChild("Select") or card))
				if clicked then
					MatchFlow.Requested = choiceEpoch
				else
					setStatus("Playback", "Waiting for loadout button | " .. tostring(clickError))
				end
			end
			setStatus("Playback", "Waiting for confirmed loadout: " .. recordedLoadout.Name)
		elseif getWave() > 0 and not MatchFlow.Requested then
			return false, "Cannot confirm recorded loadout; choose it before starting the match"
		elseif MatchFlow.Requested then
			setStatus("Playback", "Waiting for confirmed loadout: " .. recordedLoadout.Name)
		else
			setStatus("Playback", "Waiting for preset loadout selection")
		end
		task.wait(0.2)
	end
	return false, isPlaying(session) and "Loadout selection timed out" or "Playback stopped"
end

function MatchFlow.SkipCutscenes()
	if not State.AutoSkipCutscene then
		return
	end
	local value = getPlayerGui()
	if not value then
		return
	end
	local records = {}
	for _, item in ipairs(value:GetChildren()) do
		local lowered = item.Name:lower()
		if lowered:find("intro", 1, true) or lowered:find("cutscene", 1, true) then
			for _, item3 in ipairs(item:GetDescendants()) do
				records[# records + 1] = item3
			end
		end
	end
	for _, item4 in ipairs(records) do
		if item4:IsA("TextButton") then
			local uppered = tostring(item4.Text or ""):upper()
			if uppered:find("SKIP CUTSCENE", 1, true) or MatchFlow.Cutscene[item4] then
				local result = MatchFlow.Visible(item4)
				local child = MatchFlow.Cutscene[item4] or {}
				MatchFlow.Cutscene[item4] = child
				if not result then
					child.Visible = false
				elseif uppered:find("VOTED", 1, true) then
					child.Sent = true
					child.Visible = true
				else
					if not child.Visible then
						child.Sent = false
					end
					child.Visible = true
					if not child.Sent and os.clock() >= (child.NextAt or 0) then
						child.NextAt = os.clock() + 1
						child.Sent = MatchFlow.Click(item4) == true
					end
				end
			end
		end
	end
end
function MatchFlow.ReportMatchEnd()
	local ok2, result2, result22 = pcall(sendMatchEndReport)
	State.LastWebhookError = not ok2 and tostring(result2) or result2 == false and tostring(result22) or nil
	State.LiveRoundStarted = false
	return ok2 and result2 ~= false
end
function MatchFlow.EndStep(hasMatchEnded)
	if not hasMatchEnded then
		if MatchFlow.End and MatchFlow.End.ChoiceEpoch == MatchFlow.ChoiceEpoch then
			MatchFlow.Applied = nil
			MatchFlow.Requested = nil
			MatchFlow.ChoiceEpoch = nil
		end
		MatchFlow.End = nil
		return
	end

	-- Replay is a supported After Match action; keep it distinct from lobby return.
	local selectedAction = State.PendingLobbyReturn and "Return Lobby" or State.AfterMatch
	if selectedAction ~= "Replay" and selectedAction ~= "Return Lobby" then
		return
	end

	local now = os.clock()
	local endState = MatchFlow.End
	if not endState or endState.Action ~= selectedAction then
		endState = {
			Action = selectedAction,
			NextAt = now + 0.5,
			ChoiceEpoch = MatchFlow.ChoiceEpoch
		}
		MatchFlow.End = endState
	end

	if endState.Sent then
		if selectedAction == "Return Lobby" and not endState.Fallback and now - endState.Sent >= 12 then
			endState.Fallback = true
			if UI.SaveConfigNow then
				pcall(UI.SaveConfigNow)
			end
			if Hub.QueueTeleport then
				pcall(Hub.QueueTeleport)
			end
			local teleportRequested = pcall(function()
				TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
			end)
			setStatus("Match end", teleportRequested and "Lobby teleport requested" or "Lobby teleport failed")
		end
		return
	end

	if now < endState.NextAt then
		return
	end
	endState.NextAt = now + 1
	if UI.SaveConfigNow then
		pcall(UI.SaveConfigNow)
	end
	if Hub.QueueTeleport then
		pcall(Hub.QueueTeleport)
	end

	-- Replay must target Frame/replay; Return Lobby targets Frame/back.
	local resultButton = selectedAction == "Replay" and "replay" or "back"
	local clickSucceeded, clickError = MatchFlow.ClickResult(resultButton)
	if clickSucceeded then
		endState.Sent = now
		setStatus("Match end", selectedAction == "Replay" and "Replay vote sent; waiting for game" or "Returning to lobby")
	else
		setStatus("Match end", tostring(clickError))
		if selectedAction == "Return Lobby" then
			endState.Sent = now - 12
		end
	end
end
MatchFlow.Bind()
-- Game speed and wave controls
Hub.SpeedControl = {}
do
	local speedControl = Hub.SpeedControl
	local function setupSpeedControl(data)
		data = tonumber(data)
		return data and data == data and data >= 1 and data < math.huge and data or nil
	end
	function speedControl.Reset()
		speedControl.Pending, speedControl.NextAt, speedControl.Signature, speedControl.DelayStartedAt = nil, 0, nil, nil
	end
	function speedControl.Read()
		local game2 = ReplicatedStorage:FindFirstChild("Game")
		local value = game2 and game2:FindFirstChild("Speed")
		if value then
			local ok2, result2 = pcall(function()
				return tonumber(value.Value)
			end)
			if ok2 and result2 and result2 >= 0 and result2 < math.huge then
				return result2
			end
		end
		return getSpeedMultiplier()
	end
	function speedControl.Limit()
		local game2 = ReplicatedStorage:FindFirstChild("Game")
		local value = game2 and game2:FindFirstChild("Speed")
		local result = getPlayerGui()
		local child = result and result:FindFirstChild("Towers")
		local element = child and child:FindFirstChild("speedButton")
		local function helperFunction(data, options)
			if not data then
				return nil
			end
			for _, item in ipairs(options) do
				local ok2, result2 = pcall(data.GetAttribute, data, item)
				if ok2 and setupSpeedControl(result2) then
					return setupSpeedControl(result2)
				end
				local label = data:FindFirstChild(item)
				if label then
					ok2, result2 = pcall(function()
						return label.Value
					end)
					if ok2 and setupSpeedControl(result2) then
						return setupSpeedControl(result2)
					end
				end
			end
		end
		local records = {
			"MaxSpeed",
			"SpeedLimit",
			"MaximumSpeed",
			"MaxGameSpeed"
		}
		local textValue = helperFunction(value, {
			"MaxSpeed",
			"SpeedLimit",
			"MaximumSpeed",
			"MaxGameSpeed",
			"Max",
			"Limit"
		}) or helperFunction(game2, records) or helperFunction(element, records)
		local indexValue = element and element:FindFirstChild("ClockText")
		local cachedValue = tostring(textValue) .. "/" .. tostring(indexValue and indexValue.Visible) .. "/" .. tostring(indexValue and indexValue.Text)
		return textValue, cachedValue
	end
	function speedControl.Step(data)
		-- Enforce the configured delay here so no caller can bypass it.
		local requiredDelay = math.clamp(tonumber(State.SpeedScaleDelay) or 1, 1, 30)
		if not speedControl.DelayStartedAt then
			speedControl.DelayStartedAt = data
			return
		end
		if data - speedControl.DelayStartedAt < requiredDelay then
			return
		end
		-- Fix: preserve currentSpeed; the previous second local declaration shadowed it with maxSpeed.
		local currentSpeed = speedControl.Read()
		local maxSpeed, limitSignature = speedControl.Limit()
		local modeSignature = State.AutoMaxSpeed and "max" or "selected"
		limitSignature = modeSignature .. "/" .. tostring(limitSignature) .. "/" .. tostring(State.Speed)
		if limitSignature ~= speedControl.Signature then
			speedControl.Signature, speedControl.Pending, speedControl.NextAt = limitSignature, nil, data
		end
		local pending = speedControl.Pending
		if pending then
			if currentSpeed and currentSpeed ~= pending.Before then
				speedControl.Pending, speedControl.NextAt = nil, data
			elseif data - pending.At < .8 then
				return
			else
				speedControl.Pending, speedControl.NextAt = nil, data + 1
				return
			end
		end
		if data < (speedControl.NextAt or 0) or not Remotes.Speed then
			return
		end
		local targetSpeed
		if State.AutoMaxSpeed then
			targetSpeed = maxSpeed or (currentSpeed and currentSpeed >= 1 and currentSpeed + 1 or 1)
		else
			targetSpeed = math.clamp(tonumber(State.Speed) or 1, 1, 6)
		end
		if currentSpeed == targetSpeed then
			return
		end
		local ok2 = pcall(function()
			Remotes.Speed:FireServer(targetSpeed)
		end)
		speedControl.NextAt = data + (ok2 and .1 or 1)
		if ok2 then
			speedControl.Pending = {
				Before = currentSpeed,
				Target = targetSpeed,
				At = data
			}
		end
	end
	speedControl.Reset()
end
local function shouldAutoSkip(wave, stopList)
	for item0 in tostring(stopList or ""):gmatch("%d+") do
		if tonumber(item0) == wave then
			return false
		end
	end
	return true
end
task.spawn(function()
	local count = 0
	local count2 = 0
	local value = nil
	local isActive = false
	local count3 = 0
	local isEnabled = false
	local wasUpdated = false
	local isConnected = false
	local result = - math.huge
	while State.Running do
		local now = os.clock()
		if now - count3 >= 1 then
			count3 = now
			refreshRemotes()
		end
		if now - result >= 0.5 then
			result = now
			Hub.MatchFlow.Bind()
			Hub.MatchFlow.SkipCutscenes()
			Hub.MatchFlow.UpdateLoadoutStatus()
		end
		local child = isMatchEnded()
		Hub.MatchFlow.UpdateRecorderClock()
		local element = towerData ~= nil and towerModels ~= nil and Remotes.Place ~= nil
		local label = State.PlaybackEnabled and State.ProfileName ~= ""
		local textValue = not label or # State.Actions > 0
		local indexValue = textValue and (not label or State.PlaybackFirstActionArmed)
		if element and not child and getWave() > 0 then
			State.LiveRoundStarted = true
			if isConnected or not State.ReportStartedAt then
				State.ReportStartedAt = now
				State.ReportEndedAt = nil
			end
		elseif child and State.ReportStartedAt and not State.ReportEndedAt then
			State.ReportEndedAt = now
		end
		if not element or child then
			State.AutoPlaybackStarted = false
			State.PlaybackFirstActionArmed = false
			State.PlaybackFirstActionDone = false
			isEnabled = false
			value = nil
			isActive = false
			Hub.SpeedControl.Reset()
			wasUpdated = false
		elseif not isEnabled then
			isEnabled = true
			value = nil
			isActive = false
			Hub.SpeedControl.Reset()
			wasUpdated = false
		elseif State.PlaybackEnabled and not State.AutoPlaybackStarted and not State.Playing and not State.Recording and # State.Actions > 0 and UI.StartEnabledPlayback then
			UI.StartEnabledPlayback()
		end
		if State.AutoReady and not child and Remotes.Ready and not Hub.MatchFlow.PickerOpen() and now - count >= (State.ReadyDelay or 1) then
			count = now
			pcall(function()
				Remotes.Ready:FireServer(true)
			end)
		end
		local cachedValue = getPlayerGui()
		local nextValue = cachedValue and cachedValue:FindFirstChild("skipWave")
		local currentValue = nextValue and nextValue.Enabled == true
		if State.AutoSkip and indexValue and not child and Remotes.Skip and currentValue and shouldAutoSkip(getWave(), State.StopAutoSkipAt) and now - count2 >= (State.SkipDelay or 0.35) then
			count2 = now
			pcall(function()
				Remotes.Skip:FireServer(true)
			end)
		end
		local entryValue = (State.AutoSpeed or State.AutoMaxSpeed) and indexValue and element and Remotes.Speed and not child
		if entryValue and State.SpeedConfigLoaded then
			Hub.SpeedControl.Step(now)
		else
			Hub.SpeedControl.Reset()
		end
		if child and not isConnected then
			isConnected = true
			if State.AutoBackLobby and (State.LastCountedJobId ~= game.JobId or State.LiveRoundStarted) then
				State.LastCountedJobId = game.JobId
				State.MatchesCompleted = State.MatchesCompleted + 1
				if State.MatchesCompleted >= State.MatchesBeforeLobby then
					State.PendingLobbyReturn = true
					setStatus("Match cycle complete", "Using the game's Return to Lobby button")
				else
					setStatus("Match counted", string.format("%d/%d matches before lobby", State.MatchesCompleted, State.MatchesBeforeLobby))
				end
				if UI.UpdateMatchCounter then
					UI.UpdateMatchCounter()
				end
				if UI.SaveConfigNow then
					UI.SaveConfigNow()
				elseif UI.QueueSave then
					UI.QueueSave()
				end
			end
			if State.WebhookEnabled and State.WebhookMatchEnd then
				task.wait(1)
			end
			if not State.Running then
				break
			end
			Hub.MatchFlow.ReportMatchEnd()
		elseif not child then
			isConnected = false
		end
		Hub.MatchFlow.EndStep(child)
		task.wait(0.1)
	end
end)
-- Utilities, performance, and reconnection
local Utilities = {
	Connections = {},
	Hidden = {},
	NameConnections = {},
	FPSOriginal = {}
}
Hub.Utilities = Utilities
function Hub.QueueTeleport()
	if not State.Running or not State.AutoExecute or Utilities.Queued then
		return false
	end
	local queueFunction = queue_on_teleport or queueonteleport or syn and syn.queue_on_teleport
	if type(queueFunction) ~= "function" or not hasFileApi or not isfile(MACRO_FOLDER .. "/Hub.lua") then
		Utilities.AutoExecuteError = "Executor needs teleport queue and shared files"
		return false
	end
	local queuedSource = [=[
		if not game:IsLoaded() then game.Loaded:Wait() end
		if game.GameId ~= 4938220315 then return end
		task.wait(3)
		local e = getgenv()
		local player = game:GetService("Players").LocalPlayer
		local key = tostring(game.JobId) .. "/" .. tostring(player.UserId)
		if e.__SkibidiQueuedJob == key or (e.SkibidiDefenseHub and e.SkibidiDefenseHub.State and e.SkibidiDefenseHub.State.Running) then return end
		local ok, raw = pcall(readfile, "SkibidiDefense_Macros/HubConfig.json")
		if not ok then return end
		local good, config = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
		if not good or type(config) ~= "table" or config.AutoExecute == false then return end
		local source = readfile("SkibidiDefense_Macros/Hub.lua")
		local chunk, reason = loadstring(source)
		assert(chunk, reason)
		e.__SkibidiQueuedJob = key
		local loaded, problem = pcall(chunk)
		if not loaded then e.__SkibidiQueuedJob = nil; error(problem) end
	]=]
	local ok2, result2 = pcall(queueFunction, queuedSource)
	Utilities.Queued = ok2
	Utilities.AutoExecuteError = not ok2 and tostring(result2) or nil
	return ok2
end
function Hub.SetFPSBoost(data)
	Utilities.FPSGeneration = (Utilities.FPSGeneration or 0) + 1
	Utilities.FPSEnabled = data == true
	Utilities.FPSQueue = nil
	if not Utilities.FPSEnabled then
		for index, item in pairs(Utilities.FPSOriginal) do
			for index2, item3 in pairs(item) do
				pcall(function()
					index[index2] = item3
				end)
			end
		end
		Utilities.FPSOriginal = {}
		return
	end
	local lighting = game:GetService("Lighting")
	Utilities.FPSSet(lighting, "GlobalShadows", false)
	local fPSGeneration = Utilities.FPSGeneration
	task.defer(function()
		if not State.Running or fPSGeneration ~= Utilities.FPSGeneration then
			return
		end
		for _, item4 in ipairs(Workspace:GetDescendants()) do
			Utilities.QueueFPS(item4)
		end
		for _, item5 in ipairs(lighting:GetDescendants()) do
			Utilities.QueueFPS(item5)
		end
	end)
end
function Utilities.FPSSet(data, options, callback)
	local ok2, result2 = pcall(function()
		return data[options]
	end)
	if not ok2 then
		return
	end
	local value = Utilities.FPSOriginal[data]
	if not value then
		value = {}
		Utilities.FPSOriginal[data] = value
	end
	if value[options] == nil then
		value[options] = result2
	end
	pcall(function()
		data[options] = callback
	end)
end
function Utilities.ApplyFPS(data)
	if data:IsA("ParticleEmitter") or data:IsA("Trail") or data:IsA("Beam") or data:IsA("Smoke") or data:IsA("Fire") or data:IsA("Sparkles") or data:IsA("PostEffect") then
		Utilities.FPSSet(data, "Enabled", false)
	elseif data:IsA("BasePart") then
		Utilities.FPSSet(data, "CastShadow", false)
		Utilities.FPSSet(data, "Material", Enum.Material.SmoothPlastic)
	elseif data:IsA("Decal") or data:IsA("Texture") then
		Utilities.FPSSet(data, "Transparency", 1)
	end
end
function Utilities.QueueFPS(data)
	if not State.Running or not Utilities.FPSEnabled then
		return
	end
	if Utilities.FPSQueue then
		table.insert(Utilities.FPSQueue, data)
		return
	end
	local records = {
		data
	}
	Utilities.FPSQueue = records
	task.defer(function()
		local count, now = 1, os.clock()
		while State.Running and Utilities.FPSEnabled and Utilities.FPSQueue == records and count <= # records do
			local value = records[count]
			if value.Parent then
				pcall(Utilities.ApplyFPS, value)
			end
			count = count + 1
			if count % 16 == 0 and os.clock() - now >= 0.002 then
				task.wait()
				now = os.clock()
			end
		end
		if Utilities.FPSQueue == records then
			Utilities.FPSQueue = nil
		end
	end)
end
function Utilities.RestoreNames()
	for index, item in pairs(Utilities.Hidden) do
		for index2, item3 in pairs(item) do
			pcall(function()
				index[index2] = item3
			end)
		end
	end
	Utilities.Hidden = {}
end
function Utilities.IsOwnName(data)
	local matched2 = tostring(data or ""):match("^%s*(.-)%s*$")
	return matched2 == LocalPlayer.Name or matched2 == "@" .. LocalPlayer.Name or LocalPlayer.DisplayName ~= "" and matched2 == LocalPlayer.DisplayName
end
function Utilities.WatchName(data, options)
	if data:IsA("Humanoid") and options then
		Utilities.Hidden[data] = {
			DisplayName = data.DisplayName,
			NameDisplayDistance = data.NameDisplayDistance
		}
		data.DisplayName, data.NameDisplayDistance = "", 0
		return
	end
	if not (data:IsA("TextLabel") or data:IsA("TextButton")) or Utilities.NameWatched[data] then
		return
	end
	Utilities.NameWatched[data] = true
	local function helperFunction()
		if not State.Running or not Utilities.NamesEnabled then
			return
		end
		local str = tostring(data.Text or "")
		local value = Utilities.IsOwnName(str)
		if options and data:FindFirstAncestorWhichIsA("BillboardGui") then
			value = value or str:find(LocalPlayer.Name, 1, true) ~= nil or LocalPlayer.DisplayName ~= "" and str:find(LocalPlayer.DisplayName, 1, true) ~= nil
		end
		if value then
			if not Utilities.Hidden[data] then
				Utilities.Hidden[data] = {
					Visible = data.Visible,
					TextTransparency = data.TextTransparency,
					TextStrokeTransparency = data.TextStrokeTransparency
				}
			end
			data.Visible, data.TextTransparency, data.TextStrokeTransparency = false, 1, 1
		elseif Utilities.Hidden[data] then
			for index, item in pairs(Utilities.Hidden[data]) do
				data[index] = item
			end
			Utilities.Hidden[data] = nil
		end
	end
	trackConnection(Utilities.NameConnections, data:GetPropertyChangedSignal("Text"):Connect(helperFunction))
	helperFunction()
end
function Hub.SetHideName(data)
	Utilities.NamesEnabled = data == true
	Utilities.NameGeneration = (Utilities.NameGeneration or 0) + 1
	local nameGeneration = Utilities.NameGeneration
	disconnectAll(Utilities.NameConnections)
	Utilities.RestoreNames()
	Utilities.NameWatched = setmetatable({}, {
		__mode = "k"
	})
	if not Utilities.NamesEnabled then
		return
	end
	local function helperFunction(options, callback)
		if not options then
			return
		end
		for _, item in ipairs(options:GetDescendants()) do
			pcall(Utilities.WatchName, item, callback)
		end
		trackConnection(Utilities.NameConnections, options.DescendantAdded:Connect(function(context)
			task.defer(function()
				if State.Running and Utilities.NamesEnabled and nameGeneration == Utilities.NameGeneration then
					pcall(Utilities.WatchName, context, callback)
				end
			end)
		end))
	end
	helperFunction(LocalPlayer.Character, true)
	helperFunction(getPlayerGui(), false)
	pcall(function()
		helperFunction(game:GetService("CoreGui"), false)
	end)
end
function Hub.StartRejoin()
	if Hub.Rejoin then
		return
	end
	local records = {
		Active = true,
		Attempts = 0,
		Connections = {},
		Message = "Monitoring connection"
	}
	Hub.Rejoin = records
	function records.ConnectionError(data)
		if type(data) ~= "string" or data == "" then
			return false
		end
		local lowered = data:lower()
		return lowered:find("disconnect", 1, true) ~= nil
			or lowered:find("kicked", 1, true) ~= nil
			or lowered:find("kick", 1, true) ~= nil
			or lowered:find("lost connection", 1, true) ~= nil
			or lowered:find("connection lost", 1, true) ~= nil
			or lowered:find("reconnect", 1, true) ~= nil
			or lowered:match("error%s*code%s*:%s*%d+") ~= nil
	end
	function records.ReadPrompt()
		local coreGui = game:GetService("CoreGui")
		local robloxPromptGui = coreGui:FindFirstChild("RobloxPromptGui")
		if not robloxPromptGui then
			return nil
		end
		local function helperFunction(data)
			while data do
				if data:IsA("GuiObject") and not data.Visible then
					return false
				end
				if data:IsA("ScreenGui") and not data.Enabled then
					return false
				end
				data = data.Parent
			end
			return true
		end
		local copiedData = {}
		local errorPrompt = robloxPromptGui:FindFirstChild("ErrorPrompt", true)
		if not errorPrompt or not helperFunction(errorPrompt) then
			return nil
		end
		for _, item in ipairs(errorPrompt:GetDescendants()) do
			if item:IsA("TextLabel") and helperFunction(item) and item.Text ~= "" then
				table.insert(copiedData, item.Text)
			end
		end
		return # copiedData > 0 and table.concat(copiedData, " | ") or nil
	end
	function records.Step(data)
		if not records.Active or not State.Running then
			return
		end
		local now = os.clock()
		if records.InFlight then
			if now - records.InFlight < 45 then
				return
			end
			records.InFlight = nil
		end
		if not records.ConnectionError(data) then
			records.Prompt, records.NextAt, records.Attempts = nil, nil, 0
			return
		end
		if not records.Prompt then
			records.Prompt = data
			records.NextAt = now + 3
		end
		if now < records.NextAt then
			return
		end
		records.Attempts = records.Attempts + 1
		records.NextAt = now + ({
			10,
			20,
			30,
			60
		})[math.min(records.Attempts, 4)]
		records.InFlight = now
		records.Message = "Rejoining lobby | attempt " .. records.Attempts
		if UI.SaveConfigNow then
			pcall(UI.SaveConfigNow)
		end
		pcall(Hub.QueueTeleport)
		local ok2, result2 = pcall(function()
			TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
		end)
		if not ok2 then
			records.InFlight = nil
			records.Message = "Retrying lobby: " .. tostring(result2)
		end
	end
	function records.Stop()
		records.Active = false
		disconnectAll(records.Connections)
	end
	trackConnection(records.Connections, TeleportService.TeleportInitFailed:Connect(function(data, options, _, callback)
		if data ~= LocalPlayer or callback ~= LOBBY_PLACE_ID or records.Attempts == 0 then
			return
		end
		records.InFlight = nil
		records.Message = "Lobby teleport failed; retrying | " .. tostring(options)
	end))
	trackConnection(records.Connections, LocalPlayer.OnTeleport:Connect(function(data)
		if records.Attempts == 0 then
			return
		end
		if data == Enum.TeleportState.Failed then
			records.InFlight = nil
		end
	end))
	pcall(function()
		local guiService = game:GetService("GuiService")
		trackConnection(records.Connections, guiService.ErrorMessageChanged:Connect(function(data)
			records.EventText = data
		end))
		records.GuiService = guiService
	end)
	task.spawn(function()
		while State.Running and records.Active do
			local ok2, result2 = pcall(records.ReadPrompt)
			local value = ok2 and result2 or nil
			if not value and records.GuiService then
				local ok3, result3 = pcall(function()
					return records.GuiService:GetErrorMessage()
				end)
				value = ok3 and result3 or records.EventText
			end
			pcall(records.Step, value)
			task.wait(1)
		end
	end)
end
function Hub.StartUtilities()
	trackConnection(Utilities.Connections, LocalPlayer.Idled:Connect(function()
		if not State.Running or not State.AntiAFK then
			return
		end
		pcall(function()
			local virtualUser = game:GetService("VirtualUser")
			virtualUser:CaptureController()
			virtualUser:ClickButton2(Vector2.new(0, 0))
		end)
	end))
	trackConnection(Utilities.Connections, LocalPlayer.OnTeleport:Connect(function(data)
		if data == Enum.TeleportState.Started then
			if UI.SaveConfigNow then
				pcall(UI.SaveConfigNow)
			end
			Hub.QueueTeleport()
		end
	end))
	trackConnection(Utilities.Connections, LocalPlayer.CharacterAdded:Connect(function()
		if State.Running and State.HideName then
			Hub.SetHideName(true)
		end
	end))
	trackConnection(Utilities.Connections, Workspace.DescendantAdded:Connect(Utilities.QueueFPS))
	trackConnection(Utilities.Connections, game:GetService("Lighting").DescendantAdded:Connect(Utilities.QueueFPS))
	Hub.SetHideName(State.HideName)
	Hub.SetFPSBoost(State.FPSBoost)
	Hub.QueueTeleport()
	Hub.StartRejoin()
end
function Hub.StopUtilities()
	if Hub.Rejoin then
		Hub.Rejoin.Stop()
	end
	Hub.SetHideName(false)
	Hub.SetFPSBoost(false)
	disconnectAll(Utilities.Connections)
end
-- Door interaction automation
local Knock = {
	Session = 0,
	Connections = {},
	Bound = {},
	Cooldowns = {},
	RetryAt = {}
}
Knock.VisiblePrompts = setmetatable({}, {
	__mode = "k"
})
Hub.Knock = Knock
function Knock.Status(data)
	Knock.Message = data
	if UI.KnockStatus then
		UI.KnockStatus:SetDesc(data)
	end
end
function Knock.Alive(data)
	return State.Running and State.AutoKnockDoor and data == Knock.Session
end
function Knock.CooldownSeconds(data)
	data = tostring(data or ""):lower()
	if not data:find("cooldown", 1, true) then
		return nil
	end
	local value = tonumber(data:match("(%d+)%s+minute")) or 0
	local result = tonumber(data:match("(%d+)%s+second")) or 0
	return value * 60 + result > 0 and value * 60 + result or nil
end
function Knock.SaveCooldowns()
	if not hasFileApi then
		return
	end
	pcall(function()
		local value = MACRO_FOLDER .. "/Knock"
		if not isfolder(value) then
			makefolder(value)
		end
		writefile(value .. "/" .. LocalPlayer.UserId .. ".json", HttpService:JSONEncode(Knock.Cooldowns))
	end)
end
function Knock.LoadCooldowns()
	if not hasFileApi then
		return
	end
	pcall(function()
		local value = MACRO_FOLDER .. "/Knock/" .. LocalPlayer.UserId .. ".json"
		if not isfile(value) then
			return
		end
		local decoded = HttpService:JSONDecode(readfile(value))
		local timestamp = os.time()
		if type(decoded) ~= "table" then
			return
		end
		for index, item in pairs(decoded) do
			if type(index) == "string" and index:match("^Door%d+$") and type(item) == "number" and item > timestamp and item <= timestamp + 1805 then
				Knock.Cooldowns[index] = item
			end
		end
	end)
end
function Knock.SetCooldown(data, options)
	Knock.Cooldowns[data.Name] = os.time() + math.ceil(options) + 2
	Knock.SaveCooldowns()
end
function Knock.Ready(data)
	return (Knock.Cooldowns[data.Name] or 0) <= os.time() and (Knock.RetryAt[data.Name] or 0) <= os.clock()
end
function Knock.Doors()
	local records = {}
	for _, item in ipairs(Workspace:GetChildren()) do
		if item:IsA("Model") and item.Name:match("^Door%d+$") then
			local proximityPrompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
			if proximityPrompt then
				records[# records + 1] = {
					Door = item,
					Prompt = proximityPrompt
				}
			end
		end
	end
	return records
end
function Knock.PromptPosition(data)
	local parent = data.Parent
	if parent and parent:IsA("Attachment") then
		return parent.WorldPosition
	end
	if parent and parent:IsA("BasePart") then
		return parent.Position
	end
	if parent and parent:IsA("Model") then
		return parent:GetPivot().Position
	end
end
function Knock.CancelMove()
	local movingHumanoid = Knock.MovingHumanoid
	Knock.MovingHumanoid = nil
	if movingHumanoid then
		pcall(function()
			movingHumanoid:Move(Vector3.new(0, 0, 0))
			movingHumanoid:MoveTo(movingHumanoid.RootPart.Position)
		end)
	end
	if Knock.WalkControls then
		local walkControls, restoreControls = Knock.WalkControls, Knock.RestoreControls
		Knock.WalkControls, Knock.RestoreControls = nil, nil
		if restoreControls then
			pcall(function()
				walkControls:Enable()
			end)
		end
	end
end
function Knock.OwnWalk(data)
	Knock.MovingHumanoid = data
	if Knock.WalkControls then
		return
	end
	pcall(function()
		local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
		local value = playerScripts and playerScripts:FindFirstChild("PlayerModule")
		if not value then
			return
		end
		local result = require(value):GetControls()
		Knock.RestoreControls = result.controlsEnabled ~= false
		Knock.WalkControls = result
		result:Disable()
	end)
end
function Knock.ReachedWaypoint(data, options, callback)
	local value = data.Position - options
	return math.sqrt(value.X * value.X + value.Z * value.Z) < callback and math.abs(value.Y) < 6
end
function Knock.ReleaseCamera()
	local savedCamera = Knock.SavedCamera
	Knock.SavedCamera = nil
	if not savedCamera or not savedCamera.Owned then
		return
	end
	pcall(function()
		if Workspace.CurrentCamera ~= savedCamera.Camera or savedCamera.Camera.CameraType ~= Enum.CameraType.Scriptable then
			return
		end
		savedCamera.Camera.CFrame = savedCamera.CFrame
		savedCamera.Camera.Focus = savedCamera.Focus
		savedCamera.Camera.CameraSubject = savedCamera.Subject
		savedCamera.Camera.CameraType = savedCamera.Type
	end)
end
function Knock.PromptReady(prompt)
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local promptPosition = Knock.PromptPosition(prompt)
	local currentCamera = Workspace.CurrentCamera
	if not currentCamera or not rootPart or not promptPosition or not prompt.Enabled
		or (rootPart.Position - promptPosition).Magnitude >= prompt.MaxActivationDistance then
		return false
	end
	local screenPosition, isOnScreen = currentCamera:WorldToViewportPoint(promptPosition)
	if not isOnScreen or screenPosition.Z <= 0 or Knock.VisiblePrompts[prompt] == false then
		return false
	end
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	local obstruction = Workspace:Raycast(
		currentCamera.CFrame.Position,
		promptPosition - currentCamera.CFrame.Position,
		raycastParams
	)
	return not obstruction or (obstruction.Position - promptPosition).Magnitude < 1.8
end
function Knock.FocusPrompt(data, options)
	local currentCamera = Workspace.CurrentCamera
	local value = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local result = Knock.PromptPosition(data.Prompt)
	if not currentCamera or not value or not result or not Knock.Alive(options) then
		return false
	end
	if not Knock.SavedCamera then
		if currentCamera.CameraType == Enum.CameraType.Scriptable then
			return false
		end
		Knock.SavedCamera = {
			Camera = currentCamera,
			Type = currentCamera.CameraType,
			CFrame = currentCamera.CFrame,
			Focus = currentCamera.Focus,
			Subject = currentCamera.CameraSubject,
			Owned = true
		}
	end
	if not Knock.SavedCamera.Owned then
		return false
	end
	Knock.Status(data.Door.Name .. " | Facing door / waiting for E")
	local vector = Vector3.new(value.Position.X - result.X, 0, value.Position.Z - result.Z)
	if vector.Magnitude < 0.1 then
		return false
	end
	vector = vector.Unit
	for _, item in ipairs({
		4,
		2,
		6
	}) do
		if not Knock.Alive(options) then
			return false
		end
		currentCamera.CameraType = Enum.CameraType.Scriptable
		local child = value.Position + vector * item + Vector3.new(0, 2.5, 0)
		currentCamera.CFrame = CFrame.lookAt(child, result)
		currentCamera.Focus = CFrame.new(result)
		local element = os.clock() + 0.7
		repeat
			task.wait(0.05)
			if not Knock.Alive(options) then
				return false
			end
			if Knock.PromptReady(data.Prompt) then
				task.wait(0.1)
				if Knock.Alive(options) and Knock.PromptReady(data.Prompt) then
					if Knock.LastAttempt then
						Knock.LastAttempt.CameraAimed = true
						Knock.LastAttempt.PromptVisible = true
					end
					return true
				end
			end
		until os.clock() >= element
	end
	return false
end
function Knock.Targets(doorRecord, rootPart, humanoid)
	local prompt = doorRecord.Prompt
	local promptPosition = Knock.PromptPosition(prompt)
	if not promptPosition then
		return {}
	end
	local cameraPart = doorRecord.Door:FindFirstChild("CamCF", true)
	local forward = cameraPart and cameraPart:IsA("BasePart") and cameraPart.Position - promptPosition
	forward = forward and Vector3.new(forward.X, 0, forward.Z)
	if not forward or forward.Magnitude < 0.1 then
		local promptParent = prompt.Parent
		local facingCFrame = promptParent and promptParent:IsA("Attachment") and promptParent.WorldCFrame
			or promptParent and promptParent:IsA("BasePart") and promptParent.CFrame
			or doorRecord.Door:GetPivot()
		forward = Vector3.new(facingCFrame.LookVector.X, 0, facingCFrame.LookVector.Z)
	end
	if forward.Magnitude < 0.1 then
		return {}
	end
	forward = forward.Unit
	local maxDistance = tonumber(prompt.MaxActivationDistance) or 10
	if maxDistance < 3 then
		return {}
	end
	local groundRaycastParams = RaycastParams.new()
	groundRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	groundRaycastParams.FilterDescendantsInstances = {
		LocalPlayer.Character
	}
	groundRaycastParams.RespectCanCollide = true
	local occupancyParams = OverlapParams.new()
	occupancyParams.FilterType = Enum.RaycastFilterType.Exclude
	occupancyParams.FilterDescendantsInstances = {
		LocalPlayer.Character
	}
	occupancyParams.RespectCanCollide = true
	local hipHeight = humanoid.HipHeight or 2
	if hipHeight <= 0 then
		local leftLeg = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Left Leg")
		hipHeight = leftLeg and leftLeg.Size.Y or 2
	end
	local targetHeight = hipHeight + rootPart.Size.Y / 2
	local targets = {}
	for _, radialDistance in ipairs({
		math.min(4.5, maxDistance - 1.5),
		math.min(6.5, maxDistance - 1)
	}) do
		for _, angleDegrees in ipairs({
			0,
			25,
			-25,
			50,
			-50
		}) do
			local angle = math.rad(angleDegrees)
			local direction = Vector3.new(
				forward.X * math.cos(angle) - forward.Z * math.sin(angle),
				0,
				forward.X * math.sin(angle) + forward.Z * math.cos(angle)
			)
			local groundProbe = promptPosition + direction * radialDistance
			local groundHit = Workspace:Raycast(groundProbe + Vector3.new(0, 8, 0), Vector3.new(0, -28, 0), groundRaycastParams)
			if groundHit and groundHit.Normal.Y > 0.65 and groundHit.Position.Y <= promptPosition.Y + 1.5 and groundHit.Position.Y >= promptPosition.Y - 12 then
				local targetPosition = groundHit.Position + Vector3.new(0, targetHeight + 0.1, 0)
				local lookAtPosition = Vector3.new(promptPosition.X, targetPosition.Y, promptPosition.Z)
				local targetCFrame = CFrame.lookAt(targetPosition, lookAtPosition)
				local isClear = true
				for _, part in ipairs(Workspace:GetPartBoundsInBox(targetCFrame, Vector3.new(3.4, 4.5, 2.6), occupancyParams)) do
					if part.CanCollide then
						isClear = false
						break
					end
				end
				if isClear and (targetPosition - promptPosition).Magnitude < maxDistance - 0.3 then
					local lineOfSightHit = Workspace:Raycast(targetPosition, promptPosition - targetPosition, groundRaycastParams)
					local hasLineOfSight = not lineOfSightHit or (lineOfSightHit.Position - promptPosition).Magnitude < 1.8
					if not prompt.RequiresLineOfSight or hasLineOfSight then
						targets[#targets + 1] = {
							Position = targetPosition,
							CFrame = targetCFrame
						}
					end
				end
			end
		end
	end
	return targets
end

function Knock.Travel(data, options, callback)
	local character = LocalPlayer.Character
	local value = character and character:FindFirstChild("HumanoidRootPart")
	local result = character and character:FindFirstChildOfClass("Humanoid")
	local child = Knock.PromptPosition(data.Prompt)
	if not value or not result or not child or result.Health <= 0 then
		return false, "Character unavailable"
	end
	if value.Anchored then
		return false, "Character busy"
	end
	local function helperFunction()
		return Knock.Alive(options) and LocalPlayer.Character == character and value.Parent and result.Health > 0
	end
	if not helperFunction() then
		return false, "Canceled"
	end
	local element = Knock.Targets(data, value, result)
	if # element == 0 then
		return false, "No clear ground in front of door"
	end
	local text = "Arrival not confirmed"
	for index, item in ipairs(element) do
		if index > 4 then
			break
		end
		if not helperFunction() then
			return false, "Canceled"
		end
		Knock.Status(data.Door.Name .. " | " .. callback .. " approach " .. index)
		Knock.LastAttempt = {
			Door = data.Door.Name,
			Method = callback,
			Target = {
				item.Position.X,
				item.Position.Y,
				item.Position.Z
			},
			Approach = index
		}
		if callback == "TP" then
			local label = value.CFrame:ToObjectSpace(character:GetPivot())
			character:PivotTo(item.CFrame * label)
			task.wait(0.4)
			value.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			value.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		else
			local textValue = game:GetService("PathfindingService"):CreatePath({
				AgentRadius = 2,
				AgentHeight = 5,
				AgentCanJump = true,
				WaypointSpacing = 6
			})
			local ok2 = pcall(function()
				textValue:ComputeAsync(value.Position, item.Position)
			end)
			if not helperFunction() then
				return false, "Canceled"
			end
			if ok2 and textValue.Status == Enum.PathStatus.Success then
				Knock.OwnWalk(result)
				local indexValue = os.clock() + 40
				local cachedValue = textValue:GetWaypoints()
				for index2, item3 in ipairs(cachedValue) do
					if not helperFunction() then
						return false, "Canceled"
					end
					if item3.Action == Enum.PathWaypointAction.Jump then
						result.Jump = true
					end
					result:MoveTo(item3.Position)
					local num = math.min(indexValue, os.clock() + 5)
					local nextValue = index2 == # cachedValue and 1.8 or math.max(3, (result.WalkSpeed or 16) * 0.2)
					repeat
						task.wait(0.03)
					until not helperFunction() or Knock.ReachedWaypoint(value, item3.Position, nextValue) or os.clock() >= num
					if not helperFunction() then
						return false, "Canceled"
					end
					if os.clock() >= num and not Knock.ReachedWaypoint(value, item3.Position, nextValue) then
						text = "Walk blocked"
						break
					end
				end
			else
				text = "No walking path"
			end
			Knock.CancelMove()
		end
		if not helperFunction() then
			return false, "Canceled"
		end
		if (value.Position - item.Position).Magnitude < 2.5 and (value.Position - child).Magnitude < data.Prompt.MaxActivationDistance - 0.2 then
			if value.Anchored then
				return false, "Character busy"
			end
			task.wait(0.25)
			if not helperFunction() then
				return false, "Canceled"
			end
			if Knock.FocusPrompt(data, options) then
				return true
			end
			Knock.ReleaseCamera()
			text = "Door prompt hidden or obstructed"
		end
	end
	return false, text
end
function Knock.OnToast(data)
	local pending = Knock.Pending
	if not pending or type(data) ~= "table" or pending.Conflicted then
		return
	end
	local str, str2 = tostring(data.Title or ""), tostring(data.ContentText or "")
	local lowered = (str .. " " .. str2):lower()
	if not (lowered:find("treat", 1, true) or lowered:find("trick", 1, true) or lowered:find("door", 1, true)) then
		return
	end
	local value = str .. "|" .. str2
	if pending.Seen[value] then
		return
	end
	pending.Seen[value] = true
	local result = Knock.CooldownSeconds(str2)
	if not result and lowered:find("cooldown", 1, true) then
		result = 1800
	end
	if result then
		pending.Cooldown = result
		pending.Done = true
		Knock.SetCooldown(pending.Door, result)
		return
	end
	local child = Reports.ParseRewards(str2)
	for index, item in pairs(child) do
		pending.Rewards[index] = (pending.Rewards[index] or 0) + item
	end
	if next(child) then
		pending.Outcome = "Reward"
		pending.Done = true
		Knock.SetCooldown(pending.Door, 1800)
	end
	if not next(child) and str2 ~= "" then
		pending.Messages[# pending.Messages + 1] = str2
		if lowered:find("nothing", 1, true) or lowered:find("no reward", 1, true) or lowered:find("empty", 1, true) then
			pending.Outcome = "Empty"
			pending.Done = true
			Knock.SetCooldown(pending.Door, 1800)
		elseif str:lower():find("treat", 1, true) then
			pending.Outcome = "Other"
			pending.Done = true
			Knock.SetCooldown(pending.Door, 1800)
		end
	end
end
function Knock.OnCamera(data, options)
	local pending = Knock.Pending
	if not pending or typeof(data) ~= "Instance" then
		return
	end
	if options == "lock" and Knock.SavedCamera then
		Knock.SavedCamera.Owned = false
	end
	if not data:IsDescendantOf(pending.Door) then
		pending.Conflicted = true
		return
	end
	if options == "lock" then
		pending.Started = true
		pending.Locked = true
	end
	if options == "unlock" then
		pending.Locked = false
		pending.ReleasedAt = os.clock()
	end
end
function Knock.Bind()
	if not Knock.PromptSignalsBound then
		pcall(function()
			local proximityPromptService = game:GetService("ProximityPromptService")
			trackConnection(Knock.Connections, proximityPromptService.PromptShown:Connect(function(data)
				Knock.VisiblePrompts[data] = true
			end))
			trackConnection(Knock.Connections, proximityPromptService.PromptHidden:Connect(function(data)
				Knock.VisiblePrompts[data] = false
			end))
			Knock.PromptSignalsBound = true
		end)
	end
	local toasts = ReplicatedStorage:FindFirstChild("Toasts")
	local value = toasts and toasts:FindFirstChild("Assets")
	local result = value and value:FindFirstChild("Remotes")
	local eventStuff = ReplicatedStorage:FindFirstChild("EventStuff")
	local function helperFunction(data, options)
		if data and data:IsA("RemoteEvent") and not Knock.Bound[data] then
			Knock.Bound[data] = true
			trackConnection(Knock.Connections, data.OnClientEvent:Connect(options))
		end
	end
	helperFunction(result and result:FindFirstChild("Display"), Knock.OnToast)
	helperFunction(eventStuff and eventStuff:FindFirstChild("TweenCamera"), Knock.OnCamera)
end
function Knock.Trigger(data, options, callback, context)
	if not Knock.Alive(options) or not Knock.PromptReady(data) then
		return false, "Door prompt not ready"
	end
	local num = math.max(0, tonumber(data.HoldDuration) or 0)
	Knock.Status(callback.Door.Name .. " | Holding Knock " .. string.format("%.1fs", num))
	callback.Attempts = (callback.Attempts or 0) + 1
	local now = os.clock()
	local value = not context and type(data.InputHoldBegin) == "function" and type(data.InputHoldEnd) == "function"
	local ok2, result2 = pcall(function()
		if value then
			data:InputHoldBegin()
		elseif type(fireproximityprompt) == "function" then
			fireproximityprompt(data, num)
		else
			error("No supported prompt input")
		end
		repeat
			task.wait(0.05)
		until not Knock.Alive(options) or callback.Started or callback.Done or os.clock() - now >= num + 0.2
	end)
	if value then
		pcall(function()
			data:InputHoldEnd()
		end)
	end
	if Knock.LastAttempt then
		Knock.LastAttempt.Input = value and "Hold" or "fireproximityprompt"
		Knock.LastAttempt.HoldDuration = num
		Knock.LastAttempt.Attempts = callback.Attempts
	end
	return ok2, result2
end
function Knock.TryDoor(data, options, callback)
	local door, prompt = data.Door, data.Prompt
	if not Knock.Alive(options) or not Knock.Ready(door) then
		return nil
	end
	if door.Parent ~= Workspace or not prompt:IsDescendantOf(door) then
		return {
			Status = "Unavailable"
		}
	end
	if not prompt.Enabled then
		Knock.RetryAt[door.Name] = os.clock() + 60
		return {
			Status = "Unavailable"
		}
	end
	Knock.Bind()
	local value, value1 = Knock.Travel(data, options, callback)
	Knock.CancelMove()
	if not value then
		Knock.RetryAt[door.Name] = os.clock() + 120
		return {
			Status = "Failed",
			Message = value1
		}
	end
	if not Knock.Alive(options) then
		return nil
	end
	Knock.Bind()
	local records = {
		Door = door,
		Rewards = {},
		Messages = {},
		Seen = {}
	}
	Knock.Pending = records
	local value2, value12 = Knock.Trigger(prompt, options, records, false)
	local isActive = false
	if not value2 and Knock.Alive(options) and not records.Started and not records.Done and type(fireproximityprompt) == "function" then
		isActive = true
		value2, value12 = Knock.Trigger(prompt, options, records, true)
	end
	if not value2 then
		Knock.Pending = nil
		Knock.RetryAt[door.Name] = os.clock() + 120
		return {
			Status = "Failed",
			Message = tostring(value12)
		}
	end
	local now = os.clock()
	local value = now + 40
	Knock.Status(door.Name .. " | Waiting for door response")
	while Knock.Alive(options) and os.clock() < value do
		if records.Cooldown then
			break
		end
		if records.Done and not records.Locked then
			task.wait(0.5)
			break
		end
		if records.ReleasedAt and os.clock() - records.ReleasedAt >= 3 then
			break
		end
		if not records.Started and not records.Done and os.clock() - now >= 6 then
			if not isActive and type(fireproximityprompt) == "function" then
				isActive = true
				local result = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				local child = Knock.PromptPosition(prompt)
				if not result or result.Anchored or not child or (result.Position - child).Magnitude >= prompt.MaxActivationDistance then
					break
				end
				if not Knock.FocusPrompt(data, options) then
					break
				end
				Knock.Trigger(prompt, options, records, true)
				now = os.clock()
				Knock.Status(door.Name .. " | Waiting for door response")
			else
				break
			end
		end
		task.wait(0.1)
	end
	Knock.Pending = nil
	if records.Conflicted then
		Knock.RetryAt[door.Name] = os.clock() + 120
		return {
			Status = "Unknown"
		}
	end
	if records.Cooldown then
		return {
			Status = "Cooldown",
			Seconds = records.Cooldown
		}
	end
	if records.Outcome then
		return {
			Status = records.Outcome,
			Rewards = records.Rewards,
			Messages = records.Messages
		}
	end
	Knock.RetryAt[door.Name] = os.clock() + 300
	if Knock.LastAttempt then
		Knock.LastAttempt.Result = "No door response / reward unconfirmed"
	end
	return {
		Status = "Unknown",
		Message = "No reward confirmation"
	}
end
function Knock.Try(data, options, callback)
	local ok2, result2 = xpcall(function()
		return Knock.TryDoor(data, options, callback)
	end, function(context)
		return tostring(context)
	end)
	Knock.ReleaseCamera()
	if not ok2 then
		Knock.Pending = nil
		Knock.RetryAt[data.Door.Name] = os.clock() + 120
		Knock.CancelMove()
		return {
			Status = "Failed",
			Message = result2
		}
	end
	return result2
end
function Knock.BuildReport(data)
	local records = {
		string.format("\240\159\143\160 Checked: %d | Reward: %d | Empty: %d", data.Checked, data.Reward, data.Empty),
		string.format("\226\143\179 Cooldown: %d | Unconfirmed: %d | Failed: %d", data.Cooldown, data.Unknown, data.Failed)
	}
	local copiedData = {
		{
			name = "Rewards",
			value = Reports.Lines(data.Rewards),
			inline = false
		}
	}
	if # data.Messages > 0 then
		local joined = table.concat(data.Messages, "\n")
		if # joined > 950 then
			joined = joined:sub(1, 900) .. "\n\226\128\166 More messages stored in the local debug report."
		end
		copiedData[# copiedData + 1] = {
			name = "Other rewards / messages",
			value = joined,
			inline = false
		}
	end
	return {
		title = "Knock Door Report",
		description = "\240\159\145\164 ||" .. Reports.Escape(LocalPlayer.Name) .. "|| \194\183 " .. Reports.Escape(data.Method) .. "\n" .. table.concat(records, "\n"),
		color = 16753920,
		fields = copiedData,
		footer = {
			text = "Made By Kero"
		},
		timestamp = DateTime.now():ToIsoDate()
	}
end
function Knock.Report(data)
	Knock.LastRound = data
	if not State.KnockWebhookEnabled or data.Checked == 0 then
		return
	end
	local value, value1 = Reports.Post(State.WebhookURL, Knock.BuildReport(data))
	Knock.LastWebhookResult = value and "Sent" or value1
end
function Knock.Sweep(data, options)
	local records = {
		Checked = 0,
		Reward = 0,
		Empty = 0,
		Cooldown = 0,
		Unknown = 0,
		Failed = 0,
		Rewards = {},
		Messages = {},
		Method = State.KnockMethod
	}
	while Knock.Alive(data) and # options > 0 do
		local character = LocalPlayer.Character
		local value = character and character:FindFirstChild("HumanoidRootPart")
		if not value then
			break
		end
		table.sort(options, function(callback, context)
			local result, child = Knock.PromptPosition(callback.Prompt), Knock.PromptPosition(context.Prompt)
			return (result and (value.Position - result).Magnitude or math.huge) < (child and (value.Position - child).Magnitude or math.huge)
		end)
		local element = table.remove(options, 1)
		if Knock.Ready(element.Door) then
			Knock.Status(element.Door.Name .. " | " .. records.Method)
			local label = Knock.Try(element, data, records.Method)
			if label then
				records.Checked = records.Checked + 1
				local status = label.Status
				if status == "Reward" or status == "Other" then
					records.Reward = records.Reward + 1
				elseif status == "Empty" then
					records.Empty = records.Empty + 1
				elseif status == "Cooldown" then
					records.Cooldown = records.Cooldown + 1
				elseif status == "Unknown" then
					records.Unknown = records.Unknown + 1
				else
					records.Failed = records.Failed + 1
				end
				for index, item in pairs(label.Rewards or {}) do
					records.Rewards[index] = (records.Rewards[index] or 0) + item
				end
				for _, item3 in ipairs(label.Messages or {}) do
					records.Messages[# records.Messages + 1] = Reports.Escape(element.Door.Name .. ": " .. item3)
				end
			end
			local textValue = os.clock() + 1
			repeat
				task.wait(0.1)
			until not Knock.Alive(data) or os.clock() >= textValue
		end
	end
	Knock.Report(records)
end
function Hub.SetAutoKnock(data)
	State.AutoKnockDoor = data == true
	Knock.Session = Knock.Session + 1
	Knock.CancelMove()
	Knock.ReleaseCamera()
	if not State.AutoKnockDoor then
		Knock.Status("Off")
		return
	end
	if Knock.Worker then
		return
	end
	Knock.Worker = true
	task.spawn(function()
		local session = Knock.Session
		local ok2, result2 = xpcall(function()
			while Knock.Alive(session) do
				Knock.Bind()
				local value = Knock.Doors()
				local records = {}
				for _, item in ipairs(value) do
					if Knock.Ready(item.Door) then
						records[# records + 1] = item
					end
				end
				if # records > 0 then
					Knock.Sweep(session, records)
				else
					Knock.Status(# value == 0 and "Waiting for event houses" or "Waiting for available doors")
				end
				local result = os.clock() + 5
				repeat
					task.wait(0.2)
				until not Knock.Alive(session) or os.clock() >= result
			end
		end, function(options)
			return tostring(options)
		end)
		Knock.Pending = nil
		Knock.CancelMove()
		Knock.Worker = false
		if not ok2 then
			State.AutoKnockDoor = false
			Knock.Status("Stopped: " .. tostring(result2))
			if UI.QueueSave then
				UI.QueueSave()
			end
			if UI.KnockToggle then
				pcall(function()
					UI.KnockToggle:Set(false)
				end)
			end
		elseif State.Running and State.AutoKnockDoor and session ~= Knock.Session then
			Hub.SetAutoKnock(true)
		end
	end)
end
function Hub.StopKnock()
	Knock.Session = Knock.Session + 1
	Knock.CancelMove()
	Knock.Pending = nil
	Knock.ReleaseCamera()
	disconnectAll(Knock.Connections)
end
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local Window = Attribution.Bind(WindUI:CreateWindow(Attribution.Check({
	Title = "Skibidi Defense Hub",
	Author = Attribution.Author,
	Folder = "SkibidiDefenseHub",
	Icon = "clapperboard",
	Theme = "Dark",
	Size = UDim2.fromOffset(620, 480),
	Transparent = true,
	HideSearchBar = true,
	NewElements = true,
	ToggleKey = Enum.KeyCode.RightShift,
	OpenButton = {
		Title = Attribution.OpenButton,
		Enabled = true,
		Draggable = true,
		OnlyMobile = false
	}
})), function()
	return State.Running
end, function()
	if Hub.Destroy then
		pcall(Hub.Destroy)
	end
	State.Running = false
	State.Playing = false
end, WindUI)
pcall(function()
	Window:SetToggleKey(Enum.KeyCode.RightShift)
end)
pcall(function()
	Window:SetTogleKey(Enum.KeyCode.RightShift)
end)
-- Window setup and interface construction
local function notifyUser(data, options)
	pcall(function()
		WindUI:Notify({
			Title = data,
			Content = options,
			Duration = 4,
			Icon = "bell"
		})
	end)
end
local function createParagraphAdapter(data)
	local records = {}
	function records:SetTitle(options)
		pcall(function()
			if data.SetTitle then
				data:SetTitle(options)
			else
				data:Set({
					Title = options
				})
			end
		end)
	end
	function records:SetDesc(options)
		pcall(function()
			if data.SetDesc then
				data:SetDesc(options)
			else
				data:Set({
					Desc = options
				})
			end
		end)
	end
	return records
end
local function loadConfig()
	if not hasFileApi or not isfile(CONFIG_PATH) then
		return {}
	end
	local ok2, result2 = pcall(function()
		return HttpService:JSONDecode(readfile(CONFIG_PATH))
	end)
	return ok2 and type(result2) == "table" and result2 or {}
end
local savedConfig = loadConfig()
State.BlackScreen = savedConfig.BlackScreen == true
State.HideUser = savedConfig.HideUser == true
State.HideName = savedConfig.HideName == true
State.FPSBoost = savedConfig.FPSBoost == true
State.AntiAFK = savedConfig.AntiAFK ~= false
State.AutoExecute = savedConfig.AutoExecute ~= false
State.ReadyDelay = math.clamp(tonumber(savedConfig.ReadyDelay) or 1, 0.1, 10)
State.SkipDelay = math.clamp(tonumber(savedConfig.SkipDelay) or 0.35, 0.1, 10)
State.StopAutoSkipAt = tostring(savedConfig.StopAutoSkipAt or "")
State.AutoKnockDoor = savedConfig.AutoKnockDoor == true
State.KnockMethod = savedConfig.KnockMethod == "TP" and "TP" or "Walk"
State.KnockWebhookEnabled = savedConfig.KnockWebhookEnabled == true
State.AutoReplay = savedConfig.AutoReplay == true
State.AfterMatch = table.find({
	"None",
	"Replay",
	"Return Lobby"
}, savedConfig.AfterMatch) and savedConfig.AfterMatch or (State.AutoReplay and "Replay" or "None")
State.AutoReplay = State.AfterMatch == "Replay"
State.AutoSkipCutscene = savedConfig.AutoSkipCutscene == true
State.AutoReady = savedConfig.AutoReady == true
State.AutoSkip = savedConfig.AutoSkip == true
State.AutoSpeed = savedConfig.AutoSpeed == true
State.AutoMaxSpeed = savedConfig.AutoMaxSpeed == true
State.SpeedScaleDelay = math.clamp(tonumber(savedConfig.SpeedScaleDelay or savedConfig.AutoReadyDelay) or 1, 1, 30)
State.SpeedConfigLoaded = true
State.AutoJoinMap = savedConfig.AutoJoinMap == true
State.LobbyMode = tostring(savedConfig.LobbyMode or "Story")
State.LobbyChapter = tostring(savedConfig.LobbyChapter or "Chapter 1")
if type(savedConfig.LobbyModifiers) == "table" then
	for index3, item7 in pairs(savedConfig.LobbyModifiers) do
		if type(index3) == "string" and item7 == true then
			State.LobbyModifiers[index3] = true
		elseif type(index3) == "number" and type(item7) == "string" then
			State.LobbyModifiers[item7] = true
		end
	end
end
State.AutoBackLobby = savedConfig.AutoBackLobby == true
State.MatchesBeforeLobby = math.max(1, math.floor(tonumber(savedConfig.MatchesBeforeLobby) or 5))
State.MatchesCompleted = math.max(0, math.floor(tonumber(savedConfig.MatchesCompleted) or 0))
State.LastCountedJobId = tostring(savedConfig.LastCountedJobId or "")
State.PendingLobbyReturn = savedConfig.PendingLobbyReturn == true
State.WebhookEnabled = savedConfig.WebhookEnabled == true
State.WebhookURL = tostring(savedConfig.WebhookURL or "")
State.WebhookMatchEnd = savedConfig.WebhookMatchEnd ~= false
State.PlaybackEnabled = savedConfig.PlaybackEnabled == true
State.Speed = math.clamp(tonumber(savedConfig.Speed) or 1, 1, 6)
State.PlaybackMode = table.find({
	"Hybrid",
	"Time",
	"Money"
}, savedConfig.PlaybackMode) and savedConfig.PlaybackMode or "Hybrid"
State.ProfileName = sanitizeProfileName(savedConfig.SelectedProfile or "")
local isVisible = false
Knock.LoadCooldowns()
local function saveConfig()
	if not hasFileApi then
		return
	end
	local records = {
		BlackScreen = State.BlackScreen,
		HideUser = State.HideUser,
		HideName = State.HideName,
		FPSBoost = State.FPSBoost,
		AntiAFK = State.AntiAFK,
		AutoExecute = State.AutoExecute,
		ReadyDelay = State.ReadyDelay,
		SkipDelay = State.SkipDelay,
		StopAutoSkipAt = State.StopAutoSkipAt,
		AutoKnockDoor = State.AutoKnockDoor,
		KnockMethod = State.KnockMethod,
		KnockWebhookEnabled = State.KnockWebhookEnabled,
		AutoReplay = State.AutoReplay,
		AfterMatch = State.AfterMatch,
		AutoSkipCutscene = State.AutoSkipCutscene,
		AutoReady = State.AutoReady,
		AutoSkip = State.AutoSkip,
		AutoSpeed = State.AutoSpeed,
		AutoMaxSpeed = State.AutoMaxSpeed,
		SpeedScaleDelay = State.SpeedScaleDelay,
		AutoJoinMap = State.AutoJoinMap,
		LobbyMode = State.LobbyMode,
		LobbyChapter = State.LobbyChapter,
		LobbyModifiers = State.LobbyModifiers,
		AutoBackLobby = State.AutoBackLobby,
		MatchesBeforeLobby = State.MatchesBeforeLobby,
		MatchesCompleted = State.MatchesCompleted,
		LastCountedJobId = State.LastCountedJobId,
		PendingLobbyReturn = State.PendingLobbyReturn,
		WebhookEnabled = State.WebhookEnabled,
		WebhookURL = State.WebhookURL,
		WebhookMatchEnd = State.WebhookMatchEnd,
		PlaybackEnabled = State.PlaybackEnabled,
		Speed = State.Speed,
		PlaybackMode = State.PlaybackMode,
		SelectedProfile = State.ProfileName,
		NewProfileName = savedConfig.NewProfileName or ""
	}
	pcall(function()
		writefile(CONFIG_PATH, HttpService:JSONEncode(records))
	end)
end
local function queueConfigSave()
	if isVisible then
		return
	end
	isVisible = true
	task.delay(0.25, function()
		isVisible = false
		saveConfig()
	end)
end
UI.QueueSave = queueConfigSave
UI.SaveConfigNow = saveConfig
if State.PendingLobbyReturn then
	if game.PlaceId == LOBBY_PLACE_ID then
		State.PendingLobbyReturn = false
		State.MatchesCompleted = 0
		State.LastCountedJobId = ""
		saveConfig()
	else
		task.delay(1, function()
			if State.Running and State.PendingLobbyReturn then
				local value, value1 = clickBackButton()
				if not value then
					local ok2, result2 = pcall(function()
						TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
					end)
					if not ok2 then
						notifyUser("Lobby return failed", tostring(value1) .. " | " .. tostring(result2))
					end
				end
			end
		end)
	end
end
local lobbyTab = Window:Tab({
	Title = "Lobby",
	Icon = "house"
})
local matchTab = Window:Tab({
	Title = "Match",
	Icon = "swords"
})
local macrosTab = Window:Tab({
	Title = "Macros",
	Icon = "clapperboard"
})
local webhookTab = Window:Tab({
	Title = "Webhook",
	Icon = "webhook"
})
local miscTab = Window:Tab({
	Title = "Misc",
	Icon = "settings"
})
do
	local infoTab = Window:Tab({
		Title = "Info",
		Icon = "info"
	})
	local text2 = "https://discord.gg/rTXtujuWm6"
	infoTab:Section({
		Title = "Information"
	})
	infoTab:Paragraph({
		Title = "Everything Are Made By Kero",
		Desc = "Feel Free To Join Discord For Suggestion and Report Bugs"
	})
	infoTab:Button({
		Title = "Discord",
		Desc = text2,
		Icon = "external-link",
		Callback = function()
			local value
			if type(openurl) == "function" then
				local ok2, result2 = pcall(openurl, text2)
				if ok2 and result2 ~= false then
					value = "Discord link opened."
				end
			end
			if not value then
				for _, item in ipairs({
					"setclipboard",
					"toclipboard",
					"set_clipboard"
				}) do
					local result = type(getgenv) == "function" and getgenv() or _G
					local child = result[item]
					if type(child) == "function" then
						local ok3, result3 = pcall(child, text2)
						if ok3 and result3 ~= false then
							value = "Copied! Paste the link into your browser or Discord."
							break
						end
					end
				end
			end
			pcall(function()
				WindUI:Notify({
					Title = "Discord",
					Content = value or "Open this link: " .. text2,
					Duration = 5,
					Icon = "message-circle"
				})
			end)
		end
	})
end
-- Display options
Hub.BlackScreenPersistence = {
	Get = function()
		return State.BlackScreen == true
	end,
	Set = function(data)
		State.BlackScreen = data == true
		saveConfig()
	end
}
do
	local actionValue = type(getgenv) == "function" and getgenv() or _G
	local blackScreenController
	local blackScreenPersistence = Hub.BlackScreenPersistence
	local isBlackScreenEnabled = blackScreenPersistence and blackScreenPersistence.Get() == true or false
	local function syncBlackScreenPreference(data)
		if blackScreenPersistence and not blackScreenController.Cleaning and blackScreenPersistence.Get() ~= data then
			blackScreenPersistence.Set(data)
		end
	end
	local blackScreenState = actionValue.__KeroBlackScreen
	if blackScreenState and type(blackScreenState.Destroy) == "function" and blackScreenState.Destroy() == false then
		return
	end
	blackScreenController = {
		Alive = true,
		Enabled = false,
		Connections = {}
	}
	actionValue.__KeroBlackScreen = blackScreenController
	Hub.BlackScreenController = blackScreenController
	local blackScreenConnection, blackScreenChangedConnection
	local blackScreenGui
	local function notifyBlackScreen(data)
		pcall(function()
			WindUI:Notify({
				Title = "Black Screen",
				Content = data,
				Duration = 5
			})
		end)
	end
	local function setBlackScreenToggle(data)
		if not blackScreenConnection or blackScreenChangedConnection then
			return
		end
		blackScreenChangedConnection = true
		pcall(function()
			blackScreenConnection:Set(data)
		end)
		blackScreenChangedConnection = false
	end
	local function cleanupBlackScreenResources()
		for _, item in ipairs(blackScreenController.Connections) do
			pcall(item.Disconnect, item)
		end
		blackScreenController.Connections = {}
		local gui = blackScreenController.Gui
		blackScreenController.Gui = nil
		if gui then
			pcall(gui.Destroy, gui)
		end
	end
	function blackScreenController.Set(data)
		data = data == true
		if data and not blackScreenController.Alive then
			return false
		end
		if not data then
			if blackScreenController.RenderDisabled then
				local ok2 = pcall(blackScreenGui.Set3dRenderingEnabled, blackScreenGui, true)
				if not ok2 then
					notifyBlackScreen("Could not restore 3D rendering. Press Disable Black Screen to retry.")
					return false
				end
				blackScreenController.RenderDisabled = nil
			end
			blackScreenController.Enabled = false
			syncBlackScreenPreference(false)
			cleanupBlackScreenResources()
			setBlackScreenToggle(false)
			return true
		end
		if blackScreenController.Enabled and blackScreenController.Gui and blackScreenController.Gui.Parent then
			return true
		end
		local value
		local ok5, result4 = pcall(function()
			value = Instance.new("ScreenGui")
			value.Name = "KeroBlackScreen_skibidi"
			value.Enabled = false
			value.IgnoreGuiInset = true
			value.ResetOnSpawn = false
			value.DisplayOrder = 2147483647
			value.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			local frame = Instance.new("Frame")
			frame.Name = "Background"
			frame.Size = UDim2.fromScale(1, 1)
			frame.BackgroundColor3 = Color3.new(0, 0, 0)
			frame.BorderSizePixel = 0
			frame.Active = true
			frame.ZIndex = 1
			frame.Parent = value
			local textButton = Instance.new("TextButton")
			textButton.Name = "DisableBlackScreen"
			textButton.AnchorPoint = Vector2.new(.5, .5)
			textButton.Position = UDim2.fromScale(.5, .5)
			textButton.Size = UDim2.fromOffset(230, 52)
			textButton.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
			textButton.BorderSizePixel = 0
			textButton.Text = "Disable Black Screen"
			textButton.TextColor3 = Color3.fromRGB(245, 245, 245)
			textButton.TextSize = 17
			textButton.Font = Enum.Font.GothamSemibold
			textButton.ZIndex = 2
			textButton.Parent = frame
			local uICorner = Instance.new("UICorner")
			uICorner.CornerRadius = UDim.new(0, 10)
			uICorner.Parent = textButton
			local records = {}
			if type(gethui) == "function" then
				local ok3, result2 = pcall(gethui)
				if ok3 and result2 then
					records[# records + 1] = result2
				end
			end
			local ok4, result3 = pcall(game.GetService, game, "CoreGui")
			if ok4 and result3 then
				records[# records + 1] = result3
			end
			local localPlayer = game:GetService("Players").LocalPlayer
			local result = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
			if result then
				records[# records + 1] = result
			end
			local isActive = false
			for _, item in ipairs(records) do
				if pcall(function()
					value.Parent = item
				end) and value.Parent == item then
					isActive = true
					break
				end
			end
			assert(isActive, "Overlay unavailable on this executor")
			blackScreenController.Gui = value
			blackScreenController.Connections[# blackScreenController.Connections + 1] = textButton.Activated:Connect(function()
				blackScreenController.Set(false)
			end)
			if value.Destroying then
				blackScreenController.Connections[# blackScreenController.Connections + 1] = value.Destroying:Connect(function()
					blackScreenController.Gui = nil
					blackScreenController.Set(false)
				end)
			end
			value.Enabled = true
		end)
		if not ok5 then
			if value then
				pcall(value.Destroy, value)
			end
			cleanupBlackScreenResources()
			blackScreenController.Enabled = false
			setBlackScreenToggle(false)
			notifyBlackScreen(tostring(result4))
			return false
		end
		local ok6 = pcall(function()
			blackScreenGui = game:GetService("RunService")
			blackScreenGui:Set3dRenderingEnabled(false)
		end)
		blackScreenController.RenderDisabled = ok6 or nil
		blackScreenController.Enabled = true
		syncBlackScreenPreference(true)
		if not ok6 then
			notifyBlackScreen("Black overlay enabled; this executor cannot disable 3D rendering.")
		end
		return true
	end
	function blackScreenController.Destroy()
		blackScreenController.Cleaning = true
		if not blackScreenController.Set(false) then
			blackScreenController.Cleaning = false
			return false
		end
		blackScreenController.Alive = false
		if actionValue.__KeroBlackScreen == blackScreenController then
			actionValue.__KeroBlackScreen = nil
		end
		return true
	end
	miscTab:Section({
		Title = "Display"
	})
	blackScreenConnection = miscTab:Toggle({
		Title = "Black Screen",
		Desc = "Black overlay with a visible Disable button. Turns off 3D rendering when supported.",
		Value = isBlackScreenEnabled,
		Callback = function(data)
			if not blackScreenChangedConnection then
				blackScreenController.Set(data)
			end
		end
	})
	if isBlackScreenEnabled then
		blackScreenController.Set(true)
	end
end
lobbyTab:Section({
	Title = "Play"
})
if not chaptersByMode[State.LobbyMode] and State.LobbyMode ~= "All" then
	State.LobbyMode = "Story"
end
local chapterList = getChapters(State.LobbyMode)
if not table.find(chapterList, State.LobbyChapter) then
	State.LobbyChapter = chapterList[1] or "Chapter 1"
end
local selectedChapter
lobbyTab:Dropdown({
	Title = "Mode",
	Values = {
		"Story",
		"Multiverse",
		"Nightmare",
		"Event",
		"Versus",
		"Endless",
		"Episodes",
		"Raid",
		"All"
	},
	Value = State.LobbyMode,
	Multi = false,
	Callback = function(data)
		State.LobbyMode = data
		local value = getChapters(data)
		if not table.find(value, State.LobbyChapter) then
			State.LobbyChapter = value[1] or ""
		end
		if selectedChapter then
			pcall(function()
				selectedChapter:Refresh(value)
			end)
			pcall(function()
				selectedChapter:Select(State.LobbyChapter)
			end)
		end
		State.JoinRequested = false
		queueConfigSave()
	end
})
selectedChapter = lobbyTab:Dropdown({
	Title = "Map",
	Values = chapterList,
	Value = State.LobbyChapter,
	Multi = false,
	Callback = function(data)
		State.LobbyChapter = data
		State.JoinRequested = false
		queueConfigSave()
	end
})
lobbyTab:Button({
	Title = "Refresh Maps",
	Callback = function()
		local value = getChapters(State.LobbyMode)
		if not table.find(value, State.LobbyChapter) then
			State.LobbyChapter = value[1] or ""
		end
		pcall(function()
			selectedChapter:Refresh(value)
		end)
		pcall(function()
			selectedChapter:Select(State.LobbyChapter)
		end)
		queueConfigSave()
	end
})
lobbyTab:Toggle({
	Title = "Auto Join & Start",
	Value = State.AutoJoinMap,
	Callback = function(data)
		State.AutoJoinMap = data == true
		State.JoinRequested = false
		queueConfigSave()
	end
})
lobbyTab:Dropdown({
	Title = "Modifiers",
	Values = modifierLabels,
	Value = modifiersToLabels(State.LobbyModifiers),
	Multi = true,
	AllowNone = true,
	SearchBarEnabled = true,
	Callback = function(data)
		State.LobbyModifiers = normalizeModifiers(data)
		State.JoinRequested = false
		queueConfigSave()
	end
})
task.spawn(function()
	while State.Running do
		if game.PlaceId == LOBBY_PLACE_ID and State.AutoJoinMap and not State.JoinRequested and State.LobbyChapter ~= "" then
			refreshRemotes()
			if Remotes.CreateServer then
				State.JoinRequested = true
				setStatus("Auto Join", "Creating " .. State.LobbyChapter)
				task.spawn(function()
					local ok2, result2 = pcall(function()
						return Remotes.CreateServer:InvokeServer(State.LobbyChapter)
					end)
					if not ok2 then
						State.JoinRequested = false
						notifyUser("Auto Join failed", tostring(result2))
						return
					end
					if result2 == false then
						setStatus("Auto Join stopped", "Room creation rejected; check chapter access")
						return
					end
					local value, value1 = applyLobbyModifiers()
					if not value then
						State.JoinRequested = false
						notifyUser("Auto Join modifiers failed", tostring(value1))
						return
					end
					setStatus("Auto Join", "Starting " .. State.LobbyChapter)
					local startServer = Remotes.StartServer
					for _ = 1, 20 do
						if startServer then
							break
						end
						task.wait(0.25)
						refreshRemotes()
						startServer = Remotes.StartServer
					end
					if not startServer then
						State.JoinRequested = false
						notifyUser("Auto Join failed", "Events.start was not found")
						return
					end
					local ok3, result3 = pcall(function()
						startServer:FireServer(false)
					end)
					if not ok3 then
						State.JoinRequested = false
						notifyUser("Auto Join failed", tostring(result3))
					end
				end)
			end
		end
		task.wait(1)
	end
end)
lobbyTab:Section({
	Title = "Knock Door"
})
UI.KnockStatus = createParagraphAdapter(lobbyTab:Paragraph({
	Title = "Knock Door State",
	Desc = "Off"
}))
lobbyTab:Dropdown({
	Title = "Method",
	Values = {
		"Walk",
		"TP"
	},
	Value = State.KnockMethod,
	Multi = false,
	Callback = function(data)
		State.KnockMethod = data == "TP" and "TP" or "Walk"
		if State.AutoKnockDoor then
			Hub.SetAutoKnock(true)
		end
		queueConfigSave()
	end
})
UI.KnockToggle = lobbyTab:Toggle({
	Title = "Auto Knock Door",
	Desc = "Knock available event houses.",
	Value = State.AutoKnockDoor,
	Callback = function(data)
		Hub.SetAutoKnock(data)
		queueConfigSave()
	end
})
matchTab:Section({
	Title = "Wave"
})
matchTab:Toggle({
	Title = "Auto Ready Up",
	Value = State.AutoReady,
	Callback = function(data)
		State.AutoReady = data == true
		queueConfigSave()
	end
})
matchTab:Slider({
	Title = "Ready Delay",
	Step = 0.1,
	Value = {
		Min = 0.1,
		Max = 10,
		Default = State.ReadyDelay
	},
	Callback = function(data)
		State.ReadyDelay = math.clamp(tonumber(data) or 1, 0.1, 10)
		queueConfigSave()
	end
})
matchTab:Toggle({
	Title = "Auto Skip Waves",
	Value = State.AutoSkip,
	Callback = function(data)
		State.AutoSkip = data == true
		queueConfigSave()
	end
})
matchTab:Slider({
	Title = "Skip Delay",
	Step = 0.1,
	Value = {
		Min = 0.1,
		Max = 10,
		Default = State.SkipDelay
	},
	Callback = function(data)
		State.SkipDelay = math.clamp(tonumber(data) or 0.35, 0.1, 10)
		queueConfigSave()
	end
})
matchTab:Input({
	Title = "Stop Auto Skip At",
	Placeholder = "5, 10, 15",
	Value = State.StopAutoSkipAt,
	Callback = function(data)
		State.StopAutoSkipAt = tostring(data or "")
		queueConfigSave()
	end
})
matchTab:Toggle({
	Title = "Auto Speed Scale",
	Value = State.AutoSpeed,
	Callback = function(data)
		State.AutoSpeed = data == true
		queueConfigSave()
	end
})
matchTab:Toggle({
	Title = "Auto Max Speed",
	Desc = "Use the highest available speed.",
	Value = State.AutoMaxSpeed,
	Callback = function(data)
		State.AutoMaxSpeed = data == true
		queueConfigSave()
	end
})
matchTab:Dropdown({
	Title = "Speed Scale",
	Values = {
		"x1",
		"x2",
		"x3",
		"x4",
		"x5",
		"x6"
	},
	Value = "x" .. tostring(State.Speed),
	Multi = false,
	Callback = function(data)
		local value = tonumber(tostring(data):match("%d+")) or 1
		State.Speed = math.clamp(value, 1, 6)
		queueConfigSave()
	end
})
matchTab:Slider({
	Title = "Speed Delay",
	Desc = "Wait once at match start.",
	Step = 1,
	Value = {
		Min = 1,
		Max = 30,
		Default = State.SpeedScaleDelay
	},
	Callback = function(data)
		State.SpeedScaleDelay = math.clamp(tonumber(data) or 1, 1, 30)
		queueConfigSave()
	end
})
matchTab:Section({
	Title = "Match End"
})
local matchCounterParagraph = createParagraphAdapter(matchTab:Paragraph({
	Title = "Match Count",
	Desc = "Loading..."
}))
-- Match counter and lobby automation
local function updateMatchCounter()
	matchCounterParagraph:SetDesc(string.format("%d/%d completed | %s", State.MatchesCompleted, State.MatchesBeforeLobby, State.PendingLobbyReturn and "returning to lobby" or "running"))
end
UI.UpdateMatchCounter = updateMatchCounter
updateMatchCounter()
matchTab:Toggle({
	Title = "Auto Back Lobby After X Matches",
	Value = State.AutoBackLobby,
	Callback = function(data)
		State.AutoBackLobby = data == true
		queueConfigSave()
		updateMatchCounter()
	end
})
matchTab:Input({
	Title = "Matches Before Lobby",
	Placeholder = "5",
	Value = tostring(State.MatchesBeforeLobby),
	Callback = function(data)
		local num = tonumber(tostring(data):match("%d+"))
		if num then
			State.MatchesBeforeLobby = math.max(1, math.floor(num))
			queueConfigSave()
			updateMatchCounter()
		end
	end
})
matchTab:Button({
	Title = "Reset Match Counter",
	Icon = "rotate-ccw",
	Callback = function()
		State.MatchesCompleted = 0
		State.LastCountedJobId = ""
		State.PendingLobbyReturn = false
		queueConfigSave()
		updateMatchCounter()
	end
})
matchTab:Dropdown({
	Title = "After Match",
	Values = {
		"None",
		"Replay",
		"Return Lobby"
	},
	Value = State.AfterMatch,
	Multi = false,
	Callback = function(selectedAfterMatch)
		-- Keep the legacy AutoReplay flag synchronized with the dropdown selection.
		if selectedAfterMatch ~= "None" and selectedAfterMatch ~= "Replay" and selectedAfterMatch ~= "Return Lobby" then
			return
		end
		State.AfterMatch = selectedAfterMatch
		State.AutoReplay = selectedAfterMatch == "Replay"
		queueConfigSave()
	end
})
matchTab:Toggle({
	Title = "Auto Vote Skip Cutscene",
	Value = State.AutoSkipCutscene,
	Callback = function(data)
		State.AutoSkipCutscene = data == true
		queueConfigSave()
	end
})
webhookTab:Section({
	Title = "Discord Webhook",
	Desc = "Optional match notifications"
})
webhookTab:Input({
	Title = "Webhook URL",
	Placeholder = "https://discord.com/api/webhooks/...",
	Value = State.WebhookURL,
	Callback = function(data)
		State.WebhookURL = tostring(data or "")
		queueConfigSave()
	end
})
webhookTab:Toggle({
	Title = "Enable Webhook",
	Value = State.WebhookEnabled,
	Callback = function(data)
		State.WebhookEnabled = data == true
		queueConfigSave()
	end
})
webhookTab:Toggle({
	Title = "Notify On Match End",
	Value = State.WebhookMatchEnd,
	Callback = function(data)
		State.WebhookMatchEnd = data == true
		queueConfigSave()
	end
})
webhookTab:Button({
	Title = "Send Test Webhook",
	Icon = "send",
	Callback = function()
		local value, value1 = sendWebhookMessage("Webhook Test", "Skibidi Defense Hub webhook is working.", 5763719)
		if value then
			notifyUser("Webhook", "Test message sent")
		else
			notifyUser("Webhook failed", tostring(value1))
		end
	end
})
webhookTab:Section({
	Title = "Webhook Knock Door"
})
webhookTab:Toggle({
	Title = "Webhook Knock Door",
	Desc = "One report per door sweep.",
	Value = State.KnockWebhookEnabled,
	Callback = function(data)
		State.KnockWebhookEnabled = data == true
		queueConfigSave()
	end
})
macrosTab:Section({
	Title = "Macro State"
})
UI.Status = createParagraphAdapter(macrosTab:Paragraph({
	Title = "State: Idle",
	Desc = "Waiting"
}))
UI.Runtime = createParagraphAdapter(macrosTab:Paragraph({
	Title = "Live match",
	Desc = "Reading game state..."
}))
UI.ActionSummary = createParagraphAdapter(macrosTab:Paragraph({
	Title = "Recorded actions: 0",
	Desc = "No actions loaded"
}))
UI.LoadoutStatus = createParagraphAdapter(macrosTab:Paragraph({
	Title = "Recorded Loadout",
	Desc = "Not recorded"
}))
macrosTab:Button({
	Title = "Save Current Loadout",
	Callback = function()
		local value, value1 = Hub.MatchFlow.SaveCurrentLoadout()
		setStatus(value and "Loadout saved" or "Loadout unavailable", value1)
	end
})
local newProfileName = savedConfig.NewProfileName or ""
local _ = macrosTab:Input({
	Title = "Create Macro",
	Placeholder = "Macro name",
	Value = newProfileName,
	Callback = function(data)
		newProfileName = sanitizeProfileName(data)
		savedConfig.NewProfileName = newProfileName
		queueConfigSave()
	end
})
local profileList = listProfiles()
if # profileList == 0 then
	profileList = {
		"(none)"
	}
end
local selectedProfile = State.ProfileName ~= "" and State.ProfileName or profileList[1]
local profileRefreshConnection
local function refreshMacroProfiles(data)
	local value = listProfiles()
	if # value == 0 then
		value = {
			"(none)"
		}
	end
	pcall(function()
		profileRefreshConnection:Refresh(value)
	end)
	if data and data ~= "" then
		pcall(function()
			profileRefreshConnection:Select(data)
		end)
	end
end
UI.RefreshProfiles = refreshMacroProfiles
-- Macro controls and import and export
local function startEnabledPlayback()
	if not State.PlaybackEnabled or State.Playing or State.Recording or # State.Actions == 0 then
		return
	end
	local value, value1 = startPlayback()
	if value then
		State.AutoPlaybackStarted = true
	else
		setStatus("Auto playback", tostring(value1))
	end
end
UI.StartEnabledPlayback = startEnabledPlayback
macrosTab:Button({
	Title = "Create New Macro",
	Icon = "file-plus",
	Callback = function()
		local value = sanitizeProfileName(newProfileName)
		if value == "" then
			notifyUser("Create Macro", "Enter a macro name first")
			return
		end
		if hasFileApi and isfile(profilePath(value)) then
			notifyUser("Create Macro", "That macro already exists")
			return
		end
		local actions, profileName, macroLoadout = State.Actions, State.ProfileName, State.MacroLoadout
		State.Actions, State.ProfileName, State.MacroLoadout = {}, value, nil
		local value, value1 = saveProfile(value)
		if not value then
			State.Actions, State.ProfileName, State.MacroLoadout = actions, profileName, macroLoadout
			notifyUser("Create failed", tostring(value1))
			return
		end
		refreshMacroProfiles(value)
		updateActionSummary()
		setStatus("Created", value .. " is ready to record")
		queueConfigSave()
	end
})
profileRefreshConnection = macrosTab:Dropdown({
	Title = "Select Macro",
	Values = profileList,
	Value = selectedProfile,
	Multi = false,
	Callback = function(data)
		if data == "(none)" then
			return
		end
		local value, value1 = loadProfile(data)
		if value then
			updateActionSummary()
			setStatus("Loaded", string.format("%s (%d actions)", State.ProfileName, # State.Actions))
			queueConfigSave()
			task.defer(startEnabledPlayback)
		else
			setStatus("Load failed", tostring(value1))
		end
	end
})
macrosTab:Button({
	Title = "Delete Selected Macro",
	Icon = "trash-2",
	Callback = function()
		if State.Recording or State.Playing then
			setStatus("Delete blocked", "Stop recording/playback first")
			return
		end
		local profileName = State.ProfileName
		if profileName == "" or not hasFileApi or type(delfile) ~= "function" then
			setStatus("Delete unavailable", "Select a macro; executor needs delfile")
			return
		end
		local ok2, result2 = pcall(function()
			local value = profilePath(profileName)
			local result = MACRO_FOLDER .. "/Deleted"
			if not isfolder(result) then
				makefolder(result)
			end
			writefile(result .. "/" .. sanitizeProfileName(profileName) .. "_" .. os.time() .. ".json", readfile(value))
			delfile(value)
		end)
		if not ok2 then
			setStatus("Delete failed", tostring(result2))
			return
		end
		State.Actions = {}
		State.ProfileName = ""
		State.PlaybackEnabled = false
		State.MacroLoadout = nil
		if UI.SetPlaybackToggle then
			UI.SetPlaybackToggle(false)
		end
		refreshMacroProfiles("(none)")
		updateActionSummary()
		queueConfigSave()
		setStatus("Deleted", profileName)
	end
})
macrosTab:Dropdown({
	Title = "Playback Mode",
	Values = {
		"Money",
		"Time",
		"Hybrid"
	},
	Value = State.PlaybackMode,
	Multi = false,
	Callback = function(data)
		State.PlaybackMode = data
		queueConfigSave()
	end
})
local isInitialized = false
local profileWatcher
local profileRefreshTask
local function setToggleValue(data, options)
	if not data then
		return
	end
	isInitialized = true
	pcall(function()
		data:Set(options)
	end)
	isInitialized = false
end
UI.SetRecordToggle = function(data)
	setToggleValue(profileWatcher, data)
end
UI.SetPlaybackToggle = function(data)
	setToggleValue(profileRefreshTask, data)
end
profileWatcher = macrosTab:Toggle({
	Title = "Record",
	Value = false,
	Callback = function(data)
		if isInitialized then
			return
		end
		if data then
			if State.PlaybackEnabled then
				setToggleValue(profileRefreshTask, false)
				State.PlaybackEnabled = false
				queueConfigSave()
			end
			if State.Playing then
				stopPlayback("Stopped to begin recording")
			end
			local value = State.ProfileName ~= "" and State.ProfileName or newProfileName
			local value, value1 = startRecording(value)
			if not value then
				setToggleValue(profileWatcher, false)
				notifyUser("Cannot record", tostring(value1))
			end
		elseif State.Recording then
			local value2, value12 = stopRecording(true)
			if value2 then
				refreshMacroProfiles(State.ProfileName)
				queueConfigSave()
			else
				notifyUser("Cannot save", tostring(value12))
			end
		end
	end
})
UI.RecordToggle = profileWatcher
profileRefreshTask = macrosTab:Toggle({
	Title = "Auto Playback Every Match",
	Value = State.PlaybackEnabled,
	Callback = function(data)
		if isInitialized then
			return
		end
		State.PlaybackEnabled = data == true
		queueConfigSave()
		if data then
			if State.Recording then
				setToggleValue(profileWatcher, false)
				stopRecording(true)
			end
			local value, value1 = startPlayback()
			if not value then
				setStatus("Playback armed", tostring(value1))
			end
		elseif State.Playing then
			stopPlayback("Stopped by user")
		end
	end
})
do
	local macroManager = {
		Tab = macrosTab,
		Owner = Hub,
		HTTP = HttpService,
		StateTables = {
			State
		},
		Games = {
			"Skibidi Defense"
		},
		KindKey = "Type",
		Kinds = {
			"Place",
			"Upgrade",
			"Sell",
			"Target",
			"Ability",
			"BoostLink"
		},
		FS = function()
			return type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
		end,
		Busy = function()
			return State.Recording or State.Playing or State.RecordDraining or State.PlaybackEnabled
		end,
		Clean = sanitizeProfileName,
		Path = profilePath,
		Load = loadProfile,
		Notify = function(data)
			notifyUser("Macro", tostring(data))
		end,
		Refresh = function(data)
			refreshMacroProfiles(data)
			updateActionSummary()
			queueConfigSave()
		end,
		Validate = function(data)
			if data.Universe ~= nil and data.Universe ~= game.GameId then
				return false, "Wrong game"
			end
			for _, item in ipairs(data.Actions) do
				if item.Type == "Place" then
					if type(item.Unit) ~= "string" or type(item.CFrame) ~= "table" or # item.CFrame ~= 12 or type(item.Handle) ~= "string" then
						return false, "Invalid Skibi placement"
					end
					for _, item3 in ipairs(item.CFrame) do
						if type(item3) ~= "number" or item3 ~= item3 or math.abs(item3) == math.huge then
							return false, "Invalid placement transform"
						end
					end
				end
			end
			return true
		end,
		Legacy = function(data)
			return data.Game == nil and type(data.Version) == "number" and data.Version >= 1 and data.Version <= 6
		end
	}
	assert(type(macroManager.Load) == "function" and type(macroManager.Path) == "function" and type(macroManager.Clean) == "function", "Macro import adapter unavailable")
	local macroImporter = {}
	local function parseMacroImport(data)
		if type(data) ~= "string" then
			return nil, "Paste macro JSON or a Discord file link"
		end
		data = data:match("^%s*(.-)%s*$")
		if data:sub(1, 3) == "```" then
			data = data:sub(4):gsub("%s*```$", ""):gsub("^[jJ][sS][oO][nN]%s+", ""):match("^%s*(.-)%s*$")
		end
		if data == "" then
			return nil, "Paste macro JSON or a Discord file link"
		end
		local value = data:match("^https?://") ~= nil
		if value then
			if # data > 4096 or data:find("[%s%c<>\\]") then
				return nil, "Paste one complete Discord file link"
			end
			local value, value1 = data:match("^https://([^/%?#]+)(/[^#]*)$")
			if not value or not (value:lower() == "cdn.discordapp.com" or value:lower() == "media.discordapp.net") or not value1:match("^/attachments/%d+/%d+/[^%?#]+") then
				return nil, "Use the Discord file link, not a message or Copy Link page URL"
			end
			local result = type(request) == "function" and request or type(http_request) == "function" and http_request or type(syn) == "table" and type(syn.request) == "function" and syn.request or type(http) == "table" and type(http.request) == "function" and http.request
			local ok2, result2, result22 = pcall(function()
				if result then
					local child = result({
						Url = data,
						Method = "GET",
						Headers = {
							Accept = "application/json"
						},
						Redirect = false
					})
					assert(type(child) == "table", "Invalid HTTP response")
					local num = tonumber(child.StatusCode or child.Status)
					if num == 403 or num == 404 then
						return nil, "Link expired or unavailable; copy a fresh file link from Discord"
					end
					if num and (num < 200 or num >= 300) then
						return nil, "Download failed (HTTP " .. num .. ")"
					end
					return child.Body or child.body
				end
				return game:HttpGet(data)
			end)
			if not ok2 then
				return nil, "Cannot download macro; check the link, network and executor HTTP support"
			end
			if type(result2) ~= "string" or result2 == "" then
				return nil, result22 or "Link expired or unavailable; copy a fresh file link from Discord"
			end
			data = result2
		end
		if # data > 200 * 1024 then
			return nil, "Macro exceeds 200 KB"
		end
		data = data:gsub("^\239\187\191", "")
		return data, value
	end
	local function snapshotMacroState()
		local records = {}
		for _, item in ipairs(macroManager.StateTables) do
			local copiedData = {}
			for index, item3 in pairs(item) do
				copiedData[index] = item3
			end
			records[# records + 1] = {
				State = item,
				Copy = copiedData
			}
		end
		return function()
			for _, item4 in ipairs(records) do
				for index2 in pairs(item4.State) do
					item4.State[index2] = nil
				end
				for index4, item5 in pairs(item4.Copy) do
					item4.State[index4] = item5
				end
			end
		end
	end
	local function sanitizeImportedData(data, options)
		assert(options < 40, "Macro nesting is too deep")
		if type(data) == "number" then
			assert(data == data and math.abs(data) < math.huge, "Invalid macro number")
		end
		if type(data) ~= "table" then
			return data
		end
		local records = {}
		for index, item in pairs(data) do
			local value = type(index) == "string" and (index:lower() == "owneruserid" or index:lower() == "ownerid")
			if not value then
				records[index] = sanitizeImportedData(item, options + 1)
			end
		end
		return records
	end
	function macroImporter.Import(data, options)
		if macroImporter.Busy or macroImporter.Fetching or macroManager.Busy() then
			return false, "Stop recording and Auto Playback before importing"
		end
		if not macroManager.FS() or type(delfile) ~= "function" then
			return false, "File read/write/delete APIs required"
		end
		macroImporter.Fetching = true
		local value, value1 = parseMacroImport(data)
		macroImporter.Fetching = false
		if not value then
			return false, value1
		end
		if macroImporter.Busy or macroManager.Busy() then
			return false, "Stop recording and Auto Playback before importing"
		end
		data = value
		local ok2, result2 = pcall(macroManager.HTTP.JSONDecode, macroManager.HTTP, data)
		if not ok2 or type(result2) ~= "table" then
			return false, value1 and "Link did not return macro JSON; copy a fresh Discord file link" or "Invalid JSON; paste the complete macro file"
		end
		if not table.find(macroManager.Games, result2.Game) and not (macroManager.Legacy and macroManager.Legacy(result2)) then
			return false, "This macro belongs to another game"
		end
		if type(result2.Actions) ~= "table" or # result2.Actions == 0 or # result2.Actions > 50000 then
			return false, "Invalid macro actions"
		end
		local count = 0
		for index, item in pairs(result2.Actions) do
			count = count + 1
			if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > # result2.Actions or type(item) ~= "table" or not table.find(macroManager.Kinds, item[macroManager.KindKey]) then
				return false, "Invalid macro action"
			end
			for _, item3 in ipairs({
				"Time",
				"At",
				"Wave",
				"WaveAt",
				"WaveTime"
			}) do
				local value = item[item3]
				if value ~= nil and (type(value) ~= "number" or value ~= value or value < 0 or value == math.huge) then
					return false, "Invalid action " .. item3
				end
			end
		end
		if count ~= # result2.Actions then
			return false, "Macro actions must be a list"
		end
		ok2, result2 = pcall(sanitizeImportedData, result2, 0)
		if not ok2 then
			return false, tostring(result2)
		end
		if macroManager.Validate then
			local ok3, result3, result22 = pcall(macroManager.Validate, result2)
			if not ok3 or not result3 then
				return false, ok3 and (result22 or "Invalid macro data") or "Invalid macro data"
			end
		end
		options = tostring(options or ""):match("^%s*(.-)%s*$")
		if options == "" then
			options = type(result2.Name) == "string" and result2.Name or type(result2.Profile) == "string" and result2.Profile or "Imported Macro"
		end
		options = macroManager.Clean(options)
		local lowered = options:lower()
		if options == "" or lowered == "settings" or lowered == "hubconfig" or lowered == "playback_debug" or lowered:match("_config$") then
			return false, "Enter another macro name"
		end
		local result = macroManager.Path(options)
		if not result then
			return false, "Invalid macro name"
		end
		local ok4, result4 = pcall(isfile, result)
		if not ok4 then
			return false, "Cannot check existing macro files"
		end
		if result4 then
			return false, "Macro name already exists; choose another name"
		end
		local child = snapshotMacroState()
		macroImporter.Busy = true
		local ok5, result5 = pcall(function()
			local json = macroManager.HTTP:JSONEncode(result2)
			writefile(result .. ".pending", json)
			assert(readfile(result .. ".pending") == json, "Pending verification failed")
			assert(not isfile(result), "Macro name already exists")
			macroImporter.Created = result
			writefile(result, json)
			assert(readfile(result) == json, "Save verification failed")
			local value2, value12 = macroManager.Load(options)
			assert(value2, value12 or "Macro failed its game-specific validation")
		end)
		if not ok5 then
			child()
			if macroImporter.Created then
				pcall(delfile, macroImporter.Created)
			end
			macroImporter.Created = nil
			macroImporter.Busy = false
			pcall(delfile, result .. ".pending")
			return false, "Import failed: " .. tostring(result5)
		end
		macroImporter.Created = nil
		macroImporter.Busy = false
		pcall(delfile, result .. ".pending")
		return true, options, # result2.Actions
	end
	macroManager.Owner.MacroImport = macroImporter
	macroManager.Tab:Section({
		Title = "Import Macro"
	})
	local usernameInput, userIdInput = "", ""
	local macroNameInput = macroManager.Tab:Input({
		Title = "Macro Name",
		Desc = "Enter Any Names You Want",
		Placeholder = "Imported Macro",
		Value = "",
		Callback = function(data)
			usernameInput = tostring(data or "")
		end
	})
	local macroJSONInput = macroManager.Tab:Input({
		Title = "Macro JSON",
		Desc = "Paste JSON or a Discord file link.",
		Type = "Textarea",
		ClearTextOnFocus = false,
		Placeholder = "Paste JSON or Discord file link...",
		Value = "",
		Callback = function(data)
			userIdInput = tostring(data or "")
		end
	})
	macroManager.Tab:Button({
		Title = "Import Macro",
		Icon = "download",
		Callback = function()
			local value, value1, value2 = macroImporter.Import(userIdInput, usernameInput)
			if not value then
				macroManager.Notify(value1)
				return
			end
			usernameInput = value1
			userIdInput = ""
			macroNameInput:Set(value1)
			macroJSONInput:Set("")
			local ok2, _ = pcall(macroManager.Refresh, value1)
			macroManager.Notify("Imported " .. value1 .. " (" .. tostring(value2) .. " actions)" .. (not ok2 and "; reopen Select Macro to refresh" or ""))
		end
	})
end
UI.PlayToggle = profileRefreshTask
do
	local hubReference, stateReference, localPlayerReference = Hub, State, LocalPlayer
	local globalEnvironment = type(getgenv) == "function" and getgenv() or _G
	local text3 = "__KeroHideUser_Skibidi_Defense_Hub"
	local previousGlobalValue = globalEnvironment[text3]
	if previousGlobalValue and type(previousGlobalValue.Destroy) == "function" then
		pcall(previousGlobalValue.Destroy)
	end
	local playerDisplayData = {
		Alive = true,
		Enabled = false,
		Saved = {},
		Generation = 0
	}
	hubReference.HideUserController = playerDisplayData
	globalEnvironment[text3] = playerDisplayData
	playerDisplayData.ImageSaved = {}
	playerDisplayData.ImageWatches = {}
	playerDisplayData.ImageConnections = {}
	local function setupPlayerDisplay()
		for _, item in ipairs(playerDisplayData.ImageConnections) do
			pcall(item.Disconnect, item)
		end
		for _, item3 in pairs(playerDisplayData.ImageWatches) do
			for _, item4 in ipairs(item3) do
				pcall(item4.Disconnect, item4)
			end
		end
		playerDisplayData.ImageConnections = {}
		playerDisplayData.ImageWatches = {}
		for index, item5 in pairs(playerDisplayData.ImageSaved) do
			pcall(function()
				index.ImageTransparency = item5
			end)
		end
		playerDisplayData.ImageSaved = {}
	end
	local function updatePlayerNames(data)
		local value = playerDisplayData.PlayerNames or {}
		local parent = data.Parent
		for _ = 1, 2 do
			if not parent then
				break
			end
			if value[parent.Name] then
				return true
			end
			for _, item in ipairs(parent:GetChildren()) do
				if item:IsA("TextLabel") or item:IsA("TextButton") then
					local result = item.Name:lower():gsub("[^%a]", "")
					if result == "username" or result == "displayname" or result == "playername" or result == "name" or result == "namelabel" then
						local matched2 = tostring(item.Text):gsub("<[^>]+>", ""):match("^%s*(.-)%s*$")
						if value[matched2] or stateReference.HideName and matched2 == "Player" then
							return true
						end
					end
				end
			end
			parent = parent.Parent
		end
		return false
	end
	local function getPlayerNameKey(data)
		local value = ""
		pcall(function()
			value = tostring(data.Image):lower()
		end)
		if value:find("rbxthumb://", 1, true) and (value:find("type=avatar", 1, true) or value:find("type=headshot", 1, true)) then
			return true
		end
		if value:find("headshot%-thumbnail") or value:find("avatar%-thumbnail") or value:find("avatar%.ashx") or value:find("headshot%.ashx") or value:find("thumbnails.roblox.com/v1/users/", 1, true) then
			return true
		end
		local result = data.Name:lower():gsub("[^%a]", "")
		if result:find("avatar", 1, true) or result:find("headshot", 1, true) or result:find("portrait", 1, true) or result == "playericon" or result == "playerimage" or result == "profilepicture" then
			return true
		end
		return updatePlayerNames(data)
	end
	local function setupPlayerImageTracking()
		setupPlayerDisplay()
		if not playerDisplayData.Alive or not playerDisplayData.Enabled then
			return
		end
		playerDisplayData.PlayerNames = {}
		local function helperFunction(data)
			if data.Name then
				playerDisplayData.PlayerNames[data.Name] = true
			end
			if data.DisplayName then
				playerDisplayData.PlayerNames[data.DisplayName] = true
			end
			if data.UserId then
				playerDisplayData.PlayerNames[tostring(data.UserId)] = true
			end
		end
		helperFunction(localPlayerReference)
		local value
		pcall(function()
			value = game:GetService("Players")
			for _, item in ipairs(value:GetPlayers()) do
				helperFunction(item)
			end
		end)
		local records = setmetatable({}, {
			__mode = "k"
		})
		local function createUiElement(data)
			if not playerDisplayData.Alive or not playerDisplayData.Enabled or records[data] then
				return
			end
			if not (data:IsA("ImageLabel") or data:IsA("ImageButton") or data:IsA("ViewportFrame")) then
				return
			end
			local result = getPlayerNameKey(data)
			if result then
				if playerDisplayData.ImageSaved[data] == nil then
					playerDisplayData.ImageSaved[data] = data.ImageTransparency
				end
				records[data] = true
				data.ImageTransparency = 1
				records[data] = nil
			elseif playerDisplayData.ImageSaved[data] ~= nil then
				local child = playerDisplayData.ImageSaved[data]
				playerDisplayData.ImageSaved[data] = nil
				records[data] = true
				data.ImageTransparency = child
				records[data] = nil
			end
		end
		local function setupUiElement(data)
			local parent = data.Parent
			if not parent then
				return
			end
			for index in pairs(playerDisplayData.ImageWatches) do
				if index.Parent == parent or index.Parent and index.Parent.Parent == parent then
					pcall(createUiElement, index)
				end
			end
		end
		local function isPlayerDisplayElement(data)
			if playerDisplayData.ImageWatches[data] then
				pcall(createUiElement, data)
				return
			end
			local result = data:IsA("ImageLabel") or data:IsA("ImageButton") or data:IsA("ViewportFrame")
			local child = data.Name:lower():gsub("[^%a]", "")
			local element = (data:IsA("TextLabel") or data:IsA("TextButton")) and (child == "username" or child == "displayname" or child == "playername" or child == "name" or child == "namelabel")
			if not result and not element then
				return
			end
			local copiedData = {}
			playerDisplayData.ImageWatches[data] = copiedData
			local function updatePlayerDisplayElement(options, callback)
				local ok2, result2 = pcall(function()
					return data:GetPropertyChangedSignal(options):Connect(callback)
				end)
				if ok2 then
					copiedData[# copiedData + 1] = result2
				end
			end
			if result then
				updatePlayerDisplayElement("Image", function()
					pcall(createUiElement, data)
				end)
				updatePlayerDisplayElement("Name", function()
					pcall(createUiElement, data)
				end)
				if data.AncestryChanged then
					copiedData[# copiedData + 1] = data.AncestryChanged:Connect(function()
						pcall(createUiElement, data)
					end)
				end
				updatePlayerDisplayElement("ImageTransparency", function()
					if records[data] or not playerDisplayData.Enabled then
						return
					end
					if playerDisplayData.ImageSaved[data] ~= nil then
						playerDisplayData.ImageSaved[data] = data.ImageTransparency
					end
					pcall(createUiElement, data)
				end)
				pcall(createUiElement, data)
			else
				updatePlayerDisplayElement("Text", function()
					setupUiElement(data)
				end)
				setupUiElement(data)
			end
			if data.Destroying then
				copiedData[# copiedData + 1] = data.Destroying:Connect(function()
					for _, item in ipairs(copiedData) do
						pcall(item.Disconnect, item)
					end
					playerDisplayData.ImageWatches[data] = nil
					playerDisplayData.ImageSaved[data] = nil
				end)
			end
		end
		local actionData = {}
		pcall(function()
			local playerGui = localPlayerReference:FindFirstChildOfClass("PlayerGui")
			if playerGui then
				actionData[# actionData + 1] = playerGui
			end
		end)
		for _, item3 in ipairs({
			"CoreGui",
			"Workspace"
		}) do
			pcall(function()
				actionData[# actionData + 1] = game:GetService(item3)
			end)
		end
		local function refreshPlayerDisplay(data)
			if data.DescendantAdded then
				playerDisplayData.ImageConnections[# playerDisplayData.ImageConnections + 1] = data.DescendantAdded:Connect(function(options)
					task.defer(function()
						if playerDisplayData.Alive and playerDisplayData.Enabled then
							pcall(isPlayerDisplayElement, options)
						end
					end)
				end)
			end
			local ok2, result2 = pcall(data.GetDescendants, data)
			if ok2 then
				for _, item in ipairs(result2) do
					pcall(isPlayerDisplayElement, item)
				end
			end
		end
		for _, item4 in ipairs(actionData) do
			refreshPlayerDisplay(item4)
		end
		if localPlayerReference.ChildAdded then
			playerDisplayData.ImageConnections[# playerDisplayData.ImageConnections + 1] = localPlayerReference.ChildAdded:Connect(function(data)
				if playerDisplayData.Alive and playerDisplayData.Enabled and data:IsA("PlayerGui") then
					refreshPlayerDisplay(data)
				end
			end)
		end
		if value and value.PlayerAdded then
			playerDisplayData.ImageConnections[# playerDisplayData.ImageConnections + 1] = value.PlayerAdded:Connect(function(data)
				helperFunction(data)
				for index in pairs(playerDisplayData.ImageWatches) do
					pcall(createUiElement, index)
				end
			end)
		end
	end
	local function initializePlayerDisplay()
		for index, item in pairs(playerDisplayData.Saved) do
			for index2, item3 in pairs(item) do
				pcall(function()
					index[index2] = item3
				end)
			end
		end
		playerDisplayData.Saved = {}
	end
	local function applyPlayerDisplaySettings(data)
		playerDisplayData.Generation = playerDisplayData.Generation + 1
		local generation = playerDisplayData.Generation
		if playerDisplayData.Descendants then
			playerDisplayData.Descendants:Disconnect()
			playerDisplayData.Descendants = nil
		end
		initializePlayerDisplay()
		playerDisplayData.Character = data
		if not playerDisplayData.Alive or not playerDisplayData.Enabled or not data then
			return
		end
		local color = Color3.fromRGB(255, 0, 0)
		local function helperFunction(options)
			if playerDisplayData.Saved[options] or not options:IsDescendantOf(data) then
				return
			end
			local value
			if options:IsA("Accessory") or options:IsA("Shirt") or options:IsA("Pants") or options:IsA("ShirtGraphic") or options:IsA("CharacterMesh") then
				value = {
					Parent = false
				}
			elseif options:IsA("BasePart") and options.Parent == data and options.Name ~= "HumanoidRootPart" then
				value = {
					Color = color
				}
				if options:IsA("MeshPart") then
					value.TextureID = ""
				end
			elseif options:IsA("BodyColors") then
				value = {}
				for _, item in ipairs({
					"HeadColor3",
					"TorsoColor3",
					"LeftArmColor3",
					"RightArmColor3",
					"LeftLegColor3",
					"RightLegColor3"
				}) do
					value[item] = color
				end
			elseif options:IsA("SpecialMesh") and options.Parent and options.Parent.Parent == data then
				value = {
					TextureId = ""
				}
			elseif options:IsA("SurfaceAppearance") and options.Parent and options.Parent.Parent == data then
				value = {
					Parent = false
				}
			end
			if value then
				local records = {}
				playerDisplayData.Saved[options] = records
				for index, item3 in pairs(value) do
					pcall(function()
						records[index] = options[index]
						if index == "Parent" then
							options.Parent = nil
						else
							options[index] = item3
						end
					end)
				end
			end
		end
		playerDisplayData.Descendants = data.DescendantAdded:Connect(function(options)
			task.defer(function()
				if playerDisplayData.Alive and playerDisplayData.Enabled and generation == playerDisplayData.Generation then
					pcall(helperFunction, options)
				end
			end)
		end)
		for _, item4 in ipairs(data:GetDescendants()) do
			pcall(helperFunction, item4)
		end
	end
	function playerDisplayData.Set(data)
		if not playerDisplayData.Alive then
			return
		end
		data = data == true
		stateReference.HideUser = data
		if playerDisplayData.Enabled == data and (not data or playerDisplayData.Character == localPlayerReference.Character) then
			return
		end
		playerDisplayData.Enabled = data
		applyPlayerDisplaySettings(data and localPlayerReference.Character or nil)
		setupPlayerImageTracking()
	end
	function playerDisplayData.Destroy()
		if not playerDisplayData.Alive then
			return
		end
		playerDisplayData.Alive = false
		playerDisplayData.Enabled = false
		applyPlayerDisplaySettings(nil)
		setupPlayerDisplay()
		if playerDisplayData.Respawn then
			playerDisplayData.Respawn:Disconnect()
			playerDisplayData.Respawn = nil
		end
		if globalEnvironment[text3] == playerDisplayData then
			globalEnvironment[text3] = nil
		end
	end
	playerDisplayData.Respawn = localPlayerReference.CharacterAdded:Connect(function(data)
		if playerDisplayData.Alive and playerDisplayData.Enabled then
			applyPlayerDisplaySettings(data)
		end
	end)
	function hubReference.SetHideUser(data)
		playerDisplayData.Set(data)
	end
	if Window and type(Window.OnDestroy) == "function" then
		pcall(function()
			Window:OnDestroy(playerDisplayData.Destroy)
		end)
	end
	playerDisplayData.Set(stateReference.HideUser)
end
-- Settings and privacy controls
miscTab:Section({
	Title = "Automation"
})
miscTab:Toggle({
	Title = "Auto Execute",
	Desc = "Reload after teleport.",
	Value = State.AutoExecute,
	Callback = function(data)
		State.AutoExecute = data == true
		saveConfig()
		if State.AutoExecute and not Hub.QueueTeleport() then
			setStatus("Auto Execute", Utilities.AutoExecuteError or "Unavailable")
		end
	end
})
miscTab:Section({
	Title = "Privacy"
})
miscTab:Toggle({
	Title = "Hide Name",
	Value = State.HideName,
	Callback = function(data)
		State.HideName = data == true
		Hub.SetHideName(State.HideName)
		queueConfigSave()
	end
})
miscTab:Toggle({
	Title = "Hide User",
	Desc = "Hide your character locally.",
	Value = State.HideUser,
	Callback = function(data)
		Hub.SetHideUser(data)
		queueConfigSave()
	end
})
miscTab:Section({
	Title = "Performance"
})
miscTab:Toggle({
	Title = "FPS Boost",
	Desc = "Reduce effects and shadows.",
	Value = State.FPSBoost,
	Callback = function(data)
		State.FPSBoost = data == true
		Hub.SetFPSBoost(State.FPSBoost)
		queueConfigSave()
	end
})
miscTab:Toggle({
	Title = "Anti-AFK",
	Value = State.AntiAFK,
	Callback = function(data)
		State.AntiAFK = data == true
		queueConfigSave()
	end
})
if State.ProfileName ~= "" then
	local loadedProfile = loadProfile(State.ProfileName)
	if not loadedProfile then
		State.ProfileName = ""
	end
end
if State.PlaybackEnabled and # State.Actions > 0 then
	task.defer(startEnabledPlayback)
end
task.spawn(function()
	while State.Running do
		if UI.Runtime then
			UI.Runtime:SetTitle("Live match")
			UI.Runtime:SetDesc(getRuntimeText())
		end
		task.wait(0.5)
	end
end)
-- Shutdown and public API
function Hub.Destroy()
	if Hub.BlackScreenController then
		Hub.BlackScreenController.Destroy()
	end
	if not State.Running then
		return
	end
	if State.Recording then
		pcall(stopRecording, true)
	end
	stopPlayback()
	if Hub.HideUserController then
		Hub.HideUserController.Destroy()
	end
	State.Running = false
	Hub.StopKnock()
	Hub.StopUtilities()
	State.Recording = false
	State.Playing = false
	clearLegacyAbilityHook()
	saveConfig()
	disconnectAll(State.RecorderConnections)
	disconnectAll(State.Connections)
	pcall(function()
		Window:Destroy()
	end)
	if env.SkibidiDefenseHub == Hub then
		env.SkibidiDefenseHub = nil
	end
end
pcall(function()
	Window:OnDestroy(Hub.Destroy)
end)
Hub.State = State
Hub.StartRecording = startRecording
Hub.StopRecording = stopRecording
Hub.StartPlayback = startPlayback
Hub.StopPlayback = stopPlayback
Hub.SaveProfile = saveProfile
Hub.LoadProfile = loadProfile
Hub.ListProfiles = listProfiles
Hub.SetSpeed = ApplySpeed
updateActionSummary()
setStatus("Idle", State.ProfileName ~= "" and "Loaded " .. State.ProfileName or "Create or select a macro")
saveConfig()
Hub.StartUtilities()
if State.AutoKnockDoor and not Knock.Worker then
	Hub.SetAutoKnock(true)
end
print("Skibidi Defense Hub loaded. Made By Kero :3 | RightShift toggles WindUI.")
