## layout.nim — Layout patterns demo for OpenTUI Nim bindings.
##
## Cycles through four layout patterns every 3 seconds:
##   1. Horizontal  — sidebar (left 20%) + main content (right 80%)
##   2. Vertical    — top bar (20%) + main content (bottom 80%)
##   3. Centered    — content centered with margins (60% width)
##   4. Three-column — left (15%) + center (70%) + right (15%)
##
## Each layout has a header bar at top and footer bar at bottom.  A small
## "MOVE" box travels across the screen to demonstrate absolute positioning.
##
## Original TS source: opentui/packages/examples/src/simple-layout-example.ts
##
## Run:  nim c -r -p:src examples/layout.nim
import std/[os, unicode, math]
import opentui

const
  W = 80'u32
  H = 24'u32
  FramesPerLayout = 60   # ~3 seconds at 50ms per frame
  TotalFrames = FramesPerLayout * 4
  SleepMs = 50

type
  LayoutKind = enum
    lkHorizontal, lkVertical, lkCentered, lkThreeColumn

  Region = object
    x, y, w, h: int
    bg, border: OtuiColor16
    label: string

# ── Drawing helpers ────────────────────────────────────────────

proc fillRect(b: Buffer, x, y, w, h: int, color: OtuiColor16) =
  let bw = int(b.width())
  let bh = int(b.height())
  for cy in max(0, y) ..< min(bh, y + h):
    for cx in max(0, x) ..< min(bw, x + w):
      b.putCell(cx, cy, " ".runeAt(0), color, color)

proc drawRegion(b: Buffer, r: Region) =
  ## Draw a filled region with border and centered label.
  b.fillRect(r.x, r.y, r.w, r.h, r.bg)
  b.drawBox(r.x, r.y, r.w, r.h, fg = r.border, bg = r.bg)
  if r.label.len > 0:
    let lx = r.x + (r.w - r.label.len) div 2
    let ly = r.y + r.h div 2
    b.drawText(lx, ly, r.label, fg = rgb8(255, 255, 255), bg = r.bg)

proc drawTextAttr(b: Buffer, x, y: int, text: string, fg, bg: OtuiColor16,
                  attrs: uint32 = 0) =
  var cx = x
  for r in text.runes:
    b.putCell(cx, y, r, fg, bg, attrs)
    inc cx

# ── Layout definitions ─────────────────────────────────────────

const
  HeaderH = 3
  FooterH = 3
  ContentY = HeaderH
  ContentH = int(H) - HeaderH - FooterH
  ContentW = int(W)

proc layoutName(kind: LayoutKind): string =
  case kind
  of lkHorizontal:  "Horizontal Layout"
  of lkVertical:    "Vertical Layout"
  of lkCentered:    "Centered Layout"
  of lkThreeColumn: "Three Column Layout"

proc layoutDesc(kind: LayoutKind): string =
  case kind
  of lkHorizontal:  "Sidebar on left, main content on right"
  of lkVertical:    "Sidebar on top, main content below"
  of lkCentered:    "Content centered with margins"
  of lkThreeColumn: "Left sidebar, center content, right sidebar"

proc drawLayout(b: Buffer, kind: LayoutKind) =
  let headerBg = rgb8(0x3b, 0x82, 0xf6)
  let footerBg = rgb8(0x1e, 0x40, 0xaf)
  let sidebarBg = rgb8(0x64, 0x74, 0x8b)
  let mainBg = rgb8(0x91, 0x95, 0x99)
  let rightBg = rgb8(0x7c, 0x3a, 0xed)

  # Header
  b.drawRegion(Region(
    x: 0, y: 0, w: ContentW, h: HeaderH,
    bg: headerBg, border: rgb8(0x1e, 0x40, 0xaf),
    label: "LAYOUT DEMO — " & layoutName(kind)))

  # Footer
  let footerText = "SPACE: next | R: restart | P: autoplay (ON) | WASD: move"
  b.drawRegion(Region(
    x: 0, y: int(H) - FooterH, w: ContentW, h: FooterH,
    bg: footerBg, border: rgb8(0x1e, 0x3a, 0x8a),
    label: footerText))

  case kind
  of lkHorizontal:
    let sw = max(15, ContentW div 5)  # 20%
    b.drawRegion(Region(
      x: 0, y: ContentY, w: sw, h: ContentH,
      bg: sidebarBg, border: rgb8(0x47, 0x54, 0x6b), label: "LEFT SIDEBAR"))
    b.drawRegion(Region(
      x: sw, y: ContentY, w: ContentW - sw, h: ContentH,
      bg: mainBg, border: rgb8(0x64, 0x66, 0x6a), label: "MAIN CONTENT"))

  of lkVertical:
    let th = max(3, ContentH div 5)  # 20%
    b.drawRegion(Region(
      x: 0, y: ContentY, w: ContentW, h: th,
      bg: rgb8(0x05, 0x96, 0x69), border: rgb8(0x06, 0x5f, 0x46),
      label: "TOP BAR"))
    b.drawRegion(Region(
      x: 0, y: ContentY + th, w: ContentW, h: ContentH - th,
      bg: mainBg, border: rgb8(0x64, 0x66, 0x6a), label: "MAIN CONTENT"))

  of lkCentered:
    let cw = max(30, ContentW * 3 div 5)  # 60%
    let cx = (ContentW - cw) div 2
    b.drawRegion(Region(
      x: cx, y: ContentY, w: cw, h: ContentH,
      bg: rgb8(0x7c, 0x3a, 0xed), border: rgb8(0x5b, 0x21, 0xb6),
      label: "CENTERED CONTENT"))

  of lkThreeColumn:
    let sw = max(12, ContentW * 15 div 100)  # 15%
    b.drawRegion(Region(
      x: 0, y: ContentY, w: sw, h: ContentH,
      bg: rgb8(0xdc, 0x26, 0x26), border: rgb8(0x99, 0x1b, 0x1b),
      label: "LEFT"))
    b.drawRegion(Region(
      x: sw, y: ContentY, w: ContentW - sw * 2, h: ContentH,
      bg: rgb8(0x05, 0x96, 0x69), border: rgb8(0x06, 0x5f, 0x46),
      label: "CENTER"))
    b.drawRegion(Region(
      x: ContentW - sw, y: ContentY, w: sw, h: ContentH,
      bg: rightBg, border: rgb8(0x5b, 0x21, 0xb6), label: "RIGHT"))

# ── Main ───────────────────────────────────────────────────────

proc main() =
  var r = newRenderer(W, H)
  setupTerminal()
  try:
    for frame in 0 .. TotalFrames:
      var b = r.nextBuffer()
      b.clear(rgb8(0x00, 0x11, 0x22))

      let kind = LayoutKind(frame div FramesPerLayout)
      b.drawLayout(kind)

      # Description text
      drawTextAttr(b, 2, 1, "LAYOUT DEMO",
                   rgb8(255, 255, 255), rgb8(0x3b, 0x82, 0xf6),
                   uint32(attrBold))

      # "MOVE" box traveling across screen
      let moveX = int(float(frame * 80) / float(TotalFrames))
      let moveY = ContentY + ContentH div 2 +
                  int(sin(float(frame) * 0.1) * 3.0)
      let moveBg = rgb8(0xff, 0x6b, 0x6b)
      b.drawRegion(Region(
        x: moveX, y: moveY, w: 8, h: 3,
        bg: moveBg, border: rgb8(0xff, 0x47, 0x57), label: "MOVE"))

      # Bottom-right absolute positioned box
      b.drawRegion(Region(
        x: int(W) - 22, y: int(H) - FooterH - 4, w: 20, h: 3,
        bg: rgb8(0x22, 0xc5, 0x5e), border: rgb8(0x16, 0xa3, 0x4a),
        label: "BOTTOM RIGHT"))

      # Layout description at bottom
      let descY = int(H) - FooterH - 1
      b.drawText(2, descY, layoutDesc(kind), fg = rgb8(0xaa, 0xaa, 0xaa))

      discard r.render(true)
      sleep(SleepMs)
  finally:
    restoreTerminal()

main()
