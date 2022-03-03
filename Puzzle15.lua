-- Puzzle 15 info: https://en.wikipedia.org/wiki/15_puzzle
-- Author: TheM0rt0nator

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local require = require(ReplicatedStorage.ZenithFramework)

local Table = require("Table")
local MouseFuncs = require("Mouse")
local Maid = require("Maid")

local Puzzle15 = {}
Puzzle15.__index = Puzzle15

local N = 3
local missingPartColor = Color3.fromRGB(255, 64, 64)
local randomGen = Random.new()

-- Starts the puzzle, with a board argument which is a model containing the 9 pieces for the puzzle, 
-- and an optional onCompleted argument which is a function to be run when the puzzle is completed
function Puzzle15.startPuzzle(board, onCompleted)
	assert(typeof(board) == "Instance" and #board:GetChildren() == N ^ 2, "First argument needs to be a model with N ^ 2 parts inside, named accordingly")

	local self = setmetatable({}, Puzzle15)

	self._maid = Maid.new()
	self.board = board
	self.onCompleted = onCompleted

	self.goal_configuration = self:createNumberTable()
	self.originCFrame = board:FindFirstChild("1").CFrame
	self.indexCFrames = {}

	-- Set an attribute to keep track of which part is which (will be changing this when the part moves), and save the parts current CFrame relative to the origin CFrame
	for _, part in pairs(board:GetChildren()) do
		if part.Name == "0" then
			part:SetAttribute("TileNumber", N ^ 2)
		else
			part:SetAttribute("TileNumber", tonumber(part.Name))
		end

		self.indexCFrames[part:GetAttribute("TileNumber")] = self.originCFrame:toObjectSpace(part.CFrame)
	end

	self:Shuffle()

	-- Set the parts CFrames according to the shuffled order
	for index, partNum in pairs(self.start_configuration) do
		board:FindFirstChild(tostring(partNum)).CFrame = self.originCFrame * self.indexCFrames[index]
		board:FindFirstChild(tostring(partNum)):SetAttribute("TileNumber", index)
	end

	self.current_configuration = self.start_configuration

	-- Change the 'missing' parts color to make it obvious
	self.originalMissingPartColor = self.board:FindFirstChild("0").Color
	self.board:FindFirstChild("0").Color = missingPartColor

	-- Add a user input check using raycasting from the mouse to check if the player clicks on a tile
	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local hitTile = MouseFuncs.findHitWithWhitelist(Mouse, board:GetChildren(), 300)
			if hitTile and hitTile.Parent == board then
				self:TileClicked(hitTile:GetAttribute("TileNumber"))
			end
		end
	end))

	return self
end

-- Creates a table of numbers in order, with N indexes and the Nth index is 0
function Puzzle15.createNumberTable()
	local numberTable = {}
	for i = 1, N ^ 2 - 1 do
		numberTable[i] = i
	end
	table.insert(numberTable, 0)

	return numberTable
end

-- Checks if the tile can move by checking if any of it's adjacent tiles are the 'missing' tile
function Puzzle15:CheckMovePossible(index)
	for _, tableIndex in pairs(self:GetAdjacentTiles(index)) do
		if self.current_configuration[tableIndex] == 0 then
			return true, tableIndex
		end
	end

	return false
end

-- Returns all the indexes of the adjacent tiles to the given tile index
function Puzzle15:GetAdjacentTiles(index)
	local adjacentIndexes = {}

	-- Horizontal adjacent tiles
	if index % N == 0 then
		table.insert(adjacentIndexes, index - 1)
	elseif index % N == 1 then
		table.insert(adjacentIndexes, index + 1)
	else
		table.insert(adjacentIndexes, index + 1)
		table.insert(adjacentIndexes, index - 1)
	end

	-- Vertical adjacent tiles
	if index <= N then
		table.insert(adjacentIndexes, index + N)
	elseif index > N * (N - 1) then
		table.insert(adjacentIndexes, index - N)
	else
		table.insert(adjacentIndexes, index + N)
		table.insert(adjacentIndexes, index - N)
	end

	return adjacentIndexes
end

-- Swap values in the table when tiles are moved
function Puzzle15:SwapIndexes(numberIndex, number, spaceIndex)
	self.current_configuration[numberIndex] = 0
	self.current_configuration[spaceIndex] = number
end

-- Get number of inversions: If inversions are even then is solvable, else is not
function Puzzle15:GetNumInversions(initialConfig)
	local inversionCount = 0
	for i = 1,  (N ^ 2 - 1) do
		for j = i + 1, N ^ 2 do
			if initialConfig[j] and initialConfig[i] and initialConfig[j] ~= 0 and initialConfig[i] ~= 0 and initialConfig[i] > initialConfig[j] then
				inversionCount += 1
			end
		end
	end

	return inversionCount
end

-- Shuffle puzzle but make sure it is not equal to the final configuration and is solvable
function Puzzle15:Shuffle()
	local function randomizeTiles()
		local numbers = self:CreateNumberTable()

		-- Swap tiles randomly
		for i = #numbers, 2, -1 do
			local j = randomGen:NextInteger(1, i)
			numbers[i], numbers[j] = numbers[j], numbers[i]
		end

		-- Run checks, if all is good then set this as thhe start configuration
		if (self:GetNumInversions(numbers) % 2) == 1 or Table.deepCheckEquality(numbers, self.goal_configuration) then
			randomizeTiles()
		else
			self.start_configuration = numbers
		end
	end

	randomizeTiles()
end

-- Check when players clicks on tile and move it if possible
function Puzzle15:TileClicked(tileIndex)
	local canMove, spaceIndex = self:CheckMovePossible(tileIndex)
	if canMove then
		local tile = self.board:FindFirstChild(self.current_configuration[tileIndex])
		local space = self.board:FindFirstChild(self.current_configuration[spaceIndex])

		self:SwapIndexes(tileIndex, self.current_configuration[tileIndex], spaceIndex)

		tile:SetAttribute("TileNumber", spaceIndex)
		space:SetAttribute("TileNumber", tileIndex)

		local tweenInfo = TweenInfo.new(.1)

		local tileTween = TweenService:Create(tile, tweenInfo, {CFrame = self.originCFrame * self.indexCFrames[spaceIndex]})
		local spaceTween = TweenService:Create(space, tweenInfo, {CFrame = self.originCFrame * self.indexCFrames[tileIndex]})

		tileTween:Play()
		spaceTween:Play()

		-- Check if puzzle is complete by comparing the current config with the goal config
		if Table.deepCheckEquality(self.current_configuration, self.goal_configuration) then
			self.board:FindFirstChild("0").Color = self.originalMissingPartColor
			self:EndPuzzle()
			if self.onCompleted and typeof(self.onCompleted) == "function" then
				self.onCompleted()
			end
		end
	end
end

function Puzzle15:EndPuzzle()
	self._maid:DoCleaning()
end

return Puzzle15