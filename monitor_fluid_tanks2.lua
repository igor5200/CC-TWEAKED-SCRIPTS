local monitor = peripheral.find("monitor")

if not monitor then
	print("Nie znaleziono monitora!")
	return
end

monitor.setTextScale(1.5)

local function getTanks()
	local tanks = {}

	for _, name in ipairs(peripheral.getNames()) do
		if peripheral.getType(name) == "create:fluid_tank" then
			table.insert(tanks, name)
		end
	end

	return tanks
end

local function drawBar(monitor, x, y, width, percent)
	local filled = math.floor(width * percent)

	monitor.setCursorPos(x, y)

	for i = 1, width do
		if i <= filled then
			monitor.setBackgroundColor(colors.green)
		else
			monitor.setBackgroundColor(colors.gray)
		end

		monitor.write(" ")
	end

	monitor.setBackgroundColor(colors.black)
end

local function drawTank(monitor, tankNumber, tank, y)
	local fluids = tank.tanks()

	monitor.setCursorPos(2, y)
	monitor.setTextColor(colors.yellow)
	monitor.write("TANK " .. tankNumber)

	y = y + 1

	if #fluids == 0 then
		monitor.setCursorPos(3, y)
		monitor.setTextColor(colors.lightGray)
		monitor.write("EMPTY")

		return y + 3
	end

	for _, fluid in ipairs(fluids) do
		local amount = fluid.amount
  local capacity = 288000

		local percent = amount / capacity

		monitor.setCursorPos(3, y)
		monitor.setTextColor(colors.white)
		monitor.write(fluid.name)

		y = y + 1

		drawBar(monitor, 3, y, 25, percent)

		monitor.setCursorPos(30, y)
		monitor.setTextColor(colors.white)
		monitor.write(string.format("%3.0f%%", percent * 100))

		y = y + 1

		monitor.setTextColor(colors.lightGray)
		monitor.setCursorPos(3, y)
		monitor.write(string.format("%d / %d mB", amount, capacity))

		y = y + 2
	end

	return y
end

while true do
	monitor.setBackgroundColor(colors.black)
	monitor.clear()

	local width, height = monitor.getSize()

	-- Naglowek
	monitor.setCursorPos(1, 1)
	monitor.setTextColor(colors.cyan)
	monitor.write("       FLUID TANK MONITOR")

	monitor.setCursorPos(1, 2)
	monitor.setTextColor(colors.gray)

	for i = 1, width do
		monitor.write("-")
	end

	-- Tanki
	local tanks = getTanks()

	local y = 4

	for i, name in ipairs(tanks) do
		local tank = peripheral.wrap(name)

		y = drawTank(monitor, i, tank, y)

		if y >= height - 2 then
			break
		end
	end

	-- Stopka
	monitor.setCursorPos(1, height)
	monitor.setTextColor(colors.gray)
	monitor.write("Tanks: " .. #tanks)

	sleep(5)
end
