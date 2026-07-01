## styled_text.nim — Styled text demo for OpenTUI Nim bindings.
##
## Demonstrates text rendering with different colors, attributes (bold,
## underline, italic), custom hex colors, and background colors.  Includes
## an animated "real-time dashboard" section that updates CPU, memory,
## network, and temperature values using sin() over time.
##
## Original TS source: opentui/packages/examples/src/styled-text-demo.ts
##
## Run:  nim c -r -p:src examples/styled_text.nim
import std/[os, unicode, math, strutils]
import opentui

const
  W = 80'u32
  H = 24'u32
  TotalFrames = 120
  SleepMs = 50

# ── Color constants ────────────────────────────────────────────

let
  cBold      = rgb8(255, 255, 255)
  cBlue      = rgb8(100, 149, 237)
  cRed       = rgb8(255, 107, 107)
  cGreen     = rgb8(86, 211, 100)
  cYellow    = rgb8(210, 153, 34)
  cCyan      = rgb8(100, 200, 255)
  cOrange    = rgb8(255, 165, 0)
  cPurple    = rgb8(155, 89, 182)
  cGray      = rgb8(136, 136, 136)
  cDarkGray  = rgb8(68, 68, 68)
  cWhite     = rgb8(240, 246, 252)
  cBgYellow  = rgb8(210, 153, 34)
  cBlack     = rgb8(0, 0, 0)
  cBgDark    = rgb8(0, 17, 34)
  cFgLink    = rgb8(100, 180, 255)
  cBgPanel   = rgb8(0, 17, 34)
  cBorderCyan = rgb8(0, 255, 255)

# ── Drawing helpers ────────────────────────────────────────────

type
  TextSegment = tuple[text: string, fg: OtuiColor16, attrs: uint32]

proc drawStyled(b: Buffer, x, y: int, segments: openArray[TextSegment],
                bg: OtuiColor16) =
  ## Draw multiple text segments on the same line with different colors/attrs.
  var cx = x
  for seg in segments:
    for r in seg.text.runes:
      b.putCell(cx, y, r, seg.fg, bg, seg.attrs)
      inc cx

proc drawTextAttr(b: Buffer, x, y: int, text: string, fg, bg: OtuiColor16,
                  attrs: uint32 = 0) =
  var cx = x
  for r in text.runes:
    b.putCell(cx, y, r, fg, bg, attrs)
    inc cx

proc fillRect(b: Buffer, x, y, w, h: int, color: OtuiColor16) =
  let bw = int(b.width())
  let bh = int(b.height())
  for cy in max(0, y) ..< min(bh, y + h):
    for cx in max(0, x) ..< min(bw, x + w):
      b.putCell(cx, cy, " ".runeAt(0), color, color)

# ── Main ───────────────────────────────────────────────────────

proc main() =
  var r = newRenderer(W, H)
  setupTerminal()
  try:
    for frame in 0 .. TotalFrames:
      var b = r.nextBuffer()
      b.clear(cBgDark)

      let t = float(frame) * 0.05

      # ── Example 1: "House" poem with blue styling ──
      drawStyled(b, 2, 2, [
        ("There's a ", cWhite, 0'u32),
        ("house", cBlue, uint32(attrUnderline)),
        (",\nWith a ", cWhite, 0'u32),
        ("window", cBlue, uint32(attrBold)),
        (",\nAnd a ", cWhite, 0'u32),
        ("corvette", cBlue, 0'u32),
        ("\nAnd everything is blue", cWhite, 0'u32),
      ], cBgDark)

      # ── Example 2: Status messages with mixed colors ──
      drawStyled(b, 2, 8, [
        ("ERROR: ", cRed, uint32(attrBold)),
        ("Connection failed", cWhite, 0'u32),
      ], cBgDark)
      drawStyled(b, 2, 9, [
        ("SUCCESS: ", cGreen, uint32(attrBold)),
        ("Data loaded", cWhite, 0'u32),
      ], cBgDark)
      drawStyled(b, 2, 10, [
        ("WARNING: ", cOrange, uint32(attrBold)),
        ("Low memory", cWhite, 0'u32),
      ], cBgDark)
      drawStyled(b, 2, 11, [
        (" NOTICE ", cBlack, 0'u32),
        (" System update available", cWhite, 0'u32),
      ], cBgYellow)

      # ── Example 3: Type examples ──
      drawStyled(b, 40, 2, [
        ("Type Examples:", cWhite, uint32(attrBold)),
      ], cBgDark)
      drawStyled(b, 40, 3, [
        ("Number: ", cWhite, 0'u32),
        ("42", cGreen, 0'u32),
      ], cBgDark)
      drawStyled(b, 40, 4, [
        ("Boolean: ", cWhite, 0'u32),
        ("true", cRed, 0'u32),
      ], cBgDark)
      drawStyled(b, 40, 5, [
        ("Float: ", cWhite, 0'u32),
        ("3.14", cBlue, 0'u32),
      ], cBgDark)
      drawStyled(b, 40, 6, [
        ("Random: ", cWhite, 0'u32),
        ($int(sin(t * 3) * 50 + 50), cCyan, 0'u32),
      ], cBgDark)

      # ── Instructions panel ──
      drawStyled(b, 40, 8, [
        ("Styled Text Demo", cWhite, uint32(attrBold)),
      ], cBgDark)
      drawStyled(b, 40, 9, [
        ("Features demonstrated:", cWhite, uint32(attrUnderline)),
      ], cBgDark)
      drawStyled(b, 40, 10, [
        ("  Template literals with ", cGray, 0'u32),
        ("colors", cBlue, 0'u32),
      ], cBgDark)
      drawStyled(b, 40, 11, [
        ("  ", cGray, 0'u32),
        ("Bold", cWhite, uint32(attrBold)),
        (", ", cGray, 0'u32),
        ("underlined", cWhite, uint32(attrUnderline)),
        (", and other styles", cGray, 0'u32),
      ], cBgDark)
      drawStyled(b, 40, 12, [
        ("  Background colors like ", cGray, 0'u32),
        ("this", cBlack, 0'u32),
      ], cBgYellow)
      drawStyled(b, 40, 13, [
        ("  Custom hex colors like ", cGray, 0'u32),
        ("this red", cRed, 0'u32),
      ], cBgDark)
      drawStyled(b, 40, 14, [
        ("  Hyperlinks: ", cGray, 0'u32),
        ("opentui", cFgLink, uint32(attrUnderline) or uint32(attrBold)),
      ], cBgDark)

      # ── Real-time dashboard ──
      let dashX = 2
      let dashY = 14
      let dashW = 72
      let dashH = 9

      b.fillRect(dashX, dashY, dashW, dashH, cBgPanel)
      b.drawBox(dashX, dashY, dashW, dashH, fg = cBorderCyan, bg = cBgPanel)
      b.drawText(dashX + 2, dashY, " COMPLEX REAL-TIME DASHBOARD ",
                 fg = cBorderCyan, bg = cBgPanel)

      # Compute animated values
      let cpuLoad = sin(t * 0.5) * 50 + 50
      let memUsage = cos(t * 0.3) * 30 + 70
      let netSpeed = abs(sin(t * 2)) * 1000
      let temp = sin(t * 0.1) * 20 + 60
      let battery = max(0.0, 100.0 - t * 0.5)
      let uptime = t
      let wave = sin(t * 3) * 10
      let progress = int((t mod 10.0) / 10.0 * 20.0)

      let dy = dashY + 2

      # System stats header
      drawStyled(b, dashX + 2, dy, [
        ("System Stats: ", cWhite, uint32(attrBold)),
        ("[Update: Every Frame]", cGray, 0'u32),
      ], cBgPanel)

      # Uptime
      drawStyled(b, dashX + 2, dy + 1, [
        ("Uptime: ", cBlue, 0'u32),
        (formatFloat(uptime, ffDecimal, 2) & "s", cGreen, 0'u32),
      ], cBgPanel)

      # CPU Load with bar
      let cpuBarLen = int(cpuLoad / 5.0)
      let cpuBar = repeat("█", cpuBarLen) & repeat("░", 20 - cpuBarLen)
      let cpuColor = if cpuLoad > 80: cRed else: cGreen
      drawStyled(b, dashX + 2, dy + 2, [
        ("CPU Load: ", cRed, 0'u32),
        (formatFloat(cpuLoad, ffDecimal, 1) & "% ", cpuColor,
         if cpuLoad > 80: uint32(attrBold) else: 0'u32),
        (cpuBar, cDarkGray, 0'u32),
      ], cBgPanel)

      # Memory
      let memColor = if memUsage > 85: cRed else: cOrange
      drawStyled(b, dashX + 2, dy + 3, [
        ("Memory: ", rgb8(0xFF, 0x6B, 0x6B), 0'u32),
        (formatFloat(memUsage, ffDecimal, 1) & "%", memColor, 0'u32),
      ], cBgPanel)

      # Network
      let netColor = if netSpeed > 500: cGreen else: cOrange
      drawStyled(b, dashX + 2, dy + 4, [
        ("Network: ", cPurple, 0'u32),
        (formatFloat(netSpeed, ffDecimal, 0) & " KB/s", netColor, 0'u32),
      ], cBgPanel)

      # Temperature
      let tempColor = if temp > 75: cRed else: cBlue
      drawStyled(b, dashX + 2, dy + 5, [
        ("Temp: ", rgb8(0xE7, 0x4C, 0x3C), 0'u32),
        (formatFloat(temp, ffDecimal, 1) & "°C", tempColor, 0'u32),
      ], cBgPanel)

      # Battery
      let batColor = if battery < 20: cRed else: cGreen
      drawStyled(b, dashX + 2, dy + 6, [
        ("Battery: ", rgb8(0xF3, 0x9C, 0x12), 0'u32),
        (formatFloat(battery, ffDecimal, 0) & "%", batColor, 0'u32),
      ], cBgPanel)

      # Progress bar
      let progBar = repeat("█", progress) & repeat("░", 20 - progress)
      drawStyled(b, dashX + 38, dy + 6, [
        ("Progress: ", cPurple, 0'u32),
        (progBar, cGreen, 0'u32),
      ], cBgPanel)

      # Wave value
      let waveColor = if wave >= 0: cGreen else: cRed
      let waveStr = (if wave >= 0: "+" else: "") & formatFloat(wave, ffDecimal, 2)
      drawStyled(b, dashX + 38, dy + 2, [
        ("Wave: ", rgb8(0x1A, 0xBC, 0x9C), 0'u32),
        (waveStr, waveColor, 0'u32),
      ], cBgPanel)

      # Status
      let alertLevel = if temp > 75: "CRITICAL" else: "NORMAL"
      let alertColor = if temp > 75: cRed else: cGreen
      drawStyled(b, dashX + 38, dy + 4, [
        ("Status: ", cWhite, uint32(attrBold)),
        ("● ", cRed, uint32(attrBold)),
        ((if temp > 75: "SYSTEM ALERT" else: "ALL SYSTEMS GO"),
         alertColor, 0'u32),
      ], cBgPanel)

      discard r.render(true)
      sleep(SleepMs)
  finally:
    restoreTerminal()

main()
