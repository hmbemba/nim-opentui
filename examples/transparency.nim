## transparency.nim — Interactive alpha transparency & blending demo.
##
## Demonstrates multiple overlapping semi-transparent boxes with different
## colors and alpha values.  Text is rendered underneath the transparent
## boxes to show how alpha blending preserves underlying content.  Alpha
## values animate over time to demonstrate the blending effect dynamically.
##
## Original TS source: opentui/packages/examples/src/transparency-demo.ts
##
## Run:  nim c -r -p:src examples/transparency.nim
import std/[os, unicode, math, strutils]
import opentui

const
  W = 80'u32
  H = 24'u32
  Frames = 120
  SleepMs = 60

type
  TransparentBox = object
    x, y, w, h: int
    baseColor: OtuiColor16
    baseAlpha: float
    label: string

# ── Color helpers ──────────────────────────────────────────────

proc blend(fg, bg: OtuiColor16, alpha: float): OtuiColor16 =
  ## Blend fg over bg using alpha (0.0 = fully bg, 1.0 = fully fg).
  let a = max(0.0, min(1.0, alpha))
  result[0] = uint16(float(fg[0]) * a + float(bg[0]) * (1.0 - a))
  result[1] = uint16(float(fg[1]) * a + float(bg[1]) * (1.0 - a))
  result[2] = uint16(float(fg[2]) * a + float(bg[2]) * (1.0 - a))
  result[3] = 65535'u16

# ── Drawing helpers ────────────────────────────────────────────

proc fillRect(b: Buffer, x, y, w, h: int, color: OtuiColor16) =
  let bw = int(b.width())
  let bh = int(b.height())
  for cy in max(0, y) ..< min(bh, y + h):
    for cx in max(0, x) ..< min(bw, x + w):
      b.putCell(cx, cy, " ".runeAt(0), color, color)

proc drawTextAttr(b: Buffer, x, y: int, text: string, fg, bg: OtuiColor16,
                  attrs: uint32 = 0) =
  ## Draw text with an optional attribute bitmask (e.g. attrBold).
  var cx = x
  for r in text.runes:
    b.putCell(cx, y, r, fg, bg, attrs)
    inc cx

proc drawTransparentBox(b: Buffer, box: TransparentBox, bgColor: OtuiColor16,
                         alphaMod: float) =
  ## Draw a filled box with animated alpha.
  let alpha = max(0.0, min(1.0, box.baseAlpha * alphaMod))
  let blended = blend(box.baseColor, bgColor, alpha)
  b.fillRect(box.x, box.y, box.w, box.h, blended)
  b.drawBox(box.x, box.y, box.w, box.h,
            fg = blend(rgb8(255, 255, 255), bgColor, alpha),
            bg = blended)
  # Alpha percentage label centered in box
  let pctStr = $int(alpha * 100) & "%"
  let lx = box.x + (box.w - pctStr.len) div 2
  let ly = box.y + box.h div 2
  b.drawText(lx, ly, pctStr,
             fg = blend(rgb8(255, 255, 255), bgColor, max(alpha, 0.5)),
             bg = blended)

# ── Main ───────────────────────────────────────────────────────

proc main() =
  let bgColor = rgb8(0x0a, 0x0e, 0x14)

  # Transparent boxes — colors and alphas from TS source
  var boxes: array[6, TransparentBox]

  boxes[0] = TransparentBox(
    x: 15, y: 5, w: 25, h: 8,
    baseColor: rgb8(64, 176, 255), baseAlpha: 0.5,
    label: "blue-50")
  boxes[1] = TransparentBox(
    x: 30, y: 7, w: 25, h: 8,
    baseColor: rgb8(255, 107, 129), baseAlpha: 0.75,
    label: "red-75")
  boxes[2] = TransparentBox(
    x: 45, y: 9, w: 25, h: 8,
    baseColor: rgb8(139, 69, 193), baseAlpha: 0.25,
    label: "purple-25")
  boxes[3] = TransparentBox(
    x: 20, y: 11, w: 30, h: 5,
    baseColor: rgb8(88, 214, 141), baseAlpha: 0.375,
    label: "green-37")
  boxes[4] = TransparentBox(
    x: 25, y: 13, w: 20, h: 6,
    baseColor: rgb8(255, 183, 77), baseAlpha: 0.5,
    label: "yellow-50")
  boxes[5] = TransparentBox(
    x: 10, y: 17, w: 65, h: 4,
    baseColor: rgb8(200, 162, 255), baseAlpha: 0.125,
    label: "lavender-12")

  var r = newRenderer(W, H)
  setupTerminal()
  try:
    for frame in 0 .. Frames:
      var b = r.nextBuffer()
      b.clear(bgColor)

      # Header
      let headerFg = rgb8(0x00, 0xD4, 0xAA)
      drawTextAttr(b, 2, 1,
        "Interactive Alpha Transparency & Blending Demo",
        headerFg, bgColor, uint32(attrBold) or uint32(attrUnderline))
      b.drawText(2, 2,
        "Animated alpha values — watch boxes blend with background and each other",
        fg = rgb8(0xA8, 0xA8, 0xB2))

      # Text underneath transparent boxes (should show through)
      let underFg = rgb8(0xFF, 0xB8, 0x4D)
      drawTextAttr(b, 10, 6, "This text should not be selectable",
                   underFg, bgColor, uint32(attrBold))
      drawTextAttr(b, 15, 10, "Selectable text to show character preservation",
                   rgb8(0x7B, 0x68, 0xEE), bgColor, uint32(attrBold))

      # Animate alpha with a gentle sine wave
      let alphaMod = 0.6 + 0.4 * sin(float(frame) * 0.03)

      # Draw boxes in order (later draws on top)
      for box in boxes:
        b.drawTransparentBox(box, bgColor, alphaMod)

      # Status info at bottom
      let statusY = 22
      b.drawText(2, statusY,
        "Frame: " & $frame & "/" & $Frames &
        "  |  Alpha modulation: " & formatFloat(alphaMod, ffDecimal, 2) &
        "  |  6 overlapping transparent boxes",
        fg = rgb8(0x64, 0x74, 0x8B))

      discard r.render(true)
      sleep(SleepMs)
  finally:
    restoreTerminal()

main()
