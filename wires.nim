

var
    a* : array[16, bool]
    d* : array[8, bool]
    m* : array[18, bool]
    io* : array[16, bool]
    clk* : bool


proc dToNum*(data: array[8, bool]): uint8=
    var output: uint8 = 0
    for i in data:
        output = output shl 1
        output = output or i.uint8
    return output

proc aToNum*(data: array[16, bool]): uint16=
    var output: uint16 = 0
    for i in data:
        output = output shl 1
        output = output or i.uint16
    return output
