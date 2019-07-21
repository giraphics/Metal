OBJECTIVE_SOURCES +=    $$PWD/AAPLBufferExamination.mm \
                        $$PWD/AAPLMathUtilities.mm \
                        $$PWD/AAPLRenderer.mm \
                        $$PWD/AAPLMesh.mm \
                        $$PWD/AAPLRenderer_macOS.mm

HEADERS +=  $$PWD/AAPLBufferExamination.h \
            $$PWD/AAPLMathUtilities.h \
            $$PWD/AAPLMesh.h \
            $$PWD/AAPLRenderer_macOS.h \
            $$PWD/AAPLRenderer.h

HEADERS +=  $$PWD/Shaders/AAPLConfig.h \
            $$PWD/Shaders/AAPLDefine.h \
            $$PWD/Shaders/AAPLShaderTypes.h \
            $$PWD/Shaders/AAPLShaderCommon.h

RESOURCES += $$PWD/GBufferResource.qrc
