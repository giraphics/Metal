TEMPLATE = app

QT       += core gui
greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

QMAKE_OBJECTIVE_CFLAGS += -fmodules -fcxx-modules

include($$PWD/Renderer/Renderer.pri)

macx {
    SOURCES += DemoApp.cpp
    OBJECTIVE_SOURCES += MetalEntry.mm \
}

INCLUDEPATH += Renderer/External

# gbuffer shaders
#gbuffershaders_air.target = gbuffershaders.air
#gbuffershaders_air.commands = xcrun -sdk macosx metal -Wall -Wextra -std=osx-metal1.1 $$PWD/gbuffer/AAPLShaders.metal -o Shaders.air

#gbuffershaders_ar.target = haders.metal-ar
#gbuffershaders_ar.commands = xcrun -sdk macosx metal-ar rcs $$PWD/Shaders.metal-ar Shaders.air

#gbuffershaders_lib.target = gbuffershaders222.metallib
#gbuffershaders_lib.commands = xcrun -sdk macosx metallib -o gbuffershaders222.metallib $$PWD/Shaders.metal-ar
#gbuffershaders_lib.depends = gbuffershaders_air
#QMAKE_EXTRA_TARGETS += gbuffershaders_air gbuffershaders_lib
#rcc.depends += $$gbuffershaders_lib.target
#RESOURCES += GBufferResource.qrc

CONFIG += c++11
