import decomp.dyntype
import unittest

suite "dynamic types":
  test "new type":
    let struct = newSlotType(TkObject)
    check struct.kind == TkObject
    dispose struct

  test "add types":
    let struct = newSlotType(TkObject)
    for idx in 0 ..< 10:
      struct.add newSlotType(TkF32)
    for idx in 0 ..< struct.length:
      let
        son =
          cast[ptr ptr SlotType](cast[int](struct.sons) + idx * sizeof(ptr SlotType))[]
      check son.kind == TkF32
    dispose struct

  test "equality":
    let
      struct1 = newSlotType(TkObject)
      struct2 = newSlotType(TkObject)

    for idx in 0 ..< 10:
      struct1.add newSlotType(TkF32)
      struct2.add newSlotType(TkF32)
    struct1.add struct2.copy()
    struct2.add struct2.copy()

    check struct1 ~== struct2
