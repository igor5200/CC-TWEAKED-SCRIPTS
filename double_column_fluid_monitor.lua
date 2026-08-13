local monitor = peripheral.find("monitor")

if not monitor then
    print("Nie znaleziono monitora!")
    return
end

monitor.setTextScale(1.5)

-- Ile miejsca potrzebuje jeden tank
local TANK_WIDTH = 30
local TANK_HEIGHT = 7

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
    percent = math.max(0, math.min(1, percent))

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

local function drawTank(monitor, tankNumber, tank, x, y)
    local fluids = tank.tanks()

    monitor.setCursorPos(x, y)
    monitor.setTextColor(colors.yellow)
    monitor.write("TANK " .. tankNumber)

    y = y + 1

    if #fluids == 0 then
        monitor.setCursorPos(x + 1, y)
        monitor.setTextColor(colors.lightGray)
        monitor.write("EMPTY")
        return
    end

    for _, fluid in ipairs(fluids) do
        local amount = fluid.amount
        local capacity = 288000

        local percent = amount / capacity

        -- Nazwa fluidu
        local fluidName = fluid.name

        if #fluidName > 20 then
            fluidName = string.sub(fluidName, 1, 20)
        end

        monitor.setCursorPos(x + 1, y)
        monitor.setTextColor(colors.white)
        monitor.write(fluidName)

        y = y + 1

        -- Pasek
        drawBar(
            monitor,
            x + 1,
            y,
            20,
            percent
        )

        -- Procent
        monitor.setCursorPos(x + 22, y)
        monitor.setTextColor(colors.white)
        monitor.write(
            string.format("%3.0f%%", percent * 100)
        )

        y = y + 1

        -- Ilość
        monitor.setCursorPos(x + 1, y)
        monitor.setTextColor(colors.lightGray)
        monitor.write(
            string.format(
                "%d / %d mB",
                amount,
                capacity
            )
        )

        y = y + 2
    end
end

while true do

    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    local width, height = monitor.getSize()

    -- ==========================================
    -- NAGŁÓWEK
    -- ==========================================

    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.cyan)
    monitor.write("FLUID TANK MONITOR")

    monitor.setCursorPos(1, 2)
    monitor.setTextColor(colors.gray)

    for i = 1, width do
        monitor.write("-")
    end

    -- ==========================================
    -- TANKI
    -- ==========================================

    local tanks = getTanks()

    -- Automatyczne obliczenie liczby kolumn
    local columns = math.floor(width / TANK_WIDTH)

    -- Minimum 1 kolumna
    columns = math.max(1, columns)

    -- Rzeczywista szerokość kolumny
    local columnWidth = math.floor(width / columns)

    local startY = 4

    for i, name in ipairs(tanks) do

        local tank = peripheral.wrap(name)

        -- Numer kolumny
        local column = (i - 1) % columns

        -- Numer wiersza
        local row = math.floor((i - 1) / columns)

        -- Pozycja X
        local x = 1 + column * columnWidth

        -- Pozycja Y
        local y = startY + row * TANK_HEIGHT

        -- Czy mieści się na monitorze?
        if y < height - 2 then
            drawTank(
                monitor,
                i,
                tank,
                x,
                y
            )
        end
    end

    -- ==========================================
    -- STOPKA
    -- ==========================================

    monitor.setCursorPos(1, height)
    monitor.setTextColor(colors.gray)
    monitor.write(
        "Tanks: " .. #tanks ..
        " | Columns: " .. columns
    )

    sleep(5)
end
