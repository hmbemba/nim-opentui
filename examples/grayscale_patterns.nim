## grayscale_patterns.nim — Animated grayscale pattern demo.
##
## Renders six mathematical patterns (plasma, ripples, waves, starburst, dots,
## checkers) as grayscale terminal graphics using direct buffer cell writes.
## Two side-by-side panels show the pattern at 1:1 and 2× supersampled
## resolution.  Patterns cycle automatically every few seconds.
##
## Original TS source: opentui/packages/examples/src/grayscale-buffer-demo.ts
##
## Run:  nim c -r -p:src examples/grayscale_patterns.nim
import std/[os, unicode, math, strutils]
import opentui

const
  W = 80'u32
  H = 24'u32
  HeaderH = 3
  FramesPerPattern = 60   # ~3 seconds at 50ms/frame
  TotalFrames = FramesPerPattern * 6
  SleepMs = 50

type
  PatternKind = enum
    pkPlasma, pkRipples, pkWaves, pkStarburst, pkDots, pkCheckers

const PatternNames = ["Plasma", "Ripples", "Waves", "Starburst", "Dots", "Checkers"]

# ── Pattern generators — return intensity [0.0, 1.0] ───────────

proc plasma(x, y, w, h: int, t: float): float =
  let nx = float(x) / float(w)
  let ny = float(y) / float(h)
  let v1 = sin(nx * 10 + t)
  let v2 = sin(ny * 10 + t * 0.7)
  let v3 = sin((nx + ny) * 8 + t * 1.3)
  let v4 = sin(sqrt((nx - 0.5)^2 + (ny - 0.5)^2) * 12 - t * 2)
  result = (v1 + v2 + v3 + v4 + 4.0) / 8.0

proc ripples(x, y, w, h: int, t: float): float =
  let cx = float(w) / 2
  let cy = float(h) / 2
  let dist = sqrt(float((x - int(cx))^2 + (y - int(cy))^2))
  let wave = sin(dist * 0.5 - t * 3) * 0.5 + 0.5
  let fade = 1.0 - min(dist / float(max(w, h)), 1.0)
  result = wave * fade

proc waves(x, y, w, h: int, t: float): float =
  let nx = float(x) / float(w)
  let ny = float(y) / float(h)
  let diagonal = (nx + ny) * 6 - t * 2
  let cross = sin(nx * 8 + t) * sin(ny * 8 + t * 0.8)
  result = (sin(diagonal) * 0.5 + 0.5) * 0.6 + (cross * 0.5 + 0.5) * 0.4

proc starburst(x, y, w, h: int, t: float): float =
  let cx = float(w) / 2
  let cy = float(h) / 2
  let dx = float(x) - cx
  let dy = float(y) - cy
  let angle = arctan2(dy, dx) + t * 0.5
  let numRays = 12.0
  let rayAngle = angle * numRays / (2.0 * PI)
  let rayIntensity = abs(sin(rayAngle * PI))
  result = if rayIntensity > 0.7: 1.0 else: 0.0

proc dots(x, y, w, h: int, t: float): float =
  let gridSize = float(min(w, h)) / 6.0
  let offsetX = t * 3
  let offsetY = t * 2
  let gx = ((float(x) + offsetX) mod gridSize + gridSize) mod gridSize - gridSize / 2
  let gy = ((float(y) + offsetY) mod gridSize + gridSize) mod gridSize - gridSize / 2
  let dist = sqrt(gx * gx + gy * gy)
  let radius = gridSize * 0.35
  result = if dist < radius: 1.0 else: 0.0

proc checkers(x, y, w, h: int, t: float): float =
  let cx = float(w) / 2
  let cy = float(h) / 2
  let dx = float(x) - cx
  let dy = float(y) - cy
  let c = cos(t * 0.3)
  let s = sin(t * 0.3)
  let rx = dx * c - dy * s
  let ry = dx * s + dy * c
  let size = float(min(w, h)) / 8.0
  let checkX = int(rx / size)
  let checkY = int(ry / size)
  result = if (checkX + checkY) mod 2 == 0: 1.0 else: 0.0

proc getIntensity(pattern: PatternKind, x, y, w, h: int, t: float): float =
  case pattern
  of pkPlasma:    plasma(x, y, w, h, t)
  of pkRipples:   ripples(x, y, w, h, t)
  of pkWaves:     waves(x, y, w, h, t)
  of pkStarburst: starburst(x, y, w, h, t)
  of pkDots:      dots(x, y, w, h, t)
  of pkCheckers:  checkers(x, y, w, h, t)

# ── Grayscale mapping ──────────────────────────────────────────

const grayChars = [" ", "·", "░", "▒", "▓", "█"]

proc intensityToChar(v: float): Rune =
  let idx = min(int(v * 5.99), 5)
  result = grayChars[idx].runeAt(0)

proc intensityToColor(v: float): OtuiColor16 =
  let c = uint16(v * 65535.0)
  result = [c, c, c, 65535'u16]

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

# ── Render a pattern panel ─────────────────────────────────────

proc renderPanel(b: Buffer, originX, originY, panelW, panelH: int,
                 pattern: PatternKind, t: float, supersample: bool) =
  let ss = if supersample: 2 else: 1
  for y in 0 ..< panelH:
    for x in 0 ..< panelW:
      # For supersampled, average a 2×2 grid
      var sum = 0.0
      for sy in 0 ..< ss:
        for sx in 0 ..< ss:
          let px = x * ss + sx
          let py = y * ss + sy
          sum += getIntensity(pattern, px, py, panelW * ss, panelH * ss, t)
      let v = sum / float(ss * ss)
      let ch = intensityToChar(v)
      let color = intensityToColor(v)
      b.putCell(originX + x, originY + y, ch, color, color)

# ── Main ───────────────────────────────────────────────────────

proc main() =
  let bgColor = rgb8(20, 20, 30)
  let headerBg = rgb8(40, 40, 60)

  let panelW = 37
  let panelH = int(H) - HeaderH - 1  # leave room for header + bottom margin
  let leftX = 1
  let rightX = panelW + 3
  let panelY = HeaderH

  var r = newRenderer(W, H)
  setupTerminal()
  try:
    for frame in 0 .. TotalFrames:
      var b = r.nextBuffer()
      b.clear(bgColor)

      let pattern = PatternKind(frame div FramesPerPattern)
      let t = float(frame) * 0.025

      # Header bar
      b.fillRect(0, 0, int(W), HeaderH, headerBg)

      # Left label
      let leftLabel = "1:1 Standard"
      drawTextAttr(b, leftX + panelW div 2 - leftLabel.len div 2, 1,
                   leftLabel, rgb8(200, 200, 220), headerBg)

      # Right label
      let rightLabel = "2x Supersampled"
      drawTextAttr(b, rightX + panelW div 2 - rightLabel.len div 2, 1,
                   rightLabel, rgb8(100, 200, 255), headerBg)

      # Info line at top
      let info = "[" & PatternNames[int(pattern)] & "] Cycling through 6 patterns"
      drawTextAttr(b, int(W) div 2 - info.len div 2, 0,
                   info, rgb8(150, 150, 170), headerBg)

      # Render left panel (1:1)
      renderPanel(b, leftX, panelY, panelW, panelH, pattern, t, false)

      # Render right panel (2x supersampled)
      renderPanel(b, rightX, panelY, panelW, panelH, pattern, t, true)

      # Divider line
      let dividerX = panelW + 1
      for y in HeaderH ..< int(H):
        b.putCell(dividerX, y, "|".runeAt(0),
                  rgb8(60, 60, 80), bgColor)

      # Bottom info
      let frameInfo = "Frame " & $frame & "/" & $TotalFrames &
                      "  |  Pattern: " & PatternNames[int(pattern)] &
                      "  |  Time: " & $t.formatFloat(ffDecimal, 2)
      b.drawText(2, int(H) - 1, frameInfo, fg = rgb8(100, 100, 120))

      discard r.render(true)
      sleep(SleepMs)
  finally:
    restoreTerminal()

main()
