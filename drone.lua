local nav = peripheral.wrap("navigation_table_0")
local gimbal = peripheral.wrap("gimbal_sensor_0")

if not nav then
    error("Brak navigation_table_0")
end

if not gimbal then
    error("Brak gimbal_sensor_0")
end

print("=== DIRECTION TESTER ===")
print("Nie steruje propellerami.")
print()

while true do
    local heading = nav.getHeadingRad()

    local pitch, roll = gimbal.getAnglesRad()

    -- Kierunek FRONT drona w układzie świata.
    --
    -- Navigation Table:
    -- heading = 0 oznacza FRONT w +Z
    --
    -- Przyjmujemy:
    -- world X = wschód/zachód
    -- world Z = północ/południe

    local frontX = math.sin(heading)
    local frontZ = math.cos(heading)

    -- Prawa strona drona jest obrócona o +90°
    local rightX = math.cos(heading)
    local rightZ = -math.sin(heading)

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
    print("FRONT vector:")
    print(string.format(
        "  X = %+0.3f",
        frontX
    ))
    print(string.format(
        "  Z = %+0.3f",
        frontZ
    ))

    print()
    print("RIGHT vector:")
    print(string.format(
        "  X = %+0.3f",
        rightX
    ))
    print(string.format(
        "  Z = %+0.3f",
        rightZ
    ))

    print()
    print("WORLD X+ expressed in drone coordinates:")

    -- Rzut światowego X+ na lokalny FRONT/RIGHT
    local localFrontX = frontX
    local localRightX = rightX

    print(string.format(
        "  FRONT = %+0.3f",
        localFrontX
    ))

    print(string.format(
        "  RIGHT = %+0.3f",
        localRightX
    ))

    print()
    print("WORLD Z+ expressed in drone coordinates:")

    local localFrontZ = frontZ
    local localRightZ = rightZ

    print(string.format(
        "  FRONT = %+0.3f",
        localFrontZ
    ))

    print(string.format(
        "  RIGHT = %+0.3f",
        localRightZ
    ))

    sleep(0.2)
end
