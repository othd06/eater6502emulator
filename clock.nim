import raylib

import wires

var elapsedTime: float = 0

proc init*()=
    elapsedTime = getTime()

proc loop*()=
    if isKeyDown(C):
        if getTime() - elapsedTime > 0.5/100:
            elapsedTime = getTime()
            clk = not clk
    else:
        clk = isKeyDown(Space)

