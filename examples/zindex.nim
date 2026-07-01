## zindex.nim — Nested z-index layering demo for OpenTUI Nim bindings.
##
## Simulates z-index layering by drawing overlapping boxes in z-order (lowest
## first, highest last).  Three groups (A/B/C) of nested boxes overlap each
## other.  The demo cycles through 4 animation phases where z-indices change,
## showing how parent z-index controls group layering while child z-index
## controls order within a group.
##
## Original TS source: opentui/packages/examples/src/nested-zindex-demo.ts
##
## Run:  nim c -r -p:src examples/zindex.nim
import std/[os, unicode, math, strutils, algorithm]
import opentui

const
  W = 80'u32
  H = 24'u32
  FramesPerPhase = 40   # ~2 seconds at 50ms/frame
  TotalFrames = FramesPerPhase * 4
  SleepMs = 50

type
  ZBox = object
    x, y, w, h: int
    bg, border: OtuiColor16
    title: string
    text: string
    textFg: OtuiColor16
    zIndex: int

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

proc drawZBox(b: Buffer, box: ZBox) =
  ## Draw a filled box with border, title, and inner text.
  b.fillRect(box.x, box.y, box.w, box.h, box.bg)
  b.drawBox(box.x, box.y, box.w, box.h, fg = box.border, bg = box.bg)
  if box.title.len > 0:
    b.drawText(box.x + 2, box.y, " " & box.title & " ",
               fg = box.border, bg = box.bg)
  if box.text.len > 0:
    drawTextAttr(b, box.x + 2, box.y + 2, box.text,
                 box.textFg, box.bg, uint32(attrBold))

proc drawSorted(b: Buffer, boxes: seq[ZBox]) =
  ## Draw boxes sorted by z-index (lowest first = drawn first = behind).
  var sorted = boxes
  sorted.sort(proc(a, b: ZBox): int = a.zIndex - b.zIndex)
  for box in sorted:
    b.drawZBox(box)

# ── Phase definitions ──────────────────────────────────────────

type PhaseInfo = object
  zA, zB, zC: int
  titleA, titleB, titleC: string
  desc: string

const Phases = [
  PhaseInfo(zA: 100, zB: 50, zC: 20,
    titleA: "Parent A (z=100)", titleB: "Parent B (z=50)", titleC: "Parent C (z=20)",
    desc: "Original Hierarchy"),
  PhaseInfo(zA: 50, zB: 20, zC: 100,
    titleA: "Parent A (z=50)", titleB: "Parent B (z=20)", titleC: "Parent C (z=100)",
    desc: "C Group on Top"),
  PhaseInfo(zA: 20, zB: 100, zC: 50,
    titleA: "Parent A (z=20)", titleB: "Parent B (z=100)", titleC: "Parent C (z=50)",
    desc: "B Group on Top"),
  PhaseInfo(zA: 60, zB: 60, zC: 60,
    titleA: "Parent A (z=60)", titleB: "Parent B (z=60)", titleC: "Parent C (z=60)",
    desc: "Equal Parents (child z-index matters)"),
]

# ── Main ───────────────────────────────────────────────────────

proc main() =
  let bgColor = rgb8(0x00, 0x11, 0x22)

  var r = newRenderer(W, H)
  setupTerminal()
  try:
    for frame in 0 .. TotalFrames:
      var b = r.nextBuffer()
      b.clear(bgColor)

      let phaseIdx = frame div FramesPerPhase
      let phase = Phases[phaseIdx]

      # Title
      drawTextAttr(b, 10, 2, "Nested Render Objects & Z-Index Demo",
                   rgb8(0xFF, 0xFF, 0x00), bgColor,
                   uint32(attrBold) or uint32(attrUnderline))

      # Build all boxes for this frame
      var boxes: seq[ZBox] = @[]

      # Group A — purple/magenta
      boxes.add(ZBox(
        x: 15, y: 8, w: 25, h: 6,
        bg: rgb8(0x22, 0x00, 0x44), border: rgb8(0xFF, 0x44, 0xFF),
        title: phase.titleA, text: "Child A1 (z=10)",
        textFg: rgb8(0xFF, 0x44, 0xFF), zIndex: phase.zA))
      boxes.add(ZBox(
        x: 20, y: 11, w: 15, h: 4,
        bg: rgb8(0x44, 0x00, 0x44), border: rgb8(0xFF, 0x88, 0xFF),
        title: "", text: "Child A2 (z=5)",
        textFg: rgb8(0xFF, 0x88, 0xFF), zIndex: phase.zA - 5))

      # Group B — green
      boxes.add(ZBox(
        x: 30, y: 12, w: 25, h: 6,
        bg: rgb8(0x00, 0x44, 0x22), border: rgb8(0x44, 0xFF, 0x44),
        title: phase.titleB, text: "Child B1 (z=20)",
        textFg: rgb8(0x44, 0xFF, 0x44), zIndex: phase.zB))
      boxes.add(ZBox(
        x: 35, y: 15, w: 15, h: 4,
        bg: rgb8(0x00, 0x44, 0x00), border: rgb8(0x88, 0xFF, 0x88),
        title: "", text: "Child B2 (z=15)",
        textFg: rgb8(0x88, 0xFF, 0x88), zIndex: phase.zB - 5))

      # Group C — yellow/amber
      boxes.add(ZBox(
        x: 45, y: 16, w: 25, h: 6,
        bg: rgb8(0x44, 0x22, 0x00), border: rgb8(0xFF, 0xFF, 0x44),
        title: phase.titleC, text: "Child C1 (z=30)",
        textFg: rgb8(0xFF, 0xFF, 0x44), zIndex: phase.zC))
      boxes.add(ZBox(
        x: 50, y: 19, w: 15, h: 4,
        bg: rgb8(0x44, 0x44, 0x00), border: rgb8(0xFF, 0xFF, 0x88),
        title: "", text: "Child C2 (z=25)",
        textFg: rgb8(0xFF, 0xFF, 0x88), zIndex: phase.zC - 5))

      # Draw all boxes sorted by z-index
      b.drawSorted(boxes)

      # Explanation text at bottom
      b.drawText(2, 18,
        "Key: parent z-index determines group layering, child z-index orders within group",
        fg = rgb8(0xAA, 0xAA, 0xAA))
      b.drawText(2, 19,
        "Even if Child C1 has z=30, it renders behind A & B when Parent C has low z-index",
        fg = rgb8(0xAA, 0xAA, 0xAA))

      # Phase indicator
      let phaseText = "Animation Phase: " & $(phaseIdx + 1) & "/4 — " & phase.desc
      drawTextAttr(b, 2, 21, phaseText, rgb8(255, 255, 255), bgColor, uint32(attrBold))

      # Z-index display
      let zText = "Current Z-Indices — A:" & $phase.zA &
                  ", B:" & $phase.zB & ", C:" & $phase.zC
      b.drawText(2, 22, zText, fg = rgb8(255, 255, 255))

      discard r.render(true)
      sleep(SleepMs)
  finally:
    restoreTerminal()

main()
