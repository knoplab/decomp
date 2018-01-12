import threadpool, random, os, times

type
  Ready* = FlowVar[bool]
  Component* = object
    name: string
    slots: seq[FlowVar[pointer]]
    handler: Handler
  Handler* = object
    impl: pointer
    numSlots*: proc(): cint
    setSlot*: proc(slot: pointer; slotID: cint): cint
    setOutput*: proc(output: pointer): cint
    getSlotsDescription*: proc(): ptr SlotDescriptor
    done*: proc(): void
    process*: proc(): void
  SlotDescriptor* = object
    dataType: SlotDataType
  SlotDataType* = object
    name: cstring
    kind: DataKind
    number: cint
  DataKind* = enum
    dkF32, dkF64

## Example:
type SomeHandler = object
  state: int
  slot: ptr array[5, int]
  output: ptr int
proc newComponent: ptr SomeHandler {. cdecl .} =
  result = create(SomeHandler)
  result.state = 0
  result.slot = nil
  result.output = nil
proc disposeComponent(h: ptr SomeHandler) {. cdecl .} = dealloc(h)
proc numSlots(h: ptr SomeHandler): cint {. cdecl .} = 5
proc setSlot(h: ptr SomeHandler; slot: pointer; slotID: cint): cint {. cdecl .} =
  if slotID != 0: return 0
  h.slot = cast[ptr array[5, int]](slot)
  return 1
proc setOutput(h: ptr SomeHandler; output: pointer): cint {. cdecl .} =
  h.output = cast[ptr int](output)
proc process(h: ptr SomeHandler) {. cdecl .} =
  for val in h.slot[]:
    h.state += val
  h.output[] = h.state
proc done(h: SomeHandler) {. cdecl .} =
  sleep(rand(1000))
  echo "My state is: ", h.state

proc makeSomeHandler: Handler =
  let someHandler = newComponent()
  result.impl = someHandler
  result.numSlots = proc: cint = numSlots(someHandler)
  result.setSlot = proc(slot: pointer; slotID: cint): cint = setSlot(someHandler, slot, slotID)
  result.setOutput = proc(output: pointer): cint = setOutput(someHandler, output)
  result.done = proc = done(someHandler[])
  result.process = proc = process(someHandler)

proc runHandler*(h: ptr Handler; ready: ptr Ready): bool =
  await ready[]
  h.process()
  return true

## Implicitly copy state to done method!
proc doneHandler*(h: ptr Handler; ready: ptr Ready): bool =
  await ready[]
  h.done()
  return true

proc makeInput(input: ptr array[5, int]): bool =
  for idx in 0 ..< 5:
    input[idx] = rand(5)
  return true

## Timing
template timeIt(name: static[string], it: untyped): untyped =
  var startTime = epochTime()
  it
  echo "Time taken for ", name, ": ", epochTime() - startTime

## Main loop:
proc main =
  var
    slot = [0, 0, 0, 0, 0]
    output = 0
    handler = makeSomeHandler()
  discard handler.setSlot(slot.addr, 0)
  discard handler.setOutput(output.addr)
  for idx in 0 ..< 10:
    timeIt "processing":
      var
        inputCreated = spawn makeInput(slot.addr)
        inputProcessed = spawn runHandler(handler.addr, inputCreated.addr)
        allDone = spawn doneHandler(handler.addr, inputProcessed.addr)
      await inputProcessed
  sync()

main()
