

import wires

var
    data: array[0b100000000000000, uint8]
    oldA: array[16, bool]

proc init*()=
    for i in 0..<data.len():
        data[i] = 0b00000000



proc loop*()=
    if a[0] == true or a[1] == true: return

    if m[5]:
        var output = data[a.aToNum()]
        for i in 0..<d.len():
            d[i] = ((output shl i) and 0b10000000) == 0b10000000
    else:
        data[a.aToNum()] = d.dToNum()