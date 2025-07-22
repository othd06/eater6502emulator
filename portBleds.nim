import raylib

import wires


proc init*()=
    discard


proc loop*()=
    if io[8]:
        drawCircle(100-25, 250, 20.0, Color(r: 255, g: 0, b: 0, a: 255))
    else:
        drawCircle(100-25, 250, 20.0, Color(r: 100, g: 0, b: 0, a: 255))
    if io[9]:
        drawCircle(150-25, 250, 20.0, Color(r: 255, g: 0, b: 0, a: 255))
    else:
        drawCircle(150-25, 250, 20.0, Color(r: 100, g: 0, b: 0, a: 255))
    if io[10]:
        drawCircle(200-25, 250, 20.0, Color(r: 255, g: 0, b: 0, a: 255))
    else:
        drawCircle(200-25, 250, 20.0, Color(r: 100, g: 0, b: 0, a: 255))
    if io[11]:
        drawCircle(250-25, 250, 20.0, Color(r: 255, g: 0, b: 0, a: 255))
    else:
        drawCircle(250-25, 250, 20.0, Color(r: 100, g: 0, b: 0, a: 255))
    if io[12]:
        drawCircle(300-25, 250, 20.0, Color(r: 255, g: 0, b: 0, a: 255))
    else:
        drawCircle(300-25, 250, 20.0, Color(r: 100, g: 0, b: 0, a: 255))
    if io[13]:
        drawCircle(350-25, 250, 20.0, Color(r: 255, g: 0, b: 0, a: 255))
    else:
        drawCircle(350-25, 250, 20.0, Color(r: 100, g: 0, b: 0, a: 255))
    if io[14]:
        drawCircle(400-25, 250, 20.0, Color(r: 255, g: 0, b: 0, a: 255))
    else:
        drawCircle(400-25, 250, 20.0, Color(r: 100, g: 0, b: 0, a: 255))
    if io[15]:
        drawCircle(450-25, 250, 20.0, Color(r: 255, g: 0, b: 0, a: 255))
    else:
        drawCircle(450-25, 250, 20.0, Color(r: 100, g: 0, b: 0, a: 255))


