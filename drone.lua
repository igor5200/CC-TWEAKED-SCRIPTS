local nav = peripheral.wrap("navigation_table_0")

local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")
local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")


-- =========================================================
-- USTAWIENIA
-- =========================================================

local MAX_RPM = 100

-- Jak mocno reagujemy na kierunek celu
local GAIN = 80

-- Przy tej odległości zatrzymujemy drona
local TARGET_DISTANCE = 2


-- =========================================================
-- CLAMP
-- =========================================================

local function clamp(value, min, max)
    if value < min then
        return min
    end

    if value > max then
        return max
    end

    return value
end


-- =========================================================
-- USTAWIANIE RPM
-- =========================================================

local function setRPM(l, r, f, b)

    left.setTargetSpeed(l)
    right.setTargetSpeed(r)
    front.setTargetSpeed(f)
    back.setTargetSpeed(b)

end


-- =========================================================
-- GŁÓWNA PĘTLA
-- =========================================================

while true do

    -- Kierunek celu względem drona
    local bearing = nav.getBearingRad()

    -- Odległość do celu
    local distance = nav.getDistanceToTarget()

    -- Różnica wysokości
    local vertical = nav.getVerticalOffsetToTarget()


    -- =====================================================
    -- CEL OSIĄGNIĘTY
    -- =====================================================

    if distance <= TARGET_DISTANCE then

        setRPM(0, 0, 0, 0)

    else

        -- =================================================
        -- WEKTOR DO CELU
        -- =================================================

        -- 0 rad = przód
        -- +pi/2 = prawo
        -- -pi/2 = lewo
        -- pi = tył

        local forward = math.cos(bearing)
        local rightPower = math.sin(bearing)


        -- =================================================
        -- SIŁA ZALEŻNA OD ODLEGŁOŚCI
        -- =================================================

        local power = math.min(
            MAX_RPM,
            distance * GAIN
        )


        forward = forward * power
        rightPower = rightPower * power


        -- =================================================
        -- MIXER
        -- =================================================

        local frontRPM = math.max(0, forward)
        local backRPM  = math.max(0, -forward)

        local rightRPM = math.max(0, rightPower)
        local leftRPM  = math.max(0, -rightPower)


        -- =================================================
        -- OGRANICZENIE
        -- =================================================

        frontRPM = clamp(frontRPM, 0, MAX_RPM)
        backRPM  = clamp(backRPM, 0, MAX_RPM)

        leftRPM  = clamp(leftRPM, 0, MAX_RPM)
        rightRPM = clamp(rightRPM, 0, MAX_RPM)


        -- =================================================
        -- PROPULSJA
        -- =================================================

        setRPM(
            leftRPM,
            rightRPM,
            frontRPM,
            backRPM
        )


        -- =================================================
        -- DEBUG
        -- =================================================

        term.clear()
        term.setCursorPos(1, 1)

        print("=== DRONE NAVIGATION ===")
        print()

        print(string.format(
            "Bearing: %.2f rad",
            bearing
        ))

        print(string.format(
            "Bearing: %.1f deg",
            math.deg(bearing)
        ))

        print(string.format(
            "Distance: %.2f",
            distance
        ))

        print(string.format(
            "Vertical: %.2f",
            vertical
        ))

        print()

        print(string.format(
            "Forward: %.2f",
            forward
        ))

        print(string.format(
            "Right: %.2f",
            rightPower
        ))

        print()

        print("LEFT  :", leftRPM)
        print("RIGHT :", rightRPM)
        print("FRONT :", frontRPM)
        print("BACK  :", backRPM)

    end

    sleep(0.05)
end
