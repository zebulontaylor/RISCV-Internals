import sys

with open(sys.argv[1], "rb") as f:
    words = f.read()

with open(sys.argv[2], "w") as f:
    for i in range(0, len(words), 4):
        chunk = words[i:i+4]
        chunk += b'\x00' * (4 - len(chunk))
        val = int.from_bytes(chunk, byteorder='little')
        f.write(f"{val:08X}\n")
