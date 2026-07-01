## test_buffer.nim — tests for the safe Buffer wrapper.
##
## Syntax check (no library needed):
##   nim check -p:src tests/test_buffer.nim
## Run (requires libopentui):
##   nim c -p:src -r tests/test_buffer.nim
import opentui
import std/unicode

echo "=== Buffer Wrapper Tests ==="

var r = newRenderer(80, 24)
var b = r.nextBuffer()

# 1. Dimensions
doAssert(b.width() == 80'u32, "width should be 80")
doAssert(b.height() == 24'u32, "height should be 24")

# 2. clear does not crash
b.clear(rgb8(10, 20, 30))

# 3. putCell does not crash
b.putCell(0, 0, "A".runeAt(0), rgb8(255, 255, 255), rgb8(0, 0, 0))

# 4. putCell with attributes (bold)
b.putCell(1, 0, "B".runeAt(0), rgb8(255, 0, 0), rgb8(0, 0, 0),
          uint32(ord(attrBold)))

# 5. drawText does not crash
b.drawText(2, 2, "Hello, World!", rgb8(0, 255, 0))

# 6. drawBox does not crash
b.drawBox(10, 5, 20, 8, rgb8(0, 128, 255))

# 7. Out-of-bounds writes are silently ignored (no crash)
b.putCell(-1, -1, "X".runeAt(0))
b.putCell(1000, 1000, "X".runeAt(0))
b.drawBox(-5, -5, 3, 3)

# 8. render one frame
discard r.render(true)

echo "All buffer wrapper tests passed."
