import raylib

import wires, signals

var
    elapsedTime: float = 0
    waitingRTS: bool = false

proc init*()=
    elapsedTime = getTime()

proc loop*()=
    if waitingRTS:
        if subReturn[1]:
            waitingRTS = false
            subReturn[0] -= 1
            if subReturn[0] == 0:
                subReturn[1] = false
        if getTime() - elapsedTime > 0.5/500:
            elapsedTime = getTime()
            clk = not clk
    elif isKeyPressed(S):
        waitingRTS = true
        subReturn[0] += 1
    elif isKeyDown(C):
        #if getTime() - elapsedTime > 0.5/500:
        #elapsedTime = getTime()
        clk = not clk
    else:
        clk = isKeyDown(Space)

