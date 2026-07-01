## dashboard.nim — Mock system dashboard demo for OpenTUI Nim bindings.
##
## Renders a single-frame dashboard layout:
##   • Title bar at the top (bold, bright blue)
##   • CPU-usage panel — box with a horizontal bar graph
##   • Memory panel    — box with a horizontal bar graph
##   • Status line at the bottom
##
## The terminal is always restored in a finally block.
##
## Run:  nim c -r -p:src dashboard.nim
import std/[os, unicode]
import opentui

const
  W = 80'u32
  H = 24'u32

proc drawTextAttr(b: Buffer, x, y: int, text: string, fg, bg: OtuiColor16,
                  attrs: uint32 = 0) =
  ## Draw text with an optional attribute bitmask (e.g. attrBold).
  var cx = x
  for r in text.runes:
    b.putCell(cx, y, r, fg, bg, attrs)
    inc cx

proc drawPanel(b: Buffer, x, y, w, h: int, title, label: string,
               value: int, fg, bg: OtuiColor16) =
  ## Draw a titled panel containing a label and a horizontal bar graph.
  b.drawBox(x, y, w, h, fg = fg, bg = bg)
  b.drawText(x + 2, y, " " & title & " ", fg = fg, bg = bg)

  b.drawText(x + 2, y + 2, label, fg = rgb8(220, 220, 220), bg = bg)

  # Bar graph (filled + empty portion)
  let barX = x + 2
  let barY = y + 4
  let barW = w - 4
  let filled = (barW * value) div 100
  let onCh  = "█".runeAt(0)
  let offCh = "░".runeAt(0)
  for cx in 0 ..< barW:
    let ch = if cx < filled: onCh else: offCh
    b.putCell(barX + cx, barY, ch, fg = fg, bg = bg)

  b.drawText(x + 2, y + 6, $value & "%", fg = rgb8(255, 255, 100), bg = bg)

proc main() =
  var r = newRenderer(W, H)
  setupTerminal()
  try:
    var b = r.nextBuffer()
    b.clear()

    # --- Title bar ---
    let titleBg = rgb8(20, 30, 50)
    let titleFg = rgb8(100, 200, 255)
    b.drawBox(0, 0, 80, 3, fg = titleFg, bg = titleBg)
    drawTextAttr(b, 2, 1, "System Dashboard — OpenTUI",
                 rgb8(255, 255, 255), titleBg, uint32(attrBold))

    # --- CPU panel ---
    drawPanel(b, 1, 4, 38, 12, "CPU Usage", "Core Load", 73,
              rgb8(80, 200, 255), rgb8(15, 20, 35))

    # --- Memory panel ---
    drawPanel(b, 41, 4, 38, 12, "Memory", "RAM Usage", 58,
              rgb8(120, 255, 120), rgb8(15, 30, 20))

    # --- Status line ---
    let statusBg = rgb8(40, 30, 15)
    let statusFg = rgb8(255, 180, 80)
    b.drawBox(0, 17, 80, 5, fg = statusFg, bg = statusBg)
    b.drawText(2, 18, "Status: All systems nominal",
               fg = rgb8(120, 255, 120), bg = statusBg)
    b.drawText(2, 20, "Uptime: 03:42:17  |  Processes: 142  |  Temp: 52°C",
               fg = statusFg, bg = statusBg)

    discard r.render(true)
    sleep(4000)
  finally:
    restoreTerminal()

main()
