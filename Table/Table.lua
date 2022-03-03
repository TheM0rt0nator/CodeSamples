-- Useful table functions
-- Author: TheM0rt0nator

local Table = {None = "Table.None"}

-- Checks if a table is exactly equal to another table
function Table.deepCheckEquality(tab1, tab2)
	assert(typeof(tab1) == "table" and typeof(tab2) == "table", "Cannot compare " .. typeof(tab1) .. " with " .. typeof(tab2))

	for index, value in pairs(tab1) do
		if typeof(value) == "table" and typeof(tab2[index]) == "table" then
			if not Table.deepCheckEquality(value, tab2[index]) then
				return false
			end
		elseif tab2[index] ~= value then
			return false
		end
	end

	for index, value in pairs(tab2) do
		if typeof(value) == "table" and typeof(tab1[index]) == "table" then
			if not Table.deepCheckEquality(value, tab1[index]) then
				return false
			end
		elseif tab1[index] ~= value then
			return false
		end
	end

	return true
end

-- Checks if a table contains a certain value (value can be a table)
function Table.contains(tab, value)
	assert(typeof(tab) == "table", "First argument not a table")

	local isTable = typeof(value) == "table"

	for _, val in pairs(tab) do
		if (not isTable and typeof(val) ~= "table" and val == value) 
			or (isTable and typeof(val) == "table" and Table.deepCheckEquality(val, value))
		 then
			return true
		end
	end

	return false
end

-- Returns the length of a table including dictionaries
function Table.length(tab)
	assert(typeof(tab == "table"), "Argument needs to be a table")

	local length = 0
	for _, _ in pairs(tab) do
		length += 1
	end

	return length
end

-- Returns a clone of the given table
function Table.clone(tab)
	assert(typeof(tab == "table"), "Argument needs to be a table")

	local newTable = {}

	for key, value in pairs(tab) do
		newTable[key] = value
	end

	return newTable
end

-- Returns the index of the value in the given table
function Table.getIndex(tab, value)
	assert(typeof(tab) == "table", "First argument not a table")

	if typeof(value) ~= "table" then
		for index, val in pairs(tab) do
			if val == value then
				return index
			end
		end
	else
		for index, val in pairs(tab) do
			if typeof(val) == "table" and Table.deepCheckEquality(val, value) then
				return index
			end
		end
	end
end

-- Removes all duplicates in a list (doesn't work if table values are tables)
function Table.removeListDuplicates(tab)
	assert(typeof(tab == "table"), "Argument needs to be a table")

	local checkTable = {}
	for index, value in pairs(tab) do
		if not checkTable[value] then
			checkTable[value] = value
		else
			table.remove(tab, index)
		end
	end

	return tab
end

-- Merges the given tables into a new table, where keys specified in later tables will overwrite keys in previous tables
function Table.merge(...)
	local newTab = {}

	for i = 1, select("#", ...) do
		local tab = select(i, ...)
		assert(assert(typeof(tab == "table"), "All arguments need to be tables"))

		for index, val in pairs(tab) do
			if val == Table.None then
				newTab[index] = nil
			else
				newTab[index] = val
			end
		end
	end

	return newTab
end

-- Follows the path of descendants starting from tab and returns the endpoint
function Table.followPath(tab, ...)
	assert(typeof(tab) == "table", "Table argument must be a table")

	local path = {...}
	local location = tab
	for _, waypoint in ipairs(path) do
		if typeof(location) == "table" then
			location = location[waypoint]
		else
			return nil
		end
	end
	return location
end

-- Follows the given path, creating it if it doesn't exist, and returns the endpoint
function Table.createPath(start, endVal, ...)
	assert(typeof(start) == "table", "Start argument must be a table")

	local path = {...}
	local currentStage = start
	for i, pathName in ipairs(path) do
		currentStage[pathName] = currentStage[pathName] or {}
		if i == #path then
			currentStage[pathName] = if typeof(endVal) == "table" then Table.merge(currentStage[pathName], endVal) elseif endVal ~= nil then endVal else {}
		end
		currentStage = currentStage[pathName]
	end
	return currentStage
end

return Table