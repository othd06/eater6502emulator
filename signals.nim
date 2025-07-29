import raylib

#Each signal is a tuple of an int and a bool. The int is incremented for everything listening to the signal and the bool goes true when the signal is emitted. Each object listening to the signal then decrements the int againn and it is the job of the last listener (the one for which the int gets decremented to 0) to reset the bool to false

var
    subReturn*: (int, bool) = (0, false)
    draw*: (int, bool) = (0, false)

    image*: Image = loadImage("image.png")
    texture*: Texture







