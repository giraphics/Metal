#include <QtGui>

#include <Renderer/AAPLRenderer.h>

int main(int argc, char **argv)
{
    // This example shows how to use QWindow with Metal view

    QGuiApplication app(argc, argv);
    QWindow *window = NULL;
    AAPLRenderer *renderer = nil;

    QTimer::singleShot(0, [&window, &renderer]() {

        MTKView *view = [[[MTKView alloc] init] autorelease];
        view.device = MTLCreateSystemDefaultDevice();
        if (!view.device) { qFatal("Metal is not supported"); }

        renderer = [[AAPLRenderer alloc] initWithMetalKitView:view];
        [renderer mtkView:view drawableSizeWillChange:view.drawableSize];
        view.delegate = renderer;

        // Create and show a Qt Window which controls the metal view
        window = QWindow::fromWinId((WId)view);
        window->setTitle("QWindow with MTKView");
        window->resize(640, 480);
        window->show();
    });

    int code = app.exec();

    delete window;
    [renderer release];

    return code;
}
