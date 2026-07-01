## hello.nim — green-text smoke test for the OpenTUI Nim bindings.
##
## Demonstrates the full pipeline: create renderer -> get buffer ->
## write characters + foreground colors via direct buffer pointers ->
## render one frame.
##
## Syntax check (no linking, no libopentui.so needed):
##   nim check -p:src examples/hello.nim
## Run (requires libopentui.so findable via LD_LIBRARY_PATH):
##   nim c -p:src -r examples/hello.nim
import opentui

const
  Msg = "Hello, OpenTUI from Nim!"
  StartX = 2
  RowY = 2
  Green = [0'u16, 65535'u16, 0'u16, 65535'u16]   # R,G,B,A — pure green, opaque

proc main() =
  var r = newRenderer(80, 24)
  var b = r.nextBuffer()
  b.clear()  # opaque black background

  let w = b.width()
  let chars = bufferGetCharPtr(b.handle)
  let fg = cast[ptr UncheckedArray[OtuiColor16]](bufferGetFgPtr(b.handle))

  for i, ch in Msg:
    let idx = int(RowY) * int(w) + StartX + i
    chars[idx] = uint32(ch.uint8)
    if fg != nil:
      fg[idx] = Green

  discard r.render(true)
  # Renderer is destroyed automatically when `r` goes out of scope (ORC).

main()
