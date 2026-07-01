## Probe: what exception does Nim raise when a dynlib can't be loaded?
import opentui

proc main() =
  echo "before newRenderer"
  try:
    var r = newRenderer(80, 24)
    echo "renderer created, handle=", r.handle
    var b = r.nextBuffer()
    echo "buffer w=", b.width(), " h=", b.height()
  except LibraryError as e:
    echo "caught LibraryError: ", e.msg
  except OSError as e:
    echo "caught OSError: ", e.msg
  except CatchableError as e:
    echo "caught CatchableError (", e.name, "): ", e.msg
  echo "after (graceful)"

main()
