## test_raw.nim — tests for the raw C ABI binding layer.
##
## Syntax check (no library needed):
##   nim check -p:src tests/test_raw.nim
## Run (requires libopentui):
##   nim c -p:src -r tests/test_raw.nim
import opentui

echo "=== Raw ABI Tests ==="

# 1. InvalidHandle constant
doAssert(InvalidHandle == 0'u32, "InvalidHandle must be 0")

# 2. createRenderer returns a valid handle
let h = createRenderer(80'u32, 24'u32, 0'u8, 0'u8, nil)
doAssert(h != InvalidHandle, "createRenderer should return a valid handle")

# 3. getNextBuffer returns a valid handle
let buf = getNextBuffer(h)
doAssert(buf != InvalidHandle, "getNextBuffer should return a valid handle")

# 4. getCurrentBuffer returns a handle
let cur = getCurrentBuffer(h)
doAssert(cur != InvalidHandle, "getCurrentBuffer should return a valid handle")

# 5. Buffer dimensions match requested size
doAssert(getBufferWidth(buf) == 80'u32, "width should be 80")
doAssert(getBufferHeight(buf) == 24'u32, "height should be 24")

# 6. render does not crash and returns a uint8
let rc = render(h, true)
doAssert(rc == 0'u8 or rc == 1'u8, "render should return 0 or 1")

# 7. bufferClear does not crash
var bg: OtuiColor16 = [0'u16, 0'u16, 0'u16, 65535'u16]
bufferClear(buf, addr bg)

# 8. Pointer APIs return non-nil
let chars = bufferGetCharPtr(buf)
doAssert(chars != nil, "bufferGetCharPtr should not be nil")

let fgPtr = bufferGetFgPtr(buf)
doAssert(fgPtr != nil, "bufferGetFgPtr should not be nil")

let bgPtr = bufferGetBgPtr(buf)
doAssert(bgPtr != nil, "bufferGetBgPtr should not be nil")

let attrPtr = bufferGetAttributesPtr(buf)
doAssert(attrPtr != nil, "bufferGetAttributesPtr should not be nil")

# 9. Write a character through the raw pointer
chars[0] = uint32('H'.uint8)
discard render(h, true)

# 10. destroyRenderer can be called once
destroyRenderer(h)

echo "All raw ABI tests passed."
