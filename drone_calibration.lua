```lua
-- =========================================================
-- GPS DRONE
-- GPS -> VECTOR -> LOCAL VECTOR -> GYROSCOPIC BEARINGS
--
-- Ten program:
--   * NIE steruje RSC
--   * NIE ustala mocy propellerów
--   * tylko wylicza kierunek lotu
--   * ustawia kierunek 4 gyroscopic propeller bearings
-- =========================================================


-- =========================================================
-- CEL
-- =========================================================

local TARGET_X = -232
local TARGET_Y = 70
local TARGET_Z = -59


-- =========================================================
-- URZĄDZENIA
-- =========================================================

local nav =
    peripheral.wrap("navigation_table_0")


-- =========================================================
-- GYROSCOPIC PROPELLER BEARINGS
-- =========================================================

local front =
    peripheral.wrap("gyroscopic_propeller_bearing_0")

local right =
    peripheral.wrap("gyroscopic_propeller_bearing_1")

local back =
    peripheral.wrap("gyroscopic_propeller_bearing_2")

local left =
    peripheral.wrap("gyroscopic_propeller_bearing_3")


-- =========================================================
-- FUNKCJE
-- =========================================================

local function normalize(x, y, z)

    local length =
        math.sqrt(
            x * x +
            y * y +
            z * z
        )

    if length < 0.0001 then
        return 0, 0, 0
    end

    return
        x / length,
        y / length,
        z / length
end


-- =========================================================
-- GŁÓWNA PĘTLA
-- =========================================================

while true do

    -- =====================================================
    -- POZYCJA DRONA
    -- =====================================================

    local pose =
        sublevel.getLogicalPose()

    local droneX =
        pose.position.x

    local droneY =
        pose.position.y

    local droneZ =
        pose.position.z


    -- =====================================================
    -- WEKTOR ŚWIATOWY DO CELU
    -- =====================================================

    local vx =
        TARGET_X - droneX

    local vy =
        TARGET_Y - droneY

    local vz =
        TARGET_Z - droneZ


    -- =====================================================
    -- ODLEGŁOŚĆ
    -- =====================================================

    local distance =
        math.sqrt(
            vx * vx +
            vy * vy +
            vz * vz
        )


    -- =====================================================
    -- WEKTOR ZNORMALIZOWANY WORLD SPACE
    -- =====================================================

    local worldX
    local worldY
    local worldZ


    worldX,
    worldY,
    worldZ =
        normalize(
            vx,
            vy,
            vz
        )


    -- =====================================================
    -- HEADING
    -- =====================================================

    local heading =
        nav.getHeadingRad()


    -- =====================================================
    -- WORLD -> LOCAL
    --
    -- forward = przód drona
    -- right   = prawa strona drona
    -- up      = góra
    -- =====================================================

    local forward =
        -worldX * math.cos(heading)
        +
        worldZ * math.sin(heading)


    local rightDirection =
        worldX * math.sin(heading)
        +
        worldZ * math.cos(heading)


    local up =
        worldY


    -- =====================================================
    -- NORMALIZACJA LOCAL VECTOR
    -- =====================================================

    local localX
    local localY
    local localZ


    localX,
    localY,
    localZ =
        normalize(
            rightDirection,
            up,
            forward
        )


    -- =====================================================
    -- OKREŚLENIE KIERUNKU
    -- =====================================================

    local direction = ""


    if math.abs(localX) > 0.15 then

        if localX > 0 then
            direction = direction .. "RIGHT "
        else
            direction = direction .. "LEFT "
        end

    end


    if math.abs(localZ) > 0.15 then

        if localZ > 0 then
            direction = direction .. "FRONT "
        else
            direction = direction .. "BACK "
        end

    end


    if math.abs(localY) > 0.15 then

        if localY > 0 then
            direction = direction .. "UP "
        else
            direction = direction .. "DOWN "
        end

    end


    if direction == "" then
        direction = "STOP"
    end


    -- =====================================================
    -- GYROSCOPIC BEARINGS
    --
    -- Każdy bearing dostaje TEN SAM WORLD VECTOR.
    --
    -- Dzięki temu każdy propeller jest skierowany
    -- w kierunku, w którym chcemy uzyskać ciąg.
    -- =====================================================

    front.setManualTarget(
        worldX,
        worldY,
        worldZ
    )

    right.setManualTarget(
        worldX,
        worldY,
        worldZ
    )

    back.setManualTarget(
        worldX,
        worldY,
        worldZ
    )

    left.setManualTarget(
        worldX,
        worldY,
        worldZ
    )


    -- =====================================================
    -- DEBUG
    -- =====================================================

    term.clear()
    term.setCursorPos(1, 1)

    print("================================")
    print("        GPS DRONE")
    print("================================")
    print()

    print("POSITION")

    print(string.format(
        "X: %.2f",
        droneX
    ))

    print(string.format(
        "Y: %.2f",
        droneY
    ))

    print(string.format(
        "Z: %.2f",
        droneZ
    ))

    print()

    print("TARGET")

    print(string.format(
        "X: %.2f",
        TARGET_X
    ))

    print(string.format(
        "Y: %.2f",
        TARGET_Y
    ))

    print(string.format(
        "Z: %.2f",
        TARGET_Z
    ))

    print()

    print("DISTANCE")

    print(string.format(
        "%.2f blocks",
        distance
    ))

    print()

    print("WORLD VECTOR")

    print(string.format(
        "X: %.3f",
        worldX
    ))

    print(string.format(
        "Y: %.3f",
        worldY
    ))

    print(string.format(
        "Z: %.3f",
        worldZ
    ))

    print()

    print("LOCAL VECTOR")

    print(string.format(
        "RIGHT : %.3f",
        localX
    ))

    print(string.format(
        "UP    : %.3f",
        localY
    ))

    print(string.format(
        "FRONT : %.3f",
        localZ
    ))

    print()

    print("DIRECTION")

    print(direction)

    print()

    print("HEADING")

    print(string.format(
        "%.2f deg",
        math.deg(heading)
    ))

    sleep(0.1)

end
```
