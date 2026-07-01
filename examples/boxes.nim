## boxes.nim — Demonstrates nested box drawing with the OpenTUI Nim bindings.
##
## Creates a renderer, switches to the alternate screen, then draws three
## nested boxes of decreasing size and different colours.  Each box carries a
## text label on its top border, and a greeting is placed in the centre of the
## innermost box.  After a brief pause the terminal is restored.
##
## Run:  nim c -r -p:src boxes.nim
import std/os
import opentui

const
  W = 80'u32
  H = 24'u32

proc main() =
  var r = newRenderer(W, H)

  var cfg = defaultConfig()
  cfg.screenMode = alternateScreen
  setupTerminal(cfg)
  try:
    var b = r.nextBuffer()
    b.clear()

    # --- Outer box (bright blue) ---
    let outerFg = rgb8(80, 180, 255)
    b.drawBox(1, 1, 78, 22, fg = outerFg)
    b.drawText(3, 1, " Outer Box ", fg = outerFg)

    # --- Middle box (green) ---
    let midFg = rgb8(80, 255, 120)
    b.drawBox(6, 4, 68, 16, fg = midFg)
    b.drawText(8, 4, " Middle Box ", fg = midFg)

    # --- Inner box (magenta) ---
    let innerFg = rgb8(255, 100, 255)
    b.drawBox(12, 7, 56, 10, fg = innerFg)
    b.drawText(14, 7, " Inner Box ", fg = innerFg)

    # --- Centre greeting ---
    b.drawText(22, 12, "Hello from OpenTUI!", fg = rgb8(255, 255, 100))

    discard r.render(true)
    sleep(3000)
  finally:
    restoreTerminal()

main()
