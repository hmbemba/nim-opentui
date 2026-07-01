## relative_positioning.nim — Relative positioning demo for OpenTUI Nim bindings.
##
## Demonstrates parent-child positioning where child boxes move relative to
## their parents.  Parent A moves in a circular pattern using sin/cos, while
## Parent B moves vertically.  A static box stays fixed for contrast.  Children
## inside each parent maintain their relative positions as the parent moves.
##
## Original TS source: opentui/packages/examples/src/relative-positioning-demo.ts
##
## Run:  nim c -r -p:src examples/relative_positioning.nim
import std/[os, unicode, math]
import opentui

const
  W = 80'u32
  H = 24'u32
  TotalFrames = 120
  SleepMs = 50

type
  PositionedBox = object
    x, y, w, h: int
    bg, border: OtuiColor16
    title: string
    borderStyle: string  # "single", "double", "rounded" (for display only)

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

proc drawBox(b: Buffer, box: PositionedBox) =
  b.fillRect(box.x, box.y, box.w, box.h, box.bg)
  b.drawBox(box.x, box.y, box.w, box.h, fg = box.border, bg = box.bg)
  if box.title.len > 0:
    b.drawText(box.x + 2, box.y, " " & box.title & " ",
               fg = box.border, bg = box.bg)

# ── Main ───────────────────────────────────────────────────────

proc main() =
  let bgColor = rgb8(0x00, 0x11, 0x22)

  # Parent A — purple, moves in a circle
  let parentABg = rgb8(0x22, 0x00, 0x44)
  let parentABorder = rgb8(0xFF, 0x44, 0xFF)

  # Parent B — green, moves vertically
  let parentBBg = rgb8(0x00, 0x44, 0x22)
  let parentBBorder = rgb8(0x44, 0xFF, 0x44)

  # Static box — amber, doesn't move
  let staticBg = rgb8(0x44, 0x22, 0x00)
  let staticBorder = rgb8(0xFF, 0xFF, 0x44)

  var r = newRenderer(W, H)
  setupTerminal()
  try:
    for frame in 0 .. TotalFrames:
      var b = r.nextBuffer()
      b.clear(bgColor)

      let t = float(frame) * 0.04

      # Title
      drawTextAttr(b, 5, 1,
        "Relative Positioning Demo — Child positions are relative to parent",
        rgb8(0xFF, 0xFF, 0x00), bgColor,
        uint32(attrBold) or uint32(attrUnderline))

      # ── Parent A: moves in a circle ──
      let circleRadius = 12
      let parentAX = 20 + int(cos(t) * float(circleRadius))
      let parentAY = 8 + int(sin(t) * float(circleRadius) / 2)
      let parentAW = 40
      let parentAH = 8

      drawBox(b, PositionedBox(
        x: parentAX, y: parentAY, w: parentAW, h: parentAH,
        bg: parentABg, border: parentABorder,
        title: "Parent A (moves in circle)", borderStyle: "double"))

      # Children inside Parent A — flex row of 3 boxes
      let childW = (parentAW - 4) div 3
      for i in 0 ..< 3:
        let cx = parentAX + 2 + i * childW
        let cy = parentAY + 2
        let childBg = if i mod 2 == 0: rgb8(0x44, 0x00, 0x66) else: rgb8(0x66, 0x00, 0x44)
        drawBox(b, PositionedBox(
          x: cx, y: cy, w: childW - 1, h: parentAH - 4,
          bg: childBg, border: rgb8(0xFF, 0x88, 0xFF),
          title: "Child " & $(i + 1), borderStyle: "single"))

      # ── Parent B: moves vertically ──
      let parentBY = 8 + int(sin(t * 0.7) * 6.0)
      let parentBX = 52
      let parentBW = 25
      let parentBH = 8

      drawBox(b, PositionedBox(
        x: parentBX, y: parentBY, w: parentBW, h: parentBH,
        bg: parentBBg, border: parentBBorder,
        title: "Parent B (moves vertically)", borderStyle: "rounded"))

      # Children inside Parent B — text labels
      b.drawText(parentBX + 2, parentBY + 2,
        "Parent B Position: (" & $parentBX & ", " & $parentBY & ")",
        fg = rgb8(0x44, 0xFF, 0x44), bg = parentBBg)
      b.drawText(parentBX + 2, parentBY + 4,
        "Child at (1,3) - relative to parent",
        fg = rgb8(0x88, 0xFF, 0x88), bg = parentBBg)
      b.drawText(parentBX + 2, parentBY + 5,
        "Child at (1,5) - relative to parent",
        fg = rgb8(0x88, 0xFF, 0x88), bg = parentBBg)

      # ── Static box: doesn't move ──
      let staticX = 5
      let staticY = 20
      let staticW = 40
      let staticH = 3

      drawBox(b, PositionedBox(
        x: staticX, y: staticY, w: staticW, h: staticH,
        bg: staticBg, border: staticBorder,
        title: "Static Parent (doesn't move)", borderStyle: "single"))

      b.drawText(staticX + 2, staticY + 1,
        "Static child — never moves",
        fg = rgb8(0xFF, 0xFF, 0x88), bg = staticBg)

      # ── Explanatory text ──
      b.drawText(5, 14,
        "Key Concept: Parent A uses flex layout — children arranged in a row",
        fg = rgb8(0xAA, 0xAA, 0xAA))
      b.drawText(5, 15,
        "When parent moves, children move with it while maintaining layout",
        fg = rgb8(0xAA, 0xAA, 0xAA))
      b.drawText(5, 16,
        "Flex children automatically fit parent width and grow/shrink as needed",
        fg = rgb8(0xAA, 0xAA, 0xAA))

      # Controls
      drawTextAttr(b, 5, 18, "Controls: demo auto-cycles animation",
                   rgb8(255, 255, 255), bgColor, uint32(attrBold))

      discard r.render(true)
      sleep(SleepMs)
  finally:
    restoreTerminal()

main()
