--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

--// Flags & Keybinds
local autoDiveEnabled = false
local autoRecEnabled = false
local holdModeEnabled = false
local infStaminaEnabled = false
local holdDiveKey, holdRecKey, toggleUIKey = nil, nil, nil

--// Cleanup old GUI
if gui:FindFirstChild("KLXUI") then gui.KLXUI:Destroy() end
local screen = Instance.new("ScreenGui", gui)
screen.Name = "KLXUI"
screen.ResetOnSpawn = false

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0, 270, 0, 460)
frame.Position = UDim2.new(0.5, -135, 0.5, -230)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

--// Top Bar
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1, 0, 0, 32)
top.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

local underline = Instance.new("Frame", top)
underline.Size = UDim2.new(1, 0, 0, 2)
underline.Position = UDim2.new(0, 0, 1, -1)
underline.BackgroundColor3 = Color3.fromRGB(0, 255, 150)

local title = Instance.new("TextLabel", top)
title.Text = "J Hub"
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

--// Drag functionality
local dragging, dragStart, startPos
top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

--// Layout
local layout = Instance.new("UIListLayout", frame)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
top.LayoutOrder = 0

--// Helpers
local function withPadding(instance)
	local wrapper = Instance.new("Frame")
	wrapper.BackgroundTransparency = 1
	wrapper.Size = UDim2.new(1, 0, 0, 40)
	instance.Position = UDim2.new(0.5, 0, 0.5, 0)
	instance.AnchorPoint = Vector2.new(0.5, 0.5)
	instance.Size = UDim2.new(0.9, 0, 0.9, 0)
	instance.Parent = wrapper
	return wrapper
end

local function makeSectionTitle(text)
	local wrapper = Instance.new("Frame")
	wrapper.Size = UDim2.new(1, 0, 0, 26)
	wrapper.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", wrapper)
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Position = UDim2.new(0.5, 0, 0, 0)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Text = text
	label.TextColor3 = Color3.fromRGB(0, 255, 150)
	label.TextXAlignment = Enum.TextXAlignment.Center

	local underline = Instance.new("Frame", wrapper)
	underline.Size = UDim2.new(0.4, 0, 0, 2)
	underline.Position = UDim2.new(0.5, 0, 1, -2)
	underline.AnchorPoint = Vector2.new(0.5, 0)
	underline.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
	underline.BorderSizePixel = 0

	return wrapper
end

local function makeToggle(text, callback)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 14
	button.Text = text .. ": OFF"
	button.AutoButtonColor = false
	button.Size = UDim2.new(1, 0, 1, 0)
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

	local state = false
	button.MouseButton1Click:Connect(function()
		state = not state
		button.Text = text .. ": " .. (state and "ON" or "OFF")
		button.BackgroundColor3 = state and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(45, 45, 45)
		button.TextColor3 = state and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
		callback(state, button)
	end)

	return withPadding(button)
end

local function makeKeyPicker(text, assign)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 14
	btn.Text = text .. ": None"
	btn.AutoButtonColor = false
	btn.Size = UDim2.new(1, 0, 1, 0)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Click:Connect(function()
		btn.Text = text .. ": ..."
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				assign(input.KeyCode)
				btn.Text = text .. ": " .. input.KeyCode.Name
				conn:Disconnect()
			end
		end)
	end)

	return withPadding(btn)
end

--// Control Constants
local LEFT_CONSTANTS = {
	DIVE_RADIUS = 16,
	MOVE_RADIUS = 16,
	CLICK_RADIUS = 8,
	CLICK_RADIUS_BEHIND = 8,
	SPEED_THRESHOLD = 50,
	MAX_BALL_DISTANCE = 40
}

local RIGHT_CONSTANTS = {
	MOVE_RADIUS = 30,
	CLICK_RADIUS = 25,
	CLICK_RADIUS_BEHIND = 30,
	SPEED_THRESHOLD = 50,
	MAX_BALL_DISTANCE = 50
}

--// Character refs
local character, humanoid, rootPart
local function UpdateCharacterRefs()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:FindFirstChildOfClass("Humanoid")
	rootPart = character:FindFirstChild("HumanoidRootPart")
end
UpdateCharacterRefs()
player.CharacterAdded:Connect(function()
	task.wait(0.5)
	UpdateCharacterRefs()
end)

-- Helpers to call CharacterActions functions
local function GetCharacterActions()
	local charScript = character and character:FindFirstChild("CharacterScript")
	if not charScript then return nil end
	local success, actions = pcall(function() return require(charScript:WaitForChild("CharacterActions")) end)
	if success and type(actions) == "table" then
		return actions
	end
	return nil
end

local function SafeDive()
	local actions = GetCharacterActions()
	if actions and typeof(actions.Dive) == "function" then
		-- call method style
		pcall(function() actions:Dive() end)
	end
end

local function SafeBump()
	local actions = GetCharacterActions()
	if actions and typeof(actions.Bump) == "function" then
		pcall(function() actions:Bump() end)
	end
end

-- Predict landing (solve y(t)=0). returns Vector3 landing (y = 0)
local function PredictLandingPosition(pos, vel)
	local g = workspace.Gravity or 196.2 -- default fallback
	-- Solve 0 = pos.y + vel.y * t - 0.5 * g * t^2
	-- => 0.5*g*t^2 - vel.y * t - pos.y = 0
	if pos.Y <= 0 then
		return Vector3.new(pos.X, 0, pos.Z)
	end
	local a = 0.5 * g
	local b = -vel.Y
	local c = -pos.Y
	local disc = b*b - 4*a*c
	if disc < 0 then return Vector3.new(pos.X, 0, pos.Z) end
	local t = (-b + math.sqrt(disc)) / (2*a) -- positive root
	if not t or t <= 0 then return Vector3.new(pos.X, 0, pos.Z) end
	local landing = pos + vel * t
	return Vector3.new(landing.X, 0, landing.Z)
end

local function IsBallComingAtMe(ballPos, velocity)
	if not rootPart then return false end
	if velocity.Magnitude < 1 then return false end
	local toPlayer = (rootPart.Position - ballPos)
	if toPlayer.Magnitude == 0 then return false end
	local dot = toPlayer.Unit:Dot(velocity.Unit)
	-- positive dot means ball is generally moving toward the player
	return dot > 0.45 -- tunable threshold (0.45 is permissive)
end

local function MoveToPosition(targetPosition)
	if humanoid and rootPart then
		local dir = (targetPosition - rootPart.Position)
		if dir.Magnitude > 0.1 then
			pcall(function() humanoid:Move(dir.Unit, false) end)
		end
	end
end

--// Marker (debug)
local Marker = Instance.new("Part")
Marker.Anchored = true
Marker.CanCollide = false
Marker.Transparency = 0.6
Marker.Shape = Enum.PartType.Ball
Marker.Size = Vector3.new(2, 2, 2)
Marker.Material = Enum.Material.Neon
Marker.BrickColor = BrickColor.new("Bright violet")
Marker.Parent = workspace
Marker.CFrame = CFrame.new(0, -100, 0) -- hide initially

--// Inf Stamina setup (kept from original, but safe)
local successPlayerData, P_dVr_1 = pcall(function() return require(game:GetService("ReplicatedStorage"):WaitForChild("PlayerData")) end)
if successPlayerData then
	repeat task.wait(0.1) until P_dVr_1.DataLoaded
	local infCharacter, infHumanoid, infActions, infState
	local function UpdateInfRefs()
		infCharacter = player.Character or player.CharacterAdded:Wait()
		infHumanoid = infCharacter:FindFirstChildOfClass("Humanoid")
		local ok, actions = pcall(function() return require(infCharacter:WaitForChild("CharacterScript"):WaitForChild("CharacterActions")) end)
		if ok and actions then
			infActions = actions
			infState = actions.State
			if infHumanoid then infHumanoid.JumpPower = 0 end
		end
	end
	pcall(UpdateInfRefs)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		pcall(UpdateInfRefs)
	end)

	RunService.RenderStepped:Connect(function()
		if not infStaminaEnabled then return end
		if not infState then return end

		if infState.Sprinting then
			if infState.Stamina < 1 then
				infState.Stamina = 1
			end
		end

		if infState.Stamina == 0 then
			infState.Stamina = 1
		end
	end)
end

--// GUI Elements (kept UI layout)
local elements = {
	makeSectionTitle("Toggle Modes"),

	makeToggle("Auto Dive", function(v)
		autoDiveEnabled = v
		if v then
			autoRecEnabled = false
			holdModeEnabled = false
		end
	end),

	makeToggle("Auto Receive", function(v)
		autoRecEnabled = v
		if v then
			autoDiveEnabled = false
			holdModeEnabled = false
		end
	end),

	makeToggle("Inf Stamina", function(v)
		infStaminaEnabled = v
	end),

	makeSectionTitle("Hold Mode"),

	makeToggle("Hold Mode", function(v)
		holdModeEnabled = v
		if v then
			autoDiveEnabled = false
			autoRecEnabled = false
		end
	end),

	makeKeyPicker("Hold Dive Key", function(k)
		holdDiveKey = k
	end),

	makeKeyPicker("Hold Rec Key", function(k)
		holdRecKey = k
	end),

	makeKeyPicker("Toggle UI Key", function(k)
		toggleUIKey = k
	end),
}

for _, el in ipairs(elements) do
	el.Parent = frame
end


--// Active control constants
local activeConstants = nil

-- cooldowns to avoid spam
local lastDiveTime = 0
local lastBumpTime = 0
local COOLDOWN_DIVE = 1.2
local COOLDOWN_BUMP = 0.8

-- Helper: find all ball-like objects robustly
local function GetAllBalls()
	local balls = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		-- consider Model named "Ball" or Part named "Ball"
		if (obj:IsA("Model") and obj.Name == "Ball") or (obj:IsA("BasePart") and obj.Name == "Ball") then
			table.insert(balls, obj)
		end
	end
	return balls
end

--// Auto Logic Loop (improved)
RunService:BindToRenderStep("AutoAction", Enum.RenderPriority.Camera.Value, function()
	pcall(function()
		if not character or not rootPart then return end
		if not autoDiveEnabled and not autoRecEnabled and not holdModeEnabled then
			activeConstants = nil
			Marker.CFrame = CFrame.new(0, -100, 0)
			return
		end

		local currentlyHoldingDive = holdModeEnabled and holdDiveKey and UserInputService:IsKeyDown(holdDiveKey)
		local currentlyHoldingRec = holdModeEnabled and holdRecKey and UserInputService:IsKeyDown(holdRecKey)

		if holdModeEnabled then
			if currentlyHoldingDive then
				activeConstants = LEFT_CONSTANTS
			elseif currentlyHoldingRec then
				activeConstants = RIGHT_CONSTANTS
			else
				activeConstants = nil
			end
		else
			if autoDiveEnabled then
				activeConstants = LEFT_CONSTANTS
			elseif autoRecEnabled then
				activeConstants = RIGHT_CONSTANTS
			else
				activeConstants = nil
			end
		end

		if not activeConstants then
			Marker.CFrame = CFrame.new(0, -100, 0)
			return
		end

		local balls = GetAllBalls()
		local bestBall, bestScore, bestLanding = nil, math.huge, nil

		for _, ballModel in ipairs(balls) do
			local ballPart = nil
			local velocityValue = nil
			if ballModel:IsA("Model") then
				ballPart = ballModel:FindFirstChild("BallPart") or ballModel:FindFirstChildWhichIsA("BasePart")
				velocityValue = ballModel:FindFirstChild("Velocity")
			else
				-- it's a part named Ball
				ballPart = ballModel
				velocityValue = ballModel:FindFirstChild("Velocity")
				if not velocityValue and ballModel:FindFirstChildWhichIsA("Vector3Value") then
					velocityValue = ballModel:FindFirstChildWhichIsA("Vector3Value")
				end
			end

			if ballPart and velocityValue and velocityValue:IsA("Vector3Value") then
				local speed = velocityValue.Value.Magnitude
				if speed >= (activeConstants.SPEED_THRESHOLD or 0) then
					local landing = PredictLandingPosition(ballPart.Position, velocityValue.Value)
					local dist = (landing - rootPart.Position).Magnitude
					if dist <= (activeConstants.MAX_BALL_DISTANCE or 9999) then
						-- choose nearest landing point
						if dist < bestScore then
							bestScore = dist
							bestBall = {model = ballModel, part = ballPart, vel = velocityValue.Value}
							bestLanding = landing
						end
					end
				end
			end
		end

		if not bestBall or not bestLanding then
			Marker.CFrame = CFrame.new(0, -100, 0)
			return
		end

		-- place marker for debug
		Marker.CFrame = CFrame.new(bestLanding + Vector3.new(0, 1, 0))

		local distToLanding = (bestLanding - rootPart.Position).Magnitude
		local isBehind = rootPart.CFrame.LookVector:Dot((bestLanding - rootPart.Position).Unit) < 0
		local canClick = (isBehind and distToLanding <= (activeConstants.CLICK_RADIUS_BEHIND or 0)) or
		                 (not isBehind and distToLanding <= (activeConstants.CLICK_RADIUS or 0))

		-- Move if within move radius
		if distToLanding <= (activeConstants.MOVE_RADIUS or 0) then
			MoveToPosition(bestLanding)
		end

		-- RIGHT constants -> Auto Receive (Bump)
		if activeConstants == RIGHT_CONSTANTS and canClick then
			if tick() - lastBumpTime >= COOLDOWN_BUMP then
				lastBumpTime = tick()
				SafeBump()
			end
		-- LEFT constants -> Auto Dive logic
		elseif activeConstants == LEFT_CONSTANTS then
			-- if ball is coming at me and within click radius -> prefer Bump (click)
			if canClick and IsBallComingAtMe(bestBall.part.Position, bestBall.vel) then
				if tick() - lastBumpTime >= COOLDOWN_BUMP then
					lastBumpTime = tick()
					SafeBump()
				end
			end
			-- if within dive radius -> Dive
			if distToLanding <= (activeConstants.DIVE_RADIUS or 0) then
				if tick() - lastDiveTime >= COOLDOWN_DIVE then
					lastDiveTime = tick()
					SafeDive()
				end
			end
		end
	end)
end)

--// ✅ Input Fixed
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- GUI toggle should always work
	if input.KeyCode == toggleUIKey then
		screen.Enabled = not screen.Enabled
	end

	if holdModeEnabled then
		if input.KeyCode == holdDiveKey then
			activeConstants = LEFT_CONSTANTS
		elseif input.KeyCode == holdRecKey then
			activeConstants = RIGHT_CONSTANTS
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if holdModeEnabled then
		if input.KeyCode == holdDiveKey or input.KeyCode == holdRecKey then
			activeConstants = nil
		end
	end
end)

--// Hitbox Adjustment (テキスト入力版)
local hitboxValues = {
    BlockHitBox = 2,
    DiveHitBox = 2,
    RecHitBox = 2,
    TopHitBox = 2,
}

-- プレイヤーパーツ取得
local function getPlayerPart(name)
    local plrModel = game:workspace:FindFirstChild(player.Name)
    if plrModel then
        local part = plrModel:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

-- 入力ボックス作成関数
local function makeHitboxInput(name, default)
    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 40)
    wrapper.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", wrapper)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(0, 255, 150)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name

    local input = Instance.new("TextBox", wrapper)
    input.Size = UDim2.new(0.45, 0, 0.7, 0)
    input.Position = UDim2.new(0.5, 0, 0.15, 0)
    input.Text = tostring(default)
    input.ClearTextOnFocus = false
    input.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.Font = Enum.Font.GothamMedium
    input.TextSize = 14
    input.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    -- 入力完了時に値を更新
    input.FocusLost:Connect(function(enterPressed)
        local value = tonumber(input.Text)
        if value then
            hitboxValues[name] = value
        else
            input.Text = tostring(hitboxValues[name]) -- 無効入力なら元の値に戻す
        end
    end)

    return wrapper
end

-- セクションタイトル作成
local function makeSectionTitle(text)
    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 26)
    wrapper.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", wrapper)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0.5, 0, 0, 0)
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = text
    label.TextColor3 = Color3.fromRGB(0, 255, 150)
    label.TextXAlignment = Enum.TextXAlignment.Center

    local underline = Instance.new("Frame", wrapper)
    underline.Size = UDim2.new(0.4, 0, 0, 2)
    underline.Position = UDim2.new(0.5, 0, 1, -2)
    underline.AnchorPoint = Vector2.new(0.5, 0)
    underline.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
    underline.BorderSizePixel = 0

    return wrapper
end

-- UIに追加
local hitboxInputs = {
    makeSectionTitle("Hitbox Size Adjustments (Text Input)"),
    makeHitboxInput("BlockHitBox", hitboxValues.BlockHitBox),
    makeHitboxInput("DiveHitBox", hitboxValues.DiveHitBox),
    makeHitboxInput("RecHitBox", hitboxValues.RecHitBox),
    makeHitboxInput("TopHitBox", hitboxValues.TopHitBox),
}

for _, el in ipairs(hitboxInputs) do
    el.Parent = frame
end

-- リアルタイム更新
RunService.RenderStepped:Connect(function()
    for name, value in pairs(hitboxValues) do
        local part = getPlayerPart(name)
        if part then
            part.Size = Vector3.new(value, value, value)
        end
    end
end)

-- リスポーン時も自動適用
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    for name, value in pairs(hitboxValues) do
        local part = getPlayerPart(name)
        if part then
            part.Size = Vector3.new(value, value, value)
        end
    end
end)

print("[J Hub Hub] Hitbox input boxes loaded (real-time).")
