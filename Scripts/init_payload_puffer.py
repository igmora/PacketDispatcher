import math

depth = 4096
width = 52
path = "../Quartus/PacketDispatcher/src"

padding_size = math.ceil(math.log2(depth) / 4)

with open(path + '/PayloadBuffer.mif', 'w') as file:
    file.write(f"DEPTH = {depth};\n")
    file.write(f"WIDTH = {width};\n")
    file.write("CONTENT BEGIN\n")
    for addr in range(0, depth):
        nextPtr = addr + 1
        line = "{:0" + str(padding_size) + "x}: "
        line += "{:0" + str(padding_size) + "x};\n"
        file.write(line.format(addr, nextPtr % depth));
    file.write("END;\n")
    file.close();