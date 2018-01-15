import threadpool, random, os, times
import decomp.dyntype

type
  Ready* = FlowVar[bool] ## Connects different components in time by awaiting \
                         ## on ``Ready`` values.
  Component* = object
    ## Dataflow component implemented by a plugin.
    ## TODO; WIP
    name: string
    slots: seq[Ready]
    handler: Handler
  Handler* = object
    ## Plugin implementing the component interface as specified in
    ## `plugin_interface.h`.
    ## TODO: WIP
    impl: pointer
    numSlots*: proc(): cint
    setSlot*: proc(slot: pointer; slotID: cint): cint
    setOutput*: proc(output: pointer): cint
    getSlotsDescription*: proc(): ptr SlotDescriptor
    done*: proc(): void
    process*: proc(): void
  SlotDescriptor* = object
    ## Describes an input or output slot in a Component.
    dataType: SlotType

proc runHandler*(h: ptr Handler; ready: ptr Ready): bool =
  await ready[]
  h.process()
  return true

## Implicitly copy state to done method!
proc doneHandler*(h: ptr Handler; ready: ptr Ready): bool =
  await ready[]
  h.done()
  return true
