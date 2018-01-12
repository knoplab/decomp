# Pluggable decision architecture in Nim.
import component

type
  FlowInput* = ref object
    ## A slot for input data in an executable dataflow graph.
    source*: FlowEdge
  FlowOutput* = ref object
    ## A slot for owned output data in an executable dataflow graph.
    ## ``FlowOutput``s are allocated during graph construction.
    sinks*: seq[FlowEdge]
  FlowNode* = ref object
    component*: Component
    incoming*: seq[FlowInput]
    outgoing*: seq[FlowOutput] ## Change to flow output?
  FlowEdge* = ref object
    ready*: Ready
    source*: FlowOutput
    sink*: FlowInput
  FlowGraph* = ref object
    sources*: seq[FlowNode]
    sinks*: seq[FlowNode]
  GraphSpec* = object
    json: string

## Procedures for ``FlowNode``s:
proc newFlowNode*: FlowNode =
  ## Creates a new empty ``FlowNode``.
  new result
  result.incoming = newSeq[FlowInput]()
  result.outgoing = newSeq[FlowOutput]()

proc newFlowNode*(comp: Component): FlowNode =
  ## Creates a new ``FlowNode`` from a ``Component``.
  result = newFlowNode()
  result.component = comp
  # TODO: configure sources and sinks!

proc newFlowNode*(pluginPath: string): FlowNode =
  ## Loads a dynamic library plugin and creates a ``Component`` and
  ## ``FlowNode`` using that plugin.
  ## TODO
  discard

## Procedures for ``FlowEdge``s:
proc newFlowEdge*: FlowEdge =
  ## Creates a new empty ``FlowEdge``.
  new result
  result.ready = nil
  result.source = nil
  result.sink = nil

proc join*(source: FlowOutput; sink: FlowInput): FlowEdge =
  ## Creates a new ``FlowEdge`` to join a source ``FlowSlot``
  ## to a sink ``FlowSlot``.
  result = newFlowEdge()
  result.source = source
  result.sink = sink

## Procedures for ``FlowGraph``s:
proc valid*(graph: FlowGraph): bool =
  ## Checks, whether a given ``FlowGraph`` is acyclic.
  ## TODO
  discard

proc run*(graph: FlowGraph): Ready =
  ## Runs a ``FlowGraph`` eternally, or until inputs are exhausted.
  ## TODO
  discard

proc newFlowGraph*: FlowGraph =
  ## Creates a new empty ``FlowGraph``.
  new result

proc newFlowGraph*(spec: GraphSpec): FlowGraph =
  ## Creates a new ``FlowGraph`` from a JSON specification.
  ## TODO
  discard
