TEMPLATE = app

QMAKE_OBJECTIVE_CFLAGS += -fmodules -fcxx-modules
INCLUDEDIRS += hellotriangle
OBJECTIVE_SOURCES += \
    Renderer/AAPLRenderer.mm

SOURCES += main.mm

CONFIG += c++11

