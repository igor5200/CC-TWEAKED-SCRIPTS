-- =========================================================
-- GYROSCOPIC BEARING TESTER
-- =========================================================
-- Sterowanie:
--
-- 1 = FRONT
-- 2 = BACK
-- 3 = LEFT
-- 4 = RIGHT
--
-- Wybór bearingu:
-- f = front
-- b = back
-- l = left
-- r = right
--
-- a = przechył w jedną stronę
-- d = przechył w drugą stronę
-- s = środek
--
-- q = wyjście
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
-- USTAWIENIE BEARINGU
-- =========================================================

local function setBearing(bearing, angle)
    if not bearing then
        print("Brak bearingu!")
        return
    end

    bearing.setManualTarget(angle)
end


-- =========================================================
-- RESET WSZYSTKICH
-- =========================================================

local function resetAll()
    for _, bearing in pairs(bearings) do
        if bearing then
            bearing.setManualTarget(0)
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
    print("f - FRONT")
    print("b - BACK")
    print("l - LEFT")
    print("r - RIGHT")
    print("")
    print("a - przechylenie (-30)")
    print("d - przechylenie (+30)")
    print("s - CENTER (0)")
    print("")
    print("q - EXIT")
    print("")
    print("Aktualny bearing:")
    print("  " .. selected)
end


-- =========================================================
-- GŁÓWNA PĘTLA
-- =========================================================

resetAll()

while true do

    printInfo()

    local event, key = os.pullEvent("key")

    -- Q
    if key == keys.q then
        resetAll()
        break
    end


    -- =====================================================
    -- WYBÓR BEARINGU
    -- =====================================================

    if key == keys.f then
        selected = "front"

    elseif key == keys.b then
        selected = "back"

    elseif key == keys.l then
        selected = "left"

    elseif key == keys.r then
        selected = "right"


    -- =====================================================
    -- STEROWANIE
    -- =====================================================

    elseif key == keys.a then
        setBearing(
            bearings[selected],
            -30
        )

    elseif key == keys.d then
        setBearing(
            bearings[selected],
            30
        )

    elseif key == keys.s then
        setBearing(
            bearings[selected],
            0
        )
    end
end

print("Tester zakonczony.")
