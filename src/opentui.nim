## opentui.nim — public re-export of the OpenTUI Nim bindings.
##
## High-level usage:
##   import opentui
##   var r = newRenderer(80, 24)
##   var b = r.nextBuffer()
##   b.clear()
##   discard r.render(true)
import ./opentui/[raw, types, renderer, buffer, terminal, dsl]

export raw, types, renderer, buffer, terminal, dsl
