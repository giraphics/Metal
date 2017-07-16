#-------------------------------------------------
#
# Project created by QtCreator 2016-11-10T17:31:02
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = QMacCocoaViewContainerTest
TEMPLATE = app
QMAKE_MAC_SDK = macosx10.12

QMAKE_LFLAGS += -F/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/usr/bin
LIBS += -framework Foundation -lobjc -framework Cocoa -framework Metal -framework MetalKit

SOURCES += main.cpp \
    MetalDialog.mm

HEADERS  += \
    MetalDialog.h

FORMS    += \
    UiMetalDialog.ui
