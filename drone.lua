local nav = peripheral.wrap("navigation_table_0")
local gimbal = peripheral.wrap("gimbal_sensor_0")

if not nav then
    error("Brak navigation_table_0")
end

if not gimbal then
    error("Brak gimbal_sensor_0")
end

while true do
    local heading = nav.getHeadingRad()

    -- getAnglesRad() zwraca {pitch, roll}
    local angles = gimbal.getAnglesRad()
    local pitch = angles[1]
    local roll  = angles[2]

    -- Kierunek FRONT drona w świecie.
    -- Navigation Table:
    -- heading = 0 -> FRONT wskazuje world +Z
    local frontX = math.sin(heading)
    local frontZ = math.cos(heading)

    -- Kierunek RIGHT drona w świecie.
    local rightX = math.cos(heading)
    local rightZ = -math.sin(heading)

    -- Światowy X+ wyrażony w lokalnym układzie drona.
    local worldX_front = frontX
    local worldX_right = rightX

    -- Światowy Z+ wyrażony w lokalnym układzie drona.
    local worldZ_front = frontZ
    local worldZ_right = rightZ

    term.clear()
    term.setCursorPos(1, 1)

    print("=== DIRECTION TESTER ===")
    print()

    print(string.format(
        "Heading : %7.2f deg",
        math.deg(heading)
    ))

    print(string.format(
        "Pitch   : %7.2f deg",
        math.deg(pitch)
    ))

    print(string.format(
        "Roll    : %7.2f deg",
        math.deg(roll)
    ))

    print()
    print("FRONT -> WORLD")
    print(string.format(
        "X = %+0.3f",
        frontX
    ))
    print(string.format(
        "Z = %+0.3f",
        frontZ
    ))

    print()
    print("RIGHT -> WORLD")
    print(string.format(
        "X = %+0.3f",
        rightX
    ))
    print(string.format(
        "Z = %+0.3f",
        rightZ
    ))

    print()
    print("WORLD X+ -> DRONE")
    print(string.format(
        "FRONT = %+0.3f",
        worldX_front
    ))
    print(string.format(
        "RIGHT = %+0.3f",
        worldX_right
    ))

    print()
    print("WORLD Z+ -> DRONE")
    print(string.format(
        "FRONT = %+0.3f",
        worldZ_front
    ))
    print(string.format(
        "RIGHT = %+0.3f",
        worldZ_right
    ))

    sleep(0.1)
end
