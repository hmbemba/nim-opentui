# nim-opentui — Nim bindings for OpenTUI's native Zig core

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`nim-opentui` provides idiomatic Nim bindings for [OpenTUI](https://github.com/anomalyco/opentui)'s
native Zig core. It is a thin FFI layer over OpenTUI's C ABI, wrapped in safe Nim
types with automatic resource management (ORC destructors), plus a small set of
ergonomic helpers (`drawText`, `drawBox`, color constructors, terminal setup).

## Overview

The bindings are organised as a small package of focused modules:

- **`raw.nim`** — exact, boring C ABI imports (`{.cdecl, importc, dynlib.}`). No
  Nim conveniences, one proc per ABI symbol.
- **`types.nim`** — shared error type, color records, attribute bit-flags, and the
  `rgb8` / `rgba` color constructors.
- **`renderer.nim`** — a handle-owning `Renderer` object with an ORC `=destroy` so
  you never leak a native renderer.
- **`buffer.nim`** — a borrowed `Buffer` with `width`, `height`, `clear`, `putCell`,
  `drawText`, and `drawBox`.
- **`terminal.nim`** — terminal setup/restore helpers (`setupTerminal`,
  `restoreTerminal`) and a `RendererConfig`.
- **`dsl.nim`** — a declarative node-tree DSL for building UIs (`Node`, `box`,
  `text`, `stack`, `runTui`).

Everything is re-exported from the top-level `opentui` module, so a single
`import opentui` is all you need.

## Prerequisites

- **Nim >= 2.0.0** (developed and tested on 2.0.8)
- **Zig 0.15.2** — only required if you build the native library from source
- **OpenTUI native library** (`libopentui.so` / `libopentui.dylib` / `opentui.dll`)

## Getting the OpenTUI Native Library

There is no standalone `opentui.dll` distributed separately — OpenTUI's native core is distributed through platform-specific npm packages as prebuilt binaries. Here are three ways to obtain the library for Nim bindings:

### Option 1: Install via npm and extract the binary

The easiest way to get a prebuilt binary is through npm:

```bash
# Install the Windows x64 binary package
npm install @opentui/core-win32-x64

# The native binary will be in:
# node_modules/@opentui/core-win32-x64/
# Look for a .dll, .node, or similar native file
```

> **Note:** The npm package structure suggests the binary is likely a `.node` file (Node.js native addon) or a `.dll` that gets loaded via FFI. Copy the appropriate file to your project or a system library path.

Available platform packages:
- `@opentui/core-win32-x64`
- `@opentui/core-linux-x64`
- `@opentui/core-darwin-arm64`
- `@opentui/core-darwin-x64`

### Option 2: Build from source with Zig

OpenTUI is written in Zig and exposes a C ABI. Build the DLL yourself:

```bash
git clone https://github.com/anomalyco/opentui.git
cd opentui/packages/core

# Build native libraries (requires Zig installed)
bun run build:native
```

The build system creates platform-specific libraries in `zig-out/lib/`:

| Platform | Artifact |
|----------|----------|
| Linux    | `libopentui.so` |
| macOS    | `libopentui.dylib` |
| Windows  | `opentui.dll` |

### Option 3: Check the GitHub Releases

For Windows users, the README mentions: **Download the latest release directly from GitHub Releases**. However, the Releases page typically only shows source archives — the actual prebuilt binaries are distributed through npm (see Option 1 above).

### Important Notes for Nim Bindings

1. **The C ABI is the key**: OpenTUI's native core exposes a C ABI specifically so it "can be used from any language". This enables Go and Rust bindings to exist (`opentui_rust` and Go packages).

2. **No official Nim bindings yet**: As noted by the OpenTUI author, "Right now opentui is really only usable from js/ts ecosystem sadly. There is a really valuable project here for someone to take these and make them easy to use as a library with c API or standard FFI".

3. **The binary format**: The TypeScript bindings use Bun's FFI to load the native library. The actual file may be named differently than `opentui.dll` (it could be `opentui.node` or similar). Use Nim's `dynlib` module to load it dynamically.

## Building the native library

The native core is written in Zig and shipped in the OpenTUI repository. Clone and
build it with Zig:

```bash
git clone https://github.com/anomalyco/opentui
cd opentui/packages/core/src/zig
zig build -Doptimize=ReleaseFast
```

The compiled shared library lands in `zig-out/lib/`:

| Platform | Artifact |
|----------|----------|
| Linux    | `libopentui.so` |
| macOS    | `libopentui.dylib` |
| Windows  | `opentui.dll` |

## Library path setup (CRITICAL)

The bindings load the native library at runtime via `dynlib`, so the OS dynamic
loader **must** be able to find it. Pick one of the platform options below.

### Linux

```bash
# Option A: copy to a standard path
sudo cp libopentui.so /usr/local/lib/
sudo ldconfig

# Option B: set LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/path/to/opentui/packages/core/src/zig/zig-out/lib:$LD_LIBRARY_PATH
```

### macOS

```bash
# Option A: copy to /usr/local/lib
sudo cp libopentui.dylib /usr/local/lib/

# Option B: set DYLD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=/path/to/lib:$DYLD_LIBRARY_PATH
```

### Windows

```cmd
:: Copy opentui.dll next to your .exe, or add its directory to PATH:
set PATH=C:\path\to\opentui\packages\core\src\zig\zig-out\lib;%PATH%
```

## Vendored binary strategy

For zero-friction installs, prebuilt binaries can be placed in a `vendor/`
directory structured by target triple:

```
vendor/
  linux-x64/libopentui.so
  linux-arm64/libopentui.so
  windows-x64/opentui.dll
  macos-arm64/libopentui.dylib
  macos-x64/libopentui.dylib
```

Users have two options:

1. **Build from source** — run `nimble buildNative`, which clones/builds the Zig
   core under `vendor/opentui/` (requires Zig 0.15.2).
2. **Drop in prebuilt binaries** — place the appropriate artifact for your
   platform under `vendor/<target>/` and ensure that directory is on your library
   search path (see [Library path setup](#library-path-setup-critical)).

## Quick start

```nim
import opentui

var r = newRenderer(80, 24)
var b = r.nextBuffer()
b.clear()
b.drawText(2, 2, "Hello, OpenTUI from Nim!", rgb8(0, 255, 0))
discard r.render(true)
```

For a full-screen TUI with proper terminal setup/teardown, wrap your render loop
with the terminal helpers:

```nim
import opentui

setupTerminal()
defer: restoreTerminal()

var r = newRenderer(80, 24)
var b = r.nextBuffer()
b.clear()
b.drawBox(1, 1, 40, 10, rgb8(0, 255, 255))
b.drawText(3, 3, "Press Ctrl+C to exit", rgb8(255, 255, 0))
discard r.render(true)
```

> **Note:** `drawText`/`drawBox` operate on the buffer in memory; `render(true)`
> pushes the buffer to the terminal. The `Renderer` is freed automatically when it
> goes out of scope (ORC), so manual cleanup is not required.

## API reference (brief)

All modules are re-exported by `opentui`, so you can import everything at once.

### `opentui/raw.nim` — exact C ABI imports

| Symbol | Notes |
|--------|-------|
| `otuiLib` | Platform-specific library name (`opentui.dll` / `libopentui.dylib` / `libopentui.so`) |
| `NativeHandle` | `uint32` handle returned by the core |
| `OtuiColor16` | `array[4, uint16]` — RGBA in 16-bit channels |
| `InvalidHandle` | `NativeHandle(0)` sentinel |
| `createRenderer`, `destroyRenderer`, `getNextBuffer`, `getCurrentBuffer` | Renderer lifecycle |
| `render(renderer, force)` | Render the current buffer |
| `getBufferWidth`, `getBufferHeight` | Buffer dimensions |
| `bufferClear`, `bufferGetCharPtr`, `bufferGetFgPtr`, `bufferGetBgPtr`, `bufferGetAttributesPtr` | Direct buffer access |

### `opentui/types.nim` — shared types & color helpers

- `OpenTuiError` — `object of CatchableError`, raised on native failures.
- `Rgba` — `{r, g, b, a: uint16}` color record.
- `Attr` — bit-flag enum: `attrBold`, `attrItalic`, `attrUnderline`, `attrDim`,
  `attrReverse`, `attrStrike` (OR-able into a `uint32`).
- `rgb8(r, g, b: uint8): OtuiColor16` — 8-bit RGB → 16-bit, opaque alpha.
- `rgba(r, g, b: uint16; a = 65535): OtuiColor16` — 16-bit RGBA constructor.
- `toColor(c: Rgba): OtuiColor16` — record → native array.

### `opentui/renderer.nim` — handle-owning renderer

- `Renderer` — object wrapping a `NativeHandle` (`owns` flag prevents double-free).
- `newRenderer(width = 80, height = 24): Renderer` — create and own a renderer.
- `nextBuffer(r): Buffer` — borrow the next buffer for writing.
- `render(r, force = false): uint8` — present the buffer to the terminal.
- `checkHandle(h, msg)` — raise `OpenTuiError` on an invalid handle.
- `=destroy` / `=copy` — ORC hooks (copies become non-owning views).

### `opentui/buffer.nim` — borrowed buffer (owned by the renderer)

- `Buffer` — object wrapping a `NativeHandle` (`owns == false`).
- `width(b): uint32`, `height(b): uint32` — dimensions.
- `clear(b, bg = opaqueBlack)` — fill the buffer with a background color.
- `putCell(b, x, y, ch: Rune, fg, bg, attrs = 0)` — write one rune (out-of-bounds ignored).
- `drawText(b, x, y, text, fg, bg)` — draw a string left-to-right (rune-aware).
- `drawBox(b, x, y, w, h, fg, bg)` — single-line box border (Unicode box-drawing).

### `opentui/terminal.nim` — terminal setup & cleanup

- `ScreenMode` — enum: `alternateScreen`, `mainScreen`, `splitFooter`.
- `RendererConfig` — `{width, height, screenMode, exitOnCtrlC, mouse}`.
- `defaultConfig(): RendererConfig` — 80×24 alternate screen, Ctrl+C exit.
- `setupTerminal(config = defaultConfig())` — enter alt screen, hide cursor, optional mouse.
- `restoreTerminal()` — show cursor, disable mouse, leave alt screen.

### `opentui/dsl.nim` — declarative node-tree DSL *(coming soon)*

A declarative API for building component trees (nodes, layout, state) on top of the
imperative buffer API. Not yet implemented; tracked separately.

## Examples

The `examples/` directory contains runnable demos (syntax-checkable without the
native library, runnable once `libopentui` is on your library path):

| File | Description |
|------|-------------|
| `hello.nim` | Minimal green-text smoke test — the full create→write→render pipeline. |
| `boxes.nim` | Box-drawing and layout with `drawBox`. |
| `progress.nim` | Animated progress bar render loop. |
| `dashboard.nim` | Multi-panel dashboard composition. |

Syntax-check an example without linking:

```bash
nim check -p:src examples/hello.nim
```

Run an example (requires the native library on your library path):

```bash
nim c -p:src -r examples/hello.nim
```

## Testing

Tests live in `tests/` and can be syntax-checked without the native library, or
compiled and run once the library is available.

```bash
# Syntax-check a test (no linking, no libopentui needed)
nim check -p:src tests/test_raw.nim

# Run a test (requires libopentui on the library path)
nim c -p:src -r tests/test_raw.nim

# Run via nimble
nimble test
```

## Packaging tasks

The `opentui.nimble` file defines helper tasks:

```bash
nimble check        # run nim check across all source files
nimble test         # compile and run the test suite
nimble buildNative  # build the OpenTUI native library from source (needs Zig)
```

## License

MIT — see [LICENSE](LICENSE).
