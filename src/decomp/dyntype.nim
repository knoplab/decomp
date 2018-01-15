
## Nim compatibility layer for the plugin dynamic slot typing API.

type
  TypeKind* = enum
    TK_F32, TK_F64, TK_I8, TK_I16, TK_I32, TK_I64, TK_U8, TK_U16, TK_U32, TK_U64,
    TK_OBJECT, TK_POINTER, TK_ARRAY
  SlotType* = object
    kind*: TypeKind
    length*: cint
    elements*: cint
    ident*: cstring
    sons*: ptr ptr SlotType
  SlotDescriptor* = object
    name*: cstring
    typ*: ptr SlotType
  Component* = pointer

proc cmalloc(size: cuint): pointer {. importc: "malloc", header: "malloc.h" .}
proc crealloc(p: pointer; size: cuint): pointer
  {. importc: "realloc", header: "malloc.h" .}
proc cfree(p: pointer) {. importc: "free", header: "malloc.h" .}

proc newSlotType*(kind: TypeKind): ptr SlotType =
  ## Creates a new ``SlotType`` of a given kind, with an optional identifier.
  result = cast[ptr SlotType](cmalloc(cuint sizeof((SlotType))))
  result.kind = kind
  result.length = 0
  result.elements = 0
  result.sons = nil
  return result

proc dispose*(typ: ptr SlotType) =
  ## Deallocates a ``SlotType``.
  if typ.length != 0:
    var sonIndex: cint = 0
    while sonIndex < typ.length:
      dispose(
        cast[ptr ptr SlotType](cast[int](typ.sons) + sonIndex * sizeof(pointer))[])
      inc(sonIndex)
  cfree(typ)

proc add*(typ: ptr SlotType; toAdd: ptr SlotType) =
  ## Adds a son to a given ``SlotType``.
  inc(typ.length, 1)
  typ.sons =
    cast[ptr ptr SlotType](
      crealloc(typ.sons, cuint typ.length * sizeof(pointer)))
  cast[ptr ptr SlotType](
    cast[int](typ.sons) + (typ.length - 1) * sizeof(pointer))[] = toAdd

proc newPointer*(memoryType: ptr SlotType): ptr SlotType =
  ## Creates a new ``SlotType`` representing a pointer.
  result = newSlotType(TK_POINTER)
  result.add(memoryType)
  return result

proc newArray*(elemType: ptr SlotType; elements: cint): ptr SlotType =
  ## Creates a new ``SlotType`` representing an array.
  result = newSlotType(TK_ARRAY)
  result.elements = elements
  result.add(elemType)
  return result

proc newObject*(types: varargs[ptr SlotType]): ptr SlotType =
  ## Creates a new ``SlotType`` representing an object
  result = newSlotType(TK_OBJECT)
  for elem in types:
    result.add elem

proc copy*(typ: ptr SlotType): ptr SlotType =
  ## Performs a deep copy of a ``SlotType``.
  result = newSlotType(typ.kind)
  result.length = 0
  result.elements = typ.elements
  result.ident = typ.ident
  for idx in 0 ..< typ.length:
    result.add copy(
      cast[ptr ptr SlotType](cast[int](typ.sons) + idx * sizeof(pointer))[])

proc `~==`*(typ1: ptr SlotType; typ2: ptr SlotType): bool =
  ## Checks two ``SlotType``s for equality.
  if typ1.kind != typ2.kind: return false
  if typ1.length != typ2.length: return false
  if typ1.length != 0:
    var sonIndex: cint = 0
    while sonIndex < typ1.length:
      if not(cast[ptr ptr SlotType](cast[int](typ1.sons) + sonIndex * sizeof(ptr SlotType))[] ~==
         cast[ptr ptr SlotType](cast[int](typ2.sons) + sonIndex * sizeof(ptr SlotType))[]):
        return false
      inc(sonIndex)
  return true
