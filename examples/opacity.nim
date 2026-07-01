## opacity.nim — Alpha-blending opacity demo for OpenTUI Nim bindings.
##
## Demonstrates simulated transparency by alpha-blending overlapping boxes.
## Four boxes at different opacity levels (1.0, 0.8, 0.5, 0.3) overlap each
## other, with labels showing the current opacity value.  An animation phase
## oscillates the opacities using sin().  A nested opacity example shows
## parent (0.7) × child (0.5) = effective 0.35.
##
## Original TS source: opentui/packages/examples/src/opacity-example.ts
##
## Run:  nim c -r -p:src examples/opacity.nim
import std/[os, unicode, math, strutils]
import opentui

const
  W = 80'u32
  H = 24'u32
  Frames = 120
  SleepMs = 50

type
  OpacityBox = object
    x, y, w, h: int
    baseColor: OtuiColor16   # full-opacity color
    opacity: float
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
  ## Fill a rectangle with a solid color.
  let bw = int(b.width())
  let bh = int(b.height())
  for cy in max(0, y) ..< min(bh, y + h):
    for cx in max(0, x) ..< min(bw, x + w):
      b.putCell(cx, cy, " ".runeAt(0), color, color)

proc drawOpacityBox(b: Buffer, box: OpacityBox, bgColor: OtuiColor16) =
  ## Draw a filled box with simulated opacity.
  let blended = blend(box.baseColor, bgColor, box.opacity)
  b.fillRect(box.x, box.y, box.w, box.h, blended)
  b.drawBox(box.x, box.y, box.w, box.h,
            fg = blend(rgb8(255, 255, 255), bgColor, box.opacity),
            bg = blended)
  # Label
  b.drawText(box.x + 2, box.y + 1, box.label,
             fg = blend(rgb8(255, 255, 255), bgColor, box.opacity),
             bg = blended)
  let opacityStr = "Opacity: " & formatFloat(box.opacity, ffDecimal, 1)
  b.drawText(box.x + 2, box.y + 3, opacityStr,
             fg = blend(rgb8(255, 255, 100), bgColor, box.opacity),
             bg = blended)

# ── Main ───────────────────────────────────────────────────────

proc main() =
  let bgColor = rgb8(0x1a, 0x1a, 0x2e)

  # Four overlapping boxes — original TS colors
  var boxes: array[4, OpacityBox]
  let colors = [rgb8(0xe9, 0x45, 0x60),  # red
                rgb8(0x0f, 0x34, 0x60),  # blue
                rgb8(0x53, 0x34, 0x83),  # purple
                rgb8(0x16, 0xa0, 0x85)]  # teal
  let labels = ["Box 1", "Box 2", "Box 3", "Box 4"]
  let baseOpacities = [1.0, 0.8, 0.5, 0.3]

  for i in 0 ..< 4:
    boxes[i] = OpacityBox(
      x: 10 + i * 8, y: 5 + i * 2, w: 20, h: 8,
      baseColor: colors[i],
      opacity: baseOpacities[i],
      label: labels[i])

  var r = newRenderer(W, H)
  setupTerminal()
  try:
    for frame in 0 .. Frames:
      var b = r.nextBuffer()
      b.clear(bgColor)

      # Header
      let headerBg = rgb8(0x16, 0x21, 0x3e)
      b.fillRect(0, 0, 80, 3, headerBg)
      b.drawBox(0, 0, 80, 3, fg = rgb8(0xe9, 0x45, 0x60), bg = headerBg)
      let headerText = if frame < 30:
        "OPACITY DEMO | 1-4: Toggle opacity | A: Animate | Ctrl+C: Exit"
      else:
        "OPACITY DEMO | Animating... | A: Stop | Ctrl+C: Exit"
      b.drawText(2, 1, headerText, fg = rgb8(0xe9, 0x45, 0x60), bg = headerBg)

      # Animate opacities after frame 30
      if frame >= 30:
        let phase = float(frame - 30) * 0.05
        for i in 0 ..< 4:
          boxes[i].opacity = 0.3 + 0.7 * abs(sin(phase + float(i) * 0.5))

      # Draw the four overlapping boxes
      for i in 0 ..< 4:
        b.drawOpacityBox(boxes[i], bgColor)

      # Nested opacity demo (right side)
      let parentAlpha = 0.7
      let childAlpha = 0.5
      let effectiveAlpha = parentAlpha * childAlpha
      let parentColor = rgb8(0xe9, 0x45, 0x60)
      let childColor = rgb8(0x0f, 0x34, 0x60)

      let nX = 52
      let nY = 5
      let nW = 25
      let nH = 12

      # Parent box at 0.7 opacity
      let parentBlended = blend(parentColor, bgColor, parentAlpha)
      b.fillRect(nX, nY, nW, nH, parentBlended)
      b.drawBox(nX, nY, nW, nH,
                fg = blend(rgb8(255, 255, 255), bgColor, parentAlpha),
                bg = parentBlended)
      b.drawText(nX + 2, nY + 1, "Parent: 0.7 opacity",
                 fg = blend(rgb8(255, 255, 255), bgColor, parentAlpha),
                 bg = parentBlended)

      # Child box at 0.5 opacity (effective = 0.35)
      let cX = nX + 2
      let cY = nY + 3
      let cW = nW - 4
      let cH = 7
      let childBlended = blend(childColor, bgColor, effectiveAlpha)
      b.fillRect(cX, cY, cW, cH, childBlended)
      b.drawBox(cX, cY, cW, cH,
                fg = blend(rgb8(255, 255, 255), bgColor, effectiveAlpha),
                bg = childBlended)
      b.drawText(cX + 2, cY + 1, "Child: 0.5 opacity",
                 fg = blend(rgb8(255, 255, 255), bgColor, effectiveAlpha),
                 bg = childBlended)
      b.drawText(cX + 2, cY + 3, "Effective: 0.35",
                 fg = blend(rgb8(255, 204, 0), bgColor, effectiveAlpha),
                 bg = childBlended)

      # Bottom explanation
      b.drawText(2, 22, "Nested opacity: parent 0.7 x child 0.5 = effective 0.35",
                 fg = rgb8(0xaa, 0xaa, 0xaa))

      discard r.render(true)
      sleep(SleepMs)
  finally:
    restoreTerminal()

main()
