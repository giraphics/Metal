#include "MetalDialog.h"
#include "ui_UiMetalDialog.h"

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

#include <QMacCocoaViewContainer>

@interface MyCustomView : MTKView
@end

// The main view.
@implementation MyCustomView {
    id <MTLCommandQueue> commandQueue;
    dispatch_semaphore_t mtlSemaphore;
    MTLViewport viewport;
    int swapChainBufferCount;
}

- (id)initWithFrame:(CGRect)inFrame
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self = [super initWithFrame:inFrame device:device];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    swapChainBufferCount = 3;

    // Set view settings.
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;

    // Create semaphore for each uniform buffer.
    mtlSemaphore = dispatch_semaphore_create(swapChainBufferCount);

    // Create command queue
    commandQueue = [self.device newCommandQueue];
}

- (void)drawRect:(CGRect)rect
{
    // Wait for an available uniform buffer.
    dispatch_semaphore_wait(mtlSemaphore, DISPATCH_TIME_FOREVER);


    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    passDescriptor.colorAttachments[0].texture = self.currentRenderPassDescriptor.colorAttachments[0].texture;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    static float color = 0.0f;
    color += 0.01;
    if (color > 1.0f)
        color = 0.0f;
    passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(color, color, 0, 1);

    // Create a command buffer.
    id <MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    // Encode render command.
    id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];

    viewport.originX = 0;
    viewport.originY = 0;
    viewport.width   = self.drawableSize.width;
    viewport.height  = self.drawableSize.height;
    [encoder setViewport:viewport];
    [encoder endEncoding];

    // Dispatch semaphore
    __block dispatch_semaphore_t semaphore = mtlSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(semaphore);
    }];

    [commandBuffer presentDrawable:self.currentDrawable];
    [commandBuffer commit];

    // Draw children.
    [super drawRect:rect];
}
@end

MyCustomView* helloWorldView = NULL;

MetalDialog::MetalDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::MetalDialogUI)
{
    ui->setupUi(this);

    m_Container = new QMacCocoaViewContainer(0, ui->frame);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSRect frame = NSMakeRect(0, 0, 256, 256);
    helloWorldView = [[MyCustomView alloc] initWithFrame:frame];
    m_Container->setCocoaView(helloWorldView);

    // Clean up our pool as we no longer need it.
    [pool release];

    ui->verticalLayout->addWidget(m_Container);
    setUpdatesEnabled(true);
}

MetalDialog::~MetalDialog()
{
    delete ui;
}

void MetalDialog::paintEvent(QPaintEvent* p_Event)
{
}


// NOTEs
// http://stackoverflow.com/questions/2154600/run-nsrunloop-in-a-cocoa-command-line-program
// https://gist.github.com/syzdek/3220789
// https://github.com/trojanfoe/RunLoopController
// https://gist.github.com/syzdek/3220789
// https://www.cocoawithlove.com/2010/09/minimalist-cocoa-programming.html
// http://bou.io/RunRunLoopRun.html
// https://shinesolutions.com/2009/06/02/run-loops-vs-threads-in-cocoa/
// http://lapcatsoftware.com/blog/2007/07/10/working-without-a-nib-part-5-open-recent-menu/
