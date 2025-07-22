import strutils

import wires

var
    oldClk: bool = false


proc testClkHigh(): bool =
    if oldClk == false and clk == true:
        oldClk = true
        return true
    else:
        oldClk = clk
        return false



proc init*()=
    discard


proc loop*()=
    if testClkHigh():
        var
            outString: string = ""
            address: int = 0
            data: int = 0
        
        for i in a:
            outString = outString & $(i.int)
            address = address shl 1
            address += i.int
        
        outString = outString & "    "
        
        for i in d:
            outString = outString & $(i.int)
            data = data shl 1
            data += i.int
        
        
        outString = outString & "      " & address.toHex(4) & "  " & data.toHex(2)

        if m[5]:
            outString = outString & "  r"
        else:
            outString = outString & "  w"
        
        echo(outString)

