local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local attackEvent = ReplicatedStorage:WaitForChild("AttackEvent")

local WALK_SPEED = 12
local RUN_SPEED = 20

local isRunning = false
local isAttacking = false

local function makeAnimation(id)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. id
	return animator:LoadAnimation(anim)
end

local idleTrack = makeAnimation("94338102278732")
local walkTrack = makeAnimation("133425926455456")
local runTrack = makeAnimation("102833117396561")

idleTrack.Priority = Enum.AnimationPriority.Idle
walkTrack.Priority = Enum.AnimationPriority.Movement
runTrack.Priority = Enum.AnimationPriority.Movement

idleTrack.Looped = true
walkTrack.Looped = true
runTrack.Looped = true

humanoid.WalkSpeed = WALK_SPEED
idleTrack:Play(0.15)

local currentSpeed = 0

local function updateMovementAnimation(speed)
	currentSpeed = speed

	if isAttacking then
		return
	end

	if speed > 0.5 then
		if idleTrack.IsPlaying then idleTrack:Stop(0.15) end

		if isRunning then
			if walkTrack.IsPlaying then walkTrack:Stop(0.15) end
			if not runTrack.IsPlaying then runTrack:Play(0.15) end
			runTrack:AdjustSpeed(1.5)
		else
			if runTrack.IsPlaying then runTrack:Stop(0.15) end
			if not walkTrack.IsPlaying then walkTrack:Play(0.15) end
			walkTrack:AdjustSpeed(speed / WALK_SPEED)
		end
	else
		if walkTrack.IsPlaying then walkTrack:Stop(0.15) end
		if runTrack.IsPlaying then runTrack:Stop(0.15) end
		if not idleTrack.IsPlaying then idleTrack:Play(0.15) end
	end
end

humanoid.Running:Connect(updateMovementAnimation)

local attackTracks = {}

local function getEquippedWeapon()
	return character:FindFirstChildOfClass("Tool")
end

local function getWeaponConfig(tool)
	local config = tool:FindFirstChild("Config")
	if not config then return nil end
	
	local attackAnimationId = config:FindFirstChild("AttackAnimationId")
	if not attackAnimationId then return nil end
	
	local attackSpeed = config:FindFirstChild("AttackSpeed")
	local lockMovement = config:FindFirstChild("LockMovement")
	
	local lockMovementValue = true

	if lockMovement ~= nil then
		lockMovementValue = lockMovement.Value
	end
	
	return {
		AttackAnimationId = attackAnimationId.Value,
		AttackSpeed = attackSpeed and attackSpeed.Value or 1,
		LockMovement = lockMovementValue,
	}	
end

local function getAttackTrack(tool, animId)
	if attackTracks[tool] then
		return attackTracks[tool]
	end
	
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. animId
	
	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	
	attackTracks[tool] = track
	return track
end

local function playWeaponAttack()
	if isAttacking then return end
	
	local weapon = getEquippedWeapon()
	if not weapon then return end
	
	local weaponConfig = getWeaponConfig(weapon)
	if not weaponConfig then return end
	
	isAttacking = true
	
	local oldJumpPower = humanoid.JumpPower
	
	if weaponConfig.LockMovement then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end
	
	if weaponConfig.LockMovement then
		if walkTrack.IsPlaying then walkTrack:Stop(0.1) end
		if runTrack.IsPlaying then runTrack:Stop(0.1) end
	end
	
	local attackTrack = getAttackTrack(weapon, weaponConfig.AttackAnimationId)
	
	attackTrack:Play(0.05)
	attackTrack:AdjustSpeed(weaponConfig.AttackSpeed)
	
	attackTrack.Stopped:Wait()
	
	if weaponConfig.LockMovement then
		humanoid.WalkSpeed = isRunning and RUN_SPEED or WALK_SPEED
		humanoid.JumpPower = oldJumpPower
	end
	
	isAttacking = false
	updateMovementAnimation(currentSpeed)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isRunning = true
		humanoid.WalkSpeed = RUN_SPEED
		updateMovementAnimation(currentSpeed)
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		playWeaponAttack()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isRunning = false
		humanoid.WalkSpeed = WALK_SPEED
		updateMovementAnimation(currentSpeed)
	end
end)