## progress.nim — Animated progress bar demo for OpenTUI Nim bindings.
##
## Switches to the alternate screen, then animates a progress bar from 0 % to
## 100 % over ~20 frames.  Each frame clears the buffer, draws a boxed
## progress bar filled with block characters, shows the percentage, renders
## with force = true, and sleeps ~100 ms.  The terminal is always restored in
## a finally block.
##
## Run:  nim c -r -p:src progress.nim
import std/[os, unicode]
import opentui

const
  W = 80'u32
  H = 24'u32
  Frames = 20
  BarX = 10
  BarY = 11
  BarW = 60
  BarH = 3

proc main() =
  var r = newRenderer(W, H)
  setupTerminal()
  try:
    let blockCh = "█".runeAt(0)
    let barFg   = rgb8(100, 200, 255)
    let barBg   = rgb8(30, 30, 50)
    let fillFg  = rgb8(80, 255, 120)

    for i in 0 .. Frames:
      var b = r.nextBuffer()
      b.clear()

      let pct    = (i * 100) div Frames
      let filled = (BarW * i) div Frames

      # Title
      b.drawText(28, 6, "Loading…", fg = rgb8(255, 200, 80))

      # Border around the bar
      b.drawBox(BarX - 1, BarY - 1, BarW + 2, BarH + 2, fg = barFg, bg = barBg)

      # Filled portion
      for cx in 0 ..< filled:
        for cy in 0 ..< BarH:
          b.putCell(BarX + cx, BarY + cy, blockCh, fg = fillFg, bg = barBg)

      # Percentage label
      let pctStr = $pct & "%"
      let tx = BarX + (BarW div 2) - (pctStr.len div 2)
      b.drawText(tx, BarY + BarH + 2, pctStr, fg = rgb8(255, 255, 255))

      discard r.render(true)
      sleep(100)
  finally:
    restoreTerminal()

main()
