/*
 * Header defining the plugin interface and dynamic typing API for
 * the FlowGraph / Decision system. A component plugin must implement
 * the following interface and expose its typing requirements to the
 * caller via the dynamic typing API below.
 *
 * To implement a plugin for FlowGraph/Decision, include this header and
 * implement the component_X procedures for your plugin, which may be
 * represented as a C++ class, a C struct, or some other construct in a
 * C-ABI-compatible language and compile your plugin into a shared library.
 * Set your environment variable FLOWGRAPH_PATH to include the plugin's
 * folder. FlowGraph/Decision will then be able to load your plugin by name.
 */

#define FLOWGRAPH_DECISION_API_VERSION_MAJOR 0
#define FLOWGRAPH_DECISION_API_VERSION_MINOR 1
#define FLOWGRAPH_DECISION_API_VERSION_PATCH 0

#ifdef __cplusplus
extern "C" {
#endif

#include <stdarg.h>
#include <malloc.h>

// Represents the kind of a SlotType, that is, whether it is a primitive type,
// and if so, which. If not, it specifies, what kind of composite type it is.
typedef enum {
  TK_F32, TK_F64, TK_I8, TK_I16, TK_I32, TK_I64,
  TK_U8, TK_U16, TK_U32, TK_U64, TK_OBJECT,
  TK_POINTER, TK_ARRAY
} TypeKind;

// Represents an arbitrary C-compatible type as a tree-like data structure.
// SlotTypes are nodes of given TypeKinds, with primitive types being
// represented by leaf nodes and composite types by Trees composed of such
// nodes, with structuring nodes representing pointers, arrays and objects.
typedef struct SlotType {
  TypeKind kind;
  int length;
  int elements;
  const char *ident;
  SlotType **sons;
} SlotType;

// Type descriptor for a single slot of a plugin component.
// This describes an input or output slot.
typedef struct {
  const char *name;
  SlotType *typ;
} SlotDescriptor;

typedef void *Component;

// Allocates memory for a component and initializes its state, if any.
Component newComponent();
// Deallocates memory for a component and all its fields.
void component_dispose(Component comp);
// Performs all computations represented by a component.
void component_process(Component comp);
// Runs after all computations represented by a component are done.
void component_done(Component comp);
// Returns the number of input slots of a component.
int component_numInputSlots(Component comp);
// Returns the number of output slots of a component.
int component_numOutputSlots(Component comp);
// Returns SlotDescriptors for all slots of a component.
SlotDescriptor *component_getSlots(Component comp);
// Sets the index'th input slot of a Component to slot.
void component_setInputSlot(Component comp, void *slot, int index);
// Sets the index'th output slot of a Component to slot.
void component_setOutputSlot(Component comp, void *slot, int index);

// Type functions:

// Creates a new type of a given kind, with an optional identifier.
SlotType *newSlotType(TypeKind kind) {
  SlotType *result = (SlotType *)malloc(sizeof(SlotType));
  result->kind = kind;
  result->length = 0;
  result->elements = 0;
  result->sons = NULL;
  return result;
}

void slotType_dispose(SlotType *typ) {
  if (typ->length) {
    for (int sonIndex = 0; sonIndex < typ->length; ++sonIndex)
      slotType_dispose(typ->sons[sonIndex]);
  }
  free(typ);
}

// Adds a son to a given SlotType.
void slotType_add(SlotType *typ, SlotType *toAdd) {
  typ->length += 1;
  typ->sons = (SlotType **)realloc(typ->sons, typ->length * sizeof(SlotType *));
}

// Creates a new SlotType representing a pointer type.
SlotType *slotType_newPointer(SlotType *memoryType) {
  SlotType *result = newSlotType(TK_POINTER);
  slotType_add(result, memoryType);
  return result;
}

// Creates a new SlotType representing an array type of `elements` elements.
SlotType *slotType_newArray(SlotType *elemType, int elements) {
  SlotType *result = newSlotType(TK_ARRAY);
  result->elements = elements;
  slotType_add(result, elemType);
  return result;
}

// Creates a new SlotType representing a struct or Nim object, with the layout
// being specified by a va_list of SlotType pointers.
SlotType *slotType_newObject(SlotType *first, ...) {
  SlotType *result = newSlotType(TK_OBJECT);
  slotType_add(result, first);
  va_list next;
  va_start(next, first);
  SlotType *arg = va_arg(next, SlotType *);
  while (arg) {
    slotType_add(result, arg);
    arg = va_arg(next, SlotType *);
  }
  va_end(next);
  return result;
}

// Perform a deep copy of a SlotType.
SlotType *slotType_copy(SlotType *typ) {
  SlotType *result = newSlotType(typ->kind);
  result->length = 0;
  result->ident = typ->ident;
  result->elements = typ->elements;
  for (int sonIndex = 0; sonIndex < typ->length; ++sonIndex)
    slotType_add(result, slotType_copy(typ->sons[sonIndex]));
  return result;
}

// Checks the equality of two SlotTypes.
int slotType_isEqual(SlotType *typ1, SlotType *typ2) {
  if (typ1->kind != typ2->kind)
    return false;
  if (typ1->length != typ2->length)
    return false;
  if (typ1->length != 0) {
    for (int sonIndex = 0; sonIndex < typ1->length; ++sonIndex) {
      if (!slotType_isEqual(typ1->sons[sonIndex], typ2->sons[sonIndex]))
        return false;
    }
  }
  return true;
}

#ifdef __cplusplus
}
#endif
