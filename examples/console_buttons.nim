## console_buttons.nim — Console logging demo with animated buttons.
##
## Draws five colored buttons in a row (LOG, INFO, WARN, ERROR, DEBUG), each
## with a different background color.  The demo cycles through the buttons,
## highlighting one at a time to simulate clicking.  A console output area at
## the bottom displays a simulated log message each time a button is "clicked".
##
## Original TS source: opentui/packages/examples/src/console-demo.ts
##
## Run:  nim c -r -p:src examples/console_buttons.nim
import std/[os, unicode, strutils]
import opentui

const
  W = 80'u32
  H = 24'u32
  SleepMs = 400
  TotalClicks = 25

type
  ButtonDef = object
    label: string
    bg: OtuiColor16
    border: OtuiColor16
    logType: string

# ── Drawing helpers ────────────────────────────────────────────

proc fillRect(b: Buffer, x, y, w, h: int, color: OtuiColor16) =
  let bw = int(b.width())
  let bh = int(b.height())
  for cy in max(0, y) ..< min(bh, y + h):
    for cx in max(0, x) ..< min(bw, x + w):
      b.putCell(cx, cy, " ".runeAt(0), color, color)

proc drawTextAttr(b: Buffer, x, y: int, text: string, fg, bg: OtuiColor16,
                  attrs: uint32 = 0) =
  var cx = x
  for r in text.runes:
    b.putCell(cx, y, r, fg, bg, attrs)
    inc cx

proc drawButton(b: Buffer, x, y, w, h: int, btn: ButtonDef,
                isHighlighted: bool) =
  ## Draw a colored button.  When highlighted, use a brighter background.
  let actualBg = if isHighlighted:
    [uint16(min(65535'u32, uint32(btn.bg[0]) * 13 div 10)),
     uint16(min(65535'u32, uint32(btn.bg[1]) * 13 div 10)),
     uint16(min(65535'u32, uint32(btn.bg[2]) * 13 div 10)),
     65535'u16]
  else:
    btn.bg

  b.fillRect(x, y, w, h, actualBg)
  b.drawBox(x, y, w, h, fg = btn.border, bg = actualBg)

  # Label centered in button
  let lx = x + (w - btn.label.len) div 2
  let ly = y + h div 2
  drawTextAttr(b, lx, ly, btn.label, rgb8(255, 255, 255), actualBg,
               if isHighlighted: uint32(attrBold) else: 0'u32)

  # Log type below label
  let tx = x + (w - btn.logType.len) div 2
  b.drawText(tx, y + h - 1, btn.logType, fg = rgb8(220, 220, 220), bg = actualBg)

# ── Main ───────────────────────────────────────────────────────

proc main() =
  let bgColor = rgb8(0x12, 0x16, 0x23)

  let buttons = [
    ButtonDef(label: "LOG",   bg: rgb8(160, 160, 170),
              border: rgb8(100, 100, 110), logType: "log"),
    ButtonDef(label: "INFO",  bg: rgb8(100, 180, 200),
              border: rgb8(60, 120, 140), logType: "info"),
    ButtonDef(label: "WARN",  bg: rgb8(220, 180, 100),
              border: rgb8(160, 130, 60), logType: "warn"),
    ButtonDef(label: "ERROR", bg: rgb8(200, 120, 120),
              border: rgb8(140, 70, 70), logType: "error"),
    ButtonDef(label: "DEBUG", bg: rgb8(140, 140, 150),
              border: rgb8(90, 90, 100), logType: "debug"),
  ]

  const
    BtnY = 7
    BtnW = 14
    BtnH = 6
    BtnSpacing = 15
    BtnStartX = 3

  # Console output lines (circular buffer)
  var
    consoleLines: array[8, string]
    consoleColors: array[8, OtuiColor16]
    consoleHead = 0
    counters: array[5, int]

  proc addLog(msg: string, color: OtuiColor16) =
    consoleLines[consoleHead] = msg
    consoleColors[consoleHead] = color
    consoleHead = (consoleHead + 1) mod 8

  var r = newRenderer(W, H)
  setupTerminal()
  try:
    for click in 0 .. TotalClicks:
      var b = r.nextBuffer()
      b.clear(bgColor)

      # Title
      drawTextAttr(b, 2, 1, "Console Logging Demo",
                   rgb8(255, 215, 135), bgColor, uint32(attrBold))

      # Instructions
      b.drawText(2, 2,
        "Click buttons to trigger different console log levels | Demo auto-cycles",
        fg = rgb8(176, 196, 222))

      # Status
      let activeBtn = click mod 5
      let statusText = "Last triggered: " & buttons[activeBtn].logType.toUpperAscii() &
                       " #" & $(counters[activeBtn] + 1)
      drawTextAttr(b, 2, 4, statusText,
                   rgb8(144, 238, 144), bgColor, uint32(attrItalic))

      # Draw 5 buttons
      for i in 0 ..< 5:
        drawButton(b, BtnStartX + i * BtnSpacing, BtnY, BtnW, BtnH,
                   buttons[i], isHighlighted = (i == activeBtn))

      # Simulate clicking the active button
      inc counters[activeBtn]
      let logColors = [rgb8(160, 160, 170), rgb8(100, 180, 200),
                       rgb8(220, 180, 100), rgb8(200, 120, 120),
                       rgb8(140, 140, 150)]
      let logMsgs = [
        "LOG   #" & $counters[0] & " — Regular log message",
        "INFO  #" & $counters[1] & " — Informational message",
        "WARN  #" & $counters[2] & " — Something might need attention",
        "ERROR #" & $counters[3] & " — Something went wrong (simulated)",
        "DEBUG #" & $counters[4] & " — Debug variables: x=0.42, y=0.67",
      ]
      addLog(logMsgs[activeBtn], logColors[activeBtn])

      # Decorative separators
      b.drawText(2, 15,
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        fg = rgb8(100, 120, 150))

      # Console output area
      drawTextAttr(b, 2, 16, "Console Output:",
                   rgb8(120, 140, 160), bgColor)
      b.drawBox(1, 17, 78, 6, fg = rgb8(60, 60, 80), bg = bgColor)

      # Display last 5 console lines
      for i in 0 ..< 5:
        let idx = (consoleHead - 5 + i + 8) mod 8
        if consoleLines[idx].len > 0:
          b.drawText(3, 18 + i, consoleLines[idx], fg = consoleColors[idx])

      discard r.render(true)
      sleep(SleepMs)
  finally:
    restoreTerminal()

main()
