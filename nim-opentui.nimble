# Package

version       = "0.1.0"
author        = "harrison"
description   = "Nim bindings for OpenTUI native Zig core"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires      = "nim >= 2.0.0"

# ---------------------------------------------------------------------------
# Tasks
# ---------------------------------------------------------------------------

task buildNative, "Build OpenTUI native library from source (requires Zig 0.15.2)":
  exec "cd vendor/opentui/packages/core/src/zig && zig build -Doptimize=ReleaseFast"

task check, "Run nim check on all source files":
  # The top-level module re-exports every submodule, so checking it covers the
  # whole public API transitively. We then check each submodule explicitly.
  exec "nim check -p:src src/opentui.nim"
  exec "nim check -p:src src/opentui/raw.nim"
  exec "nim check -p:src src/opentui/types.nim"
  exec "nim check -p:src src/opentui/renderer.nim"
  exec "nim check -p:src src/opentui/buffer.nim"
  exec "nim check -p:src src/opentui/terminal.nim"
  exec "nim check -p:src src/opentui/dsl.nim"

task test, "Compile and run the test suite":
  exec "nim c -p:src -r tests/test_raw.nim"
  exec "nim c -p:src -r tests/test_buffer.nim"
  exec "nim c -p:src -r tests/test_lifecycle.nim"
