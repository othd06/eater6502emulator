import raylib

import wires


proc init*()=
    discard

proc loop*()=
    if isKeyPressed(R):
        m[1] = true
    else:
        m[1] = false



