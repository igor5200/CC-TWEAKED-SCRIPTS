local nav = peripheral.wrap("navigation_table_0")

local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")
local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")


-- =========================================================
-- CEL
-- =========================================================

local TARGET_X = 100
local TARGET_Y = 80
local TARGET_Z = 200


-- =========================================================
-- USTAWIENIA
-- =========================================================

local MAX_POWER = 1.0
local POSITION_GAIN = 0.03
local TARGET_RADIUS = 2


-- =========================================================
-- CLAMP
-- =========================================================

local function clamp(x, min, max)

    if x < min then
        return min
    end

    if x > max then
        return max
    end

    return x
end


-- =========================================================
-- POZYCJA
-- =========================================================

local function getPosition()

    local p = nav.getPosition()

    return p.x, p.y, p.z
end


-- =========================================================
-- HEADING
-- =========================================================

local function getHeading()

    return nav.getHeadingRad()
end


-- =========================================================
-- STEROWANIE
-- =========================================================

local function setPropellers(l, r, f, b)

    left.setManualTarget(l)
    right.setManualTarget(r)
    front.setManualTarget(f)
    back.setManualTarget(b)

end


-- =========================================================
-- WORLD -> LOCAL
-- =========================================================

local function worldToLocal(dx, dz, heading)

    local forwardX = math.cos(heading)
    local forwardZ = math.sin(heading)

    local rightX = -math.sin(heading)
    local rightZ = math.cos(heading)

    local forward =
        dx * forwardX +
        dz * forwardZ

    local rightPower =
        dx * rightX +
        dz * rightZ

    return forward, rightPower
end


-- =========================================================
-- MAIN
-- =========================================================

while true do

    local x, y, z = getPosition()

    local heading = getHeading()


    -- =====================================================
    -- WEKTOR DO CELU
    -- =====================================================

    local dx = TARGET_X - x
    local dy = TARGET_Y - y
    local dz = TARGET_Z - z


    local distance =
        math.sqrt(
            dx * dx +
            dy * dy +
            dz * dz
        )


    -- =====================================================
    -- CEL OSIĄGNIĘTY
    -- =====================================================

    if distance < TARGET_RADIUS then

        setPropellers(0, 0, 0, 0)

        print("CEL OSIAGNIETY")

    else

        -- =================================================
        -- WORLD -> LOCAL
        -- =================================================

        local forwardPower, rightPower =
            worldToLocal(dx, dz, heading)


        -- =================================================
        -- NORMALIZACJA
        -- =================================================

        local horizontalDistance =
            math.sqrt(
                forwardPower * forwardPower +
                rightPower * rightPower
            )


        if horizontalDistance > 0 then

            forwardPower =
                forwardPower / horizontalDistance

            rightPower =
                rightPower / horizontalDistance

        end


        -- =================================================
        -- SIŁA
        -- =================================================

        local power =
            clamp(
                distance * POSITION_GAIN,
                0,
                MAX_POWER
            )


        forwardPower =
            forwardPower * power

        rightPower =
            rightPower * power


        -- =================================================
        -- PROPELLERY
        -- =================================================

        local frontPower =
            math.max(0, forwardPower)

        local backPower =
            math.max(0, -forwardPower)

        local rightPowerFinal =
            math.max(0, rightPower)

        local leftPower =
            math.max(0, -rightPower)


        -- =================================================
        -- USTAWIENIE
        -- =================================================

        left.setManualTarget(leftPower)
        right.setManualTarget(rightPowerFinal)

        front.setManualTarget(frontPower)
        back.setManualTarget(backPower)


        -- =================================================
        -- DEBUG
        -- =================================================

        term.clear()
        term.setCursorPos(1, 1)

        print("=== DRONE NAVIGATION ===")
        print()

        print(string.format(
            "POS %.2f %.2f %.2f",
            x, y, z
        ))

        print(string.format(
            "TARGET %.2f %.2f %.2f",
            TARGET_X,
            TARGET_Y,
            TARGET_Z
        ))

        print()

        print(string.format(
            "DIST %.2f",
            distance
        ))

        print(string.format(
            "HEADING %.2f",
            heading
        ))

        print()

        print(string.format(
            "DX %.2f",
            dx
        ))

        print(string.format(
            "DY %.2f",
            dy
        ))

        print(string.format(
            "DZ %.2f",
            dz
        ))

        print()

        print(string.format(
            "FORWARD %.2f",
            forwardPower
        ))

        print(string.format(
            "RIGHT %.2f",
            rightPower
        ))

        print()

        print("LEFT  ", leftPower)
        print("RIGHT ", rightPowerFinal)
        print("FRONT ", frontPower)
        print("BACK  ", backPower)

    end


    sleep(0.05)

end
