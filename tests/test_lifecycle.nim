## test_lifecycle.nim — tests for renderer lifecycle and resource management.
##
## Syntax check (no library needed):
##   nim check -p:src tests/test_lifecycle.nim
## Run (requires libopentui):
##   nim c -p:src -r tests/test_lifecycle.nim
import opentui

echo "=== Lifecycle Tests ==="

# 1. Create/destroy 100 renderers (ORC destroys automatically)
for i in 0 ..< 100:
  var r = newRenderer(40, 10)
  var b = r.nextBuffer()
  b.clear()
  b.drawText(0, 0, "test")
  discard r.render(false)
  # r is destroyed automatically by ORC when it goes out of scope

echo "  100 renderers created/destroyed successfully."

# 2. Multiple renderers coexist
block:
  var r1 = newRenderer(80, 24)
  var r2 = newRenderer(40, 12)
  doAssert(r1.handle != r2.handle, "renderers should have different handles")
  doAssert(r1.handle != InvalidHandle, "r1 handle should be valid")
  doAssert(r2.handle != InvalidHandle, "r2 handle should be valid")
  var b1 = r1.nextBuffer()
  var b2 = r2.nextBuffer()
  doAssert(b1.width() == 80'u32, "b1 width should be 80")
  doAssert(b2.width() == 40'u32, "b2 width should be 40")

echo "  Multiple concurrent renderers OK."

# 3. Renderer copy is non-owning (does not double-free)
block:
  var r1 = newRenderer(80, 24)
  var r2 = r1  # copy — should be non-owning
  doAssert(r2.owns == false, "copied renderer should not own")
  doAssert(r2.handle == r1.handle, "copied renderer should share handle")
  # When r1 and r2 go out of scope, only r1 destroys (r2.owns == false)

echo "  Copy semantics OK."

# 4. checkHandle raises OpenTuiError on invalid handle
try:
  checkHandle(InvalidHandle, "test error")
  doAssert(false, "checkHandle should have raised")
except OpenTuiError:
  discard  # expected

echo "  checkHandle error handling OK."

echo "All lifecycle tests passed."
