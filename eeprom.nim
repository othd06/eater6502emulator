import streams

import wires

var
    data: array[0b1000000000000000, uint8]


proc init*()=
    var dataStream = newFileStream("rom.bin", fmRead)
    for i in 0..<data.len():
        data[i] = dataStream.readUint8()
    dataStream.close()



proc loop*()=
    if a[0] == false: return

    var output = data[a.aToNum() mod 0b1000000000000000]

    for i in 0..<d.len():
        d[i] = ((output shl i) and 0b10000000) == 0b10000000




