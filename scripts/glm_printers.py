"""Show GLM vectors and bounded pointer previews without anonymous unions."""

import re

import gdb


def vector_dimension(vector_type):
    vector_type = vector_type.strip_typedefs()
    if vector_type.code != gdb.TYPE_CODE_STRUCT:
        return None
    # CUDA-GDB decorates device types and may omit the glm:: namespace.
    name = vector_type.tag or str(vector_type)
    match = re.search(r"(?:^|\s)(?:glm::)?tvec([234])<", name)
    return int(match.group(1)) if match else None


class GLMVectorPrinter(gdb.ValuePrinter):
    def __init__(self, value, dimension):
        self.value = value
        self.components = "xyzw"[:dimension]

    def to_string(self):
        try:
            return "(" + ", ".join(str(self.value[name]) for name in self.components) + ")"
        except gdb.error:
            return "<unavailable>"

    def children(self):
        for name in self.components:
            yield name, self.value[name]

    def num_children(self):
        return len(self.components)

    def child(self, index):
        name = self.components[index]
        return name, self.value[name]


def buffer_length(value):
    """Use N only for a matching Boids buffer argument, not arbitrary pointers."""
    try:
        frame = gdb.selected_frame()
        count = int(frame.read_var("N"))
        for name in ("pos", "vel", "vel1", "vel2"):
            try:
                candidate = frame.read_var(name)
                if candidate.type.strip_typedefs().code == gdb.TYPE_CODE_PTR and int(candidate) == int(value):
                    return max(0, count)
            except (gdb.error, ValueError):
                continue
    except (gdb.error, ValueError):
        pass
    return None


class GLMVectorPointerPrinter(gdb.ValuePrinter):
    PREVIEW_ELEMENTS = 4

    def __init__(self, value, dimension):
        self.value = value
        self.dimension = dimension

    def to_string(self):
        try:
            address = int(self.value)
        except (gdb.error, ValueError):
            return "<unavailable>"
        if address == 0:
            return "nullptr"
        count = buffer_length(self.value)
        limit = min(count, self.PREVIEW_ELEMENTS) if count is not None else 1
        elements = []
        for index in range(limit):
            try:
                vector = GLMVectorPrinter(self.value[index], self.dimension)
                elements.append("[{}]={}".format(index, vector.to_string()))
            except gdb.error:
                elements.append("[{}]=<unavailable>".format(index))
                break
        if count is not None and count > limit:
            elements.append("... ({} elements)".format(count))
        return "0x{:x} [{}]".format(address, ", ".join(elements))

    def num_children(self):
        try:
            if int(self.value) == 0:
                return 0
        except (gdb.error, ValueError):
            return 0
        count = buffer_length(self.value)
        return min(count, self.PREVIEW_ELEMENTS) if count is not None else 1

    def child(self, index):
        return "[{}]".format(index), self.value[index]

    def children(self):
        for index in range(self.num_children()):
            yield self.child(index)


def glm_vector_lookup(value):
    vector_type = value.type.strip_typedefs()
    if vector_type.code == gdb.TYPE_CODE_PTR:
        dimension = vector_dimension(vector_type.target())
        if dimension:
            return GLMVectorPointerPrinter(value, dimension)
    else:
        dimension = vector_dimension(vector_type)
        if dimension:
            return GLMVectorPrinter(value, dimension)
    # Leave native arrays to GDB so Nsight retains their indexed children.
    # Each element still uses GLMVectorPrinter when GDB creates its varobj.
    return None


if glm_vector_lookup not in gdb.pretty_printers:
    gdb.pretty_printers.append(glm_vector_lookup)
