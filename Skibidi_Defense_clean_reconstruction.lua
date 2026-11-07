--[[
    Skibidi Defense Hub - readable source reconstruction

    This file is a cleaned reconstruction of an uploaded, previously obfuscated
    script. It is not represented as the original author's source file.
    Runtime behavior has been preserved where possible; validate in Luau before use.
]]
-- Game validation and macro storage setup
if not game:IsLoaded() then
	game.Loaded:Wait()
end
if game.GameId ~= 4938220315 then
	return
end
pcall(function()
	if type(writefile) ~= "function" or type(makefolder) ~= "function" or type(isfolder) ~= "function" then
		return
	end
	if not isfolder("SkibidiDefense_Macros") then
		makefolder("SkibidiDefense_Macros")
	end
	writefile("SkibidiDefense_Macros/Hub.lua", "if not game:IsLoaded() then game.Loaded:Wait() end\nloadstring(game:HttpGet(\"https://raw.githubusercontent.com/KeroTwT/Kero-Hub/main/Sources/Skibidi%20Defense\"))()\n")
end)
-- Attribution validation
local Attribution = {
	Author = "Kero",
	OpenButton = "Skibidi Defense Hub",
	ToggleHint = "Hub opened | Press RightShift to hide."
}
do
	local function utilityRoutine4(parameter)
		if type(parameter) ~= "string" then
			return nil
		end
		local count = 0
		for i = 1, # parameter do
			count = (count * 131 + string.byte(parameter, i)) % 10000019
		end
		return count
	end
	local function utilityRoutine5(parameter)
		if utilityRoutine4(Attribution.Author) ~= 354808 or utilityRoutine4(Attribution.OpenButton) ~= 7010519 or utilityRoutine4(Attribution.ToggleHint) ~= 2144587 then
			return false
		end
		return not parameter or type(parameter.OpenButton) == "table" and utilityRoutine4(parameter.Author) == 354808 and utilityRoutine4(parameter.OpenButton.Title) == 7010519
	end
	function Attribution.Assert(parameter)
		if utilityRoutine5(parameter) then
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
	function Attribution.Check(parameter)
		Attribution.Assert(parameter)
		Attribution.Options = parameter
		return parameter
	end
	function Attribution.Bind(parameter, parameter2, parameter3, parameter4)
		Attribution.Window = parameter
		Attribution.Cleanup = parameter3
		Attribution.Assert(Attribution.Options)
		if parameter4 and type(parameter4.Notify) == "function" then
			pcall(function()
				parameter4:Notify({
					Title = "Skibidi Defense Hub",
					Content = Attribution.ToggleHint,
					Duration = 3
				})
			end)
		end
		task.spawn(function()
			while not Attribution.Stopped and parameter2() do
				Attribution.Assert(Attribution.Options)
				task.wait(1)
			end
		end)
		return parameter
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
		local runtimeValue17 = matched and MACRO_FOLDER .. "/" .. matched
		if runtimeValue17 and not isfile(runtimeValue17) then
			pcall(function()
				writefile(runtimeValue17, readfile(item2))
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
		return remote.OnClientEvent:Connect(function(parameter, parameter2)
			if State.Running and State.MoneySyncRemote == remote and parameter == "Money" and tonumber(parameter2) then
				State.ServerMoney = tonumber(parameter2)
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
	local runtimeValue4 = game2 and game2:FindFirstChild("Speed")
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
	Remotes.Speed = runtimeValue4 and runtimeValue4:FindFirstChild("Change")
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
	local runtimeValue4 = os.clock() + (timeout or 5)
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
	until os.clock() >= runtimeValue4
	return false
end
-- Match state and HUD readers
local function getPlayerGui()
	return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end
local function getGameEndedGui()
	local runtimeValue4 = getPlayerGui()
	return runtimeValue4 and runtimeValue4:FindFirstChild("GameEnded")
end
local function isMatchEnded()
	local runtimeValue4 = getGameEndedGui()
	local runtimeValue5 = runtimeValue4 and runtimeValue4:FindFirstChild("Frame")
	return runtimeValue4 ~= nil and runtimeValue4.Enabled ~= false and runtimeValue5 ~= nil and runtimeValue5.Visible ~= false
end
local function clickBackButton()
	if Hub.MatchFlow then
		return Hub.MatchFlow.ClickResult("back")
	end
	local runtimeValue4 = getGameEndedGui()
	local runtimeValue5 = runtimeValue4 and runtimeValue4:FindFirstChild("Frame")
	local runtimeValue6 = runtimeValue5 and runtimeValue5:FindFirstChild("back")
	if not runtimeValue6 or not runtimeValue6:IsA("GuiButton") then
		return false, "GameEnded.Frame.back was not found"
	end
	if type(getconnections) == "function" then
		local ok2, result2 = pcall(getconnections, runtimeValue6.MouseButton1Click)
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
		local ok4, result3 = pcall(firesignal, runtimeValue6.MouseButton1Click)
		if ok4 then
			return true
		end
		return false, tostring(result3)
	end
	return false, "Executor cannot invoke MouseButton1Click"
end
local function getMoney()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local runtimeValue4 = leaderstats and leaderstats:FindFirstChild("Money")
	State.LastLeaderMoney = runtimeValue4 and tonumber(runtimeValue4.Value) or 0
	local runtimeValue5 = State.ServerMoney ~= nil and tonumber(State.ServerMoney) or State.LastLeaderMoney
	if runtimeValue5 == - 9223372036854775808 or runtimeValue5 == math.huge then
		return math.huge
	end
	if runtimeValue5 ~= runtimeValue5 or runtimeValue5 == - math.huge then
		return 0
	end
	return runtimeValue5
end
local function formatMoney()
	local runtimeValue4 = getMoney()
	if runtimeValue4 == math.huge then
		return "Infinite"
	end
	if runtimeValue4 % 1 ~= 0 then
		return string.format("%.2f", runtimeValue4):gsub("0+$", ""):gsub("%.$", "")
	end
	return string.format("%.0f", runtimeValue4)
end
local function getWave()
	local runtimeValue4 = getPlayerGui()
	local runtimeValue5 = runtimeValue4 and runtimeValue4:FindFirstChild("Data")
	local runtimeValue6 = runtimeValue5 and runtimeValue5:FindFirstChild("Wave")
	local runtimeValue7 = runtimeValue6 and runtimeValue6:FindFirstChild("Frame")
	local runtimeValue8 = runtimeValue7 and runtimeValue7:FindFirstChild("TextLabel")
	local runtimeValue9 = runtimeValue8 and runtimeValue8.Text or ""
	return tonumber(runtimeValue9:match("[Ww][Aa][Vv][Ee]%s*(%d+)")) or 0
end
local function getPlacementText()
	local runtimeValue4 = getPlayerGui()
	local runtimeValue5 = runtimeValue4 and runtimeValue4:FindFirstChild("Towers")
	local runtimeValue6 = runtimeValue5 and runtimeValue5:FindFirstChild("Placement")
	local runtimeValue7 = runtimeValue6 and runtimeValue6:FindFirstChild("Frame")
	local runtimeValue8 = runtimeValue7 and runtimeValue7:FindFirstChild("TextLabel")
	return runtimeValue8 and runtimeValue8.Text or "Units: ?/?"
end
local function getRuntimeText()
	local runtimeValue4 = game.PlaceId == LOBBY_PLACE_ID and "Lobby" or "Wave " .. getWave()
	return runtimeValue4 .. " | " .. State.PlaybackMode .. " | Cash: " .. formatMoney()
end
local function getSpeedMultiplier()
	local runtimeValue4 = getPlayerGui()
	local runtimeValue5 = runtimeValue4 and runtimeValue4:FindFirstChild("Towers")
	local runtimeValue6 = runtimeValue5 and runtimeValue5:FindFirstChild("speedButton")
	local runtimeValue7 = runtimeValue6 and runtimeValue6:FindFirstChild("inner")
	local runtimeValue8 = runtimeValue7 and runtimeValue7:FindFirstChild("mult")
	local runtimeValue9 = runtimeValue8 and runtimeValue8.Text or ""
	return tonumber(runtimeValue9:match("(%d+)%s*[xX]"))
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
	local runtimeValue4 = getGameEndedGui()
	if not runtimeValue4 then
		return "Match Ended"
	end
	for _, item in ipairs(runtimeValue4:GetDescendants()) do
		if item:IsA("TextLabel") or item:IsA("TextButton") then
			local str = tostring(item.Text or "")
			local lowered = string.lower(str)
			if lowered:find("you have defeated", 1, true) or lowered:find("victory", 1, true) or lowered:find("you won", 1, true) then
				return "Victory"
			end
		end
	end
	for _, item3 in ipairs(runtimeValue4:GetDescendants()) do
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
	local dataTable = {
		Version = 6,
		Game = "Skibidi Defense",
		Universe = game.GameId,
		PlaceId = game.PlaceId,
		Name = name,
		RecordedAt = os.time(),
		Actions = State.Actions,
		Loadout = State.MacroLoadout
	}
	local ok2, result2 = pcall(HttpService.JSONEncode, HttpService, dataTable)
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
	local dataTable = {}
	for _, item in ipairs(listfiles(MACRO_FOLDER)) do
		local matched2 = item:match("([^\\/]+)%.json$")
		if matched2 and matched2 ~= "HubConfig" then
			table.insert(dataTable, matched2)
		end
	end
	table.sort(dataTable)
	return dataTable
end
-- Interface state and recorder bookkeeping
local UI = {}
local function setStatus(status, detail)
	State.Status, State.StatusDetail = status, detail or ""
	if UI.Status then
		local runtimeValue4 = "State: " .. tostring(status)
		if UI.LastStatusTitle ~= runtimeValue4 then
			UI.LastStatusTitle = runtimeValue4
			UI.Status:SetTitle(runtimeValue4)
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
local function isTruthyState(parameter)
	return parameter == true or type(parameter) == "number" and parameter > 0
end
local function abilityStateChanged(parameter, parameter2, parameter3)
	return parameter2 ~= parameter and (isTruthyState(parameter2) or parameter3 and parameter == nil and parameter2 == 0)
end
local function isModeMarker(parameter)
	return parameter == "SwitchModeState" or parameter == "AttackMode"
end
local function getGameClock()
	local game2 = ReplicatedStorage:FindFirstChild("Game")
	local runtimeValue4 = game2 and game2:FindFirstChild("Clock")
	local runtimeValue5 = runtimeValue4 and tonumber(runtimeValue4.Value)
	if runtimeValue5 and runtimeValue5 == runtimeValue5 and runtimeValue5 >= 0 and runtimeValue5 < math.huge then
		return runtimeValue5, "Game"
	end
	return os.clock(), "Real"
end
local function recorderTrace(parameter, parameter2)
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
		Type = parameter,
		Data = parameter2
	})
end
local function sanitizeTraceValue(parameter)
	if type(parameter) == "number" then
		return parameter == parameter and math.abs(parameter) ~= math.huge and parameter or tostring(parameter)
	end
	if type(parameter) == "string" then
		return parameter:sub(1, 250)
	end
	if type(parameter) == "boolean" or parameter == nil then
		return parameter
	end
	return tostring(parameter)
end
local function parseCost(parameter)
	local runtimeValue4 = tostring(parameter or ""):gsub("<[^>]+>", ""):gsub(",", ""):gsub("%s", "")
	local value, value1 = runtimeValue4:upper():match("%$?(%d+%.?%d*)([KMBT]?)")
	return (tonumber(value) or 0) * (({
		K = 1e3,
		M = 1e6,
		B = 1e9,
		T = 1e12
	})[value1] or 1)
end
local function readAbilityCard(parameter, parameter2)
	local runtimeValue4 = parameter
	for _ = 1, 12 do
		if not runtimeValue4 then
			return nil
		end
		if runtimeValue4.Parent and runtimeValue4.Parent.Name == "Abilities" then
			break
		end
		runtimeValue4 = runtimeValue4.Parent
	end
	if not runtimeValue4 or not runtimeValue4.Parent or runtimeValue4.Parent.Name ~= "Abilities" then
		return nil
	end
	local title, cost = runtimeValue4:FindFirstChild("Title"), runtimeValue4:FindFirstChild("Cost")
	if not title or not cost then
		return nil
	end
	if not (title:IsA("TextLabel") or title:IsA("TextButton")) or not (cost:IsA("TextLabel") or cost:IsA("TextButton")) then
		return nil
	end
	local runtimeValue5 = runtimeValue4
	while runtimeValue5 do
		if not parameter2 and runtimeValue5:IsA("GuiObject") and not runtimeValue5.Visible then
			return nil
		end
		if not parameter2 and runtimeValue5:IsA("ScreenGui") and not runtimeValue5.Enabled then
			return nil
		end
		runtimeValue5 = runtimeValue5.Parent
	end
	local runtimeValue6 = tostring(title.Text):gsub("<[^>]+>", "")
	if runtimeValue6 == "" or runtimeValue6 == "..." then
		return nil
	end
	local runtimeValue7 = ({
		["Switch Mode"] = "SwitchModeState",
		["Attack Mode Switch"] = "AttackMode"
	})[runtimeValue6] or "ATTACK" .. runtimeValue6:gsub("%s+", "")
	local locked = runtimeValue4:FindFirstChild("Locked")
	local runtimeValue8 = locked and locked:FindFirstChild("Frame")
	local runtimeValue9 = runtimeValue8 and runtimeValue8:IsA("TextLabel") and tonumber(tostring(runtimeValue8.Text):match("([%d%.]+)")) or nil
	local runtimeValue10 = tonumber(runtimeValue4:GetAttribute("AbilityIndex")) or tonumber(runtimeValue4.Name:match("(%d+)$"))
	if not runtimeValue10 then
		local dataTable = {}
		for index, item in ipairs(runtimeValue4.Parent:GetChildren()) do
			if item:IsA("GuiObject") and (parameter2 or item.Visible) and item:FindFirstChild("Title") and item:FindFirstChild("Cost") then
				table.insert(dataTable, {
					Object = item,
					Order = index,
					Layout = item.LayoutOrder
				})
			end
		end
		table.sort(dataTable, function(parameter3, parameter4)
			return parameter3.Layout == parameter4.Layout and parameter3.Order < parameter4.Order or parameter3.Layout < parameter4.Layout
		end)
		for index2, item3 in ipairs(dataTable) do
			if item3.Object == runtimeValue4 then
				runtimeValue10 = index2
				break
			end
		end
	end
	return {
		Card = runtimeValue4,
		Title = runtimeValue6,
		Marker = runtimeValue7,
		Index = runtimeValue10 or 1,
		Cost = parseCost(cost.Text),
		Cooldown = runtimeValue9,
		CooldownFloor = runtimeValue7 == "AttackMode" and 5 or nil,
		At = os.clock()
	}
end
local function onAbilityCardClicked(parameter)
	local runtimeValue4 = readAbilityCard(parameter)
	if not runtimeValue4 then
		return
	end
	local pendingAbility = State.PendingAbility
	if pendingAbility and pendingAbility.Card == runtimeValue4.Card and runtimeValue4.At - pendingAbility.At < 0.1 then
		return
	end
	State.PendingAbility = runtimeValue4
	recorderTrace("ability_input", {
		Title = runtimeValue4.Title,
		Index = runtimeValue4.Index,
		GuessedMarker = runtimeValue4.Marker,
		Cost = runtimeValue4.Cost
	})
end
local function resolveAbilityCard(parameter)
	local pendingAbility = State.PendingAbility
	if pendingAbility and os.clock() - pendingAbility.At <= 12 and pendingAbility.Marker == parameter then
		return pendingAbility
	end
	local runtimeValue4 = getPlayerGui()
	if runtimeValue4 then
		for _, item in ipairs(runtimeValue4:GetDescendants()) do
			if item.Name == "Title" then
				local ok2, result2 = pcall(readAbilityCard, item, true)
				if ok2 and result2 and result2.Marker == parameter then
					return result2
				end
			end
		end
	end
	if parameter == "ATTACKSoundBlast" then
		return {
			Title = "SoundBlast",
			Index = 1,
			Cost = 2500000,
			Cooldown = 3.2
		}
	end
	if parameter == "SwitchModeState" then
		return {
			Title = "Switch Mode",
			Index = 1,
			Cost = 1000000
		}
	end
	if parameter == "AttackMode" then
		return {
			Title = "Attack Mode Switch",
			Index = 1,
			Cost = 1000,
			CooldownFloor = 5
		}
	end
end
local function sampleAbilityCooldown(parameter)
	if parameter.Session ~= State.RecordSession then
		return
	end
	local card = parameter.Card
	local runtimeValue4 = card and card:FindFirstChild("Title")
	local runtimeValue5 = card and card:FindFirstChild("Locked")
	local runtimeValue6 = runtimeValue5 and runtimeValue5:FindFirstChild("Frame")
	if not runtimeValue4 or tostring(runtimeValue4.Text):gsub("<[^>]+>", "") ~= parameter.Action.AbilityName or not runtimeValue5.Visible or not runtimeValue6 or not runtimeValue6:IsA("TextLabel") then
		return
	end
	local num = tonumber(tostring(runtimeValue6.Text):match("^%s*(%d+%.?%d*)s%s*$"))
	if not num or num <= 0 or num > 3600 then
		return
	end
	local value, value1 = getGameClock()
	local runtimeValue7 = value1 == parameter.Kind and value - parameter.At or os.clock() - parameter.RealAt
	local runtimeValue8 = math.ceil((num + math.max(0, runtimeValue7)) * 10) / 10
	if runtimeValue8 > (parameter.Action.Cooldown or 0) then
		parameter.Action.Cooldown = runtimeValue8
		recorderTrace("ability_cooldown", {
			Marker = parameter.Action.Marker,
			Seconds = runtimeValue8
		})
	end
end
Hub.RecordAbilityAction = function(parameter, parameter2, parameter3, parameter4)
	if not State.Recording or not towerData then
		return false
	end
	local runtimeValue4 = typeof(parameter) == "Instance" and parameter or towerData:FindFirstChild(tostring(parameter or ""))
	local runtimeValue5 = runtimeValue4 and State.TowerMeta[runtimeValue4]
	if not runtimeValue5 then
		return false
	end
	local runtimeValue6 = parameter4 and parameter4.CapturedIntent or State.SkillIntents and State.SkillIntents[tostring(runtimeValue4.Name)]
	if runtimeValue6 and not runtimeValue6.Rejected and runtimeValue6.Session == State.RecordSession and os.clock() - runtimeValue6.At <= 12 then
		parameter2 = runtimeValue6.Index
		parameter4 = parameter4 or {}
		parameter4.RecordedAt = runtimeValue6.RecordedAt
		parameter4.RemoteIntent = true
		runtimeValue6.Marker = parameter3 or runtimeValue6.Marker
	else
		runtimeValue6 = nil
	end
	local now = os.clock()
	local lastAbilityAction = runtimeValue5.LastAbilityAction
	if lastAbilityAction and (runtimeValue6 and runtimeValue5.LastAbilityIntent == runtimeValue6 or not runtimeValue6 and lastAbilityAction.Marker == (parameter3 and tostring(parameter3) or nil) and now - (runtimeValue5.LastAbilityRecordedAt or - math.huge) <= 0.35) then
		lastAbilityAction.AbilityIndex = tonumber(parameter2) or lastAbilityAction.AbilityIndex or 1
		if parameter4 and parameter4.RecordedAt then
			lastAbilityAction.RecordedAt = parameter4.RecordedAt
		end
		if parameter3 and tostring(parameter3) ~= "" then
			lastAbilityAction.Marker = tostring(parameter3)
		end
		if parameter4 and isModeMarker(parameter3) and lastAbilityAction.ExpectedState == nil then
			lastAbilityAction.ExpectedState = parameter4.ConfirmedValue or runtimeValue4:GetAttribute(parameter3)
			lastAbilityAction.FromState = parameter4.PreviousValue
		end
		runtimeValue5.LastAbilityRecordedAt = now
		updateActionSummary()
		return true
	end
	local dataTable = {
		Type = "Ability",
		Handle = runtimeValue5.Handle,
		AbilityIndex = tonumber(parameter2) or 1,
		Marker = parameter3 and tostring(parameter3) or nil,
		RecordedAt = parameter4 and parameter4.RecordedAt,
		CaptureSource = parameter4 and parameter4.RemoteIntent and "Remote" or nil
	}
	runtimeValue5.LastAbilityAction = dataTable
	runtimeValue5.LastAbilityIntent = runtimeValue6
	runtimeValue5.LastAbilityRecordedAt = now
	if parameter4 then
		dataTable.AbilityName = parameter4.Title
		dataTable.EstimatedCost = parameter4.Cost
		dataTable.Cooldown = math.max(tonumber(parameter4.Cooldown) or 0, tonumber(parameter4.CooldownFloor) or 0)
		dataTable.RequiredLevel = tonumber(runtimeValue4:GetAttribute("Upgrade")) or 0
		if isModeMarker(parameter3) then
			dataTable.ExpectedState = parameter4.ConfirmedValue or runtimeValue4:GetAttribute(parameter3)
			dataTable.FromState = parameter4.PreviousValue
		end
	end
	queueTowerAction(runtimeValue5, dataTable)
	if parameter4 and parameter4.Card then
		local value, value1 = getGameClock()
		local dataTable2 = {
			Action = dataTable,
			Card = parameter4.Card,
			At = value,
			Kind = value1,
			RealAt = os.clock(),
			Session = State.RecordSession
		}
		State.RecordCooldownSamples = State.RecordCooldownSamples or {}
		table.insert(State.RecordCooldownSamples, dataTable2)
		for _, item in ipairs({
			.25,
			.75
		}) do
			task.delay(item, function()
				if State.Recording and State.RecordSession == dataTable2.Session then
					pcall(sampleAbilityCooldown, dataTable2)
				end
			end)
		end
	end
	recorderTrace("ability_recorded", {
		Handle = runtimeValue5.Handle,
		Marker = parameter3,
		Index = parameter2
	})
	return true
end
Hub.RecordBoostLinkAction = function(parameter, parameter2)
	if not State.Recording or not towerData then
		return false
	end
	local runtimeValue4 = typeof(parameter) == "Instance" and parameter or towerData:FindFirstChild(tostring(parameter or ""))
	local runtimeValue5 = typeof(parameter2) == "Instance" and parameter2 or towerData:FindFirstChild(tostring(parameter2 or ""))
	local runtimeValue6 = runtimeValue4 and State.TowerMeta[runtimeValue4]
	local runtimeValue7 = runtimeValue5 and State.TowerMeta[runtimeValue5]
	if not runtimeValue6 or not runtimeValue7 or runtimeValue4 == runtimeValue5 then
		return false
	end
	if not runtimeValue6.PlaceRecorded or not runtimeValue7.PlaceRecorded then
		if runtimeValue7.PendingBoostSourceHandle == runtimeValue6.Handle then
			return true
		end
		runtimeValue7.PendingBoostSourceHandle = runtimeValue6.Handle
		task.spawn(function()
			local runtimeValue8 = waitUntil(function()
				return not State.Recording or runtimeValue6.PlaceRecorded and runtimeValue7.PlaceRecorded
			end, 3, 0.03)
			if runtimeValue7.PendingBoostSourceHandle == runtimeValue6.Handle then
				runtimeValue7.PendingBoostSourceHandle = nil
			end
			if runtimeValue8 and State.Recording and runtimeValue4.Parent == towerData and runtimeValue5.Parent == towerData then
				Hub.RecordBoostLinkAction(runtimeValue4, runtimeValue5)
			end
		end)
		return true
	end
	local now = os.clock()
	local runtimeValue9 = State.BoostIntents and State.BoostIntents[tostring(runtimeValue5.Name)]
	local runtimeValue10 = runtimeValue9 and runtimeValue9.Session == State.RecordSession and runtimeValue9.Source == tostring(runtimeValue4.Name) and now - runtimeValue9.At <= 12 and runtimeValue9.RecordedAt or nil
	if runtimeValue7.LastBoostSourceHandle == runtimeValue6.Handle and now - (runtimeValue7.LastBoostRecordedAt or - math.huge) <= 0.5 then
		return true
	end
	runtimeValue7.LastBoostSourceHandle = runtimeValue6.Handle
	runtimeValue7.LastBoostRecordedAt = now
	pushAction({
		Type = "BoostLink",
		SourceHandle = runtimeValue6.Handle,
		TargetHandle = runtimeValue7.Handle,
		RecordedAt = runtimeValue10
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
	keroSkibidiSkillRouter.Begin = function(parameter, parameter2, parameter3)
		if not State.Running or not State.Recording or State.Playing then
			return
		end
		if type(parameter2) ~= "string" and type(parameter2) ~= "number" then
			return
		end
		if parameter == "Ability" and (type(parameter3) ~= "number" or parameter3 < 1 or parameter3 % 1 ~= 0) then
			return
		end
		if parameter == "Boost" and type(parameter3) ~= "string" and type(parameter3) ~= "number" then
			return
		end
		local now = os.clock()
		local dataTable = {
			At = now,
			RecordedAt = math.max(0, now - State.RecordStartedAt),
			Session = State.RecordSession,
			Id = tostring(parameter2),
			Index = parameter3,
			Source = tostring(parameter2)
		}
		if parameter == "Ability" then
			State.SkillIntents[dataTable.Id] = dataTable
		else
			State.BoostIntents[tostring(parameter3)] = dataTable
		end
		return dataTable
	end
	keroSkibidiSkillRouter.Finish = function(parameter, parameter2)
		if not parameter then
			return
		end
		if parameter2 == false then
			parameter.Rejected = true
		end
		if parameter2 ~= true then
			return
		end
		task.defer(function()
			if not State.Recording or State.RecordSession ~= parameter.Session then
				return
			end
			local runtimeValue4 = towerData and towerData:FindFirstChild(parameter.Id)
			local runtimeValue5 = runtimeValue4 and State.TowerMeta[runtimeValue4]
			if not runtimeValue5 then
				return
			end
			local lastAbilityAction = runtimeValue5.LastAbilityAction
			if lastAbilityAction and runtimeValue5.LastAbilityIntent == parameter then
				lastAbilityAction.AbilityIndex = parameter.Index
				lastAbilityAction.RecordedAt = parameter.RecordedAt
				lastAbilityAction.CaptureSource = "Remote"
				return
			end
			local pendingAbility = State.PendingAbility
			if not pendingAbility or os.clock() - pendingAbility.At > 3 then
				pendingAbility = nil
			end
			Hub.RecordAbilityAction(runtimeValue4, parameter.Index, parameter.Marker or pendingAbility and pendingAbility.Marker, {
				Title = pendingAbility and pendingAbility.Title,
				Cost = pendingAbility and pendingAbility.Cost,
				Card = pendingAbility and pendingAbility.Card,
				Cooldown = pendingAbility and pendingAbility.Cooldown,
				RecordedAt = parameter.RecordedAt,
				RemoteIntent = true,
				CapturedIntent = parameter
			})
		end)
	end
	if keroSkibidiSkillRouter.Installed then
		return
	end
	local function utilityRoutine(parameter, self, ...)
		local runtimeValue4 = coroutine.running()
		if keroSkibidiSkillRouter.Bypass[runtimeValue4] then
			return parameter(self, ...)
		end
		local runtimeValue5 = self == keroSkibidiSkillRouter.Ability and "Ability" or self == keroSkibidiSkillRouter.Boost and "Boost" or nil
		if not runtimeValue5 then
			return parameter(self, ...)
		end
		local ok2, result2 = pcall(keroSkibidiSkillRouter.Begin, runtimeValue5, ...)
		if not ok2 or not result2 then
			return parameter(self, ...)
		end
		keroSkibidiSkillRouter.Bypass[runtimeValue4] = true
		keroSkibidiSkillRouter.Pending = (keroSkibidiSkillRouter.Pending or 0) + 1
		local result3 = table.pack(pcall(parameter, self, ...))
		keroSkibidiSkillRouter.Bypass[runtimeValue4] = nil
		if result3[1] and runtimeValue5 == "Ability" then
			pcall(keroSkibidiSkillRouter.Finish, result2, result3[2])
		end
		keroSkibidiSkillRouter.Pending = keroSkibidiSkillRouter.Pending - 1
		if not result3[1] then
			error(result3[2], 0)
		end
		return table.unpack(result3, 2, result3.n)
	end
	local runtimeValue6 = type(newcclosure) == "function" and newcclosure or function(parameter)
		return parameter
	end
	if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
		local runtimeValue7
		local ok3 = pcall(function()
			local runtimeValue5 = runtimeValue6(function(self, ...)
				local runtimeValue4 = getnamecallmethod()
				if runtimeValue4 == "InvokeServer" or runtimeValue4 == "FireServer" then
					return utilityRoutine(runtimeValue7, self, ...)
				end
				return runtimeValue7(self, ...)
			end)
			local cobalt = env.Cobalt
			local runtimeValue8 = cobalt and cobalt.shared
			local runtimeValue9 = runtimeValue8 and runtimeValue8.Hooking
			if runtimeValue9 and type(runtimeValue9.HookMetaMethod) == "function" then
				runtimeValue7 = runtimeValue9.HookMetaMethod(game, "__namecall", runtimeValue5)
			else
				runtimeValue7 = hookmetamethod(game, "__namecall", runtimeValue5)
			end
		end)
		keroSkibidiSkillRouter.Namecall = ok3
	end
	if type(hookfunction) == "function" then
		for _, item in ipairs({
			Remotes.Ability,
			Remotes.BoostSelect
		}) do
			local runtimeValue10
			local ok4 = pcall(function()
				local runtimeValue4 = item == Remotes.Ability and item.InvokeServer or item.FireServer
				runtimeValue10 = hookfunction(runtimeValue4, runtimeValue6(function(self, ...)
					return utilityRoutine(runtimeValue10, self, ...)
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
local function guessAbilityIndex(parameter)
	local runtimeValue4 = parameter
	for _ = 1, 4 do
		if not runtimeValue4 then
			break
		end
		for _, item in ipairs({
			"AbilityIndex",
			"Ability",
			"Index",
			"Slot"
		}) do
			local num = tonumber(runtimeValue4:GetAttribute(item))
			if num and num >= 1 then
				return math.floor(num)
			end
		end
		local num2 = tonumber(tostring(runtimeValue4.Name):match("(%d+)$"))
		if num2 and num2 >= 1 then
			return math.floor(num2)
		end
		if runtimeValue4:IsA("GuiObject") and runtimeValue4.LayoutOrder > 0 then
			return runtimeValue4.LayoutOrder
		end
		runtimeValue4 = runtimeValue4.Parent
	end
	return 1
end
local function isOwnTower(tower)
	return tower and tower.Parent == towerData and tower:GetAttribute("Creator") == LocalPlayer.Name
end
local function waitForTowerModel(parameter, parameter2)
	if not towerModels then
		return nil
	end
	local runtimeValue4
	waitUntil(function()
		runtimeValue4 = towerModels:FindFirstChild(tostring(parameter))
		return runtimeValue4
	end, parameter2 or 2, 0.05)
	return runtimeValue4
end
local function getTowerCFrame(parameter)
	local runtimeValue4 = State.RecordPlacementReceipts and State.RecordPlacementReceipts[tostring(parameter.Name)]
	if runtimeValue4 and runtimeValue4.Unit == tostring(parameter:GetAttribute("ID")) then
		return runtimeValue4.CFrame
	end
	local boostPos = parameter:GetAttribute("BoostPos")
	local runtimeValue5 = towerModels and towerModels:FindFirstChild(tostring(parameter.Name))
	if typeof(boostPos) ~= "Vector3" and not runtimeValue5 then
		runtimeValue5 = waitForTowerModel(parameter.Name, 2)
	end
	if typeof(boostPos) == "Vector3" then
		local runtimeValue6 = CFrame.identity
		if runtimeValue5 and runtimeValue5:IsA("Model") then
			local ok2, result2 = pcall(runtimeValue5.GetPivot, runtimeValue5)
			if ok2 then
				runtimeValue6 = result2.Rotation
			end
		end
		return CFrame.new(boostPos) * runtimeValue6
	end
	return nil
end
local function isDefaultTargetMode(parameter)
	if parameter == nil then
		return true
	end
	local runtimeValue4 = tostring(parameter):upper():gsub("%s+", "")
	return runtimeValue4 == "" or runtimeValue4 == "N/A" or runtimeValue4 == "NA" or runtimeValue4 == "NONE"
end
local function matchUpgradeCosts(parameter)
	local upgradeActionQueue, upgradeCostQueue = parameter.UpgradeActionQueue, parameter.UpgradeCostQueue
	while # upgradeActionQueue > 0 and # upgradeCostQueue > 0 do
		local runtimeValue4, runtimeValue5 = upgradeActionQueue[1], upgradeCostQueue[1]
		if math.abs(runtimeValue4.At - runtimeValue5.At) <= 1 then
			runtimeValue4.Action.EstimatedCost = runtimeValue5.Value
			table.remove(upgradeActionQueue, 1)
			table.remove(upgradeCostQueue, 1)
		elseif runtimeValue4.At < runtimeValue5.At then
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
	local dataTable = {
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
			dataTable.AbilityMarkers[index] = item
		end
	end
	State.TowerMeta[tower] = dataTable
	local dataTable2 = {}
	for index2, item3 in pairs(tower:GetAttributes()) do
		dataTable2[index2] = sanitizeTraceValue(item3)
	end
	recorderTrace("tower_attached", {
		Handle = handle,
		RuntimeId = tower.Name,
		Attributes = dataTable2
	})
	trackConnection(State.RecorderConnections, tower:GetAttributeChangedSignal("SellPrice"):Connect(function()
		local runtimeValue4 = tonumber(tower:GetAttribute("SellPrice")) or dataTable.SellPrice
		if runtimeValue4 > dataTable.SellPrice then
			dataTable.PendingUpgradeCost = math.max(0, (runtimeValue4 - dataTable.SellPrice) * 2)
			dataTable.LastUpgradeAt = os.clock()
			if State.Recording and dataTable.Session == State.RecordSession then
				table.insert(dataTable.UpgradeCostQueue, {
					At = os.clock(),
					Value = dataTable.PendingUpgradeCost
				})
				matchUpgradeCosts(dataTable)
			end
		end
		dataTable.SellPrice = runtimeValue4
	end))
	trackConnection(State.RecorderConnections, tower:GetAttributeChangedSignal("Upgrade"):Connect(function()
		local runtimeValue4 = tonumber(tower:GetAttribute("Upgrade")) or dataTable.Level
		if State.Recording and dataTable.Session == State.RecordSession and runtimeValue4 > dataTable.Level then
			dataTable.LastUpgradeAt = os.clock()
			local dataTable3 = {
				Type = "Upgrade",
				Handle = dataTable.Handle,
				FromLevel = dataTable.Level,
				ToLevel = runtimeValue4,
				EstimatedCost = dataTable.PendingUpgradeCost or 0
			}
			queueTowerAction(dataTable, dataTable3)
			table.insert(dataTable.UpgradeActionQueue, {
				At = os.clock(),
				Action = dataTable3
			})
			matchUpgradeCosts(dataTable)
		end
		dataTable.Level = runtimeValue4
		dataTable.PendingUpgradeCost = nil
	end))
	trackConnection(State.RecorderConnections, tower:GetAttributeChangedSignal("TargetMode"):Connect(function()
		local targetMode = tower:GetAttribute("TargetMode")
		local targetMode2 = dataTable.TargetMode
		local runtimeValue4 = isDefaultTargetMode(targetMode2) and os.clock() - dataTable.LastUpgradeAt <= 0.5
		if State.Recording and dataTable.Session == State.RecordSession and targetMode and targetMode ~= targetMode2 and not runtimeValue4 then
			queueTowerAction(dataTable, {
				Type = "Target",
				Handle = dataTable.Handle,
				Mode = targetMode
			})
		end
		dataTable.TargetMode = targetMode
	end))
	trackConnection(State.RecorderConnections, tower:GetAttributeChangedSignal("ClockBoost"):Connect(function()
		local clockBoost = dataTable.ClockBoost
		local clockBoost2 = tower:GetAttribute("ClockBoost")
		dataTable.ClockBoost = clockBoost2
		if not State.Recording or clockBoost2 == nil or tostring(clockBoost2) == "" or tostring(clockBoost2) == "0" or tostring(clockBoost2) == tostring(clockBoost) then
			return
		end
		Hub.RecordBoostLinkAction(clockBoost2, tower)
	end))
	trackConnection(State.RecorderConnections, tower.AttributeChanged:Connect(function(parameter)
		if State.Recording and dataTable.Session == State.RecordSession then
			local dataTable3 = {
				Damage = true,
				CurrentTarget = true,
				Stun = true,
				StunMark = true,
				Health = true,
				StunTime = true,
				StunAccum = true
			}
			if not dataTable3[parameter] then
				recorderTrace("tower_attribute", {
					Handle = dataTable.Handle,
					Key = parameter,
					Value = sanitizeTraceValue(tower:GetAttribute(parameter))
				})
			end
		end
		if not tostring(parameter):match("^ATTACK") and not isModeMarker(parameter) then
			return
		end
		local runtimeValue4 = dataTable.AbilityMarkers[parameter]
		local runtimeValue5 = tower:GetAttribute(parameter)
		dataTable.AbilityMarkers[parameter] = runtimeValue5
		if not State.Recording or dataTable.Session ~= State.RecordSession or runtimeValue4 == runtimeValue5 then
			return
		end
		local pendingAbility = State.PendingAbility
		local runtimeValue6 = State.SkillIntents and State.SkillIntents[tostring(tower.Name)]
		local runtimeValue7 = pendingAbility and pendingAbility.Marker == parameter and os.clock() - pendingAbility.At <= 3 or runtimeValue6 and not runtimeValue6.Rejected and runtimeValue6.Session == State.RecordSession and os.clock() - runtimeValue6.At <= 12
		if not isModeMarker(parameter) and not abilityStateChanged(runtimeValue4, runtimeValue5, runtimeValue7) then
			return
		end
		if parameter == "SwitchModeState" and runtimeValue4 == nil and runtimeValue5 ~= 2 then
			return
		end
		if parameter == "AttackMode" and (runtimeValue4 == nil or type(runtimeValue5) ~= "number" or runtimeValue5 < 1 or runtimeValue5 > 3) then
			return
		end
		task.defer(function()
			if not State.Recording or dataTable.Session ~= State.RecordSession then
				return
			end
			local ok2, result2 = pcall(resolveAbilityCard, parameter)
			if not ok2 or not result2 then
				recorderTrace("unmapped_activation", {
					Handle = dataTable.Handle,
					Marker = parameter,
					Reason = not ok2 and tostring(result2) or "No known native skill mapping"
				})
				return
			end
			local dataTable4 = {
				Title = result2.Title,
				Card = result2.Card,
				Cost = result2.Cost,
				Cooldown = result2.Cooldown,
				CooldownFloor = result2.CooldownFloor,
				ConfirmedValue = runtimeValue5,
				PreviousValue = runtimeValue4
			}
			Hub.RecordAbilityAction(tower, result2.Index, parameter, dataTable4)
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
		return Remotes.Place.OnClientEvent:Connect(function(parameter, parameter2, parameter3, parameter4)
			if not State.Recording or State.RecordSession ~= recordSession or parameter ~= LocalPlayer or typeof(parameter3) ~= "CFrame" or type(parameter4) ~= "number" and type(parameter4) ~= "string" then
				return
			end
			if Hub.MatchFlow then
				Hub.MatchFlow.UpdateRecorderClock()
			end
			local str = tostring(parameter4)
			local dataTable = {
				Unit = tostring(parameter2),
				CFrame = parameter3,
				RecordedAt = os.clock() - State.RecordStartedAt
			}
			State.RecordPlacementReceipts[str] = dataTable
			local runtimeValue4 = State.RecordPlacementActions[str]
			if runtimeValue4 and runtimeValue4.Unit == dataTable.Unit then
				runtimeValue4.CFrame, runtimeValue4.PlacementSpace = cframeToArray(parameter3), "Ground"
				runtimeValue4.RecordedAt = dataTable.RecordedAt
			end
		end)
	end)
	if ok2 and result2 then
		trackConnection(State.RecorderConnections, result2)
	end
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local dataTable2 = setmetatable({}, {
		__mode = "k"
	})
	local function utilityRoutine(parameter)
		if dataTable2[parameter] or not parameter:IsA("GuiObject") then
			return
		end
		local runtimeValue4, stateFlag = parameter, false
		for _ = 1, 12 do
			if not runtimeValue4 then
				break
			end
			if runtimeValue4.Name == "Abilities" then
				stateFlag = true
				break
			end
			runtimeValue4 = runtimeValue4.Parent
		end
		if not stateFlag then
			return
		end
		dataTable2[parameter] = true
		trackConnection(State.RecorderConnections, parameter.InputBegan:Connect(function(parameter2)
			if State.Recording and State.RecordSession == recordSession and (parameter2.UserInputType == Enum.UserInputType.MouseButton1 or parameter2.UserInputType == Enum.UserInputType.Touch) then
				onAbilityCardClicked(parameter)
			end
		end))
	end
	if playerGui then
		for _, item in ipairs(playerGui:GetDescendants()) do
			utilityRoutine(item)
		end
		trackConnection(State.RecorderConnections, playerGui.DescendantAdded:Connect(utilityRoutine))
		trackConnection(State.RecorderConnections, game:GetService("UserInputService").InputBegan:Connect(function(parameter)
			if not State.Recording or State.RecordSession ~= recordSession then
				return
			end
			if parameter.UserInputType ~= Enum.UserInputType.MouseButton1 and parameter.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local ok3, result3 = pcall(playerGui.GetGuiObjectsAtPosition, playerGui, parameter.Position.X, parameter.Position.Y)
			local dataTable = {}
			if ok3 then
				for index, item3 in ipairs(result3) do
					if index > 12 then
						break
					end
					local name = item3.Name
					pcall(function()
						name = item3:GetFullName():gsub("Players%.[^%.]+%.", "Players.Local.")
					end)
					local runtimeValue4 = ""
					if item3:IsA("TextLabel") or item3:IsA("TextButton") then
						runtimeValue4 = item3.Text
					end
					dataTable[# dataTable + 1] = {
						Path = name,
						Class = item3.ClassName,
						Text = tostring(runtimeValue4):sub(1, 120)
					}
				end
			end
			recorderTrace("pointer_input", {
				HitTestOK = ok3,
				Hits = dataTable
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
	trackConnection(State.RecorderConnections, towerData.ChildAdded:Connect(function(parameter)
		if Hub.MatchFlow then
			Hub.MatchFlow.UpdateRecorderClock()
		end
		local runtimeValue4 = os.clock() - State.RecordStartedAt
		task.spawn(function()
			local runtimeValue5 = waitUntil(function()
				return isOwnTower(parameter) and parameter:GetAttribute("ID") ~= nil
			end, 5, 0.05)
			if not runtimeValue5 or not State.Recording or State.RecordSession ~= recordSession then
				return
			end
			local runtimeValue6 = "T" .. State.NextHandle
			State.NextHandle = State.NextHandle + 1
			trackTower(parameter, runtimeValue6)
			local runtimeValue7 = getTowerCFrame(parameter)
			if not runtimeValue7 then
				setStatus("Record warning", "Could not read placement CFrame for tower " .. parameter.Name)
				return
			end
			if not State.Recording or State.RecordSession ~= recordSession then
				return
			end
			local runtimeValue8 = tonumber(parameter:GetAttribute("SellPrice")) or 0
			local runtimeValue9 = State.RecordPlacementReceipts[tostring(parameter.Name)]
			local dataTable = {
				Type = "Place",
				Handle = runtimeValue6,
				Unit = tostring(parameter:GetAttribute("ID")),
				CFrame = cframeToArray(runtimeValue7),
				PlacementSpace = "Ground",
				RecordedAt = runtimeValue9 and runtimeValue9.RecordedAt or runtimeValue4,
				EstimatedCost = runtimeValue8 * 2
			}
			State.RecordPlacementActions[tostring(parameter.Name)] = dataTable
			pushAction(dataTable)
			local runtimeValue10 = State.TowerMeta[parameter]
			if runtimeValue10 then
				runtimeValue10.PlaceRecorded = true
				for _, item3 in ipairs(runtimeValue10.PendingActions or {}) do
					pushAction(item3)
				end
				runtimeValue10.PendingActions = nil
			end
		end)
	end))
	trackConnection(State.RecorderConnections, towerData.ChildRemoved:Connect(function(parameter)
		local runtimeValue4 = State.TowerMeta[parameter]
		if not runtimeValue4 then
			return
		end
		task.delay(0.15, function()
			if State.Recording and State.RecordSession == recordSession and not isMatchEnded() then
				pushAction({
					Type = "Sell",
					Handle = runtimeValue4.Handle
				})
			end
		end)
	end))
	local runtimeValue11 = getGameEndedGui()
	if runtimeValue11 then
		trackConnection(State.RecorderConnections, runtimeValue11:GetPropertyChangedSignal("Enabled"):Connect(function()
			if State.Recording and runtimeValue11.Enabled then
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
stopRecording = function(parameter)
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
	local dataTable = {}
	for index, item3 in ipairs(State.Actions) do
		dataTable[item3] = index
	end
	table.sort(State.Actions, function(parameter2, parameter3)
		local runtimeValue4, runtimeValue5 = tonumber(parameter2.RecordedAt) or 0, tonumber(parameter3.RecordedAt) or 0
		if runtimeValue4 == runtimeValue5 then
			return dataTable[parameter2] < dataTable[parameter3]
		end
		return runtimeValue4 < runtimeValue5
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
	if parameter then
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
local function getActionCFrame(parameter)
	local runtimeValue4 = arrayToCFrame(parameter.CFrame)
	if not runtimeValue4 or parameter.PlacementSpace == "Ground" then
		return runtimeValue4
	end
	local copy = table.clone(parameter.CFrame)
	copy[2] = tonumber(copy[2]) - 4.7
	return arrayToCFrame(copy)
end
local function findRuntimeTower(parameter, parameter2)
	if not towerData then
		return nil
	end
	local runtimeValue4 = getActionCFrame(parameter)
	if not runtimeValue4 then
		return nil
	end
	local runtimeValue5
	for _, item in ipairs(towerData:GetChildren()) do
		if isOwnTower(item) and not State.UsedRuntimeTowers[item] and (not parameter2 or not parameter2[item]) and tostring(item:GetAttribute("ID")) == tostring(parameter.Unit) then
			local boostPos = item:GetAttribute("BoostPos")
			if typeof(boostPos) == "Vector3" and flatDistance(boostPos, runtimeValue4.Position) <= 0.35 and math.abs(boostPos.Y - runtimeValue4.Position.Y) <= 1 then
				if runtimeValue5 then
					return nil, "Multiple matching towers at the recorded position"
				end
				runtimeValue5 = item
			end
		end
	end
	return runtimeValue5
end
local function isPlaying(session)
	return State.Running and State.Playing and (session == nil or State.PlaySession == session)
end
local function waitForActionTime(action, startedAt, session)
	local runtimeValue4 = tonumber(action.RecordedAt) or 0
	local runtimeValue5 = tonumber(action.EstimatedCost) or 0
	local _ = tonumber(action.Wave) or 0
	return waitUntil(function()
		if not isPlaying(session) or isMatchEnded() then
			return true
		end
		local runtimeValue6 = os.clock() - startedAt
		local runtimeValue7 = runtimeValue6 >= runtimeValue4
		local runtimeValue8 = runtimeValue5 <= 0 or getMoney() >= runtimeValue5
		local runtimeValue9 = action.Type == "Upgrade" and State.RuntimeHandles[action.Handle]
		if runtimeValue9 and runtimeValue9.Parent == towerData and (tonumber(runtimeValue9:GetAttribute("Upgrade")) or 0) >= (tonumber(action.ToLevel) or (tonumber(action.FromLevel) or 0) + 1) then
			runtimeValue8 = true
		end
		if State.PlaybackMode == "Time" then
			return runtimeValue7
		elseif State.PlaybackMode == "Money" then
			return runtimeValue8
		end
		return runtimeValue7 and runtimeValue8
	end, 600, 0.03)
end
local function playPlace(action, session)
	local runtimeValue4 = getActionCFrame(action)
	if not runtimeValue4 then
		return false, "Invalid placement CFrame"
	end
	local runtimeValue5 = os.clock() + 180
	local runtimeValue6 = tonumber(action.EstimatedCost) or 0
	local count = 0
	local dataTable = {}
	for _, item in ipairs(towerData:GetChildren()) do
		dataTable[item] = true
	end
	while isPlaying(session) and os.clock() < runtimeValue5 and not isMatchEnded() do
		if getMoney() >= runtimeValue6 then
			local runtimeValue7 = dataTable
			local value, value1 = findRuntimeTower(action, runtimeValue7)
			if value then
				State.RuntimeHandles[action.Handle] = value
				State.UsedRuntimeTowers[value] = true
				return true
			end
			if value1 then
				return false, value1
			end
			if count >= 5 then
				return false, "Placement unconfirmed after 5 attempts"
			end
			count = count + 1
			local runtimeValue8 = getMoney()
			local runtimeValue9, runtimeValue10, runtimeValue11, runtimeValue12, runtimeValue13
			local dataTable2 = {}
			for index in pairs(runtimeValue7) do
				dataTable2[tostring(index.Name)] = true
			end
			local ok2, result2 = pcall(function()
				return Remotes.Place.OnClientEvent:Connect(function(parameter, parameter2, parameter3, parameter4)
					if not isPlaying(session) or isMatchEnded() or parameter ~= LocalPlayer or tostring(parameter2) ~= tostring(action.Unit) or typeof(parameter3) ~= "CFrame" or type(parameter4) ~= "number" and type(parameter4) ~= "string" then
						return
					end
					local str = tostring(parameter4)
					if dataTable2[str] or str == "" then
						return
					end
					if flatDistance(parameter3.Position, runtimeValue4.Position) > 0.35 or math.abs(parameter3.Position.Y - runtimeValue4.Position.Y) > 1 then
						return
					end
					if runtimeValue9 and runtimeValue9 ~= str then
						runtimeValue10 = true
					end
					runtimeValue9 = str
				end)
			end)
			if ok2 then
				runtimeValue11 = result2
			end
			local ok3, result3 = pcall(function()
				return Remotes.Notice.OnClientEvent:Connect(function(parameter)
					local runtimeValue14 = type(parameter) == "table" and tostring(parameter.Text or "") or tostring(parameter)
					local lowered = runtimeValue14:lower()
					if lowered:find("place", 1, true) and (lowered:find("cash", 1, true) or lowered:find("money", 1, true)) and (lowered:find("need", 1, true) or lowered:find("enough", 1, true) or lowered:find("insufficient", 1, true)) then
						runtimeValue13 = {
							Text = runtimeValue14,
							At = os.clock(),
							Cash = getMoney()
						}
						if lowered:find("need more cash to place", 1, true) then
							local num = tonumber(runtimeValue14:gsub(",", ""):match("%$([%d%.]+)"))
							if num then
								runtimeValue6 = math.max(runtimeValue6, math.ceil(getMoney() + num))
							end
						end
					end
				end)
			end)
			if ok3 then
				runtimeValue12 = result3
			end
			local ok4, result4 = pcall(Remotes.Place.FireServer, Remotes.Place, action.Unit, runtimeValue4, false)
			local runtimeValue15
			local value3, value13 = waitUntil(function()
				if not isPlaying(session) or isMatchEnded() then
					return true
				end
				if runtimeValue10 then
					runtimeValue15 = "Multiple placement receipts matched; no duplicate retry"
					return nil
				end
				if runtimeValue9 then
					local runtimeValue14 = towerData:FindFirstChild(runtimeValue9)
					if runtimeValue14 and isOwnTower(runtimeValue14) and not runtimeValue7[runtimeValue14] and not State.UsedRuntimeTowers[runtimeValue14] and tostring(runtimeValue14:GetAttribute("ID")) == tostring(action.Unit) then
						return runtimeValue14
					end
					return nil
				end
				local value2, value12 = findRuntimeTower(action, runtimeValue7)
				runtimeValue15 = value12
				if value2 then
					return value2
				end
				if runtimeValue13 and not runtimeValue9 and not runtimeValue15 and os.clock() - runtimeValue13.At >= 0.15 then
					return "funds_rejected"
				end
				return nil
			end, 2, 0.03)
			if runtimeValue9 and not runtimeValue10 and not (value3 and typeof(value13) == "Instance") then
				value3, value13 = waitUntil(function()
					if not isPlaying(session) or isMatchEnded() then
						return true
					end
					local runtimeValue14 = towerData:FindFirstChild(runtimeValue9)
					if runtimeValue14 and isOwnTower(runtimeValue14) and not runtimeValue7[runtimeValue14] and not State.UsedRuntimeTowers[runtimeValue14] and tostring(runtimeValue14:GetAttribute("ID")) == tostring(action.Unit) then
						return runtimeValue14
					end
				end, 6, .03)
			end
			if runtimeValue11 then
				runtimeValue11:Disconnect()
			end
			if runtimeValue12 then
				runtimeValue12:Disconnect()
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
			if value13 == "funds_rejected" and runtimeValue13 and not runtimeValue9 then
				State.PlacementWait = {
					Handle = action.Handle,
					RequiredCost = runtimeValue6,
					ServerMessage = runtimeValue13.Text
				}
				setStatus("Playback", "Place " .. tostring(action.Unit) .. " | waiting for server funds " .. formatMoney() .. "/" .. tostring(runtimeValue6))
				local runtimeValue16 = getMoney()
				waitUntil(function()
					return not isPlaying(session) or isMatchEnded() or getMoney() >= runtimeValue6 and getMoney() ~= runtimeValue16
				end, math.max(0.03, runtimeValue5 - os.clock()), 0.03)
			else
				if runtimeValue15 or runtimeValue9 or not ok4 then
					return false, runtimeValue15 or (runtimeValue9 and "Placement accepted; metadata unconfirmed, no duplicate retry" or "Place transport failed: " .. tostring(result4))
				end
				if getMoney() < runtimeValue8 then
					return false, "Placement changed cash; no duplicate resend"
				end
				for _, item3 in ipairs(towerData:GetChildren()) do
					if not runtimeValue7[item3] and isOwnTower(item3) then
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
	local runtimeValue4 = State.RuntimeHandles[handle]
	if runtimeValue4 and runtimeValue4.Parent == towerData then
		return runtimeValue4
	end
	return nil
end
local function playUpgrade(action, session)
	local runtimeValue4 = getRuntimeTower(action.Handle)
	if not runtimeValue4 then
		return false, "Tower handle is missing: " .. tostring(action.Handle)
	end
	local runtimeValue5 = tonumber(action.ToLevel) or (tonumber(action.FromLevel) or 0) + 1
	local num = math.max(0, tonumber(action.EstimatedCost) or 0)
	local runtimeValue6 = os.clock() + 180
	local str, str2 = tostring(runtimeValue4.Name), tostring(runtimeValue4:GetAttribute("ID"))
	local dataTable, runtimeValue7, runtimeValue8 = {}, tonumber(runtimeValue4:GetAttribute("Upgrade")) or 0, nil
	local function utilityRoutine()
		for _, item in ipairs(dataTable) do
			item:Disconnect()
		end
		dataTable = {}
	end
	local function utilityRoutine2()
		utilityRoutine()
		for _, item in ipairs({
			"Upgrade",
			"SellPrice"
		}) do
			local ok2, result2 = pcall(function()
				return runtimeValue4:GetAttributeChangedSignal(item):Connect(function()
					local runtimeValue9 = tonumber(runtimeValue4:GetAttribute("Upgrade")) or 0
					runtimeValue7 = math.max(runtimeValue7, runtimeValue9)
					if item == "Upgrade" then
						runtimeValue8 = runtimeValue9
					end
				end)
			end)
			if ok2 and result2 then
				table.insert(dataTable, result2)
			end
		end
	end
	local function utilityRoutine3(parameter, parameter2)
		utilityRoutine()
		if parameter then
			State.UpgradeWait = nil
		end
		return parameter, parameter2
	end
	utilityRoutine2()
	local runtimeValue10, count, count2, stateFlag, runtimeValue11 = nil, 0, 0, false, nil
	while isPlaying(session) and not isMatchEnded() and os.clock() < runtimeValue6 do
		local runtimeValue12 = towerData:FindFirstChild(str)
		if runtimeValue12 and runtimeValue12 ~= runtimeValue4 and isOwnTower(runtimeValue12) and tostring(runtimeValue12:GetAttribute("ID")) == str2 then
			runtimeValue4 = runtimeValue12
			State.RuntimeHandles[action.Handle] = runtimeValue12
			State.UsedRuntimeTowers[runtimeValue12] = true
			utilityRoutine2()
		end
		if runtimeValue4.Parent ~= towerData then
			return utilityRoutine3(false, "Tower disappeared during upgrade")
		end
		local runtimeValue13 = tonumber(runtimeValue4:GetAttribute("Upgrade")) or 0
		runtimeValue7 = math.max(runtimeValue7, runtimeValue13)
		local runtimeValue14 = runtimeValue7
		if runtimeValue14 >= runtimeValue5 then
			return utilityRoutine3(true)
		end
		local runtimeValue15 = getMoney()
		local runtimeValue16 = tonumber(runtimeValue4:GetAttribute("SellPrice")) or 0
		if runtimeValue10 and runtimeValue14 > runtimeValue10.level then
			runtimeValue10, num = nil, 0
		end
		if runtimeValue10 then
			runtimeValue10.spent = runtimeValue10.spent or runtimeValue16 > runtimeValue10.price
			if runtimeValue15 < runtimeValue10.lastCash then
				runtimeValue10.cashDropAt = os.clock()
			end
			runtimeValue10.lastCash = runtimeValue15
			local runtimeValue18 = not runtimeValue10.cashDropAt or os.clock() - runtimeValue10.cashDropAt >= 1
			if not runtimeValue10.spent and runtimeValue10.cash ~= math.huge and runtimeValue18 and os.clock() - runtimeValue10.at >= 2 and runtimeValue15 >= num then
				runtimeValue10 = nil
			end
		end
		if not runtimeValue10 and runtimeValue15 >= num then
			runtimeValue10 = {
				level = runtimeValue14,
				cash = runtimeValue15,
				lastCash = runtimeValue15,
				price = runtimeValue16,
				at = os.clock(),
				spent = false
			}
			count2 = count2 + 1
			runtimeValue11 = runtimeValue11 or os.clock()
			local ok3, result3 = pcall(Remotes.Upgrade.FireServer, Remotes.Upgrade, tostring(runtimeValue4.Name))
			if not ok3 then
				return utilityRoutine3(false, "Upgrade transport failed: " .. tostring(result3))
			end
		end
		State.UpgradeWait = {
			Handle = action.Handle,
			Level = runtimeValue14,
			TargetLevel = runtimeValue5,
			RuntimeId = tostring(runtimeValue4.Name),
			RawLevel = runtimeValue13,
			EventLevel = runtimeValue8,
			Cash = runtimeValue15,
			RequiredCost = num,
			Attempts = count2,
			Pending = runtimeValue10 ~= nil,
			Spent = runtimeValue10 and runtimeValue10.spent or false,
			PendingAge = runtimeValue10 and os.clock() - runtimeValue10.at or 0,
			CashDropAt = runtimeValue10 and runtimeValue10.cashDropAt or nil
		}
		if runtimeValue10 and not stateFlag and runtimeValue11 and os.clock() - runtimeValue11 >= 4 and type(Hub.ExportDebug) == "function" then
			stateFlag = true
			pcall(Hub.ExportDebug, "Upgrade pending >4s: " .. tostring(action.Handle) .. " / server ID " .. str)
		end
		if os.clock() >= count then
			count = os.clock() + 0.5
			local runtimeValue19 = runtimeValue15 < num and "money " .. formatMoney() .. "/" .. tostring(num) or "level confirmation | sent " .. tostring(count2)
			setStatus("Playback", string.format("Upgrade %s [ID %s] | Lv %d/%d | %s", tostring(action.Handle), tostring(runtimeValue4.Name), runtimeValue14, runtimeValue5, runtimeValue19))
		end
		task.wait(0.03)
	end
	if not isPlaying(session) or isMatchEnded() then
		return utilityRoutine3(false, "Playback cancelled")
	end
	return utilityRoutine3(false, "Upgrade timed out after 180s without confirmed target level")
end
local function isLegacyDuplicateTarget(parameter, parameter2)
	if State.ProfileVersion >= 2 then
		return false
	end
	local runtimeValue4 = State.Actions[parameter - 1]
	if not runtimeValue4 or runtimeValue4.Type ~= "Upgrade" or runtimeValue4.Handle ~= parameter2.Handle then
		return false
	end
	local num = tonumber(parameter2.RecordedAt)
	local num2 = tonumber(runtimeValue4.RecordedAt)
	return num ~= nil and num2 ~= nil and num >= num2 and num - num2 <= 0.5
end
local function playSell(action, session)
	local runtimeValue4 = getRuntimeTower(action.Handle)
	if not runtimeValue4 then
		return true
	end
	for _ = 1, 3 do
		if not isPlaying(session) or runtimeValue4.Parent ~= towerData then
			return true
		end
		Remotes.Sell:FireServer(tostring(runtimeValue4.Name))
		if waitUntil(function()
			return runtimeValue4.Parent ~= towerData
		end, 3, 0.1) then
			return true
		end
		task.wait(1)
	end
	return false, "Sell was not confirmed"
end
local function playTargetMode(action, session)
	local runtimeValue4 = getRuntimeTower(action.Handle)
	if not runtimeValue4 then
		return false, "Tower handle is missing: " .. tostring(action.Handle)
	end
	for _ = 1, 8 do
		if not isPlaying(session) or runtimeValue4.Parent ~= towerData then
			return false, "Tower disappeared"
		end
		if runtimeValue4:GetAttribute("TargetMode") == action.Mode then
			return true
		end
		Remotes.Target:FireServer(tostring(runtimeValue4.Name))
		task.wait(0.25)
	end
	return runtimeValue4:GetAttribute("TargetMode") == action.Mode, "Target mode was not confirmed"
end
local function parseAbilityFailure(parameter, parameter2)
	local dataTable, runtimeValue4 = {}, nil
	for i = 3, parameter.n or # parameter do
		local runtimeValue5 = parameter[i]
		if type(runtimeValue5) == "string" then
			dataTable[# dataTable + 1] = runtimeValue5
		elseif type(runtimeValue5) == "table" then
			for _, item in ipairs({
				"Message",
				"Reason",
				"Error"
			}) do
				if type(runtimeValue5[item]) == "string" then
					dataTable[# dataTable + 1] = runtimeValue5[item]
				end
			end
			local num = tonumber(runtimeValue5.CooldownRemaining or runtimeValue5.RemainingCooldown or runtimeValue5.RetryAfter)
			if num and num >= 0 and num <= 3600 then
				runtimeValue4 = num
			end
		end
	end
	local runtimeValue6 = table.concat(dataTable, " "):sub(1, 200)
	local lowered = runtimeValue6:lower()
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
			return nil, false, runtimeValue6
		end
	end
	local runtimeValue7 = lowered:find("cooldown", 1, true) ~= nil or lowered:find("on cd", 1, true) ~= nil or runtimeValue4 ~= nil
	if not runtimeValue4 and runtimeValue7 then
		runtimeValue4 = tonumber(lowered:match("cooldown[^%d]*(%d+%.?%d*)"))
	end
	if runtimeValue4 and runtimeValue4 >= 0 and runtimeValue4 <= 3600 then
		return math.max(.25, runtimeValue4), true, runtimeValue6
	end
	return math.min(30, 2 ^ math.min(parameter2 - 1, 5)), runtimeValue7, runtimeValue6
end
local function playAbility(action, session)
	local runtimeValue4 = getRuntimeTower(action.Handle)
	if not runtimeValue4 then
		return false, "Tower handle is missing: " .. tostring(action.Handle)
	end
	if not Remotes.Ability or not Remotes.Ability:IsA("RemoteFunction") then
		return false, "spawnTowerAbility is unavailable"
	end
	local str = tostring(action.Marker or "")
	if str == "" and action.CaptureSource ~= "Remote" then
		return false, "Ability has no confirmation marker; record this skill again"
	end
	if isModeMarker(str) and action.ExpectedState ~= nil and runtimeValue4:GetAttribute(str) == action.ExpectedState then
		return true
	end
	if str == "AttackMode" and action.ExpectedState ~= nil and not action.ModeStep then
		if type(action.ExpectedState) ~= "number" or action.ExpectedState < 1 or action.ExpectedState > 3 or action.ExpectedState % 1 ~= 0 then
			return false, "Invalid recorded attack mode"
		end
		local dataTable = {}
		for index, item in pairs(action) do
			dataTable[index] = item
		end
		dataTable.ExpectedState = nil
		dataTable.ModeStep = true
		dataTable.Cooldown = math.max(5, tonumber(dataTable.Cooldown) or 0)
		for _ = 1, 3 do
			if not isPlaying(session) or runtimeValue4.Parent ~= towerData then
				return false, "Mode change cancelled"
			end
			if runtimeValue4:GetAttribute(str) == action.ExpectedState then
				return true
			end
			local value, value1 = playAbility(dataTable, session)
			if not value then
				return false, value1
			end
		end
		return runtimeValue4:GetAttribute(str) == action.ExpectedState, "Recorded attack mode was not reached"
	end
	local runtimeValue5 = tonumber(action.RequiredLevel) or 0
	local num = math.max(0, tonumber(action.Cooldown) or 0)
	local runtimeValue6 = tostring(action.Handle) .. ":" .. str .. ":" .. tostring(action.AbilityIndex or 1)
	local str2 = tostring(action.AbilityName or str)
	State.AbilityLastUsed = State.AbilityLastUsed or {}
	State.AbilityAttempts = State.AbilityAttempts or {}
	local value2, value12 = getGameClock()
	local now = os.clock()
	local count, runtimeValue7, count2 = 0, nil, 0
	local stateFlag = false
	local count3 = 0
	local function utilityRoutine()
		return isPlaying(session) and not isMatchEnded() and runtimeValue4.Parent == towerData
	end
	local function utilityRoutine2()
		local value3, value13 = getGameClock()
		return os.clock() - now >= 900 or value13 == value12 and value3 - value2 >= 600
	end
	while utilityRoutine() and not utilityRoutine2() and count3 < 32 do
		local runtimeValue15 = waitUntil(function()
			if not utilityRoutine() or utilityRoutine2() then
				return true
			end
			local value3, value13 = getGameClock()
			local runtimeValue8 = State.AbilityLastUsed[runtimeValue6]
			local runtimeValue9 = math.huge
			if type(runtimeValue8) == "table" then
				runtimeValue9 = runtimeValue8.Kind == value13 and value3 - runtimeValue8.At or os.clock() - runtimeValue8.RealAt
			elseif type(runtimeValue8) == "number" then
				runtimeValue9 = os.clock() - runtimeValue8
			end
			local runtimeValue10 = runtimeValue7 == value13 and count - value3 or count2 - os.clock()
			local num2 = math.max(0, num - runtimeValue9, runtimeValue10)
			local runtimeValue11 = getMoney() >= (tonumber(action.EstimatedCost) or 0)
			local runtimeValue12 = (tonumber(runtimeValue4:GetAttribute("Upgrade")) or 0) >= runtimeValue5
			local runtimeValue13 = not str:match("^ATTACK") or not isTruthyState(runtimeValue4:GetAttribute(str))
			local runtimeValue14 = num2 > 0 and ((stateFlag or num - runtimeValue9 > 0) and "Cooldown " or "Retry in ") .. math.ceil(num2) .. "s" or not runtimeValue11 and "Waiting for cash" or not runtimeValue12 and "Waiting for upgrade" or not runtimeValue13 and "Waiting for active ability" or "Ready"
			State.AbilityWait = {
				Name = str2,
				Phase = runtimeValue14,
				Attempt = count3,
				Action = State.PlaybackIndex
			}
			setStatus("Playback", string.format("Action %d/%d | %s | %s", State.PlaybackIndex or 1, # State.Actions, str2, runtimeValue14))
			return num2 <= 0 and runtimeValue11 and runtimeValue12 and runtimeValue13
		end, 901, .1)
		if not utilityRoutine() then
			return false, "Ability cancelled or tower disappeared"
		end
		if not runtimeValue15 or utilityRoutine2() then
			break
		end
		if isModeMarker(str) and action.ExpectedState ~= nil and runtimeValue4:GetAttribute(str) == action.ExpectedState then
			State.AbilityWait = nil
			return true
		end
		count3 = count3 + 1
		local runtimeValue16 = runtimeValue4:GetAttribute(str)
		local stateFlag2, runtimeValue18 = false, nil
		local function utilityRoutine3()
			local runtimeValue8 = runtimeValue4:GetAttribute(str)
			if runtimeValue8 == runtimeValue16 then
				return
			end
			if str:match("^ATTACK") and not abilityStateChanged(runtimeValue16, runtimeValue8, true) then
				return
			end
			if str == "AttackMode" and (type(runtimeValue8) ~= "number" or runtimeValue8 < 1 or runtimeValue8 > 3 or runtimeValue8 % 1 ~= 0) then
				return
			end
			if action.ExpectedState ~= nil and runtimeValue8 ~= action.ExpectedState then
				return
			end
			stateFlag2 = true
		end
		local runtimeValue19 = str ~= "" and runtimeValue4:GetAttributeChangedSignal(str):Connect(utilityRoutine3)
		task.spawn(function()
			runtimeValue18 = table.pack(pcall(Remotes.Ability.InvokeServer, Remotes.Ability, tostring(runtimeValue4.Name), tonumber(action.AbilityIndex) or 1))
		end)
		waitUntil(function()
			if runtimeValue18 and runtimeValue18[1] and runtimeValue18[2] == true and action.CaptureSource == "Remote" then
				stateFlag2 = true
			end
			return not utilityRoutine() or stateFlag2 or runtimeValue18 and (not runtimeValue18[1] or runtimeValue18[2] == false)
		end, 12, .03)
		if utilityRoutine() and runtimeValue18 and runtimeValue18[1] and runtimeValue18[2] == false and not stateFlag2 then
			waitUntil(function()
				return not utilityRoutine() or stateFlag2
			end, .25, .05)
		end
		if runtimeValue19 then
			runtimeValue19:Disconnect()
		end
		if not utilityRoutine() then
			return false, "Ability cancelled or tower disappeared"
		end
		if stateFlag2 then
			local value4, value14 = getGameClock()
			State.AbilityLastUsed[runtimeValue6] = {
				At = value4,
				Kind = value14,
				RealAt = os.clock()
			}
			State.AbilityWait = nil
			return true
		end
		if not runtimeValue18 then
			return false, "Ability response unconfirmed; no duplicate retry: " .. str2
		end
		if not runtimeValue18[1] then
			return false, "Ability transport failed: " .. tostring(runtimeValue18[2])
		end
		if runtimeValue18[2] ~= false then
			return false, "Ability unconfirmed; no duplicate retry: " .. str2
		end
		local value5, value15, value22 = parseAbilityFailure(runtimeValue18, count3)
		if not value5 then
			return false, "Ability unavailable: " .. value22
		end
		local value6, value16 = getGameClock()
		count, runtimeValue7, count2 = value6 + value5, value16, os.clock() + value5
		stateFlag = value15
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
	local runtimeValue4 = getRuntimeTower(action.SourceHandle)
	local runtimeValue5 = getRuntimeTower(action.TargetHandle)
	if not runtimeValue4 then
		return false, "Boost source handle is missing: " .. tostring(action.SourceHandle)
	end
	if not runtimeValue5 then
		return false, "Boost target handle is missing: " .. tostring(action.TargetHandle)
	end
	if not Remotes.BoostSelect or not Remotes.BoostSelect:IsA("RemoteEvent") then
		return false, "BoostSelect is unavailable"
	end
	local num = tonumber(runtimeValue4.Name)
	local str = tostring(runtimeValue5.Name)
	if not num then
		return false, "Boost source has an invalid server ID"
	end
	if tostring(runtimeValue5:GetAttribute("ClockBoost")) == tostring(num) then
		return true
	end
	Remotes.BoostSelect:FireServer(num, str)
	local runtimeValue6 = waitUntil(function()
		return not isPlaying(session) or runtimeValue4.Parent ~= towerData or runtimeValue5.Parent ~= towerData or tostring(runtimeValue5:GetAttribute("ClockBoost")) == tostring(num)
	end, 5, 0.05)
	if not isPlaying(session) then
		return false, "Playback stopped while linking boost"
	end
	if runtimeValue4.Parent ~= towerData or runtimeValue5.Parent ~= towerData then
		return false, "Boost tower disappeared"
	end
	return runtimeValue6, runtimeValue6 and nil or "Boost link was not confirmed"
end
function Hub.ExportDebug(parameter)
	local dataTable = {
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
		Reason = parameter or State.LastPlaybackFailure,
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
			if isOwnTower(item) and # dataTable.Towers < 100 then
				local boostPos = item:GetAttribute("BoostPos")
				table.insert(dataTable.Towers, {
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
	local runtimeValue4 = "SkibidiTD_Debug_" .. tostring(os.time()) .. ".json"
	if type(writefile) ~= "function" then
		return nil, "writefile unavailable"
	end
	local ok2, result2 = pcall(function()
		writefile(runtimeValue4, HttpService:JSONEncode(dataTable))
	end)
	return ok2 and runtimeValue4 or nil, ok2 and nil or tostring(result2)
end
local function stopPlayback(reason)
	if reason and (reason:find("failed", 1, true) or reason:find("timed out", 1, true) or reason:find("error", 1, true)) then
		State.LastPlaybackFailure = reason
		pcall(Hub.ExportDebug, reason)
	end
	State.PlaySession = nil
	State.Playing = false
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
	State.PlaySession = {}
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
			now = os.clock()
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
				local runtimeValue4 = waitForActionTime(item, now, playSession)
				if not isPlaying(playSession) then
					return
				end
				if isMatchEnded() then
					stopPlayback("Match ended before the macro finished")
					break
				end
				if not runtimeValue4 then
					stopPlayback(string.format("Action %d timed out waiting for %s | Money %s", index, State.PlaybackMode, formatMoney()))
					return
				end
				local runtimeValue5, runtimeValue6
				if item.Type == "Place" then
					runtimeValue5, runtimeValue6 = playPlace(item, playSession)
				elseif item.Type == "Upgrade" then
					runtimeValue5, runtimeValue6 = playUpgrade(item, playSession)
				elseif item.Type == "Sell" then
					runtimeValue5, runtimeValue6 = playSell(item, playSession)
				elseif item.Type == "Target" then
					if isLegacyDuplicateTarget(index, item) then
						runtimeValue5 = true
					else
						runtimeValue5, runtimeValue6 = playTargetMode(item, playSession)
					end
				elseif item.Type == "Ability" then
					runtimeValue5, runtimeValue6 = playAbility(item, playSession)
				elseif item.Type == "BoostLink" then
					runtimeValue5, runtimeValue6 = playBoostLink(item, playSession)
				else
					runtimeValue5, runtimeValue6 = false, "Unknown action type: " .. tostring(item.Type)
				end
				if not isPlaying(playSession) then
					return
				end
				if not runtimeValue5 then
					stopPlayback(string.format("Action %d failed: %s", index, runtimeValue6 or "unknown error"))
					return
				end
				if index == 1 then
					State.PlaybackFirstActionDone = true
				end
			end
			if isPlaying(playSession) then
				State.Playing = false
				updateActionSummary()
				setStatus("Playback complete", "Waiting for the match to end")
			end
		end, function(parameter)
			return tostring(parameter)
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
local function modifierLabel(parameter)
	local runtimeValue4 = modifierLabelOverrides[parameter]
	if runtimeValue4 then
		return runtimeValue4
	end
	return parameter:gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2"):gsub("(%d)(%a)", "%1 %2")
end
for _, item6 in ipairs(modifierList) do
	modifierSet[item6] = true
	local runtimeValue20 = modifierLabel(item6)
	modifierByLabel[runtimeValue20] = item6
	labelByModifier[item6] = runtimeValue20
	table.insert(modifierLabels, runtimeValue20)
end
local function normalizeModifiers(parameter)
	local dataTable = {}
	if type(parameter) ~= "table" then
		return dataTable
	end
	for index, item in pairs(parameter) do
		local runtimeValue4
		if type(index) == "string" and item == true then
			runtimeValue4 = index
		elseif type(index) == "number" and type(item) == "string" then
			runtimeValue4 = item
		end
		local runtimeValue5 = runtimeValue4 and (modifierByLabel[runtimeValue4] or runtimeValue4)
		if runtimeValue5 and modifierSet[runtimeValue5] then
			dataTable[runtimeValue5] = true
		end
	end
	return dataTable
end
State.LobbyModifiers = normalizeModifiers(State.LobbyModifiers)
local function modifiersToLabels(parameter)
	local dataTable = {}
	for _, item in ipairs(modifierList) do
		if parameter[item] == true then
			table.insert(dataTable, labelByModifier[item])
		end
	end
	return dataTable
end
local function applyLobbyModifiers()
	local dataTable = {}
	for _, item in ipairs(modifierList) do
		if State.LobbyModifiers[item] == true then
			table.insert(dataTable, item)
		end
	end
	if # dataTable == 0 then
		return true
	end
	refreshRemotes()
	if not Remotes.ModifierState or not Remotes.ModifierState:IsA("RemoteEvent") then
		return false, "ReplicatedStorage.ModifierState was not found"
	end
	setStatus("Auto Join", string.format("Applying %d modifier(s)", # dataTable))
	for _, item3 in ipairs(dataTable) do
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
	local runtimeValue4 = getPlayerGui()
	for _, item in ipairs({
		"Main",
		"Frame",
		"Layout",
		"Servers",
		"List"
	}) do
		runtimeValue4 = runtimeValue4 and runtimeValue4:FindFirstChild(item)
	end
	if not runtimeValue4 then
		return
	end
	local dataTable = {
		Story = "Story",
		Multiverse = "Multiverse",
		Event = "Nightmare",
		Event2 = "Event",
		Endless = "Endless",
		Versus = "Versus",
		Episodes = "Episodes"
	}
	for index, item3 in pairs(dataTable) do
		local runtimeValue5, dataTable2 = runtimeValue4:FindFirstChild(index), {}
		if runtimeValue5 then
			for _, item4 in ipairs(runtimeValue5:GetChildren()) do
				if item4.Name == "Chapter" then
					local init = item4:FindFirstChild("Init")
					local runtimeValue6 = init and init:FindFirstChild("TXT")
					local runtimeValue7 = runtimeValue6 and runtimeValue6:FindFirstChild("CH")
					local runtimeValue8 = runtimeValue7 and tostring(runtimeValue7.Text) or ""
					if runtimeValue8 ~= "" and not table.find(dataTable2, runtimeValue8) then
						table.insert(dataTable2, runtimeValue8)
					end
				end
			end
		end
		if # dataTable2 > 0 then
			chaptersByMode[item3] = dataTable2
		end
	end
end
local function getChapters(parameter)
	scanChapters()
	if parameter ~= "All" then
		return table.clone(chaptersByMode[parameter] or {})
	end
	local dataTable = {}
	for _, item in pairs(chaptersByMode) do
		for _, item3 in ipairs(item) do
			if not table.find(dataTable, item3) then
				table.insert(dataTable, item3)
			end
		end
	end
	local servers = ReplicatedStorage:FindFirstChild("Servers")
	if servers then
		for _, item4 in ipairs(servers:GetChildren()) do
			if not table.find(dataTable, item4.Name) then
				table.insert(dataTable, item4.Name)
			end
		end
	end
	table.sort(dataTable)
	return dataTable
end
-- Webhook and match reports
local Reports = {}
Hub.Reports = Reports
function Reports.ValidURL(parameter)
	return type(parameter) == "string"
		and (parameter:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+$") ~= nil
			or parameter:match("^https://discordapp%.com/api/webhooks/%d+/[%w_%-]+$") ~= nil)
end
function Reports.Escape(parameter)
	return tostring(parameter or ""):gsub("([\\`*_~|<>])", "\\%1"):sub(1, 900)
end
function Reports.Post(parameter, parameter2)
	if not Reports.ValidURL(parameter) then
		return false, "Enter a valid webhook URL"
	end
	local runtimeValue4 = http_request or request or syn and syn.request or fluxus and fluxus.request
	if type(runtimeValue4) ~= "function" then
		return false, "Executor HTTP unavailable"
	end
	local dataTable = {
		username = "Skibidi Defense Hub",
		allowed_mentions = {
			parse = {}
		},
		embeds = {
			parameter2
		}
	}
	local ok2, result2 = pcall(function()
		return runtimeValue4({
			Url = parameter,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode(dataTable)
		})
	end)
	if not ok2 then
		return false, "HTTP request failed"
	end
	local runtimeValue5 = type(result2) == "table" and tonumber(result2.StatusCode or result2.Status)
	return runtimeValue5 ~= nil and runtimeValue5 >= 200 and runtimeValue5 < 300, runtimeValue5 and "HTTP " .. runtimeValue5 or "HTTP result unconfirmed"
end
function Reports.FormatTime(parameter)
	parameter = tonumber(parameter)
	if not parameter then
		return "Unavailable"
	end
	parameter = math.floor(math.max(0, parameter))
	return string.format("%02d:%02d", math.floor(parameter / 60), parameter % 60)
end
function Reports.Lines(parameter)
	local dataTable = {}
	for index in pairs(parameter) do
		dataTable[# dataTable + 1] = index
	end
	table.sort(dataTable)
	local dataTable2 = {}
	for _, item in ipairs(dataTable) do
		dataTable2[# dataTable2 + 1] = "\226\128\162 " .. Reports.Escape(item) .. ": +" .. tostring(parameter[item])
	end
	return # dataTable2 > 0 and table.concat(dataTable2, "\n"):sub(1, 1000) or "No reward reported"
end
function Reports.ParseRewards(parameter)
	local dataTable = {}
	for item0, item1 in tostring(parameter or ""):gmatch("%+%s*([%d,]+)%s+([^!\n;]+)") do
		local runtimeValue4 = item0:gsub(",", "")
		local num = tonumber(runtimeValue4)
		item1 = item1:gsub("^%s+", ""):gsub("%s+$", "")
		if num and item1 ~= "" then
			dataTable[item1] = (dataTable[item1] or 0) + num
		end
	end
	return dataTable
end
function Reports.Visible(parameter)
	while parameter do
		if parameter:IsA("GuiObject") and not parameter.Visible then
			return false
		end
		if parameter:IsA("ScreenGui") and not parameter.Enabled then
			return false
		end
		parameter = parameter.Parent
	end
	return true
end
function Reports.MatchRewards()
	local runtimeValue4 = getGameEndedGui()
	local dataTable, dataTable2 = {}, {}
	if runtimeValue4 then
		for _, item in ipairs(runtimeValue4:GetDescendants()) do
			if (item:IsA("TextLabel") or item:IsA("TextButton")) and Reports.Visible(item) then
				local runtimeValue5 = tostring(item.Text or ""):gsub("<[^>]->", "")
				local lowered = runtimeValue5:lower()
				local runtimeValue6 = next(Reports.ParseRewards(runtimeValue5)) ~= nil
				local runtimeValue7 = item
				while runtimeValue7 and runtimeValue7 ~= runtimeValue4 do
					if runtimeValue7.Name:lower():find("reward", 1, true) then
						runtimeValue6 = true
						break
					end
					runtimeValue7 = runtimeValue7.Parent
				end
				if runtimeValue6 and runtimeValue5 ~= "" and not dataTable2[runtimeValue5] and # dataTable < 12 then
					dataTable2[runtimeValue5] = true
					dataTable[# dataTable + 1] = Reports.Escape(runtimeValue5)
				elseif lowered:find("reward", 1, true) and # runtimeValue5 > 12 and not dataTable2[runtimeValue5] and # dataTable < 12 then
					dataTable2[runtimeValue5] = true
					dataTable[# dataTable + 1] = Reports.Escape(runtimeValue5)
				end
			end
		end
	end
	return # dataTable > 0 and table.concat(dataTable, "\n"):sub(1, 1000) or "Unavailable"
end
function Reports.AccountTotals()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local dataTable = {}
	if leaderstats then
		for _, item in ipairs(leaderstats:GetChildren()) do
			local lowered = item.Name:lower()
			if lowered == "crystals" or lowered == "jacks" or lowered == "credits" or lowered == "gems" or lowered == "candy" or lowered == "coins" then
				local ok2, result2 = pcall(function()
					return item.Value
				end)
				if ok2 then
					dataTable[# dataTable + 1] = "\226\128\162 " .. Reports.Escape(item.Name) .. ": " .. Reports.Escape(result2)
				end
			end
		end
	end
	return # dataTable > 0 and table.concat(dataTable, "\n"):sub(1, 1000) or "Unavailable"
end
function Reports.BuildMatch()
	local runtimeValue4 = getMatchResult()
	local runtimeValue5 = State.ReportStartedAt and (State.ReportEndedAt or os.clock()) - State.ReportStartedAt
	return {
		title = "Skibidi Defense Match Report",
		description = "**Stage:** " .. Reports.Escape(State.LobbyChapter) .. "\n**Mode:** " .. Reports.Escape(State.LobbyMode) .. "\n**Result:** " .. Reports.Escape(runtimeValue4),
		color = runtimeValue4 == "Victory" and 65280 or runtimeValue4 == "Defeat" and 16711680 or 16776960,
		fields = {
			{
				name = "Player Info",
				value = "\240\159\145\164 Name: ||" .. Reports.Escape(LocalPlayer.Name) .. "||\n\240\159\140\138 Waves: " .. getWave() .. "\n\226\157\164\239\184\143 Base HP: " .. Reports.Escape(getBaseHealthText()),
				inline = true
			},
			{
				name = "Clear Time",
				value = "\226\143\177\239\184\143 " .. Reports.FormatTime(runtimeValue5),
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
sendWebhookMessage = function(parameter, parameter2, parameter3)
	if not State.WebhookEnabled then
		return false, "Webhook is disabled"
	end
	return Reports.Post(State.WebhookURL, {
		title = parameter,
		description = parameter2,
		color = parameter3 or 5793266,
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
function MatchFlow.Path(parameter, parameter2)
	for item0 in parameter2:gmatch("[^/]+") do
		parameter = parameter and parameter:FindFirstChild(item0)
	end
	return parameter
end
function MatchFlow.Visible(parameter)
	if not parameter or not parameter.Parent then
		return false
	end
	while parameter do
		if parameter:IsA("GuiObject") and not parameter.Visible then
			return false
		end
		if parameter:IsA("ScreenGui") and not parameter.Enabled then
			return false
		end
		parameter = parameter.Parent
	end
	return true
end
function MatchFlow.Click(parameter)
	if not parameter or not parameter:IsA("GuiButton") or not MatchFlow.Visible(parameter) or parameter.Active == false then
		return false, "Game button unavailable"
	end
	if type(getconnections) == "function" then
		for _, item in ipairs({
			"Activated",
			"MouseButton1Click"
		}) do
			local ok2, result2 = pcall(function()
				return getconnections(parameter[item])
			end)
			if ok2 and type(result2) == "table" then
				local stateFlag = false
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
						stateFlag = stateFlag or ok3
					end
				end
				if stateFlag then
					return true
				end
			end
		end
	end
	local ok4 = pcall(function()
		local absolutePosition, absoluteSize = parameter.AbsolutePosition, parameter.AbsoluteSize
		if absoluteSize.X <= 0 or absoluteSize.Y <= 0 then
			error("Button has no screen bounds")
		end
		local runtimeValue4, runtimeValue5 = absolutePosition.X + absoluteSize.X / 2, absolutePosition.Y + absoluteSize.Y / 2
		local runtimeValue6 = parameter:FindFirstAncestorWhichIsA("ScreenGui")
		if runtimeValue6 and not runtimeValue6.IgnoreGuiInset then
			local runtimeValue7 = game:GetService("GuiService"):GetGuiInset()
			runtimeValue4 = runtimeValue4 + runtimeValue7.X
			runtimeValue5 = runtimeValue5 + runtimeValue7.Y
		end
		local virtualInputManager = game:GetService("VirtualInputManager")
		virtualInputManager:SendMouseButtonEvent(runtimeValue4, runtimeValue5, 0, true, game, 0)
		virtualInputManager:SendMouseButtonEvent(runtimeValue4, runtimeValue5, 0, false, game, 0)
	end)
	return ok4, ok4 and nil or "Executor cannot activate the game button"
end
function MatchFlow.ClickResult(parameter)
	if not isMatchEnded() then
		return false, "Waiting for result screen"
	end
	return MatchFlow.Click(MatchFlow.Path(getGameEndedGui(), "Frame/" .. parameter))
end
function MatchFlow.ValidateLoadout(parameter)
	if type(parameter) ~= "table" or type(parameter.Towers) ~= "table" or # parameter.Towers < 1 or # parameter.Towers > 12 then
		return nil
	end
	local dataTable = {}
	for _, item in ipairs(parameter.Towers) do
		if type(item) ~= "string" or # item == 0 or # item > 100 then
			return nil
		end
		dataTable[# dataTable + 1] = item
	end
	return {
		Index = tonumber(parameter.Index),
		Name = tostring(parameter.Name or "Preset"):sub(1, 100),
		Chapter = tostring(parameter.Chapter or ""):sub(1, 100),
		Towers = dataTable
	}
end
function MatchFlow.SameTowers(parameter, parameter2)
	if type(parameter) ~= "table" or type(parameter2) ~= "table" or # parameter ~= # parameter2 or # parameter == 0 then
		return false
	end
	for index, item in ipairs(parameter) do
		if item ~= parameter2[index] then
			return false
		end
	end
	return true
end
function MatchFlow.ReadCards()
	local runtimeValue4 = MatchFlow.Path(getPlayerGui(), "EasyLoadout/Root/Cards")
	local dataTable = {}
	if runtimeValue4 then
		for i = 1, 4 do
			local runtimeValue5 = runtimeValue4:FindFirstChild("Card" .. i)
			local runtimeValue6 = runtimeValue5 and runtimeValue5:FindFirstChild("List")
			local runtimeValue7 = MatchFlow.Path(runtimeValue5, "Banner/Title")
			local dataTable2 = {}
			if runtimeValue6 then
				for i2 = 1, 12 do
					local runtimeValue8 = MatchFlow.Path(runtimeValue6, "Row" .. i2 .. "/Name")
					if not runtimeValue8 then
						break
					end
					dataTable2[# dataTable2 + 1] = runtimeValue8.Text
				end
			end
			if # dataTable2 > 0 then
				dataTable[i] = {
					Name = runtimeValue7 and runtimeValue7.Text or "Preset " .. i,
					Towers = dataTable2
				}
			end
		end
	end
	return dataTable, runtimeValue4
end
function MatchFlow.PickerOpen()
	local runtimeValue4 = MatchFlow.Path(getPlayerGui(), "EasyLoadout/Root")
	local runtimeValue5 = MatchFlow.Path(runtimeValue4, "Header/Title")
	return MatchFlow.Visible(runtimeValue4) and not (runtimeValue5 and tostring(runtimeValue5.Text):upper():find("LOCKED", 1, true))
end
function MatchFlow.OnShow(parameter)
	if type(parameter) ~= "table" or type(parameter.Presets) ~= "table" then
		return
	end
	MatchFlow.Presets = parameter.Presets
	MatchFlow.Chapter = parameter.Chapter
	MatchFlow.Applied = nil
	MatchFlow.Requested = nil
	MatchFlow.ChoiceEpoch = {}
	MatchFlow.HydrateAfter = os.clock() + 0.5
end
function MatchFlow.HydrateApplied()
	if MatchFlow.Applied or os.clock() < (MatchFlow.HydrateAfter or 0) then
		return
	end
	local runtimeValue4 = MatchFlow.Path(getPlayerGui(), "EasyLoadout/Root/Header/Title")
	if not runtimeValue4 or not tostring(runtimeValue4.Text):upper():find("LOCKED IN", 1, true) then
		return
	end
	local value, value1 = MatchFlow.ReadCards()
	local runtimeValue5
	for index, item in pairs(value) do
		local runtimeValue6 = MatchFlow.Path(value1, "Card" .. index .. "/Picked")
		local runtimeValue7 = runtimeValue6 and runtimeValue6:FindFirstChild("Label")
		if runtimeValue6 and runtimeValue6.Visible and runtimeValue7 and tostring(runtimeValue7.Text):upper():find("LOCKED IN", 1, true) then
			if runtimeValue5 then
				return
			end
			runtimeValue5 = {
				Index = index,
				Name = item.Name,
				Chapter = MatchFlow.Chapter,
				Towers = item.Towers
			}
		end
	end
	MatchFlow.Applied = MatchFlow.ValidateLoadout(runtimeValue5)
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
	local runtimeValue4 = State.MacroLoadout and State.MacroLoadout.Name or "Not recorded"
	if UI.LoadoutStatus and MatchFlow.LoadoutText ~= runtimeValue4 then
		MatchFlow.LoadoutText = runtimeValue4
		UI.LoadoutStatus:SetDesc(runtimeValue4)
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
	local runtimeValue4 = MatchFlow.ValidateLoadout(MatchFlow.Applied)
	if not runtimeValue4 then
		return false, "Choose a preset in the game first"
	end
	local macroLoadout = State.MacroLoadout
	State.MacroLoadout = runtimeValue4
	local ok2, result2, result22 = pcall(saveProfile, State.ProfileName)
	if not ok2 or not result2 then
		State.MacroLoadout = macroLoadout
		return false, tostring(ok2 and result22 or result2)
	end
	MatchFlow.UpdateLoadoutStatus()
	return true, runtimeValue4.Name
end
function MatchFlow.OnApplied(parameter)
	local presets = MatchFlow.Presets
	if not next(presets) then
		presets = MatchFlow.ReadCards()
	end
	for index, item in pairs(presets) do
		if MatchFlow.SameTowers(parameter, item.Towers) then
			MatchFlow.Applied = MatchFlow.ValidateLoadout({
				Index = index,
				Name = item.Name,
				Chapter = MatchFlow.Chapter,
				Towers = parameter
			})
			MatchFlow.RecordLoadout()
			return
		end
	end
end
function MatchFlow.Bind()
	local easyLoadout = ReplicatedStorage:FindFirstChild("EasyLoadout")
	local function utilityRoutine(parameter, parameter2)
		if parameter and not MatchFlow.Bound[parameter] then
			MatchFlow.Bound[parameter] = true
			trackConnection(State.Connections, parameter.OnClientEvent:Connect(function(...)
				if State.Running then
					parameter2(...)
				end
			end))
		end
	end
	utilityRoutine(easyLoadout and easyLoadout:FindFirstChild("Show"), MatchFlow.OnShow)
	utilityRoutine(easyLoadout and easyLoadout:FindFirstChild("Applied"), MatchFlow.OnApplied)
end
function MatchFlow.PreparePlayback(parameter)
	local runtimeValue4 = MatchFlow.ValidateLoadout(State.MacroLoadout)
	if not runtimeValue4 then
		return true
	end
	local runtimeValue5 = os.clock() + 70
	while isPlaying(parameter) and not isMatchEnded() and os.clock() < runtimeValue5 do
		MatchFlow.Bind()
		MatchFlow.HydrateApplied()
		if MatchFlow.Applied then
			return MatchFlow.SameTowers(runtimeValue4.Towers, MatchFlow.Applied.Towers), "A different preset is already applied"
		end
		local value, value1 = MatchFlow.ReadCards()
		if next(MatchFlow.Presets) then
			value = MatchFlow.Presets
		end
		if MatchFlow.PickerOpen() then
			local runtimeValue6
			for index, item in pairs(value) do
				if MatchFlow.SameTowers(runtimeValue4.Towers, item.Towers) then
					runtimeValue6 = index
					break
				end
			end
			if not runtimeValue6 and next(value) then
				return false, "Recorded loadout is unavailable in this map"
			end
			local runtimeValue7 = MatchFlow.ChoiceEpoch or value1
			if runtimeValue6 and value1 and MatchFlow.Requested ~= runtimeValue7 then
				local runtimeValue8 = value1:FindFirstChild("Card" .. runtimeValue6)
				local value2, value12 = MatchFlow.Click(runtimeValue8 and (runtimeValue8:FindFirstChild("Select") or runtimeValue8))
				if value2 then
					MatchFlow.Requested = runtimeValue7
				else
					setStatus("Playback", "Waiting for loadout button | " .. tostring(value12))
				end
			end
			setStatus("Playback", "Waiting for confirmed loadout: " .. runtimeValue4.Name)
		elseif getWave() > 0 and not MatchFlow.Requested then
			return false, "Cannot confirm recorded loadout; choose it before starting the match"
		elseif MatchFlow.Requested then
			setStatus("Playback", "Waiting for confirmed loadout: " .. runtimeValue4.Name)
		else
			setStatus("Playback", "Waiting for preset loadout selection")
		end
		task.wait(0.2)
	end
	return false, isPlaying(parameter) and "Loadout selection timed out" or "Playback stopped"
end
function MatchFlow.SkipCutscenes()
	if not State.AutoSkipCutscene then
		return
	end
	local runtimeValue4 = getPlayerGui()
	if not runtimeValue4 then
		return
	end
	local dataTable = {}
	for _, item in ipairs(runtimeValue4:GetChildren()) do
		local lowered = item.Name:lower()
		if lowered:find("intro", 1, true) or lowered:find("cutscene", 1, true) then
			for _, item3 in ipairs(item:GetDescendants()) do
				dataTable[# dataTable + 1] = item3
			end
		end
	end
	for _, item4 in ipairs(dataTable) do
		if item4:IsA("TextButton") then
			local uppered = tostring(item4.Text or ""):upper()
			if uppered:find("SKIP CUTSCENE", 1, true) or MatchFlow.Cutscene[item4] then
				local runtimeValue5 = MatchFlow.Visible(item4)
				local runtimeValue6 = MatchFlow.Cutscene[item4] or {}
				MatchFlow.Cutscene[item4] = runtimeValue6
				if not runtimeValue5 then
					runtimeValue6.Visible = false
				elseif uppered:find("VOTED", 1, true) then
					runtimeValue6.Sent = true
					runtimeValue6.Visible = true
				else
					if not runtimeValue6.Visible then
						runtimeValue6.Sent = false
					end
					runtimeValue6.Visible = true
					if not runtimeValue6.Sent and os.clock() >= (runtimeValue6.NextAt or 0) then
						runtimeValue6.NextAt = os.clock() + 1
						runtimeValue6.Sent = MatchFlow.Click(item4) == true
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
function MatchFlow.EndStep(parameter)
	if not parameter then
		if MatchFlow.End and MatchFlow.End.ChoiceEpoch == MatchFlow.ChoiceEpoch then
			MatchFlow.Applied = nil
			MatchFlow.Requested = nil
			MatchFlow.ChoiceEpoch = nil
		end
		MatchFlow.End = nil
		return
	end
	local runtimeValue4 = State.PendingLobbyReturn and "Return Lobby" or State.AfterMatch
	if runtimeValue4 ~= "Replay" and runtimeValue4 ~= "Return Lobby" then
		return
	end
	local now = os.clock()
	local runtimeValue5 = MatchFlow.End
	if not runtimeValue5 or runtimeValue5.Action ~= runtimeValue4 then
		runtimeValue5 = {
			Action = runtimeValue4,
			NextAt = now + 0.5,
			ChoiceEpoch = MatchFlow.ChoiceEpoch
		}
		MatchFlow.End = runtimeValue5
	end
	if runtimeValue5.Sent then
		if runtimeValue4 == "Return Lobby" and not runtimeValue5.Fallback and now - runtimeValue5.Sent >= 12 then
			runtimeValue5.Fallback = true
			if UI.SaveConfigNow then
				pcall(UI.SaveConfigNow)
			end
			if Hub.QueueTeleport then
				pcall(Hub.QueueTeleport)
			end
			local ok2 = pcall(function()
				TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
			end)
			setStatus("Match end", ok2 and "Lobby teleport requested" or "Lobby teleport failed")
		end
		return
	end
	if now < runtimeValue5.NextAt then
		return
	end
	runtimeValue5.NextAt = now + 1
	if UI.SaveConfigNow then
		pcall(UI.SaveConfigNow)
	end
	if Hub.QueueTeleport then
		pcall(Hub.QueueTeleport)
	end
	local value, value1 = MatchFlow.ClickResult(runtimeValue4 == "Replay" and "replay" or "back")
	if value then
		runtimeValue5.Sent = now
		setStatus("Match end", runtimeValue4 == "Replay" and "Replay vote sent; waiting for game" or "Returning to lobby")
	else
		setStatus("Match end", tostring(value1))
		if runtimeValue4 == "Return Lobby" then
			runtimeValue5.Sent = now - 12
		end
	end
end
MatchFlow.Bind()
-- Game speed and wave controls
Hub.SpeedControl = {}
do
	local speedControl = Hub.SpeedControl
	local function utilityRoutine6(parameter)
		parameter = tonumber(parameter)
		return parameter and parameter == parameter and parameter >= 1 and parameter < math.huge and parameter or nil
	end
	function speedControl.Reset()
		speedControl.Pending, speedControl.NextAt, speedControl.Signature = nil, 0, nil
	end
	function speedControl.Read()
		local game2 = ReplicatedStorage:FindFirstChild("Game")
		local runtimeValue4 = game2 and game2:FindFirstChild("Speed")
		if runtimeValue4 then
			local ok2, result2 = pcall(function()
				return tonumber(runtimeValue4.Value)
			end)
			if ok2 and result2 and result2 >= 0 and result2 < math.huge then
				return result2
			end
		end
		return getSpeedMultiplier()
	end
	function speedControl.Limit()
		local game2 = ReplicatedStorage:FindFirstChild("Game")
		local runtimeValue4 = game2 and game2:FindFirstChild("Speed")
		local runtimeValue5 = getPlayerGui()
		local runtimeValue6 = runtimeValue5 and runtimeValue5:FindFirstChild("Towers")
		local runtimeValue7 = runtimeValue6 and runtimeValue6:FindFirstChild("speedButton")
		local function utilityRoutine(parameter, parameter2)
			if not parameter then
				return nil
			end
			for _, item in ipairs(parameter2) do
				local ok2, result2 = pcall(parameter.GetAttribute, parameter, item)
				if ok2 and utilityRoutine6(result2) then
					return utilityRoutine6(result2)
				end
				local runtimeValue8 = parameter:FindFirstChild(item)
				if runtimeValue8 then
					ok2, result2 = pcall(function()
						return runtimeValue8.Value
					end)
					if ok2 and utilityRoutine6(result2) then
						return utilityRoutine6(result2)
					end
				end
			end
		end
		local dataTable = {
			"MaxSpeed",
			"SpeedLimit",
			"MaximumSpeed",
			"MaxGameSpeed"
		}
		local runtimeValue9 = utilityRoutine(runtimeValue4, {
			"MaxSpeed",
			"SpeedLimit",
			"MaximumSpeed",
			"MaxGameSpeed",
			"Max",
			"Limit"
		}) or utilityRoutine(game2, dataTable) or utilityRoutine(runtimeValue7, dataTable)
		local runtimeValue10 = runtimeValue7 and runtimeValue7:FindFirstChild("ClockText")
		local runtimeValue11 = tostring(runtimeValue9) .. "/" .. tostring(runtimeValue10 and runtimeValue10.Visible) .. "/" .. tostring(runtimeValue10 and runtimeValue10.Text)
		return runtimeValue9, runtimeValue11
	end
	function speedControl.Step(parameter)
		local runtimeValue4 = speedControl.Read()
		local value, value1 = speedControl.Limit()
		local runtimeValue5 = State.AutoMaxSpeed and "max" or "selected"
		value1 = runtimeValue5 .. "/" .. value1 .. "/" .. tostring(State.Speed)
		if value1 ~= speedControl.Signature then
			speedControl.Signature, speedControl.Pending, speedControl.NextAt = value1, nil, parameter
		end
		local pending = speedControl.Pending
		if pending then
			if runtimeValue4 and runtimeValue4 ~= pending.Before then
				speedControl.Pending, speedControl.NextAt = nil, parameter
			elseif parameter - pending.At < .8 then
				return
			else
				speedControl.Pending, speedControl.NextAt = nil, parameter + 1
				return
			end
		end
		if parameter < (speedControl.NextAt or 0) or not Remotes.Speed then
			return
		end
		local runtimeValue6
		if State.AutoMaxSpeed then
			runtimeValue6 = value or (runtimeValue4 and runtimeValue4 >= 1 and runtimeValue4 + 1 or 1)
		else
			runtimeValue6 = math.clamp(tonumber(State.Speed) or 1, 1, 6)
		end
		if runtimeValue4 == runtimeValue6 then
			return
		end
		local ok2 = pcall(function()
			Remotes.Speed:FireServer(runtimeValue6)
		end)
		speedControl.NextAt = parameter + (ok2 and .1 or 1)
		if ok2 then
			speedControl.Pending = {
				Before = runtimeValue4,
				Target = runtimeValue6,
				At = parameter
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
	local runtimeValue4 = nil
	local stateFlag = false
	local count3 = 0
	local stateFlag2 = false
	local stateFlag3 = false
	local stateFlag4 = false
	local runtimeValue5 = - math.huge
	while State.Running do
		local now = os.clock()
		if now - count3 >= 1 then
			count3 = now
			refreshRemotes()
		end
		if now - runtimeValue5 >= 0.5 then
			runtimeValue5 = now
			Hub.MatchFlow.Bind()
			Hub.MatchFlow.SkipCutscenes()
			Hub.MatchFlow.UpdateLoadoutStatus()
		end
		local runtimeValue6 = isMatchEnded()
		Hub.MatchFlow.UpdateRecorderClock()
		local runtimeValue7 = towerData ~= nil and towerModels ~= nil and Remotes.Place ~= nil
		local runtimeValue8 = State.PlaybackEnabled and State.ProfileName ~= ""
		local runtimeValue9 = not runtimeValue8 or # State.Actions > 0
		local runtimeValue10 = runtimeValue9 and (not runtimeValue8 or State.PlaybackFirstActionArmed)
		if runtimeValue7 and not runtimeValue6 and getWave() > 0 then
			State.LiveRoundStarted = true
			if stateFlag4 or not State.ReportStartedAt then
				State.ReportStartedAt = now
				State.ReportEndedAt = nil
			end
		elseif runtimeValue6 and State.ReportStartedAt and not State.ReportEndedAt then
			State.ReportEndedAt = now
		end
		if not runtimeValue7 or runtimeValue6 then
			State.AutoPlaybackStarted = false
			State.PlaybackFirstActionArmed = false
			State.PlaybackFirstActionDone = false
			stateFlag2 = false
			runtimeValue4 = nil
			stateFlag = false
			Hub.SpeedControl.Reset()
			stateFlag3 = false
		elseif not stateFlag2 then
			stateFlag2 = true
			runtimeValue4 = nil
			stateFlag = false
			Hub.SpeedControl.Reset()
			stateFlag3 = false
		elseif State.PlaybackEnabled and not State.AutoPlaybackStarted and not State.Playing and not State.Recording and # State.Actions > 0 and UI.StartEnabledPlayback then
			UI.StartEnabledPlayback()
		end
		if State.AutoReady and not runtimeValue6 and Remotes.Ready and not Hub.MatchFlow.PickerOpen() and now - count >= (State.ReadyDelay or 1) then
			count = now
			pcall(function()
				Remotes.Ready:FireServer(true)
			end)
		end
		if runtimeValue7 and runtimeValue9 and not runtimeValue10 and (State.AutoSpeed or State.AutoMaxSpeed or State.AutoSkip) and Remotes.Speed and not stateFlag3 then
			stateFlag3 = true
			pcall(function()
				Remotes.Speed:FireServer(1)
			end)
		end
		local runtimeValue11 = getPlayerGui()
		local runtimeValue12 = runtimeValue11 and runtimeValue11:FindFirstChild("skipWave")
		local runtimeValue13 = runtimeValue12 and runtimeValue12.Enabled == true
		if State.AutoSkip and runtimeValue10 and not runtimeValue6 and Remotes.Skip and runtimeValue13 and shouldAutoSkip(getWave(), State.StopAutoSkipAt) and now - count2 >= (State.SkipDelay or 0.35) then
			count2 = now
			pcall(function()
				Remotes.Skip:FireServer(true)
			end)
		end
		local runtimeValue14 = (State.AutoSpeed or State.AutoMaxSpeed) and runtimeValue10 and runtimeValue7 and Remotes.Speed and not runtimeValue6
		if State.SpeedConfigLoaded and runtimeValue7 and runtimeValue10 and not runtimeValue6 then
			runtimeValue4 = runtimeValue4 or now
			if now - runtimeValue4 >= math.clamp(tonumber(State.SpeedScaleDelay) or 1, 1, 30) then
				stateFlag = true
			end
		elseif not stateFlag then
			runtimeValue4 = nil
		end
		if runtimeValue14 and stateFlag then
			Hub.SpeedControl.Step(now)
		end
		if runtimeValue6 and not stateFlag4 then
			stateFlag4 = true
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
		elseif not runtimeValue6 then
			stateFlag4 = false
		end
		Hub.MatchFlow.EndStep(runtimeValue6)
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
function Hub.SetFPSBoost(parameter)
	Utilities.FPSGeneration = (Utilities.FPSGeneration or 0) + 1
	Utilities.FPSEnabled = parameter == true
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
function Utilities.FPSSet(parameter, parameter2, parameter3)
	local ok2, result2 = pcall(function()
		return parameter[parameter2]
	end)
	if not ok2 then
		return
	end
	local runtimeValue4 = Utilities.FPSOriginal[parameter]
	if not runtimeValue4 then
		runtimeValue4 = {}
		Utilities.FPSOriginal[parameter] = runtimeValue4
	end
	if runtimeValue4[parameter2] == nil then
		runtimeValue4[parameter2] = result2
	end
	pcall(function()
		parameter[parameter2] = parameter3
	end)
end
function Utilities.ApplyFPS(parameter)
	if parameter:IsA("ParticleEmitter") or parameter:IsA("Trail") or parameter:IsA("Beam") or parameter:IsA("Smoke") or parameter:IsA("Fire") or parameter:IsA("Sparkles") or parameter:IsA("PostEffect") then
		Utilities.FPSSet(parameter, "Enabled", false)
	elseif parameter:IsA("BasePart") then
		Utilities.FPSSet(parameter, "CastShadow", false)
		Utilities.FPSSet(parameter, "Material", Enum.Material.SmoothPlastic)
	elseif parameter:IsA("Decal") or parameter:IsA("Texture") then
		Utilities.FPSSet(parameter, "Transparency", 1)
	end
end
function Utilities.QueueFPS(parameter)
	if not State.Running or not Utilities.FPSEnabled then
		return
	end
	if Utilities.FPSQueue then
		table.insert(Utilities.FPSQueue, parameter)
		return
	end
	local dataTable = {
		parameter
	}
	Utilities.FPSQueue = dataTable
	task.defer(function()
		local count, now = 1, os.clock()
		while State.Running and Utilities.FPSEnabled and Utilities.FPSQueue == dataTable and count <= # dataTable do
			local runtimeValue4 = dataTable[count]
			if runtimeValue4.Parent then
				pcall(Utilities.ApplyFPS, runtimeValue4)
			end
			count = count + 1
			if count % 16 == 0 and os.clock() - now >= 0.002 then
				task.wait()
				now = os.clock()
			end
		end
		if Utilities.FPSQueue == dataTable then
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
function Utilities.IsOwnName(parameter)
	local matched2 = tostring(parameter or ""):match("^%s*(.-)%s*$")
	return matched2 == LocalPlayer.Name or matched2 == "@" .. LocalPlayer.Name or LocalPlayer.DisplayName ~= "" and matched2 == LocalPlayer.DisplayName
end
function Utilities.WatchName(parameter, parameter2)
	if parameter:IsA("Humanoid") and parameter2 then
		Utilities.Hidden[parameter] = {
			DisplayName = parameter.DisplayName,
			NameDisplayDistance = parameter.NameDisplayDistance
		}
		parameter.DisplayName, parameter.NameDisplayDistance = "", 0
		return
	end
	if not (parameter:IsA("TextLabel") or parameter:IsA("TextButton")) or Utilities.NameWatched[parameter] then
		return
	end
	Utilities.NameWatched[parameter] = true
	local function utilityRoutine()
		if not State.Running or not Utilities.NamesEnabled then
			return
		end
		local str = tostring(parameter.Text or "")
		local runtimeValue4 = Utilities.IsOwnName(str)
		if parameter2 and parameter:FindFirstAncestorWhichIsA("BillboardGui") then
			runtimeValue4 = runtimeValue4 or str:find(LocalPlayer.Name, 1, true) ~= nil or LocalPlayer.DisplayName ~= "" and str:find(LocalPlayer.DisplayName, 1, true) ~= nil
		end
		if runtimeValue4 then
			if not Utilities.Hidden[parameter] then
				Utilities.Hidden[parameter] = {
					Visible = parameter.Visible,
					TextTransparency = parameter.TextTransparency,
					TextStrokeTransparency = parameter.TextStrokeTransparency
				}
			end
			parameter.Visible, parameter.TextTransparency, parameter.TextStrokeTransparency = false, 1, 1
		elseif Utilities.Hidden[parameter] then
			for index, item in pairs(Utilities.Hidden[parameter]) do
				parameter[index] = item
			end
			Utilities.Hidden[parameter] = nil
		end
	end
	trackConnection(Utilities.NameConnections, parameter:GetPropertyChangedSignal("Text"):Connect(utilityRoutine))
	utilityRoutine()
end
function Hub.SetHideName(parameter)
	Utilities.NamesEnabled = parameter == true
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
	local function utilityRoutine(parameter2, parameter3)
		if not parameter2 then
			return
		end
		for _, item in ipairs(parameter2:GetDescendants()) do
			pcall(Utilities.WatchName, item, parameter3)
		end
		trackConnection(Utilities.NameConnections, parameter2.DescendantAdded:Connect(function(parameter4)
			task.defer(function()
				if State.Running and Utilities.NamesEnabled and nameGeneration == Utilities.NameGeneration then
					pcall(Utilities.WatchName, parameter4, parameter3)
				end
			end)
		end))
	end
	utilityRoutine(LocalPlayer.Character, true)
	utilityRoutine(getPlayerGui(), false)
	pcall(function()
		utilityRoutine(game:GetService("CoreGui"), false)
	end)
end
function Hub.StartRejoin()
	if Hub.Rejoin then
		return
	end
	local dataTable = {
		Active = true,
		Attempts = 0,
		Connections = {},
		Message = "Monitoring connection"
	}
	Hub.Rejoin = dataTable
	function dataTable.ConnectionError(parameter)
		if type(parameter) ~= "string" or parameter == "" then
			return false
		end
		local lowered = parameter:lower()
		return lowered:find("disconnect", 1, true) ~= nil
			or lowered:find("kicked", 1, true) ~= nil
			or lowered:find("kick", 1, true) ~= nil
			or lowered:find("lost connection", 1, true) ~= nil
			or lowered:find("connection lost", 1, true) ~= nil
			or lowered:find("reconnect", 1, true) ~= nil
			or lowered:match("error%s*code%s*:%s*%d+") ~= nil
	end
	function dataTable.ReadPrompt()
		local coreGui = game:GetService("CoreGui")
		local robloxPromptGui = coreGui:FindFirstChild("RobloxPromptGui")
		if not robloxPromptGui then
			return nil
		end
		local function utilityRoutine(parameter)
			while parameter do
				if parameter:IsA("GuiObject") and not parameter.Visible then
					return false
				end
				if parameter:IsA("ScreenGui") and not parameter.Enabled then
					return false
				end
				parameter = parameter.Parent
			end
			return true
		end
		local dataTable2 = {}
		local errorPrompt = robloxPromptGui:FindFirstChild("ErrorPrompt", true)
		if not errorPrompt or not utilityRoutine(errorPrompt) then
			return nil
		end
		for _, item in ipairs(errorPrompt:GetDescendants()) do
			if item:IsA("TextLabel") and utilityRoutine(item) and item.Text ~= "" then
				table.insert(dataTable2, item.Text)
			end
		end
		return # dataTable2 > 0 and table.concat(dataTable2, " | ") or nil
	end
	function dataTable.Step(parameter)
		if not dataTable.Active or not State.Running then
			return
		end
		local now = os.clock()
		if dataTable.InFlight then
			if now - dataTable.InFlight < 45 then
				return
			end
			dataTable.InFlight = nil
		end
		if not dataTable.ConnectionError(parameter) then
			dataTable.Prompt, dataTable.NextAt, dataTable.Attempts = nil, nil, 0
			return
		end
		if not dataTable.Prompt then
			dataTable.Prompt = parameter
			dataTable.NextAt = now + 3
		end
		if now < dataTable.NextAt then
			return
		end
		dataTable.Attempts = dataTable.Attempts + 1
		dataTable.NextAt = now + ({
			10,
			20,
			30,
			60
		})[math.min(dataTable.Attempts, 4)]
		dataTable.InFlight = now
		dataTable.Message = "Rejoining lobby | attempt " .. dataTable.Attempts
		if UI.SaveConfigNow then
			pcall(UI.SaveConfigNow)
		end
		pcall(Hub.QueueTeleport)
		local ok2, result2 = pcall(function()
			TeleportService:Teleport(LOBBY_PLACE_ID, LocalPlayer)
		end)
		if not ok2 then
			dataTable.InFlight = nil
			dataTable.Message = "Retrying lobby: " .. tostring(result2)
		end
	end
	function dataTable.Stop()
		dataTable.Active = false
		disconnectAll(dataTable.Connections)
	end
	trackConnection(dataTable.Connections, TeleportService.TeleportInitFailed:Connect(function(parameter, parameter2, _, parameter3)
		if parameter ~= LocalPlayer or parameter3 ~= LOBBY_PLACE_ID or dataTable.Attempts == 0 then
			return
		end
		dataTable.InFlight = nil
		dataTable.Message = "Lobby teleport failed; retrying | " .. tostring(parameter2)
	end))
	trackConnection(dataTable.Connections, LocalPlayer.OnTeleport:Connect(function(parameter)
		if dataTable.Attempts == 0 then
			return
		end
		if parameter == Enum.TeleportState.Failed then
			dataTable.InFlight = nil
		end
	end))
	pcall(function()
		local guiService = game:GetService("GuiService")
		trackConnection(dataTable.Connections, guiService.ErrorMessageChanged:Connect(function(parameter)
			dataTable.EventText = parameter
		end))
		dataTable.GuiService = guiService
	end)
	task.spawn(function()
		while State.Running and dataTable.Active do
			local ok2, result2 = pcall(dataTable.ReadPrompt)
			local runtimeValue4 = ok2 and result2 or nil
			if not runtimeValue4 and dataTable.GuiService then
				local ok3, result3 = pcall(function()
					return dataTable.GuiService:GetErrorMessage()
				end)
				runtimeValue4 = ok3 and result3 or dataTable.EventText
			end
			pcall(dataTable.Step, runtimeValue4)
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
	trackConnection(Utilities.Connections, LocalPlayer.OnTeleport:Connect(function(parameter)
		if parameter == Enum.TeleportState.Started then
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
function Knock.Status(parameter)
	Knock.Message = parameter
	if UI.KnockStatus then
		UI.KnockStatus:SetDesc(parameter)
	end
end
function Knock.Alive(parameter)
	return State.Running and State.AutoKnockDoor and parameter == Knock.Session
end
function Knock.CooldownSeconds(parameter)
	parameter = tostring(parameter or ""):lower()
	if not parameter:find("cooldown", 1, true) then
		return nil
	end
	local runtimeValue4 = tonumber(parameter:match("(%d+)%s+minute")) or 0
	local runtimeValue5 = tonumber(parameter:match("(%d+)%s+second")) or 0
	return runtimeValue4 * 60 + runtimeValue5 > 0 and runtimeValue4 * 60 + runtimeValue5 or nil
end
function Knock.SaveCooldowns()
	if not hasFileApi then
		return
	end
	pcall(function()
		local runtimeValue4 = MACRO_FOLDER .. "/Knock"
		if not isfolder(runtimeValue4) then
			makefolder(runtimeValue4)
		end
		writefile(runtimeValue4 .. "/" .. LocalPlayer.UserId .. ".json", HttpService:JSONEncode(Knock.Cooldowns))
	end)
end
function Knock.LoadCooldowns()
	if not hasFileApi then
		return
	end
	pcall(function()
		local runtimeValue4 = MACRO_FOLDER .. "/Knock/" .. LocalPlayer.UserId .. ".json"
		if not isfile(runtimeValue4) then
			return
		end
		local decoded = HttpService:JSONDecode(readfile(runtimeValue4))
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
function Knock.SetCooldown(parameter, parameter2)
	Knock.Cooldowns[parameter.Name] = os.time() + math.ceil(parameter2) + 2
	Knock.SaveCooldowns()
end
function Knock.Ready(parameter)
	return (Knock.Cooldowns[parameter.Name] or 0) <= os.time() and (Knock.RetryAt[parameter.Name] or 0) <= os.clock()
end
function Knock.Doors()
	local dataTable = {}
	for _, item in ipairs(Workspace:GetChildren()) do
		if item:IsA("Model") and item.Name:match("^Door%d+$") then
			local proximityPrompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
			if proximityPrompt then
				dataTable[# dataTable + 1] = {
					Door = item,
					Prompt = proximityPrompt
				}
			end
		end
	end
	return dataTable
end
function Knock.PromptPosition(parameter)
	local parent = parameter.Parent
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
function Knock.OwnWalk(parameter)
	Knock.MovingHumanoid = parameter
	if Knock.WalkControls then
		return
	end
	pcall(function()
		local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
		local runtimeValue4 = playerScripts and playerScripts:FindFirstChild("PlayerModule")
		if not runtimeValue4 then
			return
		end
		local runtimeValue5 = require(runtimeValue4):GetControls()
		Knock.RestoreControls = runtimeValue5.controlsEnabled ~= false
		Knock.WalkControls = runtimeValue5
		runtimeValue5:Disable()
	end)
end
function Knock.ReachedWaypoint(parameter, parameter2, parameter3)
	local runtimeValue4 = parameter.Position - parameter2
	return math.sqrt(runtimeValue4.X * runtimeValue4.X + runtimeValue4.Z * runtimeValue4.Z) < parameter3 and math.abs(runtimeValue4.Y) < 6
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
function Knock.PromptReady(parameter)
	local character = LocalPlayer.Character
	local runtimeValue4 = character and character:FindFirstChild("HumanoidRootPart")
	local runtimeValue5 = Knock.PromptPosition(parameter)
	local currentCamera = Workspace.CurrentCamera
	if not currentCamera or not runtimeValue4 or not runtimeValue5 or not parameter.Enabled or (runtimeValue4.Position - runtimeValue5).Magnitude >= parameter.MaxActivationDistance then
		return false
	end
	local value, value1 = currentCamera:WorldToViewportPoint(runtimeValue5)
	if not value1 or value.Z <= 0 or Knock.VisiblePrompts[parameter] == false then
		return false
	end
	local runtimeValue6 = RaycastParams.new()
	runtimeValue6.FilterType = Enum.RaycastFilterType.Exclude
	runtimeValue6.FilterDescendantsInstances = {
		character
	}
	local runtimeValue7 = Workspace:Raycast(currentCamera.CFrame.Position, runtimeValue5 - currentCamera.CFrame.Position, runtimeValue6)
	return not runtimeValue7 or (runtimeValue7.Position - runtimeValue5).Magnitude < 1.8
end
function Knock.FocusPrompt(parameter, parameter2)
	local currentCamera = Workspace.CurrentCamera
	local runtimeValue4 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local runtimeValue5 = Knock.PromptPosition(parameter.Prompt)
	if not currentCamera or not runtimeValue4 or not runtimeValue5 or not Knock.Alive(parameter2) then
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
	Knock.Status(parameter.Door.Name .. " | Facing door / waiting for E")
	local vector = Vector3.new(runtimeValue4.Position.X - runtimeValue5.X, 0, runtimeValue4.Position.Z - runtimeValue5.Z)
	if vector.Magnitude < 0.1 then
		return false
	end
	vector = vector.Unit
	for _, item in ipairs({
		4,
		2,
		6
	}) do
		if not Knock.Alive(parameter2) then
			return false
		end
		currentCamera.CameraType = Enum.CameraType.Scriptable
		local runtimeValue6 = runtimeValue4.Position + vector * item + Vector3.new(0, 2.5, 0)
		currentCamera.CFrame = CFrame.lookAt(runtimeValue6, runtimeValue5)
		currentCamera.Focus = CFrame.new(runtimeValue5)
		local runtimeValue7 = os.clock() + 0.7
		repeat
			task.wait(0.05)
			if not Knock.Alive(parameter2) then
				return false
			end
			if Knock.PromptReady(parameter.Prompt) then
				task.wait(0.1)
				if Knock.Alive(parameter2) and Knock.PromptReady(parameter.Prompt) then
					if Knock.LastAttempt then
						Knock.LastAttempt.CameraAimed = true
						Knock.LastAttempt.PromptVisible = true
					end
					return true
				end
			end
		until os.clock() >= runtimeValue7
	end
	return false
end
function Knock.Targets(parameter, parameter2, parameter3)
	local prompt = parameter.Prompt
	local runtimeValue4 = Knock.PromptPosition(prompt)
	if not runtimeValue4 then
		return {}
	end
	local camCF = parameter.Door:FindFirstChild("CamCF", true)
	local runtimeValue5 = camCF and camCF:IsA("BasePart") and camCF.Position - runtimeValue4
	runtimeValue5 = runtimeValue5 and Vector3.new(runtimeValue5.X, 0, runtimeValue5.Z)
	if not runtimeValue5 or runtimeValue5.Magnitude < 0.1 then
		local parent = prompt.Parent
		local runtimeValue6 = parent:IsA("Attachment") and parent.WorldCFrame or parent:IsA("BasePart") and parent.CFrame or parameter.Door:GetPivot()
		runtimeValue5 = Vector3.new(runtimeValue6.LookVector.X, 0, runtimeValue6.LookVector.Z)
	end
	if runtimeValue5.Magnitude < 0.1 then
		return {}
	end
	runtimeValue5 = runtimeValue5.Unit
	local runtimeValue7 = tonumber(prompt.MaxActivationDistance) or 10
	if runtimeValue7 < 3 then
		return {}
	end
	local runtimeValue8 = RaycastParams.new()
	runtimeValue8.FilterType = Enum.RaycastFilterType.Exclude
	runtimeValue8.FilterDescendantsInstances = {
		LocalPlayer.Character
	}
	runtimeValue8.RespectCanCollide = true
	local runtimeValue9 = OverlapParams.new()
	runtimeValue9.FilterType = Enum.RaycastFilterType.Exclude
	runtimeValue9.FilterDescendantsInstances = {
		LocalPlayer.Character
	}
	runtimeValue9.RespectCanCollide = true
	local runtimeValue10 = parameter3.HipHeight or 2
	if runtimeValue10 <= 0 then
		local runtimeValue11 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Left Leg")
		runtimeValue10 = runtimeValue11 and runtimeValue11.Size.Y or 2
	end
	local runtimeValue12 = runtimeValue10 + parameter2.Size.Y / 2
	local dataTable = {}
	for _, item in ipairs({
		math.min(4.5, runtimeValue7 - 1.5),
		math.min(6.5, runtimeValue7 - 1)
	}) do
		for _, item3 in ipairs({
			0,
			25,
			- 25,
			50,
			- 50
		}) do
			local num = math.rad(item3)
			local vector = Vector3.new(runtimeValue5.X * math.cos(num) - runtimeValue5.Z * math.sin(num), 0, runtimeValue5.X * math.sin(num) + runtimeValue5.Z * math.cos(num))
			local runtimeValue13 = runtimeValue4 + vector * item
			local runtimeValue14 = Workspace:Raycast(runtimeValue13 + Vector3.new(0, 8, 0), Vector3.new(0, - 28, 0), runtimeValue8)
			if runtimeValue14 and runtimeValue14.Normal.Y > 0.65 and runtimeValue14.Position.Y <= runtimeValue4.Y + 1.5 and runtimeValue14.Position.Y >= runtimeValue4.Y - 12 then
				local runtimeValue15 = runtimeValue14.Position + Vector3.new(0, runtimeValue12 + 0.1, 0)
				local vector2 = Vector3.new(runtimeValue4.X, runtimeValue15.Y, runtimeValue4.Z)
				local cframe = CFrame.lookAt(runtimeValue15, vector2)
				local stateFlag = true
				for _, item4 in ipairs(Workspace:GetPartBoundsInBox(cframe, Vector3.new(3.4, 4.5, 2.6), runtimeValue9)) do
					if item4.CanCollide then
						stateFlag = false
						break
					end
				end
				if stateFlag and (runtimeValue15 - runtimeValue4).Magnitude < runtimeValue7 - 0.3 then
					local runtimeValue16 = Workspace:Raycast(runtimeValue15, runtimeValue4 - runtimeValue15, runtimeValue8)
					local runtimeValue18 = not runtimeValue16 or (runtimeValue16.Position - runtimeValue4).Magnitude < 1.8
					if not prompt.RequiresLineOfSight or runtimeValue18 then
						dataTable[# dataTable + 1] = {
							Position = runtimeValue15,
							CFrame = cframe
						}
					end
				end
			end
		end
	end
	return dataTable
end
function Knock.Travel(parameter, parameter2, parameter3)
	local character = LocalPlayer.Character
	local runtimeValue4 = character and character:FindFirstChild("HumanoidRootPart")
	local runtimeValue5 = character and character:FindFirstChildOfClass("Humanoid")
	local runtimeValue6 = Knock.PromptPosition(parameter.Prompt)
	if not runtimeValue4 or not runtimeValue5 or not runtimeValue6 or runtimeValue5.Health <= 0 then
		return false, "Character unavailable"
	end
	if runtimeValue4.Anchored then
		return false, "Character busy"
	end
	local function utilityRoutine()
		return Knock.Alive(parameter2) and LocalPlayer.Character == character and runtimeValue4.Parent and runtimeValue5.Health > 0
	end
	if not utilityRoutine() then
		return false, "Canceled"
	end
	local runtimeValue7 = Knock.Targets(parameter, runtimeValue4, runtimeValue5)
	if # runtimeValue7 == 0 then
		return false, "No clear ground in front of door"
	end
	local text = "Arrival not confirmed"
	for index, item in ipairs(runtimeValue7) do
		if index > 4 then
			break
		end
		if not utilityRoutine() then
			return false, "Canceled"
		end
		Knock.Status(parameter.Door.Name .. " | " .. parameter3 .. " approach " .. index)
		Knock.LastAttempt = {
			Door = parameter.Door.Name,
			Method = parameter3,
			Target = {
				item.Position.X,
				item.Position.Y,
				item.Position.Z
			},
			Approach = index
		}
		if parameter3 == "TP" then
			local runtimeValue8 = runtimeValue4.CFrame:ToObjectSpace(character:GetPivot())
			character:PivotTo(item.CFrame * runtimeValue8)
			task.wait(0.4)
			runtimeValue4.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			runtimeValue4.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		else
			local runtimeValue9 = game:GetService("PathfindingService"):CreatePath({
				AgentRadius = 2,
				AgentHeight = 5,
				AgentCanJump = true,
				WaypointSpacing = 6
			})
			local ok2 = pcall(function()
				runtimeValue9:ComputeAsync(runtimeValue4.Position, item.Position)
			end)
			if not utilityRoutine() then
				return false, "Canceled"
			end
			if ok2 and runtimeValue9.Status == Enum.PathStatus.Success then
				Knock.OwnWalk(runtimeValue5)
				local runtimeValue10 = os.clock() + 40
				local runtimeValue11 = runtimeValue9:GetWaypoints()
				for index2, item3 in ipairs(runtimeValue11) do
					if not utilityRoutine() then
						return false, "Canceled"
					end
					if item3.Action == Enum.PathWaypointAction.Jump then
						runtimeValue5.Jump = true
					end
					runtimeValue5:MoveTo(item3.Position)
					local num = math.min(runtimeValue10, os.clock() + 5)
					local runtimeValue12 = index2 == # runtimeValue11 and 1.8 or math.max(3, (runtimeValue5.WalkSpeed or 16) * 0.2)
					repeat
						task.wait(0.03)
					until not utilityRoutine() or Knock.ReachedWaypoint(runtimeValue4, item3.Position, runtimeValue12) or os.clock() >= num
					if not utilityRoutine() then
						return false, "Canceled"
					end
					if os.clock() >= num and not Knock.ReachedWaypoint(runtimeValue4, item3.Position, runtimeValue12) then
						text = "Walk blocked"
						break
					end
				end
			else
				text = "No walking path"
			end
			Knock.CancelMove()
		end
		if not utilityRoutine() then
			return false, "Canceled"
		end
		if (runtimeValue4.Position - item.Position).Magnitude < 2.5 and (runtimeValue4.Position - runtimeValue6).Magnitude < parameter.Prompt.MaxActivationDistance - 0.2 then
			if runtimeValue4.Anchored then
				return false, "Character busy"
			end
			task.wait(0.25)
			if not utilityRoutine() then
				return false, "Canceled"
			end
			if Knock.FocusPrompt(parameter, parameter2) then
				return true
			end
			Knock.ReleaseCamera()
			text = "Door prompt hidden or obstructed"
		end
	end
	return false, text
end
function Knock.OnToast(parameter)
	local pending = Knock.Pending
	if not pending or type(parameter) ~= "table" or pending.Conflicted then
		return
	end
	local str, str2 = tostring(parameter.Title or ""), tostring(parameter.ContentText or "")
	local lowered = (str .. " " .. str2):lower()
	if not (lowered:find("treat", 1, true) or lowered:find("trick", 1, true) or lowered:find("door", 1, true)) then
		return
	end
	local runtimeValue4 = str .. "|" .. str2
	if pending.Seen[runtimeValue4] then
		return
	end
	pending.Seen[runtimeValue4] = true
	local runtimeValue5 = Knock.CooldownSeconds(str2)
	if not runtimeValue5 and lowered:find("cooldown", 1, true) then
		runtimeValue5 = 1800
	end
	if runtimeValue5 then
		pending.Cooldown = runtimeValue5
		pending.Done = true
		Knock.SetCooldown(pending.Door, runtimeValue5)
		return
	end
	local runtimeValue6 = Reports.ParseRewards(str2)
	for index, item in pairs(runtimeValue6) do
		pending.Rewards[index] = (pending.Rewards[index] or 0) + item
	end
	if next(runtimeValue6) then
		pending.Outcome = "Reward"
		pending.Done = true
		Knock.SetCooldown(pending.Door, 1800)
	end
	if not next(runtimeValue6) and str2 ~= "" then
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
function Knock.OnCamera(parameter, parameter2)
	local pending = Knock.Pending
	if not pending or typeof(parameter) ~= "Instance" then
		return
	end
	if parameter2 == "lock" and Knock.SavedCamera then
		Knock.SavedCamera.Owned = false
	end
	if not parameter:IsDescendantOf(pending.Door) then
		pending.Conflicted = true
		return
	end
	if parameter2 == "lock" then
		pending.Started = true
		pending.Locked = true
	end
	if parameter2 == "unlock" then
		pending.Locked = false
		pending.ReleasedAt = os.clock()
	end
end
function Knock.Bind()
	if not Knock.PromptSignalsBound then
		pcall(function()
			local proximityPromptService = game:GetService("ProximityPromptService")
			trackConnection(Knock.Connections, proximityPromptService.PromptShown:Connect(function(parameter)
				Knock.VisiblePrompts[parameter] = true
			end))
			trackConnection(Knock.Connections, proximityPromptService.PromptHidden:Connect(function(parameter)
				Knock.VisiblePrompts[parameter] = false
			end))
			Knock.PromptSignalsBound = true
		end)
	end
	local toasts = ReplicatedStorage:FindFirstChild("Toasts")
	local runtimeValue4 = toasts and toasts:FindFirstChild("Assets")
	local runtimeValue5 = runtimeValue4 and runtimeValue4:FindFirstChild("Remotes")
	local eventStuff = ReplicatedStorage:FindFirstChild("EventStuff")
	local function utilityRoutine(parameter, parameter2)
		if parameter and parameter:IsA("RemoteEvent") and not Knock.Bound[parameter] then
			Knock.Bound[parameter] = true
			trackConnection(Knock.Connections, parameter.OnClientEvent:Connect(parameter2))
		end
	end
	utilityRoutine(runtimeValue5 and runtimeValue5:FindFirstChild("Display"), Knock.OnToast)
	utilityRoutine(eventStuff and eventStuff:FindFirstChild("TweenCamera"), Knock.OnCamera)
end
function Knock.Trigger(parameter, parameter2, parameter3, parameter4)
	if not Knock.Alive(parameter2) or not Knock.PromptReady(parameter) then
		return false, "Door prompt not ready"
	end
	local num = math.max(0, tonumber(parameter.HoldDuration) or 0)
	Knock.Status(parameter3.Door.Name .. " | Holding Knock " .. string.format("%.1fs", num))
	parameter3.Attempts = (parameter3.Attempts or 0) + 1
	local now = os.clock()
	local runtimeValue4 = not parameter4 and type(parameter.InputHoldBegin) == "function" and type(parameter.InputHoldEnd) == "function"
	local ok2, result2 = pcall(function()
		if runtimeValue4 then
			parameter:InputHoldBegin()
		elseif type(fireproximityprompt) == "function" then
			fireproximityprompt(parameter, num)
		else
			error("No supported prompt input")
		end
		repeat
			task.wait(0.05)
		until not Knock.Alive(parameter2) or parameter3.Started or parameter3.Done or os.clock() - now >= num + 0.2
	end)
	if runtimeValue4 then
		pcall(function()
			parameter:InputHoldEnd()
		end)
	end
	if Knock.LastAttempt then
		Knock.LastAttempt.Input = runtimeValue4 and "Hold" or "fireproximityprompt"
		Knock.LastAttempt.HoldDuration = num
		Knock.LastAttempt.Attempts = parameter3.Attempts
	end
	return ok2, result2
end
function Knock.TryDoor(parameter, parameter2, parameter3)
	local door, prompt = parameter.Door, parameter.Prompt
	if not Knock.Alive(parameter2) or not Knock.Ready(door) then
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
	local value, value1 = Knock.Travel(parameter, parameter2, parameter3)
	Knock.CancelMove()
	if not value then
		Knock.RetryAt[door.Name] = os.clock() + 120
		return {
			Status = "Failed",
			Message = value1
		}
	end
	if not Knock.Alive(parameter2) then
		return nil
	end
	Knock.Bind()
	local dataTable = {
		Door = door,
		Rewards = {},
		Messages = {},
		Seen = {}
	}
	Knock.Pending = dataTable
	local value2, value12 = Knock.Trigger(prompt, parameter2, dataTable, false)
	local stateFlag = false
	if not value2 and Knock.Alive(parameter2) and not dataTable.Started and not dataTable.Done and type(fireproximityprompt) == "function" then
		stateFlag = true
		value2, value12 = Knock.Trigger(prompt, parameter2, dataTable, true)
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
	local runtimeValue4 = now + 40
	Knock.Status(door.Name .. " | Waiting for door response")
	while Knock.Alive(parameter2) and os.clock() < runtimeValue4 do
		if dataTable.Cooldown then
			break
		end
		if dataTable.Done and not dataTable.Locked then
			task.wait(0.5)
			break
		end
		if dataTable.ReleasedAt and os.clock() - dataTable.ReleasedAt >= 3 then
			break
		end
		if not dataTable.Started and not dataTable.Done and os.clock() - now >= 6 then
			if not stateFlag and type(fireproximityprompt) == "function" then
				stateFlag = true
				local runtimeValue5 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				local runtimeValue6 = Knock.PromptPosition(prompt)
				if not runtimeValue5 or runtimeValue5.Anchored or not runtimeValue6 or (runtimeValue5.Position - runtimeValue6).Magnitude >= prompt.MaxActivationDistance then
					break
				end
				if not Knock.FocusPrompt(parameter, parameter2) then
					break
				end
				Knock.Trigger(prompt, parameter2, dataTable, true)
				now = os.clock()
				Knock.Status(door.Name .. " | Waiting for door response")
			else
				break
			end
		end
		task.wait(0.1)
	end
	Knock.Pending = nil
	if dataTable.Conflicted then
		Knock.RetryAt[door.Name] = os.clock() + 120
		return {
			Status = "Unknown"
		}
	end
	if dataTable.Cooldown then
		return {
			Status = "Cooldown",
			Seconds = dataTable.Cooldown
		}
	end
	if dataTable.Outcome then
		return {
			Status = dataTable.Outcome,
			Rewards = dataTable.Rewards,
			Messages = dataTable.Messages
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
function Knock.Try(parameter, parameter2, parameter3)
	local ok2, result2 = xpcall(function()
		return Knock.TryDoor(parameter, parameter2, parameter3)
	end, function(parameter4)
		return tostring(parameter4)
	end)
	Knock.ReleaseCamera()
	if not ok2 then
		Knock.Pending = nil
		Knock.RetryAt[parameter.Door.Name] = os.clock() + 120
		Knock.CancelMove()
		return {
			Status = "Failed",
			Message = result2
		}
	end
	return result2
end
function Knock.BuildReport(parameter)
	local dataTable = {
		string.format("\240\159\143\160 Checked: %d | Reward: %d | Empty: %d", parameter.Checked, parameter.Reward, parameter.Empty),
		string.format("\226\143\179 Cooldown: %d | Unconfirmed: %d | Failed: %d", parameter.Cooldown, parameter.Unknown, parameter.Failed)
	}
	local dataTable2 = {
		{
			name = "Rewards",
			value = Reports.Lines(parameter.Rewards),
			inline = false
		}
	}
	if # parameter.Messages > 0 then
		local joined = table.concat(parameter.Messages, "\n")
		if # joined > 950 then
			joined = joined:sub(1, 900) .. "\n\226\128\166 More messages stored in the local debug report."
		end
		dataTable2[# dataTable2 + 1] = {
			name = "Other rewards / messages",
			value = joined,
			inline = false
		}
	end
	return {
		title = "Knock Door Report",
		description = "\240\159\145\164 ||" .. Reports.Escape(LocalPlayer.Name) .. "|| \194\183 " .. Reports.Escape(parameter.Method) .. "\n" .. table.concat(dataTable, "\n"),
		color = 16753920,
		fields = dataTable2,
		footer = {
			text = "Made By Kero"
		},
		timestamp = DateTime.now():ToIsoDate()
	}
end
function Knock.Report(parameter)
	Knock.LastRound = parameter
	if not State.KnockWebhookEnabled or parameter.Checked == 0 then
		return
	end
	local value, value1 = Reports.Post(State.WebhookURL, Knock.BuildReport(parameter))
	Knock.LastWebhookResult = value and "Sent" or value1
end
function Knock.Sweep(parameter, parameter2)
	local dataTable = {
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
	while Knock.Alive(parameter) and # parameter2 > 0 do
		local character = LocalPlayer.Character
		local runtimeValue4 = character and character:FindFirstChild("HumanoidRootPart")
		if not runtimeValue4 then
			break
		end
		table.sort(parameter2, function(parameter3, parameter4)
			local runtimeValue5, runtimeValue6 = Knock.PromptPosition(parameter3.Prompt), Knock.PromptPosition(parameter4.Prompt)
			return (runtimeValue5 and (runtimeValue4.Position - runtimeValue5).Magnitude or math.huge) < (runtimeValue6 and (runtimeValue4.Position - runtimeValue6).Magnitude or math.huge)
		end)
		local runtimeValue7 = table.remove(parameter2, 1)
		if Knock.Ready(runtimeValue7.Door) then
			Knock.Status(runtimeValue7.Door.Name .. " | " .. dataTable.Method)
			local runtimeValue8 = Knock.Try(runtimeValue7, parameter, dataTable.Method)
			if runtimeValue8 then
				dataTable.Checked = dataTable.Checked + 1
				local status = runtimeValue8.Status
				if status == "Reward" or status == "Other" then
					dataTable.Reward = dataTable.Reward + 1
				elseif status == "Empty" then
					dataTable.Empty = dataTable.Empty + 1
				elseif status == "Cooldown" then
					dataTable.Cooldown = dataTable.Cooldown + 1
				elseif status == "Unknown" then
					dataTable.Unknown = dataTable.Unknown + 1
				else
					dataTable.Failed = dataTable.Failed + 1
				end
				for index, item in pairs(runtimeValue8.Rewards or {}) do
					dataTable.Rewards[index] = (dataTable.Rewards[index] or 0) + item
				end
				for _, item3 in ipairs(runtimeValue8.Messages or {}) do
					dataTable.Messages[# dataTable.Messages + 1] = Reports.Escape(runtimeValue7.Door.Name .. ": " .. item3)
				end
			end
			local runtimeValue9 = os.clock() + 1
			repeat
				task.wait(0.1)
			until not Knock.Alive(parameter) or os.clock() >= runtimeValue9
		end
	end
	Knock.Report(dataTable)
end
function Hub.SetAutoKnock(parameter)
	State.AutoKnockDoor = parameter == true
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
				local runtimeValue4 = Knock.Doors()
				local dataTable = {}
				for _, item in ipairs(runtimeValue4) do
					if Knock.Ready(item.Door) then
						dataTable[# dataTable + 1] = item
					end
				end
				if # dataTable > 0 then
					Knock.Sweep(session, dataTable)
				else
					Knock.Status(# runtimeValue4 == 0 and "Waiting for event houses" or "Waiting for available doors")
				end
				local runtimeValue5 = os.clock() + 5
				repeat
					task.wait(0.2)
				until not Knock.Alive(session) or os.clock() >= runtimeValue5
			end
		end, function(parameter2)
			return tostring(parameter2)
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
local function notifyUser(parameter, parameter2)
	pcall(function()
		WindUI:Notify({
			Title = parameter,
			Content = parameter2,
			Duration = 4,
			Icon = "bell"
		})
	end)
end
local function createParagraphAdapter(parameter)
	local dataTable = {}
	function dataTable:SetTitle(parameter2)
		pcall(function()
			if parameter.SetTitle then
				parameter:SetTitle(parameter2)
			else
				parameter:Set({
					Title = parameter2
				})
			end
		end)
	end
	function dataTable:SetDesc(parameter2)
		pcall(function()
			if parameter.SetDesc then
				parameter:SetDesc(parameter2)
			else
				parameter:Set({
					Desc = parameter2
				})
			end
		end)
	end
	return dataTable
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
local stateFlag5 = false
Knock.LoadCooldowns()
local function saveConfig()
	if not hasFileApi then
		return
	end
	local dataTable = {
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
		writefile(CONFIG_PATH, HttpService:JSONEncode(dataTable))
	end)
end
local function queueConfigSave()
	if stateFlag5 then
		return
	end
	stateFlag5 = true
	task.delay(0.25, function()
		stateFlag5 = false
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
			local runtimeValue4
			if type(openurl) == "function" then
				local ok2, result2 = pcall(openurl, text2)
				if ok2 and result2 ~= false then
					runtimeValue4 = "Discord link opened."
				end
			end
			if not runtimeValue4 then
				for _, item in ipairs({
					"setclipboard",
					"toclipboard",
					"set_clipboard"
				}) do
					local runtimeValue5 = type(getgenv) == "function" and getgenv() or _G
					local runtimeValue6 = runtimeValue5[item]
					if type(runtimeValue6) == "function" then
						local ok3, result3 = pcall(runtimeValue6, text2)
						if ok3 and result3 ~= false then
							runtimeValue4 = "Copied! Paste the link into your browser or Discord."
							break
						end
					end
				end
			end
			pcall(function()
				WindUI:Notify({
					Title = "Discord",
					Content = runtimeValue4 or "Open this link: " .. text2,
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
	Set = function(parameter)
		State.BlackScreen = parameter == true
		saveConfig()
	end
}
do
	local runtimeValue22 = type(getgenv) == "function" and getgenv() or _G
	local runtimeValue23
	local blackScreenPersistence = Hub.BlackScreenPersistence
	local runtimeValue24 = blackScreenPersistence and blackScreenPersistence.Get() == true or false
	local function syncBlackScreenPreference(parameter)
		if blackScreenPersistence and not runtimeValue23.Cleaning and blackScreenPersistence.Get() ~= parameter then
			blackScreenPersistence.Set(parameter)
		end
	end
	local runtimeValue25 = runtimeValue22.__KeroBlackScreen
	if runtimeValue25 and type(runtimeValue25.Destroy) == "function" and runtimeValue25.Destroy() == false then
		return
	end
	runtimeValue23 = {
		Alive = true,
		Enabled = false,
		Connections = {}
	}
	runtimeValue22.__KeroBlackScreen = runtimeValue23
	Hub.BlackScreenController = runtimeValue23
	local runtimeValue26, runtimeValue27
	local runtimeValue28
	local function notifyBlackScreen(parameter)
		pcall(function()
			WindUI:Notify({
				Title = "Black Screen",
				Content = parameter,
				Duration = 5
			})
		end)
	end
	local function setBlackScreenToggle(parameter)
		if not runtimeValue26 or runtimeValue27 then
			return
		end
		runtimeValue27 = true
		pcall(function()
			runtimeValue26:Set(parameter)
		end)
		runtimeValue27 = false
	end
	local function cleanupBlackScreenResources()
		for _, item in ipairs(runtimeValue23.Connections) do
			pcall(item.Disconnect, item)
		end
		runtimeValue23.Connections = {}
		local gui = runtimeValue23.Gui
		runtimeValue23.Gui = nil
		if gui then
			pcall(gui.Destroy, gui)
		end
	end
	function runtimeValue23.Set(parameter)
		parameter = parameter == true
		if parameter and not runtimeValue23.Alive then
			return false
		end
		if not parameter then
			if runtimeValue23.RenderDisabled then
				local ok2 = pcall(runtimeValue28.Set3dRenderingEnabled, runtimeValue28, true)
				if not ok2 then
					notifyBlackScreen("Could not restore 3D rendering. Press Disable Black Screen to retry.")
					return false
				end
				runtimeValue23.RenderDisabled = nil
			end
			runtimeValue23.Enabled = false
			syncBlackScreenPreference(false)
			cleanupBlackScreenResources()
			setBlackScreenToggle(false)
			return true
		end
		if runtimeValue23.Enabled and runtimeValue23.Gui and runtimeValue23.Gui.Parent then
			return true
		end
		local runtimeValue4
		local ok5, result4 = pcall(function()
			runtimeValue4 = Instance.new("ScreenGui")
			runtimeValue4.Name = "KeroBlackScreen_skibidi"
			runtimeValue4.Enabled = false
			runtimeValue4.IgnoreGuiInset = true
			runtimeValue4.ResetOnSpawn = false
			runtimeValue4.DisplayOrder = 2147483647
			runtimeValue4.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			local frame = Instance.new("Frame")
			frame.Name = "Background"
			frame.Size = UDim2.fromScale(1, 1)
			frame.BackgroundColor3 = Color3.new(0, 0, 0)
			frame.BorderSizePixel = 0
			frame.Active = true
			frame.ZIndex = 1
			frame.Parent = runtimeValue4
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
			local dataTable = {}
			if type(gethui) == "function" then
				local ok3, result2 = pcall(gethui)
				if ok3 and result2 then
					dataTable[# dataTable + 1] = result2
				end
			end
			local ok4, result3 = pcall(game.GetService, game, "CoreGui")
			if ok4 and result3 then
				dataTable[# dataTable + 1] = result3
			end
			local localPlayer = game:GetService("Players").LocalPlayer
			local runtimeValue5 = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
			if runtimeValue5 then
				dataTable[# dataTable + 1] = runtimeValue5
			end
			local stateFlag = false
			for _, item in ipairs(dataTable) do
				if pcall(function()
					runtimeValue4.Parent = item
				end) and runtimeValue4.Parent == item then
					stateFlag = true
					break
				end
			end
			assert(stateFlag, "Overlay unavailable on this executor")
			runtimeValue23.Gui = runtimeValue4
			runtimeValue23.Connections[# runtimeValue23.Connections + 1] = textButton.Activated:Connect(function()
				runtimeValue23.Set(false)
			end)
			if runtimeValue4.Destroying then
				runtimeValue23.Connections[# runtimeValue23.Connections + 1] = runtimeValue4.Destroying:Connect(function()
					runtimeValue23.Gui = nil
					runtimeValue23.Set(false)
				end)
			end
			runtimeValue4.Enabled = true
		end)
		if not ok5 then
			if runtimeValue4 then
				pcall(runtimeValue4.Destroy, runtimeValue4)
			end
			cleanupBlackScreenResources()
			runtimeValue23.Enabled = false
			setBlackScreenToggle(false)
			notifyBlackScreen(tostring(result4))
			return false
		end
		local ok6 = pcall(function()
			runtimeValue28 = game:GetService("RunService")
			runtimeValue28:Set3dRenderingEnabled(false)
		end)
		runtimeValue23.RenderDisabled = ok6 or nil
		runtimeValue23.Enabled = true
		syncBlackScreenPreference(true)
		if not ok6 then
			notifyBlackScreen("Black overlay enabled; this executor cannot disable 3D rendering.")
		end
		return true
	end
	function runtimeValue23.Destroy()
		runtimeValue23.Cleaning = true
		if not runtimeValue23.Set(false) then
			runtimeValue23.Cleaning = false
			return false
		end
		runtimeValue23.Alive = false
		if runtimeValue22.__KeroBlackScreen == runtimeValue23 then
			runtimeValue22.__KeroBlackScreen = nil
		end
		return true
	end
	miscTab:Section({
		Title = "Display"
	})
	runtimeValue26 = miscTab:Toggle({
		Title = "Black Screen",
		Desc = "Black overlay with a visible Disable button. Turns off 3D rendering when supported.",
		Value = runtimeValue24,
		Callback = function(parameter)
			if not runtimeValue27 then
				runtimeValue23.Set(parameter)
			end
		end
	})
	if runtimeValue24 then
		runtimeValue23.Set(true)
	end
end
lobbyTab:Section({
	Title = "Play"
})
if not chaptersByMode[State.LobbyMode] and State.LobbyMode ~= "All" then
	State.LobbyMode = "Story"
end
local runtimeValue29 = getChapters(State.LobbyMode)
if not table.find(runtimeValue29, State.LobbyChapter) then
	State.LobbyChapter = runtimeValue29[1] or "Chapter 1"
end
local runtimeValue30
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
	Callback = function(parameter)
		State.LobbyMode = parameter
		local runtimeValue4 = getChapters(parameter)
		if not table.find(runtimeValue4, State.LobbyChapter) then
			State.LobbyChapter = runtimeValue4[1] or ""
		end
		if runtimeValue30 then
			pcall(function()
				runtimeValue30:Refresh(runtimeValue4)
			end)
			pcall(function()
				runtimeValue30:Select(State.LobbyChapter)
			end)
		end
		State.JoinRequested = false
		queueConfigSave()
	end
})
runtimeValue30 = lobbyTab:Dropdown({
	Title = "Map",
	Values = runtimeValue29,
	Value = State.LobbyChapter,
	Multi = false,
	Callback = function(parameter)
		State.LobbyChapter = parameter
		State.JoinRequested = false
		queueConfigSave()
	end
})
lobbyTab:Button({
	Title = "Refresh Maps",
	Callback = function()
		local runtimeValue4 = getChapters(State.LobbyMode)
		if not table.find(runtimeValue4, State.LobbyChapter) then
			State.LobbyChapter = runtimeValue4[1] or ""
		end
		pcall(function()
			runtimeValue30:Refresh(runtimeValue4)
		end)
		pcall(function()
			runtimeValue30:Select(State.LobbyChapter)
		end)
		queueConfigSave()
	end
})
lobbyTab:Toggle({
	Title = "Auto Join & Start",
	Value = State.AutoJoinMap,
	Callback = function(parameter)
		State.AutoJoinMap = parameter == true
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
	Callback = function(parameter)
		State.LobbyModifiers = normalizeModifiers(parameter)
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
	Callback = function(parameter)
		State.KnockMethod = parameter == "TP" and "TP" or "Walk"
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
	Callback = function(parameter)
		Hub.SetAutoKnock(parameter)
		queueConfigSave()
	end
})
matchTab:Section({
	Title = "Wave"
})
matchTab:Toggle({
	Title = "Auto Ready Up",
	Value = State.AutoReady,
	Callback = function(parameter)
		State.AutoReady = parameter == true
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
	Callback = function(parameter)
		State.ReadyDelay = math.clamp(tonumber(parameter) or 1, 0.1, 10)
		queueConfigSave()
	end
})
matchTab:Toggle({
	Title = "Auto Skip Waves",
	Value = State.AutoSkip,
	Callback = function(parameter)
		State.AutoSkip = parameter == true
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
	Callback = function(parameter)
		State.SkipDelay = math.clamp(tonumber(parameter) or 0.35, 0.1, 10)
		queueConfigSave()
	end
})
matchTab:Input({
	Title = "Stop Auto Skip At",
	Placeholder = "5, 10, 15",
	Value = State.StopAutoSkipAt,
	Callback = function(parameter)
		State.StopAutoSkipAt = tostring(parameter or "")
		queueConfigSave()
	end
})
matchTab:Toggle({
	Title = "Auto Speed Scale",
	Value = State.AutoSpeed,
	Callback = function(parameter)
		State.AutoSpeed = parameter == true
		queueConfigSave()
	end
})
matchTab:Toggle({
	Title = "Auto Max Speed",
	Desc = "Use the highest available speed.",
	Value = State.AutoMaxSpeed,
	Callback = function(parameter)
		State.AutoMaxSpeed = parameter == true
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
	Callback = function(parameter)
		local runtimeValue4 = tonumber(tostring(parameter):match("%d+")) or 1
		State.Speed = math.clamp(runtimeValue4, 1, 6)
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
	Callback = function(parameter)
		State.SpeedScaleDelay = math.clamp(tonumber(parameter) or 1, 1, 30)
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
	Callback = function(parameter)
		State.AutoBackLobby = parameter == true
		queueConfigSave()
		updateMatchCounter()
	end
})
matchTab:Input({
	Title = "Matches Before Lobby",
	Placeholder = "5",
	Value = tostring(State.MatchesBeforeLobby),
	Callback = function(parameter)
		local num = tonumber(tostring(parameter):match("%d+"))
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
	Callback = function(parameter)
		State.AfterMatch = parameter
		State.AutoReplay = parameter == "Replay"
		queueConfigSave()
	end
})
matchTab:Toggle({
	Title = "Auto Vote Skip Cutscene",
	Value = State.AutoSkipCutscene,
	Callback = function(parameter)
		State.AutoSkipCutscene = parameter == true
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
	Callback = function(parameter)
		State.WebhookURL = tostring(parameter or "")
		queueConfigSave()
	end
})
webhookTab:Toggle({
	Title = "Enable Webhook",
	Value = State.WebhookEnabled,
	Callback = function(parameter)
		State.WebhookEnabled = parameter == true
		queueConfigSave()
	end
})
webhookTab:Toggle({
	Title = "Notify On Match End",
	Value = State.WebhookMatchEnd,
	Callback = function(parameter)
		State.WebhookMatchEnd = parameter == true
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
	Callback = function(parameter)
		State.KnockWebhookEnabled = parameter == true
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
local runtimeValue32 = savedConfig.NewProfileName or ""
local _ = macrosTab:Input({
	Title = "Create Macro",
	Placeholder = "Macro name",
	Value = runtimeValue32,
	Callback = function(parameter)
		runtimeValue32 = sanitizeProfileName(parameter)
		savedConfig.NewProfileName = runtimeValue32
		queueConfigSave()
	end
})
local runtimeValue33 = listProfiles()
if # runtimeValue33 == 0 then
	runtimeValue33 = {
		"(none)"
	}
end
local runtimeValue34 = State.ProfileName ~= "" and State.ProfileName or runtimeValue33[1]
local runtimeValue35
local function refreshMacroProfiles(parameter)
	local runtimeValue4 = listProfiles()
	if # runtimeValue4 == 0 then
		runtimeValue4 = {
			"(none)"
		}
	end
	pcall(function()
		runtimeValue35:Refresh(runtimeValue4)
	end)
	if parameter and parameter ~= "" then
		pcall(function()
			runtimeValue35:Select(parameter)
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
		local runtimeValue4 = sanitizeProfileName(runtimeValue32)
		if runtimeValue4 == "" then
			notifyUser("Create Macro", "Enter a macro name first")
			return
		end
		if hasFileApi and isfile(profilePath(runtimeValue4)) then
			notifyUser("Create Macro", "That macro already exists")
			return
		end
		local actions, profileName, macroLoadout = State.Actions, State.ProfileName, State.MacroLoadout
		State.Actions, State.ProfileName, State.MacroLoadout = {}, runtimeValue4, nil
		local value, value1 = saveProfile(runtimeValue4)
		if not value then
			State.Actions, State.ProfileName, State.MacroLoadout = actions, profileName, macroLoadout
			notifyUser("Create failed", tostring(value1))
			return
		end
		refreshMacroProfiles(runtimeValue4)
		updateActionSummary()
		setStatus("Created", runtimeValue4 .. " is ready to record")
		queueConfigSave()
	end
})
runtimeValue35 = macrosTab:Dropdown({
	Title = "Select Macro",
	Values = runtimeValue33,
	Value = runtimeValue34,
	Multi = false,
	Callback = function(parameter)
		if parameter == "(none)" then
			return
		end
		local value, value1 = loadProfile(parameter)
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
			local runtimeValue4 = profilePath(profileName)
			local runtimeValue5 = MACRO_FOLDER .. "/Deleted"
			if not isfolder(runtimeValue5) then
				makefolder(runtimeValue5)
			end
			writefile(runtimeValue5 .. "/" .. sanitizeProfileName(profileName) .. "_" .. os.time() .. ".json", readfile(runtimeValue4))
			delfile(runtimeValue4)
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
	Callback = function(parameter)
		State.PlaybackMode = parameter
		queueConfigSave()
	end
})
local stateFlag6 = false
local runtimeValue36
local runtimeValue37
local function setToggleValue(parameter, parameter2)
	if not parameter then
		return
	end
	stateFlag6 = true
	pcall(function()
		parameter:Set(parameter2)
	end)
	stateFlag6 = false
end
UI.SetRecordToggle = function(parameter)
	setToggleValue(runtimeValue36, parameter)
end
UI.SetPlaybackToggle = function(parameter)
	setToggleValue(runtimeValue37, parameter)
end
runtimeValue36 = macrosTab:Toggle({
	Title = "Record",
	Value = false,
	Callback = function(parameter)
		if stateFlag6 then
			return
		end
		if parameter then
			if State.PlaybackEnabled then
				setToggleValue(runtimeValue37, false)
				State.PlaybackEnabled = false
				queueConfigSave()
			end
			if State.Playing then
				stopPlayback("Stopped to begin recording")
			end
			local runtimeValue4 = State.ProfileName ~= "" and State.ProfileName or runtimeValue32
			local value, value1 = startRecording(runtimeValue4)
			if not value then
				setToggleValue(runtimeValue36, false)
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
UI.RecordToggle = runtimeValue36
runtimeValue37 = macrosTab:Toggle({
	Title = "Auto Playback Every Match",
	Value = State.PlaybackEnabled,
	Callback = function(parameter)
		if stateFlag6 then
			return
		end
		State.PlaybackEnabled = parameter == true
		queueConfigSave()
		if parameter then
			if State.Recording then
				setToggleValue(runtimeValue36, false)
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
	local dataTable5 = {
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
		Notify = function(parameter)
			notifyUser("Macro", tostring(parameter))
		end,
		Refresh = function(parameter)
			refreshMacroProfiles(parameter)
			updateActionSummary()
			queueConfigSave()
		end,
		Validate = function(parameter)
			if parameter.Universe ~= nil and parameter.Universe ~= game.GameId then
				return false, "Wrong game"
			end
			for _, item in ipairs(parameter.Actions) do
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
		Legacy = function(parameter)
			return parameter.Game == nil and type(parameter.Version) == "number" and parameter.Version >= 1 and parameter.Version <= 6
		end
	}
	assert(type(dataTable5.Load) == "function" and type(dataTable5.Path) == "function" and type(dataTable5.Clean) == "function", "Macro import adapter unavailable")
	local dataTable6 = {}
	local function utilityRoutine20(parameter)
		if type(parameter) ~= "string" then
			return nil, "Paste macro JSON or a Discord file link"
		end
		parameter = parameter:match("^%s*(.-)%s*$")
		if parameter:sub(1, 3) == "```" then
			parameter = parameter:sub(4):gsub("%s*```$", ""):gsub("^[jJ][sS][oO][nN]%s+", ""):match("^%s*(.-)%s*$")
		end
		if parameter == "" then
			return nil, "Paste macro JSON or a Discord file link"
		end
		local runtimeValue4 = parameter:match("^https?://") ~= nil
		if runtimeValue4 then
			if # parameter > 4096 or parameter:find("[%s%c<>\\]") then
				return nil, "Paste one complete Discord file link"
			end
			local value, value1 = parameter:match("^https://([^/%?#]+)(/[^#]*)$")
			if not value or not (value:lower() == "cdn.discordapp.com" or value:lower() == "media.discordapp.net") or not value1:match("^/attachments/%d+/%d+/[^%?#]+") then
				return nil, "Use the Discord file link, not a message or Copy Link page URL"
			end
			local runtimeValue5 = type(request) == "function" and request or type(http_request) == "function" and http_request or type(syn) == "table" and type(syn.request) == "function" and syn.request or type(http) == "table" and type(http.request) == "function" and http.request
			local ok2, result2, result22 = pcall(function()
				if runtimeValue5 then
					local runtimeValue6 = runtimeValue5({
						Url = parameter,
						Method = "GET",
						Headers = {
							Accept = "application/json"
						},
						Redirect = false
					})
					assert(type(runtimeValue6) == "table", "Invalid HTTP response")
					local num = tonumber(runtimeValue6.StatusCode or runtimeValue6.Status)
					if num == 403 or num == 404 then
						return nil, "Link expired or unavailable; copy a fresh file link from Discord"
					end
					if num and (num < 200 or num >= 300) then
						return nil, "Download failed (HTTP " .. num .. ")"
					end
					return runtimeValue6.Body or runtimeValue6.body
				end
				return game:HttpGet(parameter)
			end)
			if not ok2 then
				return nil, "Cannot download macro; check the link, network and executor HTTP support"
			end
			if type(result2) ~= "string" or result2 == "" then
				return nil, result22 or "Link expired or unavailable; copy a fresh file link from Discord"
			end
			parameter = result2
		end
		if # parameter > 200 * 1024 then
			return nil, "Macro exceeds 200 KB"
		end
		parameter = parameter:gsub("^\239\187\191", "")
		return parameter, runtimeValue4
	end
	local function utilityRoutine21()
		local dataTable = {}
		for _, item in ipairs(dataTable5.StateTables) do
			local dataTable2 = {}
			for index, item3 in pairs(item) do
				dataTable2[index] = item3
			end
			dataTable[# dataTable + 1] = {
				State = item,
				Copy = dataTable2
			}
		end
		return function()
			for _, item4 in ipairs(dataTable) do
				for index2 in pairs(item4.State) do
					item4.State[index2] = nil
				end
				for index4, item5 in pairs(item4.Copy) do
					item4.State[index4] = item5
				end
			end
		end
	end
	local function utilityRoutine22(parameter, parameter2)
		assert(parameter2 < 40, "Macro nesting is too deep")
		if type(parameter) == "number" then
			assert(parameter == parameter and math.abs(parameter) < math.huge, "Invalid macro number")
		end
		if type(parameter) ~= "table" then
			return parameter
		end
		local dataTable = {}
		for index, item in pairs(parameter) do
			local runtimeValue4 = type(index) == "string" and (index:lower() == "owneruserid" or index:lower() == "ownerid")
			if not runtimeValue4 then
				dataTable[index] = utilityRoutine22(item, parameter2 + 1)
			end
		end
		return dataTable
	end
	function dataTable6.Import(parameter, parameter2)
		if dataTable6.Busy or dataTable6.Fetching or dataTable5.Busy() then
			return false, "Stop recording and Auto Playback before importing"
		end
		if not dataTable5.FS() or type(delfile) ~= "function" then
			return false, "File read/write/delete APIs required"
		end
		dataTable6.Fetching = true
		local value, value1 = utilityRoutine20(parameter)
		dataTable6.Fetching = false
		if not value then
			return false, value1
		end
		if dataTable6.Busy or dataTable5.Busy() then
			return false, "Stop recording and Auto Playback before importing"
		end
		parameter = value
		local ok2, result2 = pcall(dataTable5.HTTP.JSONDecode, dataTable5.HTTP, parameter)
		if not ok2 or type(result2) ~= "table" then
			return false, value1 and "Link did not return macro JSON; copy a fresh Discord file link" or "Invalid JSON; paste the complete macro file"
		end
		if not table.find(dataTable5.Games, result2.Game) and not (dataTable5.Legacy and dataTable5.Legacy(result2)) then
			return false, "This macro belongs to another game"
		end
		if type(result2.Actions) ~= "table" or # result2.Actions == 0 or # result2.Actions > 50000 then
			return false, "Invalid macro actions"
		end
		local count = 0
		for index, item in pairs(result2.Actions) do
			count = count + 1
			if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > # result2.Actions or type(item) ~= "table" or not table.find(dataTable5.Kinds, item[dataTable5.KindKey]) then
				return false, "Invalid macro action"
			end
			for _, item3 in ipairs({
				"Time",
				"At",
				"Wave",
				"WaveAt",
				"WaveTime"
			}) do
				local runtimeValue4 = item[item3]
				if runtimeValue4 ~= nil and (type(runtimeValue4) ~= "number" or runtimeValue4 ~= runtimeValue4 or runtimeValue4 < 0 or runtimeValue4 == math.huge) then
					return false, "Invalid action " .. item3
				end
			end
		end
		if count ~= # result2.Actions then
			return false, "Macro actions must be a list"
		end
		ok2, result2 = pcall(utilityRoutine22, result2, 0)
		if not ok2 then
			return false, tostring(result2)
		end
		if dataTable5.Validate then
			local ok3, result3, result22 = pcall(dataTable5.Validate, result2)
			if not ok3 or not result3 then
				return false, ok3 and (result22 or "Invalid macro data") or "Invalid macro data"
			end
		end
		parameter2 = tostring(parameter2 or ""):match("^%s*(.-)%s*$")
		if parameter2 == "" then
			parameter2 = type(result2.Name) == "string" and result2.Name or type(result2.Profile) == "string" and result2.Profile or "Imported Macro"
		end
		parameter2 = dataTable5.Clean(parameter2)
		local lowered = parameter2:lower()
		if parameter2 == "" or lowered == "settings" or lowered == "hubconfig" or lowered == "playback_debug" or lowered:match("_config$") then
			return false, "Enter another macro name"
		end
		local runtimeValue5 = dataTable5.Path(parameter2)
		if not runtimeValue5 then
			return false, "Invalid macro name"
		end
		local ok4, result4 = pcall(isfile, runtimeValue5)
		if not ok4 then
			return false, "Cannot check existing macro files"
		end
		if result4 then
			return false, "Macro name already exists; choose another name"
		end
		local runtimeValue6 = utilityRoutine21()
		dataTable6.Busy = true
		local ok5, result5 = pcall(function()
			local json = dataTable5.HTTP:JSONEncode(result2)
			writefile(runtimeValue5 .. ".pending", json)
			assert(readfile(runtimeValue5 .. ".pending") == json, "Pending verification failed")
			assert(not isfile(runtimeValue5), "Macro name already exists")
			dataTable6.Created = runtimeValue5
			writefile(runtimeValue5, json)
			assert(readfile(runtimeValue5) == json, "Save verification failed")
			local value2, value12 = dataTable5.Load(parameter2)
			assert(value2, value12 or "Macro failed its game-specific validation")
		end)
		if not ok5 then
			runtimeValue6()
			if dataTable6.Created then
				pcall(delfile, dataTable6.Created)
			end
			dataTable6.Created = nil
			dataTable6.Busy = false
			pcall(delfile, runtimeValue5 .. ".pending")
			return false, "Import failed: " .. tostring(result5)
		end
		dataTable6.Created = nil
		dataTable6.Busy = false
		pcall(delfile, runtimeValue5 .. ".pending")
		return true, parameter2, # result2.Actions
	end
	dataTable5.Owner.MacroImport = dataTable6
	dataTable5.Tab:Section({
		Title = "Import Macro"
	})
	local runtimeValue38, runtimeValue39 = "", ""
	local macroNameInput = dataTable5.Tab:Input({
		Title = "Macro Name",
		Desc = "Enter Any Names You Want",
		Placeholder = "Imported Macro",
		Value = "",
		Callback = function(parameter)
			runtimeValue38 = tostring(parameter or "")
		end
	})
	local macroJSONInput = dataTable5.Tab:Input({
		Title = "Macro JSON",
		Desc = "Paste JSON or a Discord file link.",
		Type = "Textarea",
		ClearTextOnFocus = false,
		Placeholder = "Paste JSON or Discord file link...",
		Value = "",
		Callback = function(parameter)
			runtimeValue39 = tostring(parameter or "")
		end
	})
	dataTable5.Tab:Button({
		Title = "Import Macro",
		Icon = "download",
		Callback = function()
			local value, value1, value2 = dataTable6.Import(runtimeValue39, runtimeValue38)
			if not value then
				dataTable5.Notify(value1)
				return
			end
			runtimeValue38 = value1
			runtimeValue39 = ""
			macroNameInput:Set(value1)
			macroJSONInput:Set("")
			local ok2, _ = pcall(dataTable5.Refresh, value1)
			dataTable5.Notify("Imported " .. value1 .. " (" .. tostring(value2) .. " actions)" .. (not ok2 and "; reopen Select Macro to refresh" or ""))
		end
	})
end
UI.PlayToggle = runtimeValue37
do
	local runtimeValue40, runtimeValue41, runtimeValue42 = Hub, State, LocalPlayer
	local runtimeValue43 = type(getgenv) == "function" and getgenv() or _G
	local text3 = "__KeroHideUser_Skibidi_Defense_Hub"
	local runtimeValue44 = runtimeValue43[text3]
	if runtimeValue44 and type(runtimeValue44.Destroy) == "function" then
		pcall(runtimeValue44.Destroy)
	end
	local dataTable7 = {
		Alive = true,
		Enabled = false,
		Saved = {},
		Generation = 0
	}
	runtimeValue40.HideUserController = dataTable7
	runtimeValue43[text3] = dataTable7
	dataTable7.ImageSaved = {}
	dataTable7.ImageWatches = {}
	dataTable7.ImageConnections = {}
	local function utilityRoutine23()
		for _, item in ipairs(dataTable7.ImageConnections) do
			pcall(item.Disconnect, item)
		end
		for _, item3 in pairs(dataTable7.ImageWatches) do
			for _, item4 in ipairs(item3) do
				pcall(item4.Disconnect, item4)
			end
		end
		dataTable7.ImageConnections = {}
		dataTable7.ImageWatches = {}
		for index, item5 in pairs(dataTable7.ImageSaved) do
			pcall(function()
				index.ImageTransparency = item5
			end)
		end
		dataTable7.ImageSaved = {}
	end
	local function utilityRoutine24(parameter)
		local runtimeValue4 = dataTable7.PlayerNames or {}
		local parent = parameter.Parent
		for _ = 1, 2 do
			if not parent then
				break
			end
			if runtimeValue4[parent.Name] then
				return true
			end
			for _, item in ipairs(parent:GetChildren()) do
				if item:IsA("TextLabel") or item:IsA("TextButton") then
					local runtimeValue5 = item.Name:lower():gsub("[^%a]", "")
					if runtimeValue5 == "username" or runtimeValue5 == "displayname" or runtimeValue5 == "playername" or runtimeValue5 == "name" or runtimeValue5 == "namelabel" then
						local matched2 = tostring(item.Text):gsub("<[^>]+>", ""):match("^%s*(.-)%s*$")
						if runtimeValue4[matched2] or runtimeValue41.HideName and matched2 == "Player" then
							return true
						end
					end
				end
			end
			parent = parent.Parent
		end
		return false
	end
	local function utilityRoutine25(parameter)
		local runtimeValue4 = ""
		pcall(function()
			runtimeValue4 = tostring(parameter.Image):lower()
		end)
		if runtimeValue4:find("rbxthumb://", 1, true) and (runtimeValue4:find("type=avatar", 1, true) or runtimeValue4:find("type=headshot", 1, true)) then
			return true
		end
		if runtimeValue4:find("headshot%-thumbnail") or runtimeValue4:find("avatar%-thumbnail") or runtimeValue4:find("avatar%.ashx") or runtimeValue4:find("headshot%.ashx") or runtimeValue4:find("thumbnails.roblox.com/v1/users/", 1, true) then
			return true
		end
		local runtimeValue5 = parameter.Name:lower():gsub("[^%a]", "")
		if runtimeValue5:find("avatar", 1, true) or runtimeValue5:find("headshot", 1, true) or runtimeValue5:find("portrait", 1, true) or runtimeValue5 == "playericon" or runtimeValue5 == "playerimage" or runtimeValue5 == "profilepicture" then
			return true
		end
		return utilityRoutine24(parameter)
	end
	local function utilityRoutine26()
		utilityRoutine23()
		if not dataTable7.Alive or not dataTable7.Enabled then
			return
		end
		dataTable7.PlayerNames = {}
		local function utilityRoutine(parameter)
			if parameter.Name then
				dataTable7.PlayerNames[parameter.Name] = true
			end
			if parameter.DisplayName then
				dataTable7.PlayerNames[parameter.DisplayName] = true
			end
			if parameter.UserId then
				dataTable7.PlayerNames[tostring(parameter.UserId)] = true
			end
		end
		utilityRoutine(runtimeValue42)
		local runtimeValue4
		pcall(function()
			runtimeValue4 = game:GetService("Players")
			for _, item in ipairs(runtimeValue4:GetPlayers()) do
				utilityRoutine(item)
			end
		end)
		local dataTable = setmetatable({}, {
			__mode = "k"
		})
		local function utilityRoutine2(parameter)
			if not dataTable7.Alive or not dataTable7.Enabled or dataTable[parameter] then
				return
			end
			if not (parameter:IsA("ImageLabel") or parameter:IsA("ImageButton") or parameter:IsA("ViewportFrame")) then
				return
			end
			local runtimeValue5 = utilityRoutine25(parameter)
			if runtimeValue5 then
				if dataTable7.ImageSaved[parameter] == nil then
					dataTable7.ImageSaved[parameter] = parameter.ImageTransparency
				end
				dataTable[parameter] = true
				parameter.ImageTransparency = 1
				dataTable[parameter] = nil
			elseif dataTable7.ImageSaved[parameter] ~= nil then
				local runtimeValue6 = dataTable7.ImageSaved[parameter]
				dataTable7.ImageSaved[parameter] = nil
				dataTable[parameter] = true
				parameter.ImageTransparency = runtimeValue6
				dataTable[parameter] = nil
			end
		end
		local function utilityRoutine3(parameter)
			local parent = parameter.Parent
			if not parent then
				return
			end
			for index in pairs(dataTable7.ImageWatches) do
				if index.Parent == parent or index.Parent and index.Parent.Parent == parent then
					pcall(utilityRoutine2, index)
				end
			end
		end
		local function utilityRoutine27(parameter)
			if dataTable7.ImageWatches[parameter] then
				pcall(utilityRoutine2, parameter)
				return
			end
			local runtimeValue5 = parameter:IsA("ImageLabel") or parameter:IsA("ImageButton") or parameter:IsA("ViewportFrame")
			local runtimeValue6 = parameter.Name:lower():gsub("[^%a]", "")
			local runtimeValue7 = (parameter:IsA("TextLabel") or parameter:IsA("TextButton")) and (runtimeValue6 == "username" or runtimeValue6 == "displayname" or runtimeValue6 == "playername" or runtimeValue6 == "name" or runtimeValue6 == "namelabel")
			if not runtimeValue5 and not runtimeValue7 then
				return
			end
			local dataTable2 = {}
			dataTable7.ImageWatches[parameter] = dataTable2
			local function utilityRoutine28(parameter2, parameter3)
				local ok2, result2 = pcall(function()
					return parameter:GetPropertyChangedSignal(parameter2):Connect(parameter3)
				end)
				if ok2 then
					dataTable2[# dataTable2 + 1] = result2
				end
			end
			if runtimeValue5 then
				utilityRoutine28("Image", function()
					pcall(utilityRoutine2, parameter)
				end)
				utilityRoutine28("Name", function()
					pcall(utilityRoutine2, parameter)
				end)
				if parameter.AncestryChanged then
					dataTable2[# dataTable2 + 1] = parameter.AncestryChanged:Connect(function()
						pcall(utilityRoutine2, parameter)
					end)
				end
				utilityRoutine28("ImageTransparency", function()
					if dataTable[parameter] or not dataTable7.Enabled then
						return
					end
					if dataTable7.ImageSaved[parameter] ~= nil then
						dataTable7.ImageSaved[parameter] = parameter.ImageTransparency
					end
					pcall(utilityRoutine2, parameter)
				end)
				pcall(utilityRoutine2, parameter)
			else
				utilityRoutine28("Text", function()
					utilityRoutine3(parameter)
				end)
				utilityRoutine3(parameter)
			end
			if parameter.Destroying then
				dataTable2[# dataTable2 + 1] = parameter.Destroying:Connect(function()
					for _, item in ipairs(dataTable2) do
						pcall(item.Disconnect, item)
					end
					dataTable7.ImageWatches[parameter] = nil
					dataTable7.ImageSaved[parameter] = nil
				end)
			end
		end
		local dataTable3 = {}
		pcall(function()
			local playerGui = runtimeValue42:FindFirstChildOfClass("PlayerGui")
			if playerGui then
				dataTable3[# dataTable3 + 1] = playerGui
			end
		end)
		for _, item3 in ipairs({
			"CoreGui",
			"Workspace"
		}) do
			pcall(function()
				dataTable3[# dataTable3 + 1] = game:GetService(item3)
			end)
		end
		local function utilityRoutine29(parameter)
			if parameter.DescendantAdded then
				dataTable7.ImageConnections[# dataTable7.ImageConnections + 1] = parameter.DescendantAdded:Connect(function(parameter2)
					task.defer(function()
						if dataTable7.Alive and dataTable7.Enabled then
							pcall(utilityRoutine27, parameter2)
						end
					end)
				end)
			end
			local ok2, result2 = pcall(parameter.GetDescendants, parameter)
			if ok2 then
				for _, item in ipairs(result2) do
					pcall(utilityRoutine27, item)
				end
			end
		end
		for _, item4 in ipairs(dataTable3) do
			utilityRoutine29(item4)
		end
		if runtimeValue42.ChildAdded then
			dataTable7.ImageConnections[# dataTable7.ImageConnections + 1] = runtimeValue42.ChildAdded:Connect(function(parameter)
				if dataTable7.Alive and dataTable7.Enabled and parameter:IsA("PlayerGui") then
					utilityRoutine29(parameter)
				end
			end)
		end
		if runtimeValue4 and runtimeValue4.PlayerAdded then
			dataTable7.ImageConnections[# dataTable7.ImageConnections + 1] = runtimeValue4.PlayerAdded:Connect(function(parameter)
				utilityRoutine(parameter)
				for index in pairs(dataTable7.ImageWatches) do
					pcall(utilityRoutine2, index)
				end
			end)
		end
	end
	local function utilityRoutine30()
		for index, item in pairs(dataTable7.Saved) do
			for index2, item3 in pairs(item) do
				pcall(function()
					index[index2] = item3
				end)
			end
		end
		dataTable7.Saved = {}
	end
	local function utilityRoutine31(parameter)
		dataTable7.Generation = dataTable7.Generation + 1
		local generation = dataTable7.Generation
		if dataTable7.Descendants then
			dataTable7.Descendants:Disconnect()
			dataTable7.Descendants = nil
		end
		utilityRoutine30()
		dataTable7.Character = parameter
		if not dataTable7.Alive or not dataTable7.Enabled or not parameter then
			return
		end
		local color = Color3.fromRGB(255, 0, 0)
		local function utilityRoutine(parameter2)
			if dataTable7.Saved[parameter2] or not parameter2:IsDescendantOf(parameter) then
				return
			end
			local runtimeValue4
			if parameter2:IsA("Accessory") or parameter2:IsA("Shirt") or parameter2:IsA("Pants") or parameter2:IsA("ShirtGraphic") or parameter2:IsA("CharacterMesh") then
				runtimeValue4 = {
					Parent = false
				}
			elseif parameter2:IsA("BasePart") and parameter2.Parent == parameter and parameter2.Name ~= "HumanoidRootPart" then
				runtimeValue4 = {
					Color = color
				}
				if parameter2:IsA("MeshPart") then
					runtimeValue4.TextureID = ""
				end
			elseif parameter2:IsA("BodyColors") then
				runtimeValue4 = {}
				for _, item in ipairs({
					"HeadColor3",
					"TorsoColor3",
					"LeftArmColor3",
					"RightArmColor3",
					"LeftLegColor3",
					"RightLegColor3"
				}) do
					runtimeValue4[item] = color
				end
			elseif parameter2:IsA("SpecialMesh") and parameter2.Parent and parameter2.Parent.Parent == parameter then
				runtimeValue4 = {
					TextureId = ""
				}
			elseif parameter2:IsA("SurfaceAppearance") and parameter2.Parent and parameter2.Parent.Parent == parameter then
				runtimeValue4 = {
					Parent = false
				}
			end
			if runtimeValue4 then
				local dataTable = {}
				dataTable7.Saved[parameter2] = dataTable
				for index, item3 in pairs(runtimeValue4) do
					pcall(function()
						dataTable[index] = parameter2[index]
						if index == "Parent" then
							parameter2.Parent = nil
						else
							parameter2[index] = item3
						end
					end)
				end
			end
		end
		dataTable7.Descendants = parameter.DescendantAdded:Connect(function(parameter2)
			task.defer(function()
				if dataTable7.Alive and dataTable7.Enabled and generation == dataTable7.Generation then
					pcall(utilityRoutine, parameter2)
				end
			end)
		end)
		for _, item4 in ipairs(parameter:GetDescendants()) do
			pcall(utilityRoutine, item4)
		end
	end
	function dataTable7.Set(parameter)
		if not dataTable7.Alive then
			return
		end
		parameter = parameter == true
		runtimeValue41.HideUser = parameter
		if dataTable7.Enabled == parameter and (not parameter or dataTable7.Character == runtimeValue42.Character) then
			return
		end
		dataTable7.Enabled = parameter
		utilityRoutine31(parameter and runtimeValue42.Character or nil)
		utilityRoutine26()
	end
	function dataTable7.Destroy()
		if not dataTable7.Alive then
			return
		end
		dataTable7.Alive = false
		dataTable7.Enabled = false
		utilityRoutine31(nil)
		utilityRoutine23()
		if dataTable7.Respawn then
			dataTable7.Respawn:Disconnect()
			dataTable7.Respawn = nil
		end
		if runtimeValue43[text3] == dataTable7 then
			runtimeValue43[text3] = nil
		end
	end
	dataTable7.Respawn = runtimeValue42.CharacterAdded:Connect(function(parameter)
		if dataTable7.Alive and dataTable7.Enabled then
			utilityRoutine31(parameter)
		end
	end)
	function runtimeValue40.SetHideUser(parameter)
		dataTable7.Set(parameter)
	end
	if Window and type(Window.OnDestroy) == "function" then
		pcall(function()
			Window:OnDestroy(dataTable7.Destroy)
		end)
	end
	dataTable7.Set(runtimeValue41.HideUser)
end
-- Settings and privacy controls
miscTab:Section({
	Title = "Automation"
})
miscTab:Toggle({
	Title = "Auto Execute",
	Desc = "Reload after teleport.",
	Value = State.AutoExecute,
	Callback = function(parameter)
		State.AutoExecute = parameter == true
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
	Callback = function(parameter)
		State.HideName = parameter == true
		Hub.SetHideName(State.HideName)
		queueConfigSave()
	end
})
miscTab:Toggle({
	Title = "Hide User",
	Desc = "Hide your character locally.",
	Value = State.HideUser,
	Callback = function(parameter)
		Hub.SetHideUser(parameter)
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
	Callback = function(parameter)
		State.FPSBoost = parameter == true
		Hub.SetFPSBoost(State.FPSBoost)
		queueConfigSave()
	end
})
miscTab:Toggle({
	Title = "Anti-AFK",
	Value = State.AntiAFK,
	Callback = function(parameter)
		State.AntiAFK = parameter == true
		queueConfigSave()
	end
})
if State.ProfileName ~= "" then
	local runtimeValue45 = loadProfile(State.ProfileName)
	if not runtimeValue45 then
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
