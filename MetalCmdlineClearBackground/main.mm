#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

@interface MyCustomView : MTKView
@end

int main () {
    @autoreleasepool {
        // Application Window.
        NSRect frame = NSMakeRect(0, 0, 512, 512);
        int style =
        NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask;
        NSWindow* window = [[NSWindow alloc] initWithContentRect:frame
                                                       styleMask:style
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        [window cascadeTopLeftFromPoint:NSMakePoint(100,100)];
        window.title = @"Clear background..";
        [window makeKeyAndOrderFront:nil];
        
        // Custom MTKView.
        MyCustomView* view = [[MyCustomView alloc] initWithFrame:frame];
        window.contentView = view;
        
        // Run.
        [NSApp run];
    }
    return 0;
}

// The main view.
@implementation MyCustomView
{
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
    
    // Create semaphore
    mtlSemaphore = dispatch_semaphore_create(swapChainBufferCount);
    
    // Create logical command queue
    commandQueue = [self.device newCommandQueue];
}

- (void)drawRect:(CGRect)rect {
    // Waiting for Semaphore
    dispatch_semaphore_wait(mtlSemaphore, DISPATCH_TIME_FOREVER);
    
    
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    passDescriptor.colorAttachments[0].texture = self.currentRenderPassDescriptor.colorAttachments[0].texture;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    static float color = 0.0f;
    color += 0.01;
    if (color > 1.0f)
        color = 0.0f;
    passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(color, 0, color, 1);
    
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
    
    // Set the Semaphore.
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
