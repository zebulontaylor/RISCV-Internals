import sys

RAM_WORDS = 4096

with open(sys.argv[1], "rb") as f:
    words = f.read()

with open(sys.argv[2], "w") as f:
    count = 0
    for i in range(0, len(words), 4):
        chunk = words[i:i+4]
        chunk += b'\x00' * (4 - len(chunk))
        val = int.from_bytes(chunk, byteorder='little')
        f.write(f"{val:08X}\n")
        count += 1
    # Pad to RAM_WORDS so $readmemh initializes the full array
    for _ in range(count, RAM_WORDS):
        f.write("00000000\n")
