-- =========================================================
-- GYROSCOPIC PROPELLER BEARING TESTER
-- =========================================================

local FRONT = peripheral.wrap("gyroscopic_propeller_bearing_0")
local BACK  = peripheral.wrap("gyroscopic_propeller_bearing_1")
local LEFT  = peripheral.wrap("gyroscopic_propeller_bearing_2")
local RIGHT = peripheral.wrap("gyroscopic_propeller_bearing_3")

local bearings = {
    front = FRONT,
    back = BACK,
    left = LEFT,
    right = RIGHT
}

local selected = "front"

-- =========================================================
-- USTAWIENIE CELU
-- =========================================================

local function setBearing(bearing, x, y, z)
    bearing.setManualTarget({
        x = x,
        y = y,
        z = z
    })
end

-- =========================================================
-- RESET
-- =========================================================

local function resetAll()
    for _, bearing in pairs(bearings) do
        if bearing then
            setBearing(bearing, 0, 0, 0)
        end
    end
end

-- =========================================================
-- INFO
-- =========================================================

local function printInfo()
    term.clear()
    term.setCursorPos(1, 1)

    print("=== GYROSCOPIC BEARING TESTER ===")
    print("")
    print("Wybrany: " .. selected)
    print("")
    print("f = FRONT")
    print("b = BACK")
    print("l = LEFT")
    print("r = RIGHT")
    print("")
    print("a = -30")
    print("d = +30")
    print("s = CENTER")
    print("")
    print("q = EXIT")
end

-- =========================================================
-- START
-- =========================================================

resetAll()

while true do

    printInfo()

    local _, key = os.pullEvent("key")

    -- EXIT
    if key == keys.q then
        resetAll()
        break
    end

    -- WYBÓR
    if key == keys.f then
        selected = "front"

    elseif key == keys.b then
        selected = "back"

    elseif key == keys.l then
        selected = "left"

    elseif key == keys.r then
        selected = "right"

    -- -30
    elseif key == keys.a then
        setBearing(
            bearings[selected],
            -30,
            0,
            0
        )

    -- +30
    elseif key == keys.d then
        setBearing(
            bearings[selected],
            30,
            0,
            0
        )

    -- CENTER
    elseif key == keys.s then
        setBearing(
            bearings[selected],
            0,
            0,
            0
        )
    end
end

print("Tester zakonczony.")
