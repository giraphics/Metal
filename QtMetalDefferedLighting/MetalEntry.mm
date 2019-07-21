#include "Renderer/AAPLRenderer_macOS.h"
#include <QWindow>
#include <QFile>
#include <QDebug>
#include <QMacCocoaViewContainer>

#define AAPLPlatformRenderer AAPLRenderer_macOS
AAPLPlatformRenderer* _renderer;

id <MTLLibrary> getLibrary(const QString& p_ShaderFile, id <MTLDevice> device)
{
    NSError* error = nil;
    id <MTLLibrary> library = nil;
    QString shaderName = p_ShaderFile;

    bool useBinaryShader = false;
    if (p_ShaderFile.contains(".metallib"))
    {
        useBinaryShader = true;
    }

    QFile shadersFile(shaderName);
    if (useBinaryShader)
    {
        if (shadersFile.open(QIODevice::ReadOnly))
        {
            QByteArray shaders = shadersFile.readAll();
            dispatch_data_t data = dispatch_data_create(shaders.constData(), shaders.size(),
                                   dispatch_get_main_queue(), DISPATCH_DATA_DESTRUCTOR_DEFAULT);
            library = [device newLibraryWithData:data error:&error];
            dispatch_release(data);
            shadersFile.close();
        }
    }
    else
    {
        if (shadersFile.open(QFile::ReadOnly | QFile::Text))
        {
            QTextStream in(&shadersFile);
            QString fileTextData;
            fileTextData.append(in.readAll());

            NSString* fileText = [NSString stringWithCString:fileTextData.toStdString().c_str()
                                               encoding:[NSString defaultCStringEncoding]];

            library = [device newLibraryWithSource:fileText options:nil error:&error];
            shadersFile.close();
        }
    }

    if (error)
    {
        NSLog(@"Metal shader error");
        NSString* message = [NSString stringWithFormat:@"%s\n%@\n%@\n%@", __PRETTY_FUNCTION__, [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]];
        NSLog(message);
    }

    return library;
}

MTKView* DefferredLightingView()
{
    MTKView* mtkView = [[[MTKView alloc] init] autorelease];
    mtkView.device = MTLCreateSystemDefaultDevice();
    if (!mtkView.device)
    {
        qFatal("Metal is not supported");
    }

    _renderer = [[AAPLPlatformRenderer alloc] initWithMetalKitView:mtkView];

    if(!_renderer)
    {
        NSLog(@"Renderer failed initialization");
        return NULL;
    }

    mtkView.delegate = _renderer;

    return mtkView;
}

extern "C" QMacCocoaViewContainer* DefferredLightingCocoaView()
{
    return new QMacCocoaViewContainer(reinterpret_cast<NSView*>(DefferredLightingView()), NULL);
}

extern "C" QWindow* DefferredLighting()
{
    return QWindow::fromWinId((WId)DefferredLightingView());
//    QWindow* window = QWindow::fromWinId((WId)DefferredLightingView());
//    NSView* p_NSView = reinterpret_cast<NSView*>(window->winId());

//    if (![p_NSView.layer isKindOfClass:[CAMetalLayer class]])
//    {
//        [p_NSView setLayer:[CAMetalLayer layer]];
//        [p_NSView setWantsLayer:YES];
//    }
//    return window;
}

extern "C" QWidget* DefferredLightingQMacCocoaViewContainer(QWidget* p_Parent = NULL)
{
    QMacCocoaViewContainer *cocoaViewContainer = new QMacCocoaViewContainer(0, p_Parent);
    cocoaViewContainer->move(100, 100);
    cocoaViewContainer->resize(300, 300);

    cocoaViewContainer->setCocoaView(DefferredLightingView());

    return cocoaViewContainer;
}

extern "C" void CleanUpMetal()
{
    [_renderer release];
}
